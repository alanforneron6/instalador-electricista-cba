import Foundation

struct AssignmentProgress {
    let assigned: Int
    let total: Int
    let unassigned: Int

    init(plan: CircuitPlan, validation: CircuitValidation) {
        let relevant = plan.points
        total = relevant.count
        assigned = relevant.filter { point in
            guard let circuit = plan.circuits.first(where: { $0.id == point.circuitID }) else { return false }
            return CircuitPointCompatibilityRule.evaluate(kind: point.kind, type: circuit.type) == .compatible
        }.count
        unassigned = validation.issues.filter { if case .pointUnassigned = $0 { return true }; return false }.count
    }
}

extension CircuitType {
    var displayName: String {
        switch self {
        case .iug: "Iluminación general"
        case .tug: "Tomacorrientes de uso general"
        case .tue: "Tomacorrientes de uso especial"
        case .acu: "Alimentación de carga única"
        }
    }
}

// MARK: - Feedback de la acción, separado de la selección de variante

enum MinimumCircuitAction {
    static func title(for plan: CircuitPlan) -> String {
        plan.circuits.isEmpty ? "Crear circuitos mínimos" : "Completar circuitos mínimos"
    }

    static func perform(plan: inout CircuitPlan, grade: ElectrificationGrade) throws -> String {
        let before = plan.circuits.count
        try CircuitEngine.generateMissing(in: &plan, grade: grade)
        let added = plan.circuits.count - before
        let status = MinimumCircuitsRule.evaluate(plan, grade: grade)
        // Generar no resuelve la posición libre ni su interpretación pendiente.
        if status != .conforming {
            return added > 0
                ? "\(added) circuitos creados. Revisá los pendientes de la estructura mínima."
                : "No faltan circuitos base por crear. Revisá los pendientes de la estructura mínima."
        }
        if added == 0 { return "La estructura mínima ya está completa" }
        return before == 0 ? "\(added) circuitos creados" : "Circuitos mínimos completados"
    }
}

extension UtilizationPoint {
    var assignmentTitle: String {
        switch kind {
        case .generalLighting: "Iluminación \(ordinal) · IUG"
        case .generalUseOutlet: "Tomacorriente \(ordinal) · TUG"
        }
    }

    func compatibleCircuits(in plan: CircuitPlan) -> [Circuit] {
        plan.circuits.filter { CircuitPointCompatibilityRule.evaluate(kind: kind, type: $0.type) == .compatible }
    }
}
