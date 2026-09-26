import Foundation
import Testing
@testable import InstaladorElectricistaCBA

@Suite("UX-001 — navegación y estado compartido")
@MainActor struct ProjectFlowTests {
    private func validFlow() -> ProjectFlowState {
        var flow = ProjectFlowState()
        flow.form.name = "Casa"; flow.form.coveredArea = "100"; flow.form.semiCoveredArea = "0"
        return flow
    }

    @Test func firstContinueUsesCurrentValidProjectWithoutCalculate() throws {
        var flow = ProjectFlowState()
        flow.form.name = "Flia Álvarez"
        flow.form.coveredArea = "70"
        flow.form.semiCoveredArea = "0"
        #expect(flow.canContinue)
        let before = try #require(flow.result)
        #expect(before.project.name == "Flia Álvarez")
        #expect(before.sla.value == 70)
        #expect(before.grade == .medium)
        flow.advance()
        #expect(flow.path == [.rooms])
        let destination = try #require(flow.result)
        #expect(destination.project.id == before.project.id)
        #expect(destination.sla == before.sla)
        #expect(destination.grade == before.grade)
        #expect(flow.canContinue)
    }

    @Test(arguments: ["", "-1", "texto", "NaN", "infinity", "1.2.3"])
    func invalidSurfacesBlockFirstContinue(input: String) {
        for covered in [true, false] {
            var flow = validFlow()
            if covered { flow.form.coveredArea = input }
            else { flow.form.semiCoveredArea = input }
            #expect(!flow.canContinue)
            #expect(flow.result == nil)
            #expect(flow.errorMessage != nil)
            flow.advance()
            #expect(flow.path.isEmpty)
        }
    }

    @Test func surfacesRecalculateImmediatelyWithoutClearingRooms() throws {
        var flow = validFlow()
        let id = try #require(flow.result?.project.id)
        let room = Room(name: "Baño", type: .bathroom)
        flow.form.rooms = [room]
        flow.form.coveredArea = "200,5"
        let result = try #require(flow.result)
        #expect(result.sla.value == 200.5)
        #expect(result.project.id == id)
        #expect(result.grade == .superior)
        #expect(result.project.rooms.map(\.id) == [room.id])
        flow.form.coveredArea = "60"
        flow.form.semiCoveredArea = "0.5"
        #expect(flow.result?.sla.value == 60.25)
        #expect(flow.result?.grade == .medium)
        flow.form.semiCoveredArea = "0"
        #expect(flow.result?.sla.value == 60)
        #expect(flow.result?.grade == .minimum)
        flow.advance()
        #expect(flow.step == .rooms)
    }

    @Test func emptyFormCannotNavigate() {
        var flow = ProjectFlowState()
        #expect(!flow.canContinue)
        #expect(flow.errorMessage == nil)
        flow.advance()
        #expect(flow.path.isEmpty)
    }

    @Test func movingThroughAllStepsPreservesEntireProject() throws {
        var flow = validFlow()
        flow.advance()
        var draft = RoomForm()
        draft.name = "Baño"; draft.type = .bathroom; draft.iug = "1"; draft.tug = "1"
        flow.form.rooms.append(try draft.makeRoom(grade: .medium))
        flow.form.circuitPlan.selection = .init(grade: .medium, variant: .b)
        try CircuitEngine.generateMissing(in: &flow.form.circuitPlan, grade: .medium)
        for point in flow.form.circuitPlan.points {
            let circuit = try #require(flow.form.circuitPlan.circuits.first {
                CircuitPointCompatibilityRule.evaluate(kind: point.kind, type: $0.type) == .compatible
            })
            try CircuitEngine.assign(pointID: point.id, to: circuit.id, in: &flow.form.circuitPlan)
        }
        let acuID = try CircuitEngine.addCircuit(to: &flow.form.circuitPlan, type: .acu, destination: "Bomba",
                                                 load: DeclaredLoad(value: 1, unit: .horsepower), powerFactor: PowerFactor(0.8))
        let original = try #require(flow.result?.project)
        flow.advance(); flow.advance()
        #expect(flow.step == .demand)
        flow.advance()
        #expect(flow.path.count == 3)
        flow.goBack(); flow.goBack(); flow.goBack()
        #expect(flow.step == .project)
        let after = try #require(flow.result?.project)
        #expect(after.id == original.id)
        #expect(after.rooms.map(\.id) == original.rooms.map(\.id))
        #expect(after.circuitPlan.points == original.circuitPlan.points)
        #expect(after.circuitPlan.circuits == original.circuitPlan.circuits)
        #expect(after.circuitPlan.selection == original.circuitPlan.selection)
        #expect(after.circuitPlan.freeChoiceCircuitID == original.circuitPlan.freeChoiceCircuitID)
        #expect(after.circuitPlan.circuits.first { $0.id == acuID }?.powerFactor == (try PowerFactor(0.8)))
    }

    @Test func addingAnotherRoomKeepsExistingPointIdentitiesAndAssignments() throws {
        var flow = validFlow()
        flow.advance()
        var draft = RoomForm()
        draft.name = "Baño"; draft.type = .bathroom; draft.iug = "1"
        flow.form.rooms.append(try draft.makeRoom(grade: .medium))
        let circuitID = try CircuitEngine.addCircuit(to: &flow.form.circuitPlan, type: .iug)
        let pointID = try #require(flow.form.circuitPlan.points.first?.id)
        try CircuitEngine.assign(pointID: pointID, to: circuitID, in: &flow.form.circuitPlan)
        let originalPoints = flow.form.circuitPlan.points
        draft.name = "Segundo baño"
        flow.form.rooms.append(try draft.makeRoom(grade: .medium))
        #expect(flow.form.rooms.count == 2)
        #expect(flow.form.circuitPlan.points.first == originalPoints.first)
        #expect(flow.form.circuitPlan.circuits.first?.id == circuitID)
        #expect(flow.canContinue)
        #expect(try #require(flow.result).project.rooms.count == 2)
    }
}

