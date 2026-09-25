nonisolated enum MinimumCircuitsRule {
    // Preserve the already documented identifier rather than creating a duplicate rule.
    static let ruleID = "RULE-CIRCUITS-001"
    static let source = "AEA 90364-7-770:2017 · 770.7.4 · Tabla 770.7.II"
    struct Configuration: Equatable {
        let variant: CircuitVariant
        let iug: Int
        let tug: Int
        let free: Int
        var total: Int { iug + tug + free }
    }
    static func configurations(for grade: ElectrificationGrade) -> [Configuration] {
        switch grade {
        case .minimum: [.init(variant: .a, iug: 1, tug: 1, free: 0)]
        case .medium: [.init(variant: .a, iug: 2, tug: 1, free: 0), .init(variant: .b, iug: 1, tug: 2, free: 0)]
        case .elevated: [.init(variant: .a, iug: 2, tug: 3, free: 0), .init(variant: .b, iug: 3, tug: 2, free: 0)]
        case .superior: [.init(variant: .a, iug: 2, tug: 3, free: 1), .init(variant: .b, iug: 3, tug: 2, free: 1)]
        }
    }
    static func configuration(grade: ElectrificationGrade, selection: CircuitSelection?) -> Configuration? {
        let options = configurations(for: grade)
        if options.count == 1 { return options[0] }
        guard selection?.grade == grade else { return nil }
        return options.first { $0.variant == selection?.variant }
    }
    enum Status: Equatable {
        case selectionRequired
        case conforming
        case missing(iug: Int, tug: Int, total: Int)
        case freeChoiceUndefined
        case freeChoicePendingInterpretation
    }
    static func evaluate(_ plan: CircuitPlan, grade: ElectrificationGrade) -> Status {
        guard let required = configuration(grade: grade, selection: plan.selection) else { return .selectionRequired }
        let freeCircuit = required.free > 0 ? plan.circuits.first { $0.id == plan.freeChoiceCircuitID } : nil
        // Reserve the explicitly selected free circuit: it cannot also satisfy a base position.
        let base = plan.circuits.filter { $0.id != freeCircuit?.id }
        let iug = max(0, required.iug - base.filter { $0.type == .iug }.count)
        let tug = max(0, required.tug - base.filter { $0.type == .tug }.count)
        let total = max(0, required.total - plan.circuits.count)
        if iug > 0 || tug > 0 || total > 0 { return .missing(iug: iug, tug: tug, total: total) }
        if required.free > 0 {
            guard let freeCircuit else { return .freeChoiceUndefined }
            if freeCircuit.type == .tue || freeCircuit.type == .acu { return .freeChoicePendingInterpretation }
        }
        return .conforming
    }
}
