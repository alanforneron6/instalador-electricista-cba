nonisolated enum CircuitPointLimitRule {
    static let ruleID = "RULE-CIRCUIT-POINT-LIMIT-001"
    static let source = "AEA 90364-7-770:2017 · referencia puntual pendiente de cotejo"
    enum Status: Equatable { case valid, exceeded(maximum: Int, actual: Int), notApplicable, invalidCount }
    static func maximum(for type: CircuitType) -> Int? {
        switch type { case .iug, .tug, .tue: 15; case .acu: nil }
    }
    static func evaluate(type: CircuitType, count: Int) -> Status {
        guard count >= 0 else { return .invalidCount }
        guard let maximum = maximum(for: type) else { return .notApplicable }
        return count <= maximum ? .valid : .exceeded(maximum: maximum, actual: count)
    }
}
nonisolated enum CircuitPointCompatibilityRule {
    static let ruleID = "RULE-CIRCUIT-POINT-COMPATIBILITY-001"
    enum Status: Equatable { case compatible, incompatible }
    static func evaluate(kind: CircuitPointKind, type: CircuitType) -> Status {
        switch kind {
        case .generalLighting: type == .iug ? .compatible : .incompatible
        case .generalUseOutlet: type == .tug ? .compatible : .incompatible
        }
    }
}
