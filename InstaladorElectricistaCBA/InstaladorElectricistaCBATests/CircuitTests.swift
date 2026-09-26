import Foundation
import Testing
@testable import InstaladorElectricistaCBA

@Suite("RULE-CIRCUITS-001 — mínimos y variantes")
struct MinimumCircuitsTests {
    @Test(arguments: [
        (ElectrificationGrade.minimum, CircuitVariant.a, 1, 1, 0, 2),
        (.medium, .a, 2, 1, 0, 3), (.medium, .b, 1, 2, 0, 3),
        (.elevated, .a, 2, 3, 0, 5), (.elevated, .b, 3, 2, 0, 5),
        (.superior, .a, 2, 3, 1, 6), (.superior, .b, 3, 2, 1, 6)
    ])
    func configurations(grade: ElectrificationGrade, variant: CircuitVariant, iug: Int, tug: Int, free: Int, total: Int) throws {
        let config = try #require(MinimumCircuitsRule.configurations(for: grade).first { $0.variant == variant })
        #expect(config.iug == iug); #expect(config.tug == tug); #expect(config.free == free); #expect(config.total == total)
        var plan = CircuitPlan(selection: .init(grade: grade, variant: variant))
        try CircuitEngine.generateMissing(in: &plan, grade: grade)
        if free > 0 {
            plan.freeChoiceCircuitID = try CircuitEngine.addCircuit(to: &plan, type: .iug)
        }
        #expect(MinimumCircuitsRule.evaluate(plan, grade: grade) == .conforming)
        let ids = plan.circuits.map(\.id)
        try CircuitEngine.generateMissing(in: &plan, grade: grade)
        #expect(ids == plan.circuits.map(\.id))
        try CircuitEngine.addCircuit(to: &plan, type: .tug)
        #expect(MinimumCircuitsRule.evaluate(plan, grade: grade) == .conforming)
    }
    @Test func missingAndWrongMix() throws {
        var plan = CircuitPlan(selection: .init(grade: .medium, variant: .a))
        #expect(MinimumCircuitsRule.evaluate(plan, grade: .medium) == .missing(iug: 2, tug: 1, total: 3))
        for _ in 0..<3 { try CircuitEngine.addCircuit(to: &plan, type: .tug) }
        #expect(MinimumCircuitsRule.evaluate(plan, grade: .medium) == .missing(iug: 2, tug: 0, total: 0))
    }
    @Test func selectionRequiredAndGradeChanges() throws {
        var plan = CircuitPlan()
        #expect(MinimumCircuitsRule.evaluate(plan, grade: .medium) == .selectionRequired)
        #expect(throws: CircuitEngine.OperationError.self) { try CircuitEngine.generateMissing(in: &plan, grade: .medium) }
        plan.selection = .init(grade: .medium, variant: .b)
        #expect(MinimumCircuitsRule.evaluate(plan, grade: .superior) == .selectionRequired)
        #expect(MinimumCircuitsRule.configurations(for: .minimum).count == 1)
    }
    @Test func freeChoiceIsExplicitAndNeverDoubleCounted() throws {
        var plan = CircuitPlan(selection: .init(grade: .superior, variant: .a))
        try CircuitEngine.generateMissing(in: &plan, grade: .superior)
        try CircuitEngine.addCircuit(to: &plan, type: .tug)
        let validation = CircuitEngine.validate(plan, grade: .superior)
        #expect(validation.minimum == .freeChoiceUndefined)
        #expect(validation.issues.isEmpty)
        plan.freeChoiceCircuitID = plan.circuits.first?.id
        #expect(MinimumCircuitsRule.evaluate(plan, grade: .superior) == .missing(iug: 1, tug: 0, total: 0))
        plan.freeChoiceCircuitID = try CircuitEngine.addCircuit(to: &plan, type: .acu)
        #expect(MinimumCircuitsRule.evaluate(plan, grade: .superior) == .freeChoicePendingInterpretation)
        CircuitEngine.removeCircuit(try #require(plan.freeChoiceCircuitID), from: &plan)
        #expect(plan.freeChoiceCircuitID == nil)
    }
}

@Suite("RULE-CIRCUIT-POINT-LIMIT-001 / RULE-CIRCUIT-POINT-COMPATIBILITY-001")
struct CircuitPointTests {
    @Test(arguments: [CircuitType.iug, .tug, .tue])
    func limits(type: CircuitType) {
        #expect(CircuitPointLimitRule.evaluate(type: type, count: 15) == .valid)
        #expect(CircuitPointLimitRule.evaluate(type: type, count: 16) == .exceeded(maximum: 15, actual: 16))
        #expect(CircuitPointLimitRule.evaluate(type: type, count: -1) == .invalidCount)
    }
    @Test func acuHasNoBocaLimit() {
        #expect(CircuitPointLimitRule.maximum(for: .acu) == nil)
        #expect(CircuitPointLimitRule.evaluate(type: .acu, count: 16) == .notApplicable)
    }
    @Test(arguments: [
        (CircuitPointKind.generalLighting, CircuitType.iug, true), (.generalLighting, .tug, false),
        (.generalUseOutlet, .tug, true), (.generalUseOutlet, .iug, false),
        (.generalUseOutlet, .tue, false), (.generalUseOutlet, .acu, false)
    ])
    func assignments(kind: CircuitPointKind, type: CircuitType, compatible: Bool) throws {
        var plan = CircuitPlan()
        let point = UtilizationPoint(id: UUID(), roomID: UUID(), kind: kind, ordinal: 1)
        plan.points = [point]
        #expect(CircuitEngine.validate(plan, grade: .minimum).issues.contains(.pointUnassigned(point.id)))
        let id = try CircuitEngine.addCircuit(to: &plan, type: type)
        if compatible {
            try CircuitEngine.assign(pointID: point.id, to: id, in: &plan)
            #expect(plan.points[0].circuitID == id)
            CircuitEngine.removeCircuit(id, from: &plan)
            #expect(plan.points[0].circuitID == nil)
        } else {
            #expect(throws: CircuitEngine.OperationError.self) { try CircuitEngine.assign(pointID: point.id, to: id, in: &plan) }
            plan.points[0].circuitID = id
            #expect(CircuitEngine.validate(plan, grade: .minimum).issues.contains(.incompatibleAssignment(point: point.id, circuit: id)))
        }
    }
    @Test func moduleKindCannotBeMaterializedAsCircuitPoint() {
        #expect(CircuitPointKind.allCases.map(\.roomKind) == [.generalLighting, .generalUseOutlet])
        #expect(!CircuitPointKind.allCases.map(\.roomKind).contains(.fixedApplianceModule))
    }
    @Test func synchronizationPreservesIdentityAndAssignments() throws {
        var counts = UtilizationPoints()
        try counts.setCount(2, for: .generalLighting)
        let room = Room(name: "Estar", type: .livingDiningStudy, projectedPoints: counts)
        var plan = CircuitPlan()
        try CircuitEngine.synchronize(&plan, rooms: [room])
        let ids = plan.points.map(\.id)
        let circuit = try CircuitEngine.addCircuit(to: &plan, type: .iug)
        try CircuitEngine.assign(pointID: ids[0], to: circuit, in: &plan)
        let unchangedPoints = plan.points
        try CircuitEngine.synchronize(&plan, rooms: [room])
        #expect(plan.points == unchangedPoints)
        try counts.setCount(3, for: .generalLighting)
        try CircuitEngine.synchronize(&plan, rooms: [Room(id: room.id, name: "Nuevo", type: .livingDiningStudy, projectedPoints: counts)])
        #expect(Array(plan.points.prefix(2).map(\.id)) == ids)
        #expect(plan.points[0].circuitID == circuit)
        try counts.setCount(1, for: .generalLighting)
        try CircuitEngine.synchronize(&plan, rooms: [Room(id: room.id, name: "Nuevo", type: .livingDiningStudy, projectedPoints: counts)])
        #expect(plan.points.map(\.id) == [ids[0]])
        #expect(plan.points[0].circuitID == circuit)
        try CircuitEngine.synchronize(&plan, rooms: [])
        #expect(plan.points.isEmpty)
    }
    @Test func structuredLimitExcludesModules() throws {
        var counts = UtilizationPoints()
        try counts.setCount(16, for: .generalLighting)
        try counts.setCount(1, for: .fixedApplianceModule)
        var plan = CircuitPlan()
        try CircuitEngine.synchronize(&plan, rooms: [Room(name: "Cocina", type: .kitchen, projectedPoints: counts)])
        let id = try CircuitEngine.addCircuit(to: &plan, type: .iug)
        for point in plan.points where point.kind == .generalLighting { try CircuitEngine.assign(pointID: point.id, to: id, in: &plan) }
        let issues = CircuitEngine.validate(plan, grade: .minimum).issues
        #expect(issues.contains(.pointLimit(circuit: id, maximum: 15, actual: 16)))
        #expect(plan.points.count == 16)
        #expect(issues == [.pointLimit(circuit: id, maximum: 15, actual: 16)])
    }
    @Test func resourceGuardDoesNotDestroyExistingPoints() throws {
        var counts = UtilizationPoints()
        try counts.setCount(Int.max, for: .generalLighting)
        var plan = CircuitPlan()
        #expect(throws: CircuitEngine.OperationError.self) {
            try CircuitEngine.synchronize(&plan, rooms: [Room(name: "Grande", type: .kitchen, projectedPoints: counts)])
        }
        #expect(plan.points.isEmpty)
    }
}

