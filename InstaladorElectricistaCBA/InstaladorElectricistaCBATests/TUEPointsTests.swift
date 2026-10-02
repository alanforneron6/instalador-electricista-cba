import Foundation
import Testing
@testable import InstaladorElectricistaCBA

@Suite("Bocas TUE — proyección, asignación y demanda por circuito")
@MainActor struct TUEPointsTests {
    private func room(_ count: Int) throws -> Room {
        var form = RoomForm()
        form.name = "Cocina"
        form.type = .kitchen
        form.iug = "2"; form.tug = "3"; form.modules = "2"
        form.tue = String(count)
        return try form.makeRoom(grade: .medium)
    }

    private func plan(_ count: Int, known: Double? = nil) throws -> CircuitPlan {
        var points = UtilizationPoints()
        try points.setCount(count, for: .specialUseOutlet)
        let room = Room(name: "Ambiente", type: .kitchen, projectedPoints: points)
        var plan = CircuitPlan(circuits: [
            try Circuit(number: 4, type: .tue, destination: "Aires",
                        knownDemand: known.map { try ApparentPower(voltAmperes: $0) }, phaseAssignment: .l2)
        ])
        try CircuitEngine.synchronize(&plan, rooms: [room])
        for point in plan.points {
            try CircuitEngine.assign(pointID: point.id, to: plan.circuits[0].id, in: &plan)
        }
        return plan
    }

    private func replacingTUECount(_ count: Int, in room: Room) throws -> Room {
        var points = room.projectedPoints
        try points.setCount(count, for: .specialUseOutlet)
        return Room(id: room.id, name: room.name, type: room.type,
                    area: room.area, length: room.length, projectedPoints: points)
    }


