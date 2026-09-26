import Foundation

nonisolated enum CircuitIssue: Equatable {
    case pointUnassigned(UUID)
    case incompatibleAssignment(point: UUID, circuit: UUID)
    case missingCircuit(point: UUID)
    case pointLimit(circuit: UUID, maximum: Int, actual: Int)
    case acuLoadMissing(UUID)
    case acuDestinationMissing(UUID)
}
nonisolated struct CircuitValidation {
    let minimum: MinimumCircuitsRule.Status
    let issues: [CircuitIssue]
}

nonisolated enum CircuitEngine {
    enum OperationError: Error { case selectionRequired, unknownPoint, incompatibleAssignment, tooManyPoints, circuitNumberOverflow }

    // Product resource guard, not a regulatory maximum. Keep huge Feature 002 summaries valid.
    static let maximumMaterializedPoints = 100_000
    static func synchronize(_ plan: inout CircuitPlan, rooms: [Room]) throws {
        var total = 0
        for room in rooms {
            for kind in CircuitPointKind.allCases {
                let count = room.projectedPoints.count(for: kind.roomKind)
                guard count <= maximumMaterializedPoints - total else { throw OperationError.tooManyPoints }
                total += count
            }
        }
        var points: [UtilizationPoint] = []
        for room in rooms {
            for kind in CircuitPointKind.allCases {
                let existing = plan.points.filter { $0.roomID == room.id && $0.kind == kind }
                let byOrdinal = Dictionary(existing.map { ($0.ordinal, $0) }, uniquingKeysWith: { first, _ in first })
                for index in 0..<room.projectedPoints.count(for: kind.roomKind) {
                    points.append(byOrdinal[index + 1] ?? UtilizationPoint(id: UUID(), roomID: room.id, kind: kind, ordinal: index + 1))
                }
            }
        }
        plan.points = points
    }

    @discardableResult static func addCircuit(to plan: inout CircuitPlan, type: CircuitType,
                                              destination: String = "", load: DeclaredLoad? = nil,
                                              powerFactor: PowerFactor? = nil, knownDemand: ApparentPower? = nil) throws -> UUID {
        let lastNumber = plan.circuits.map(\.number).max() ?? 0
        guard lastNumber < Int.max else { throw OperationError.circuitNumberOverflow }
        let circuit = try Circuit(number: lastNumber + 1,
                                  type: type, destination: destination, declaredLoad: load,
                                  powerFactor: powerFactor, knownDemand: knownDemand)
        plan.circuits.append(circuit)
        return circuit.id
    }
    static func removeCircuit(_ id: UUID, from plan: inout CircuitPlan) {
        plan.circuits.removeAll { $0.id == id }
        for index in plan.points.indices where plan.points[index].circuitID == id { plan.points[index].circuitID = nil }
        if plan.freeChoiceCircuitID == id { plan.freeChoiceCircuitID = nil }
    }
    static func generateMissing(in plan: inout CircuitPlan, grade: ElectrificationGrade) throws {
        guard let required = MinimumCircuitsRule.configuration(grade: grade, selection: plan.selection) else {
            throw OperationError.selectionRequired
        }
        for (type, count) in [(CircuitType.iug, required.iug), (.tug, required.tug)] {
            let existing = plan.circuits.filter { $0.type == type && (required.free == 0 || $0.id != plan.freeChoiceCircuitID) }.count
            for _ in 0..<max(0, count - existing) { try addCircuit(to: &plan, type: type) }
        }
    }
    static func assign(pointID: UUID, to circuitID: UUID?, in plan: inout CircuitPlan) throws {
        guard let index = plan.points.firstIndex(where: { $0.id == pointID }) else { throw OperationError.unknownPoint }
        if let circuitID {
            guard let circuit = plan.circuits.first(where: { $0.id == circuitID }),
                  CircuitPointCompatibilityRule.evaluate(kind: plan.points[index].kind, type: circuit.type) == .compatible else {
                throw OperationError.incompatibleAssignment
            }
        }
        plan.points[index].circuitID = circuitID
    }
    static func validate(_ plan: CircuitPlan, grade: ElectrificationGrade) -> CircuitValidation {
        var issues: [CircuitIssue] = []
        for point in plan.points {
            guard let id = point.circuitID else { issues.append(.pointUnassigned(point.id)); continue }
            guard let circuit = plan.circuits.first(where: { $0.id == id }) else {
                issues.append(.missingCircuit(point: point.id)); continue
            }
            if CircuitPointCompatibilityRule.evaluate(kind: point.kind, type: circuit.type) != .compatible {
                issues.append(.incompatibleAssignment(point: point.id, circuit: id))
            }
        }
        for circuit in plan.circuits {
            let count = plan.points.filter { $0.circuitID == circuit.id }.count
            if case let .exceeded(maximum, actual) = CircuitPointLimitRule.evaluate(type: circuit.type, count: count) {
                issues.append(.pointLimit(circuit: circuit.id, maximum: maximum, actual: actual))
            }
            if circuit.type == .acu {
                if circuit.declaredLoad == nil { issues.append(.acuLoadMissing(circuit.id)) }
                if circuit.destination.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { issues.append(.acuDestinationMissing(circuit.id)) }
            }
        }
        return CircuitValidation(minimum: MinimumCircuitsRule.evaluate(plan, grade: grade), issues: issues)
    }
}