@Suite("ACU — carga declarada e identidad")
struct DeclaredLoadTests {
    @Test(arguments: PowerUnit.allCases, [0.0, 1.0, 1300.5])
    func preservesDeclaration(unit: PowerUnit, value: Double) throws {
        let load = try DeclaredLoad(value: value, unit: unit)
        #expect(load.value == value); #expect(load.unit == unit)
        #expect(load.declaredVoltAmperes == (unit == .voltAmpere ? value : nil))
    }
    @Test(arguments: [-1.0, Double.nan, Double.infinity, -Double.infinity])
    func invalid(value: Double) {
        for unit in PowerUnit.allCases { #expect(throws: DeclaredLoad.ValidationError.self) { try DeclaredLoad(value: value, unit: unit) } }
    }
    @Test func circuitIdentityCategoryAndSingleLoad() throws {
        let load = try DeclaredLoad(value: 1, unit: .horsepower)
        var circuit = try Circuit(number: 1, type: .acu, destination: "Bomba", declaredLoad: load)
        let id = circuit.id
        circuit.destination = "Bomba patio"
        #expect(circuit.id == id); #expect(circuit.declaredLoad == load)
        #expect(circuit.type.category == .specificUse)
        #expect(CircuitType.iug.category == .generalUse); #expect(CircuitType.tug.category == .generalUse)
        #expect(CircuitType.tue.category == .specialUse)
        #expect(throws: Circuit.ValidationError.self) { try Circuit(number: 1, type: .tug, declaredLoad: load) }
        #expect(throws: Circuit.ValidationError.self) { try Circuit(number: 0, type: .iug) }
        let plan = CircuitPlan(circuits: [circuit])
        #expect(plan.points.isEmpty)
        #expect(CircuitEngine.validate(plan, grade: .minimum).issues.isEmpty)
    }
}

@MainActor struct CircuitProjectIntegrationTests {
    @Test func projectRetainsPlanAcrossRecalculations() throws {
        var form = ProjectForm()
        form.name = "Casa"; form.coveredArea = "80"; form.semiCoveredArea = "0"
        var points = UtilizationPoints(); try points.setCount(1, for: .generalLighting)
        form.rooms = [Room(name: "Estar", type: .livingDiningStudy, projectedPoints: points)]
        form.circuitPlan.selection = .init(grade: .medium, variant: .b)
        try CircuitEngine.generateMissing(in: &form.circuitPlan, grade: .medium)
        let first = try form.calculate().project.circuitPlan
        let second = try form.calculate().project.circuitPlan
        #expect(first.points == second.points); #expect(first.circuits == second.circuits)
        #expect(second.selection == first.selection)
        form.rooms = []
        #expect(form.circuitPlan.points.isEmpty)
        #expect(form.circuitPlan.circuits == first.circuits)
    }
}

@Suite("Circuitos — referencias inválidas y entradas límite")
struct CircuitIntegrityTests {
    @Test func danglingAssignmentAndUnknownPoint() throws {
        let point = UtilizationPoint(id: UUID(), roomID: UUID(), kind: .generalLighting, ordinal: 1, circuitID: UUID())
        var plan = CircuitPlan(points: [point])
        #expect(CircuitEngine.validate(plan, grade: .minimum).issues.contains(.missingCircuit(point: point.id)))
        #expect(throws: CircuitEngine.OperationError.self) { try CircuitEngine.assign(pointID: UUID(), to: nil, in: &plan) }
    }
    @Test func circuitNumberOverflowIsRejected() throws {
        var plan = CircuitPlan(circuits: [try Circuit(number: Int.max, type: .iug)])
        #expect(throws: CircuitEngine.OperationError.self) { try CircuitEngine.addCircuit(to: &plan, type: .tug) }
        #expect(plan.circuits.count == 1)
    }
    @Test func incompleteACUHasStructuredIssues() throws {
        let circuit = try Circuit(number: 1, type: .acu)
        let result = CircuitEngine.validate(CircuitPlan(circuits: [circuit]), grade: .minimum)
        #expect(result.issues.contains(.acuLoadMissing(circuit.id)))
        #expect(result.issues.contains(.acuDestinationMissing(circuit.id)))
    }
}

@Suite("RULE-ROOM-POINTS-001 — módulos de cocina separados de bocas")
@MainActor struct KitchenModuleIntegrationTests {
    private func kitchen(modules: Int, tug: Int = 3) throws -> Room {
        var counts = UtilizationPoints()
        try counts.setCount(2, for: .generalLighting)
        try counts.setCount(tug, for: .generalUseOutlet)
        try counts.setCount(modules, for: .fixedApplianceModule)
        return Room(name: "Cocina", type: .kitchen, projectedPoints: counts)
    }

