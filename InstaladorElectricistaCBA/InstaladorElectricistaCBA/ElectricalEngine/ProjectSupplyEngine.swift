nonisolated enum ProjectSupplyEngine {
    // El plan debe estar sincronizado con los ambientes, como en Feature 004.
    // Calcular desde una sola copia evita mezclar demanda antigua con receptores nuevos.
    static func assess(plan: CircuitPlan, grade: ElectrificationGrade) -> Result<ProjectElectricalAssessment, ProjectAssessmentError> {
        let demand = DemandEngine.project(plan: plan, grade: grade)
        switch demand.total {
        case .failure(let error): return .failure(.incompleteDemand(error))
        case .success(let apparentDemand):
            do {
                let factor = try PowerFactor(ProjectPowerFactorRule.adoptedValue)
                let active = try ActivePower(watts: apparentDemand.voltAmperes * factor.value)
                let power = ProjectPowerAssessment(apparentDemand: apparentDemand, adoptedPowerFactor: factor,
                                                   estimatedActivePower: active,
                                                   categoryThreePowerScope: try CategoryThreePowerScopeRule.evaluate(active),
                                                   ruleID: ProjectPowerFactorRule.ruleID, source: ProjectPowerFactorRule.source)
                let hypothetical = try SupplyCurrentCalculator.monophase(apparentPower: apparentDemand)
                let reasons = SupplyRecommendationRule.reasons(apparentDemand: apparentDemand, hypotheticalCurrent: hypothetical.current)
                    .union(ThreePhaseLoadRule.reasons(circuits: plan.circuits))
                let supply = SupplyAssessment(
                    apparentDemand: apparentDemand, reasons: reasons, hypotheticalMonophaseCurrent: hypothetical,
                    profile: CordobaSupplyProfile.current,
                    apparentRecommendationThreshold: try ApparentPower(voltAmperes: SupplyRecommendationRule.apparentThresholdVA),
                    currentRecommendationThreshold: try ElectricCurrent(amperes: SupplyRecommendationRule.monophaseThresholdAmperes),
                    recommendationRuleID: SupplyRecommendationRule.ruleID, recommendationSource: SupplyRecommendationRule.source,
                    threePhaseLoadRuleID: ThreePhaseLoadRule.ruleID, threePhaseLoadSource: ThreePhaseLoadRule.source,
                    sectionalCurrentRuleID: SectionalCurrentRule.ruleID, sectionalCurrentSource: SectionalCurrentRule.source)
                return .success(ProjectElectricalAssessment(demand: demand, power: power, supply: supply))
            } catch { return .failure(.numericOverflow) }
        }
    }
}
