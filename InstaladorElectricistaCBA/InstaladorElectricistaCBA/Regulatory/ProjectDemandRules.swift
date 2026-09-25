// MARK: - Bloque GE y cargas específicas

nonisolated enum GradeSimultaneityRule {
    static let ruleID = "RULE-SIMULTANEITY-001"
    static let source = "AEA 90364-7-770:2017 · 770.8.1 · Tabla 770.8.II"

    // Depende del GE, no del número de circuitos adicionales instalados.
    static func coefficient(for grade: ElectrificationGrade) -> Double {
        switch grade {
        case .minimum: 1.0
        case .medium: 0.8
        case .elevated: 0.7
        case .superior: 0.6
        }
    }
}

nonisolated enum TotalDemandRule {
    static let ruleID = "RULE-TOTAL-DEMAND-001"
    static let source = "AEA 90364-7-770:2017 · 770.8.3.1"

    static func belongsToGradeDemand(_ type: CircuitType) -> Bool {
        switch type {
        case .iug, .tug, .tue: true
        case .acu: false
        }
    }
}