@Suite("UX-001 — presentación de ambientes y asignaciones")
@MainActor struct RoomPresentationTests {
    @Test func draftCountsUpdateBeforeSavingAndWithoutName() {
        var draft = RoomForm()
        draft.type = .kitchen
        var presentation = RoomPresentation(draft: draft, grade: .minimum)
        #expect(presentation.completion == .incomplete(bocas: 4, modules: 2))
        #expect(presentation.completion.tone == .pending)
        draft.iug = "1"; draft.tug = "3"; draft.modules = "2"
        presentation = RoomPresentation(draft: draft, grade: .minimum)
        #expect(presentation.completion == .complete)
        #expect(presentation.completion.text == "Cumple")
        draft.tug = "2"
        #expect(RoomPresentation(draft: draft, grade: .minimum).completion == .incomplete(bocas: 1, modules: 0))
        #expect(RoomPresentation(draft: draft, grade: .minimum).completion.text == "Incompleto · falta 1 boca")
    }

    @Test(arguments: [
        (0, 1, "Incompleto · falta 1 módulo"),
        (0, 2, "Incompleto · faltan 2 módulos"),
        (1, 0, "Incompleto · falta 1 boca"),
        (2, 1, "Incompleto · faltan 2 bocas y 1 módulo"),
        (0, 0, "Cumple")
    ])
    func kitchenMissingQuantitiesKeepUnits(bocas: Int, modules: Int, expected: String) throws {
        var draft = RoomForm()
        draft.name = "Cocina"; draft.type = .kitchen
        draft.iug = "1"; draft.tug = String(3 - bocas); draft.modules = String(2 - modules)
        let preview = RoomPresentation(draft: draft, grade: .minimum)
        let room = try draft.makeRoom(grade: .minimum)
        let saved = RoomPresentation(room: room, grade: .minimum)
        #expect(preview.completion.text == expected)
        #expect(saved.completion.text == expected)
        #expect(saved.completion.tone == (bocas == 0 && modules == 0 ? .complete : .pending))
        if modules == 0 { #expect(RoomPresentation.summary(room).contains("2 módulos para equipos fijos")) }
    }

    @Test(arguments: UtilizationPointKind.allCases)
    func countLabelsUseTheKindUnit(kind: UtilizationPointKind) {
        if kind == .fixedApplianceModule {
            #expect(kind.inputTitle == "Módulos adicionales para electrodomésticos de ubicación fija")
            #expect(kind.quantityText(2) == "2 módulos")
            #expect(kind.projectedText(2) == "Módulos proyectados: 2")
            #expect(kind.missingText(1) == "Falta 1 módulo")
            #expect(kind.missingText(2) == "Faltan 2 módulos")
        } else {
            #expect(kind.quantityText(2) == "2 bocas")
            #expect(kind.projectedText(2) == "Bocas proyectadas: 2")
            #expect(kind.missingText(1) == "Falta 1 boca")
            #expect(kind.missingText(2) == "Faltan 2 bocas")
        }
    }

    @Test func requiredDimensionIsNeverInvented() {
        var draft = RoomForm()
        #expect(RoomPresentation(draft: draft, grade: .minimum).completion == .needsInformation)
        #expect(RoomPresentation(draft: draft, grade: .minimum).comparisons.isEmpty)
        draft.dimension = "-1"
        #expect(RoomPresentation(draft: draft, grade: .minimum).completion == .invalid)
        draft.dimension = "18,01"
        #expect(!RoomPresentation(draft: draft, grade: .minimum).comparisons.isEmpty)
    }

    @Test func storedRoomUsesExistingComparisons() throws {
        var counts = UtilizationPoints()
        try counts.setCount(1, for: .generalLighting)
        let room = Room(name: "Baño", type: .bathroom, projectedPoints: counts)
        let presentation = RoomPresentation(room: room, grade: .minimum)
        let existing = PointComparison.compare(counts, with: try RoomMinimumPointsRule.evaluate(room, grade: .minimum).requirements)
        #expect(presentation.comparisons.map(\.status) == existing.map(\.status))
        #expect(presentation.completion == .incomplete(bocas: 1, modules: 0))
    }

    @Test func assignmentProgressExcludesInvalidAssignments() throws {
        let room = UUID()
        let iug = try Circuit(number: 1, type: .iug)
        let plan = CircuitPlan(circuits: [iug], points: [
            .init(id: UUID(), roomID: room, kind: .generalLighting, ordinal: 1, circuitID: iug.id),
            .init(id: UUID(), roomID: room, kind: .generalLighting, ordinal: 2),
            .init(id: UUID(), roomID: room, kind: .generalUseOutlet, ordinal: 1, circuitID: iug.id)
        ])
        let progress = AssignmentProgress(plan: plan, validation: CircuitEngine.validate(plan, grade: .minimum))
        #expect(progress.assigned == 1)
        #expect(progress.total == 3)
        #expect(progress.unassigned == 1)
    }
}

@Suite("UX-001 — mensajes y total de demanda")
@MainActor struct DemandPresentationTests {
    @Test(arguments: [
        (DemandCalculationError.missingPowerFactor, "Falta el factor de potencia."),
        (.missingDeclaredLoad, "Falta indicar la potencia del equipo."),
        (.unassignedPoints, "Todavía hay bocas sin asignar a un circuito."),
        (.incompatibleAssignments, "Hay bocas asignadas a un circuito incompatible."),
        (.invalidPointCount, "La cantidad de bocas es inválida."),
        (.numericOverflow, "El valor excede el rango de cálculo. Revisá los datos.")
    ])
    func humanMessages(error: DemandCalculationError, expected: String) {
        #expect(error.displayMessage == expected)
    }