    @Test func optionalTUEControlRoundTripReachesDomain() throws {
        var draft = RoomForm()
        draft.name = "Cocina"; draft.type = .kitchen
        draft.iug = "2"; draft.tug = "3"; draft.modules = "2"
        #expect(draft.showsAddTUEAction)
        #expect(draft.projectedTUECount == 0)
        draft.addTUE()
        #expect(draft.projectedTUECount == 1)
        #expect(!draft.showsAddTUEAction)
        for count in [2, 1, 0] {
            draft.projectedTUECount = count
            #expect(draft.showsAddTUEAction == (count == 0))
            let room = try draft.makeRoom(grade: .medium)
            #expect(room.projectedPoints.count(for: .specialUseOutlet) == count)
            let presentation = RoomPresentation(room: room, grade: .medium)
            #expect(presentation.minimumComparisons.map(\.kind)
                    == [.generalLighting, .generalUseOutlet, .fixedApplianceModule])
            #expect(presentation.minimumComparisons.map(\.required) == [2, 3, 2])
            #expect(presentation.completion == .complete)
            #expect(UtilizationPointKind.fixedApplianceModule.projectedText(2) == "Módulos proyectados: 2")
            var plan = CircuitPlan()
            try CircuitEngine.synchronize(&plan, rooms: [room])
            #expect(plan.points.filter { $0.kind == .specialUseOutlet }.count == count)
        }
    }

    @Test func optionalTUEDoesNotReplaceMissingRoomDimension() throws {
        var draft = RoomForm()
        draft.name = "Estar"
        draft.addTUE()
        let pending = RoomPresentation(draft: draft, grade: .medium)
        #expect(pending.completion == .needsInformation)
        #expect(pending.minimumComparisons.isEmpty)
        #expect(draft.projectedTUECount == 1)
        draft.dimension = "18"
        let ready = RoomPresentation(draft: draft, grade: .medium)
        #expect(ready.minimumComparisons.first { $0.kind == .generalLighting }?.required == 1)
        #expect(ready.minimumComparisons.first { $0.kind == .generalUseOutlet }?.required == 3)
        #expect(try draft.makeRoom(grade: .medium).projectedPoints.count(for: .specialUseOutlet) == 1)
    }

    @Test(arguments: [0, 2])
    func projectionHasNoNormativeMinimumAndModulesStaySeparate(count: Int) throws {
        let room = try room(count)
        let presentation = RoomPresentation(room: room, grade: .medium)
        let comparison = try #require(presentation.comparisons.first { $0.kind == .specialUseOutlet })
        #expect(comparison.required == nil)
        #expect(comparison.status == .notApplicable)
        #expect(comparison.projected == count)
        #expect(presentation.completion == .complete)
        #expect(!presentation.minimumComparisons.contains { $0.kind == .specialUseOutlet })
        #expect(UtilizationPointKind.specialUseOutlet.inputTitle == "Tomacorrientes de uso especial (TUE)")
        var plan = CircuitPlan()
        try CircuitEngine.synchronize(&plan, rooms: [room])
        #expect(plan.points.count == 5 + count)
        #expect(plan.points.filter { $0.kind == .specialUseOutlet }.count == count)
        #expect(!CircuitPointKind.allCases.map(\.roomKind).contains(.fixedApplianceModule))
        #expect(room.projectedPoints.count(for: .fixedApplianceModule) == 2)
    }

    @Test func synchronizePreservesSurvivorsAndAssignments() throws {
        var room = try room(2)
        var plan = CircuitPlan(circuits: [try Circuit(number: 4, type: .tue)])
        try CircuitEngine.synchronize(&plan, rooms: [room])
        for point in plan.points where point.kind == .specialUseOutlet {
            try CircuitEngine.assign(pointID: point.id, to: plan.circuits[0].id, in: &plan)
        }
        let original = plan.points
        room = try replacingTUECount(3, in: room)
        try CircuitEngine.synchronize(&plan, rooms: [room])
        #expect(Array(plan.points.prefix(original.count)) == original)
        let third = try #require(plan.points.last)
        #expect(third.ordinal == 3)
        #expect(third.circuitID == nil)
        #expect(!original.map(\.id).contains(third.id))
        let unchanged = plan.points
        try CircuitEngine.synchronize(&plan, rooms: [room])
        #expect(plan.points == unchanged)
        room = try replacingTUECount(2, in: room)
        try CircuitEngine.synchronize(&plan, rooms: [room])
        #expect(plan.points == original)
    }

    @Test(arguments: CircuitPointKind.allCases, CircuitType.allCases)
    func explicitCompatibilityMatrix(kind: CircuitPointKind, type: CircuitType) throws {
        let expected = (kind == .generalLighting && type == .iug)
            || (kind == .generalUseOutlet && type == .tug)
            || (kind == .specialUseOutlet && type == .tue)
        #expect(CircuitPointCompatibilityRule.ruleID == "RULE-CIRCUIT-POINT-COMPATIBILITY-001")
        #expect(CircuitPointCompatibilityRule.evaluate(kind: kind, type: type) == (expected ? .compatible : .incompatible))
        let circuit = try Circuit(number: 1, type: type)
        let point = UtilizationPoint(id: UUID(), roomID: UUID(), kind: kind, ordinal: 1)
        var plan = CircuitPlan(circuits: [circuit], points: [point])
        #expect(point.compatibleCircuits(in: plan).count == (expected ? 1 : 0))
        if expected {
            try CircuitEngine.assign(pointID: point.id, to: circuit.id, in: &plan)
            #expect(plan.points[0].circuitID == circuit.id)
        } else {
            #expect(throws: CircuitEngine.OperationError.incompatibleAssignment) {
                try CircuitEngine.assign(pointID: point.id, to: circuit.id, in: &plan)
            }
            #expect(plan.points[0] == point)
        }
    }

    @Test(arguments: [0, 1, 2, 10, 15])
    func minimumDemandIsPerCircuitNotPerBoca(count: Int) throws {
        let plan = try plan(count)
        let result = DemandEngine.circuit(plan.circuits[0], points: plan.points)
        #expect(TUEDemandRule.ruleID == "RULE-DPMS-TUE-001")
        #expect(result.pointCount == count)
        #expect(try result.calculation.get().adoptedDemand.voltAmperes == 3300)
        #expect(try DemandEngine.project(plan: plan, grade: .medium).total.get().voltAmperes == 2640)
    }

    @Test func knownDemandCanExceedMinimum() throws {
        let plan = try plan(2, known: 4000)
        let result = DemandEngine.circuit(plan.circuits[0], points: plan.points)
        #expect(result.pointCount == 2)
        #expect(try result.calculation.get().adoptedDemand.voltAmperes == 4000)
    }

    @Test(arguments: [15, 16])
    func actualAssignedPointsUseExistingLimit(count: Int) throws {
        let plan = try plan(count)
        let issues = CircuitEngine.validate(plan, grade: .medium).issues
        #expect(CircuitPointLimitRule.ruleID == "RULE-CIRCUIT-POINT-LIMIT-001")
        #expect(issues.contains(.pointLimit(circuit: plan.circuits[0].id, maximum: 15, actual: count)) == (count == 16))
        #expect(!issues.contains { if case .incompatibleAssignment = $0 { return true }; return false })
    }

    @Test func unassignedTUEPreventsDefinitiveDemandWithoutInventingPower() throws {
        var plan = try plan(2)
        let original = plan.points
        try CircuitEngine.assign(pointID: original[1].id, to: nil, in: &plan)
        let result = DemandEngine.project(plan: plan, grade: .medium)
        #expect(result.total == .failure(.unassignedPoints))
        #expect(try result.resolvedSubtotal.get().voltAmperes == 2640)
        #expect(PhaseDistributionEngine.assess(plan: plan, grade: .medium).failureValue
                == .projectAssessment(.incompleteDemand(.unassignedPoints)))
        try CircuitEngine.assign(pointID: original[1].id, to: plan.circuits[0].id, in: &plan)
        #expect(plan.points == original)
        #expect(try DemandEngine.project(plan: plan, grade: .medium).total.get().voltAmperes == 2640)
    }

    @Test func phaseContributionIgnoresBocaCountAndFollowsAssignedPhase() throws {
        var plan = try plan(1)
        // Un receptor trifásico permite estudiar fases sin forzar el GE ni los umbrales.
        plan.circuits.append(try Circuit(number: 5, type: .acu, destination: "Motor",
            declaredLoad: DeclaredLoad(value: 1000, unit: .voltAmpere), supplyNature: .threePhase))
        let first = try PhaseDistributionEngine.assess(plan: plan, grade: .medium).get()
        var secondPoint = plan.points[0]
        secondPoint = UtilizationPoint(id: UUID(), roomID: secondPoint.roomID, kind: .specialUseOutlet,
                                      ordinal: 2, circuitID: plan.circuits[0].id)
        plan.points.append(secondPoint)
        let second = try PhaseDistributionEngine.assess(plan: plan, grade: .medium).get()
        #expect(first.project.demand.total == second.project.demand.total)
        #expect(second.circuitPowers[0].simultaneousDemand.voltAmperes == 2640)
        guard case .complete(let before) = second.state else { Issue.record("Distribución completa esperada"); return }
        #expect(before.contributions[0].currentCalculation.current.amperes == 12)
        try plan.circuits[0].updatePhaseAssignment(.l3)
        let moved = try PhaseDistributionEngine.assess(plan: plan, grade: .medium).get()
        guard case .complete(let after) = moved.state else { Issue.record("Distribución completa esperada"); return }
        #expect(moved.project.demand.total == second.project.demand.total)
        #expect(abs(before.currents.currentL2.amperes - after.currents.currentL2.amperes - 12) < 1e-12)
        #expect(abs(after.currents.currentL3.amperes - before.currents.currentL3.amperes - 12) < 1e-12)
        #expect(before.currents.currentL1 == after.currents.currentL1)
    }

    @Test func sharedFlowPreservesTUEPointsAndNavigation() throws {
        var flow = ProjectFlowState()
        flow.form.name = "Casa"; flow.form.coveredArea = "70"; flow.form.semiCoveredArea = "0"
        flow.form.rooms = [try room(2)]
        for type in [CircuitType.iug, .tug, .tue] {
            try CircuitEngine.addCircuit(to: &flow.form.circuitPlan, type: type)
        }
        for point in flow.form.circuitPlan.points {
            let circuit = try #require(point.compatibleCircuits(in: flow.form.circuitPlan).first)
            try CircuitEngine.assign(pointID: point.id, to: circuit.id, in: &flow.form.circuitPlan)
        }
        let original = flow.form.circuitPlan.points
        let tue = try #require(original.first { $0.kind == .specialUseOutlet })
        #expect(tue.assignmentTitle == "Tomacorriente especial 1 · TUE")
        #expect(AssignmentProgress(plan: flow.form.circuitPlan,
            validation: CircuitEngine.validate(flow.form.circuitPlan, grade: .medium)).assigned == 7)
        flow.advance(); flow.advance(); flow.advance()
        #expect(flow.step == .demand)
        flow.goBack(); flow.advance()
        #expect(flow.form.circuitPlan.points == original)
        #expect(flow.canContinueToSupply)
        let result = DemandEngine.project(plan: flow.form.circuitPlan, grade: .medium)
        #expect(result.circuits.first { $0.type == .tue }?.pointCount == 2)
    }
}

private extension Result {
    var failureValue: Failure? {
        if case .failure(let error) = self { return error }
        return nil
    }
}
