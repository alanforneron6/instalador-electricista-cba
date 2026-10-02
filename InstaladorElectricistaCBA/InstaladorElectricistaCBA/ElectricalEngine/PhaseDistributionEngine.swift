import Foundation

nonisolated enum PhaseDistributionEngine {
    // El plan debe estar sincronizado con ambientes. La misma copia alimenta demanda y fases.
    static func assess(plan: CircuitPlan, grade: ElectrificationGrade) -> Result<PhaseDistributionAssessment, PhaseDistributionError> {
        let project: ProjectElectricalAssessment
        switch ProjectSupplyEngine.assess(plan: plan, grade: grade) {
        case .failure(let error): return .failure(.projectAssessment(error))
        case .success(let value): project = value
        }
        if case .determined(let current) = project.supply.sectionalCurrentState {
            return .success(PhaseDistributionAssessment(project: project, state: .monophase(sectionalCurrent: current), circuitPowers: []))
        }
        do {
            // La potencia de cada fila no depende de su fase; está disponible antes de distribuir.
            let powers = try project.demand.circuits.map { demand in
                let adopted = try demand.calculation.get().adoptedDemand
                let coefficient = TotalDemandRule.belongsToGradeDemand(demand.type) ? project.demand.coefficient : 1
                return PhaseCircuitPower(circuitID: demand.circuitID, adoptedDemand: adopted,
                    simultaneousDemand: try ApparentPower(voltAmperes: adopted.voltAmperes * coefficient),
                    appliedCoefficient: coefficient)
            }
            let missing = Set(plan.circuits.filter { $0.supplyNature != .threePhase && $0.phaseAssignment == nil }.map(\.id))
            guard missing.isEmpty else {
                return .success(PhaseDistributionAssessment(project: project,
                    state: .incomplete(circuitIDsWithoutPhase: missing), circuitPowers: powers))
            }
            var contributions: [PhaseCircuitContribution] = []
            var l1 = 0.0, l2 = 0.0, l3 = 0.0
            // DemandEngine devuelve un resultado por circuito, en el orden del mismo plan.
            for (circuit, power) in zip(plan.circuits, powers) {
                let adopted = power.adoptedDemand
                let coefficient = power.appliedCoefficient
                let simultaneous = power.simultaneousDemand
                let calculation: SupplyCurrentCalculation
                let phases: Set<Phase>
                if circuit.supplyNature == .threePhase {
                    calculation = try SupplyCurrentCalculator.balancedThreePhaseReceiver(apparentPower: simultaneous)
                    phases = Set(Phase.allCases)
                } else if let phase = circuit.phaseAssignment {
                    calculation = try SupplyCurrentCalculator.monophase(apparentPower: simultaneous)
                    phases = [phase]
                } else {
                    return .success(PhaseDistributionAssessment(project: project, state: .incomplete(circuitIDsWithoutPhase: [circuit.id]), circuitPowers: powers))
                }
                if phases.contains(.l1) { l1 += calculation.current.amperes }
                if phases.contains(.l2) { l2 += calculation.current.amperes }
                if phases.contains(.l3) { l3 += calculation.current.amperes }
                contributions.append(PhaseCircuitContribution(circuitID: circuit.id, adoptedDemand: adopted,
                    simultaneousDemand: simultaneous, appliedCoefficient: coefficient,
                    phases: phases, currentCalculation: calculation))
            }
            let complete = CompletePhaseDistribution(
                currents: PhaseCurrents(currentL1: try ElectricCurrent(amperes: l1),
                                        currentL2: try ElectricCurrent(amperes: l2),
                                        currentL3: try ElectricCurrent(amperes: l3)),
                contributions: contributions,
                decompositionCriterionID: PhaseContributionCriterion.criterionID,
                decompositionSource: PhaseContributionCriterion.source,
                sectionalRuleID: PhaseSectionalCurrentRule.ruleID, sectionalSource: PhaseSectionalCurrentRule.source)
            return .success(PhaseDistributionAssessment(project: project, state: .complete(complete), circuitPowers: powers))
        } catch { return .failure(.numericOverflow) }
    }
}