    @Test func mediumKitchenKeepsModuleRequirementAndMaterializesOnlyFiveBocas() throws {
        let room = try kitchen(modules: 2)
        let evaluation = try RoomMinimumPointsRule.evaluate(room, grade: .medium)
        let comparisons = PointComparison.compare(room.projectedPoints, with: evaluation.requirements)
        #expect(comparisons.allSatisfy { $0.status == .conforming })
        #expect(comparisons.first { $0.kind == .fixedApplianceModule }?.required == 2)
        #expect(UtilizationPointKind.fixedApplianceModule.quantityText(2) == "2 módulos")
        var plan = CircuitPlan(selection: .init(grade: .medium, variant: .b))
        try CircuitEngine.synchronize(&plan, rooms: [room])
        #expect(plan.points.map(\.kind) == [.generalLighting, .generalLighting, .generalUseOutlet, .generalUseOutlet, .generalUseOutlet])
        #expect(plan.points.map(\.ordinal) == [1, 2, 1, 2, 3])
        #expect(plan.circuits.isEmpty)
        let unassigned = CircuitEngine.validate(plan, grade: .medium).issues
        #expect(unassigned == plan.points.map { .pointUnassigned($0.id) })
        try CircuitEngine.generateMissing(in: &plan, grade: .medium)
        for point in plan.points {
            let target = try #require(point.compatibleCircuits(in: plan).first)
            try CircuitEngine.assign(pointID: point.id, to: target.id, in: &plan)
        }
        let validation = CircuitEngine.validate(plan, grade: .medium)
        #expect(validation.minimum == .conforming)
        #expect(validation.issues.isEmpty)
        let progress = AssignmentProgress(plan: plan, validation: validation)
        #expect(progress.total == 5); #expect(progress.assigned == 5); #expect(progress.unassigned == 0)
        let result = DemandEngine.project(plan: plan, grade: .medium)
        #expect(result.circuits.compactMap(\.pointCount).reduce(0, +) == 5)
        #expect(try result.generalBase.get().voltAmperes == 4480)
        #expect(try result.total.get().voltAmperes == 3584)
        #expect(result.specificLoads.isEmpty)

        let points = plan.points
        let circuits = plan.circuits
        var fewerModules = room.projectedPoints
        try fewerModules.setCount(1, for: .fixedApplianceModule)
        let missing = Room(id: room.id, name: room.name, type: room.type, projectedPoints: fewerModules)
        #expect(RoomPresentation(room: missing, grade: .medium).completion == .incomplete(bocas: 0, modules: 1))
        let missingEvaluation = try RoomMinimumPointsRule.evaluate(missing, grade: .medium)
        #expect(PointComparison.compare(missing.projectedPoints, with: missingEvaluation.requirements)
            .first { $0.kind == .fixedApplianceModule }?.status == .missing(1))
        try CircuitEngine.synchronize(&plan, rooms: [missing])
        #expect(plan.points == points)
        #expect(plan.circuits == circuits)
        #expect(DemandEngine.project(plan: plan, grade: .medium).total == result.total)
    }

    @Test func modulesDoNotConsumeMaterializationCapacityOrCircuitBocaLimit() throws {
        let room = try kitchen(modules: Int.max, tug: 15)
        var plan = CircuitPlan()
        try CircuitEngine.synchronize(&plan, rooms: [room])
        #expect(plan.points.count == 17)
        let iug = try CircuitEngine.addCircuit(to: &plan, type: .iug)
        let tug = try CircuitEngine.addCircuit(to: &plan, type: .tug)
        for point in plan.points {
            try CircuitEngine.assign(pointID: point.id, to: point.kind == .generalLighting ? iug : tug, in: &plan)
        }
        #expect(CircuitEngine.validate(plan, grade: .minimum).issues.isEmpty)
        let tugCircuit = try #require(plan.circuits.first { $0.id == tug })
        #expect(DemandEngine.circuit(tugCircuit, points: plan.points).pointCount == 15)
    }
}
