nonisolated enum DemandEngine {
    // MARK: - DPMS individual

    static func circuit(_ circuit: Circuit, points: [UtilizationPoint]) -> CircuitDemandResult {
        let assigned = points.filter { $0.circuitID == circuit.id }
        let count = circuit.type == .acu ? nil : assigned.count
        let result: Result<CircuitDemandCalculation, DemandCalculationError>
        if assigned.contains(where: { CircuitPointCompatibilityRule.evaluate(kind: $0.kind, type: circuit.type) != .compatible }) {
            result = .failure(.incompatibleAssignments)
        } else {
            do {
                switch circuit.type {
                case .iug:
                    result = .success(.regulated(try IUGDemandRule.evaluate(pointCount: assigned.count, knownDemand: circuit.knownDemand)))
                case .tug:
                    result = .success(.regulated(try TUGDemandRule.evaluate(knownDemand: circuit.knownDemand)))
                case .tue:
                    result = .success(.regulated(try TUEDemandRule.evaluate(knownDemand: circuit.knownDemand)))
                case .acu:
                    if let load = circuit.declaredLoad {
                        result = ApparentPowerCalculator.calculate(load, powerFactor: circuit.powerFactor).map {
                            // Feature 004 considera toda la potencia resoluble, sin reducciones Ku/Ks.
                            .specific(SpecificLoadDemandCalculation(power: $0, consideredDemand: $0.apparentPower))
                        }
                    } else { result = .failure(.missingDeclaredLoad) }
                }
            } catch let error as DemandCalculationError { result = .failure(error) }
            catch { result = .failure(.numericOverflow) }
        }
        return CircuitDemandResult(circuitID: circuit.id, type: circuit.type, pointCount: count, calculation: result)
    }

    // MARK: - GE y cargas específicas se suman por separado

    static func project(plan: CircuitPlan, grade: ElectrificationGrade) -> ProjectDemandResult {
        let circuits = plan.circuits.map { circuit($0, points: plan.points) }
        let coefficient = GradeSimultaneityRule.coefficient(for: grade)
        let general = circuits.filter { TotalDemandRule.belongsToGradeDemand($0.type) }
        let specific = circuits.filter { !TotalDemandRule.belongsToGradeDemand($0.type) }
        let generalBase = sum(general.map { $0.calculation.map { $0.adoptedDemand } })
        let gradeDemand = generalBase.flatMap { checkedPower($0.voltAmperes * coefficient) }
        let specificDemand = sum(specific.map { $0.calculation.map { $0.adoptedDemand } })
        let resolvedSpecificDemand = sum(specific.compactMap {
            if case .success(let value) = $0.calculation { return .success(value.adoptedDemand) }
            return nil
        })
        // Reutilizamos la validación de las bocas distribuibles del plan.
        let issues = CircuitEngine.validate(plan, grade: grade).issues
        let total: Result<ApparentPower, DemandCalculationError>
        if issues.contains(where: {
            switch $0 {
            case .incompatibleAssignment, .missingCircuit: true
            default: false
            }
        }) {
            total = .failure(.incompatibleAssignments)
        } else if issues.contains(where: { if case .pointUnassigned = $0 { return true }; return false }) {
            total = .failure(.unassignedPoints)
        } else {
            total = sum([gradeDemand, specificDemand])
        }
        return ProjectDemandResult(circuits: circuits, grade: grade, coefficient: coefficient,
            coefficientRuleID: GradeSimultaneityRule.ruleID, coefficientSource: GradeSimultaneityRule.source,
            totalRuleID: TotalDemandRule.ruleID, totalSource: TotalDemandRule.source,
            generalBase: generalBase, gradeDemand: gradeDemand, resolvedSpecificDemand: resolvedSpecificDemand,
            resolvedSubtotal: sum([gradeDemand, resolvedSpecificDemand]), total: total)
    }

    private static func sum(_ powers: [Result<ApparentPower, DemandCalculationError>]) -> Result<ApparentPower, DemandCalculationError> {
        var total = 0.0
        for power in powers {
            switch power {
            case .success(let value): total += value.voltAmperes
            case .failure(let error): return .failure(error)
            }
        }
        return checkedPower(total)
    }

    private static func checkedPower(_ value: Double) -> Result<ApparentPower, DemandCalculationError> {
        do { return .success(try ApparentPower(voltAmperes: value)) }
        catch { return .failure(.numericOverflow) }
    }
}
