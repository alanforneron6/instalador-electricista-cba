import Foundation

// MARK: - Criterios adoptados; las referencias pendientes no se declaran verificadas

nonisolated enum ProjectPowerFactorRule {
    static let ruleID = "RULE-PROJECT-POWER-FACTOR-001"
    static let source = "Guía AEA 770 · criterio adoptado para Feature 005 · edición y referencia puntual pendientes de cotejo"
    static let adoptedValue = 0.85
}

nonisolated enum CategoryThreePowerScopeRule {
    static let ruleID = "RULE-CATEGORY-III-SCOPE-001"
    static let source = "ERSeP / Seguridad Eléctrica Córdoba · 10 kW confirmados por el titular · resolución y artículo pendientes de cotejo"
    static let maximumWatts = 10_000.0

    static func evaluate(_ power: ActivePower) throws -> CategoryThreePowerAssessment {
        CategoryThreePowerAssessment(scope: power.watts <= maximumWatts ? .withinPowerScope : .outsidePowerScope,
                                     limit: try ActivePower(watts: maximumWatts), ruleID: ruleID, source: source)
    }
}

nonisolated enum CordobaSupplyProfile {
    static let current = ElectricalSupplyProfile(
        phaseNeutralVolts: 220, phasePhaseVolts: 380, frequencyHertz: 50,
        ruleID: "PROFILE-CORDOBA-SUPPLY-001",
        source: "Perfil Córdoba adoptado para Feature 005 · fuente, edición y referencia puntual pendientes de cotejo")
}

nonisolated enum SupplyRecommendationRule {
    static let ruleID = "RULE-SUPPLY-001"
    static let source = "AEA 90364-7-770:2017 · 770.8.3.3"
    static let apparentThresholdVA = 7000.0
    static let monophaseThresholdAmperes = 32.0

    static func reasons(apparentDemand: ApparentPower, hypotheticalCurrent: ElectricCurrent) -> Set<SupplyReason> {
        var reasons: Set<SupplyReason> = []
        if apparentDemand.voltAmperes > apparentThresholdVA { reasons.insert(.apparentDemandAbove7kVA) }
        if hypotheticalCurrent.amperes > monophaseThresholdAmperes { reasons.insert(.monophaseCurrentAbove32A) }
        return reasons
    }
}

nonisolated enum ThreePhaseLoadRule {
    static let ruleID = "RULE-THREE-PHASE-LOAD-001"
    static let source = "Necesidad técnica del receptor trifásico · criterio explícito de Feature 005, sin atribuir una referencia normativa puntual"

    static func reasons(circuits: [Circuit]) -> Set<SupplyReason> {
        Set(circuits.filter { $0.type == .acu && $0.supplyNature == .threePhase }
            .map { .threePhaseLoad(circuitID: $0.id) })
    }
}

nonisolated enum SectionalCurrentRule {
    static let ruleID = "RULE-THREE-PHASE-CURRENT-001"
    static let source = "AEA 90364-7-770:2017 · 770.8.3.1, Nota 1 · Ib trifásica pendiente de distribución de fases"
}
