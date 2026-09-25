nonisolated enum PreliminaryElectrificationRule {
    static let ruleID = "RULE-GE-001"
    static let slaRuleID = "RULE-SLA-001"
    static let source = "AEA 90364-7-770 · Edición 2017 · 770.7.3 y Tabla 770.7.I"

    // Upper inclusive boundaries, in square meters, from RULE-GE-001.
    private static let minimumUpperLimit = 60.0
    private static let mediumUpperLimit = 130.0
    private static let elevatedUpperLimit = 200.0

    static func grade(for sla: SquareMeters) -> ElectrificationGrade {
        if sla.value <= minimumUpperLimit { return .minimum }
        if sla.value <= mediumUpperLimit { return .medium }
        if sla.value <= elevatedUpperLimit { return .elevated }
        return .superior
    }
}