    @Test func missingFactorIdentifiesEquipment() {
        #expect(DemandCalculationError.missingPowerFactor.message(for: "Aire acondicionado") == "Falta el factor de potencia de «Aire acondicionado».")
    }

    @Test func completeValueIsTheEngineTotal() throws {
        let circuit = try Circuit(number: 1, type: .acu, declaredLoad: DeclaredLoad(value: 1000, unit: .voltAmpere))
        let result = DemandEngine.project(plan: CircuitPlan(circuits: [circuit]), grade: .minimum)
        let presentation = DemandTotalPresentation(result: result)
        #expect(presentation.statusText == "Completa")
        #expect(presentation.valueTitle == "DPMS total")
        #expect(presentation.value == result.total)
    }

    @Test(arguments: [false, true])
    func incompleteDemandNeverLabelsSubtotalAsTotal(unassignedPoint: Bool) throws {
        let circuit = try Circuit(number: 1, type: .tug)
        var plan = CircuitPlan(circuits: [circuit])
        if unassignedPoint {
            plan.points = [.init(id: UUID(), roomID: UUID(), kind: .generalLighting, ordinal: 1)]
        } else {
            try CircuitEngine.addCircuit(to: &plan, type: .acu, load: DeclaredLoad(value: 1, unit: .horsepower))
        }
        let result = DemandEngine.project(plan: plan, grade: .minimum)
        let presentation = DemandTotalPresentation(result: result)
        #expect(presentation.statusText == "Demanda pendiente")
        #expect(presentation.valueTitle == "Subtotal resoluble (incompleto)")
        #expect(presentation.value == result.resolvedSubtotal)
        #expect(presentation.value != result.total)
        guard case .pending = presentation else { Issue.record("Un subtotal no puede presentarse como total completo"); return }
    }
}
