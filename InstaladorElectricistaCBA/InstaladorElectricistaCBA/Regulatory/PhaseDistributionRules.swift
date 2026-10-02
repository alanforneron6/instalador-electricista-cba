// MARK: - Descomposición adoptada y selección reglamentaria de corriente

nonisolated enum PhaseContributionCriterion {
    static let criterionID = "MODEL-PHASE-CONTRIBUTION-001"
    static let source = "Decisión de modelado de Feature 006: distribuir la DPMS GE multiplicando cada demanda adoptada por el coeficiente GE existente; no es una fórmula textual atribuida a AEA"
}

nonisolated enum PhaseSectionalCurrentRule {
    static let ruleID = "RULE-THREE-PHASE-CURRENT-001"
    static let source = "AEA 90364-7-770:2017 · 770.8.3.1, Nota 1"

    static func maximum(_ currents: PhaseCurrents) -> ElectricCurrent {
        var maximum = currents.currentL1
        for phase in Phase.allCases where currents[phase].amperes > maximum.amperes {
            maximum = currents[phase]
        }
        return maximum
    }

    static func mostLoaded(_ currents: PhaseCurrents) -> Set<Phase> {
        let maximum = maximum(currents).amperes
        // Comparación sin redondear: se conservan todos los máximos del cálculo.
        return Set(Phase.allCases.filter { currents[$0].amperes == maximum })
    }
}
