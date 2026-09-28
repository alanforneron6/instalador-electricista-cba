import Foundation

// MARK: - Potencia estimada, sin certificar otras incumbencias

nonisolated enum CategoryThreePowerScope { case withinPowerScope, outsidePowerScope }

nonisolated struct CategoryThreePowerAssessment {
    let scope: CategoryThreePowerScope
    let limit: ActivePower
    let ruleID: String
    let source: String
}

nonisolated struct ProjectPowerAssessment {
    let apparentDemand: ApparentPower
    let adoptedPowerFactor: PowerFactor
    let estimatedActivePower: ActivePower
    let categoryThreePowerScope: CategoryThreePowerAssessment
    let ruleID: String
    let source: String
}

// MARK: - Motivos independientes y corriente seccional explícita

nonisolated enum SupplyStatus { case monophase, threePhaseRecommended, threePhaseRequired }
nonisolated enum SupplyReason: Hashable {
    case threePhaseLoad(circuitID: UUID)
    case apparentDemandAbove7kVA
    case monophaseCurrentAbove32A
}

nonisolated struct ElectricalSupplyProfile: Equatable {
    let phaseNeutralVolts: Double
    let phasePhaseVolts: Double
    let frequencyHertz: Double
    let ruleID: String
    let source: String
}

nonisolated struct SupplyCurrentCalculation {
    enum Basis { case monophaseHypothesis, balancedThreePhaseReceiver }
    let basis: Basis
    let apparentPower: ApparentPower
    let voltageVolts: Double
    let current: ElectricCurrent
    let criterionID: String
}

nonisolated enum SectionalCurrentState: Equatable {
    case determined(ElectricCurrent)
    case pendingPhaseDistribution
}

nonisolated struct SupplyAssessment {
    let apparentDemand: ApparentPower
    let reasons: Set<SupplyReason>
    let hypotheticalMonophaseCurrent: SupplyCurrentCalculation
    let profile: ElectricalSupplyProfile
    let apparentRecommendationThreshold: ApparentPower
    let currentRecommendationThreshold: ElectricCurrent
    let recommendationRuleID: String
    let recommendationSource: String
    let threePhaseLoadRuleID: String
    let threePhaseLoadSource: String
    let sectionalCurrentRuleID: String
    let sectionalCurrentSource: String

    var status: SupplyStatus {
        if reasons.contains(where: { if case .threePhaseLoad = $0 { true } else { false } }) {
            return .threePhaseRequired
        }
        return reasons.isEmpty ? .monophase : .threePhaseRecommended
    }

    var sectionalCurrentState: SectionalCurrentState {
        status == .monophase ? .determined(hypotheticalMonophaseCurrent.current) : .pendingPhaseDistribution
    }
}

nonisolated struct ProjectElectricalAssessment {
    // Se conserva la traza completa de Feature 004, sin rehacer sumas ni factores.
    let demand: ProjectDemandResult
    let power: ProjectPowerAssessment
    let supply: SupplyAssessment
}

nonisolated enum ProjectAssessmentError: Error, Equatable {
    case incompleteDemand(DemandCalculationError)
    case numericOverflow
}
