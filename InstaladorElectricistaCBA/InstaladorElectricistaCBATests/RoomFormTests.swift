import Testing
@testable import InstaladorElectricistaCBA

@Suite("RULE-ROOM-POINTS-001 — formulario")
@MainActor struct RoomFormTests {
    @Test func projectRetainsRoomsAndUsesCurrentGrade() throws {
        var draft = RoomForm()
        draft.name = "Cocina"
        draft.type = .kitchen
        draft.iug = "1"; draft.tug = "3"; draft.modules = "2"
        let room = try draft.makeRoom(grade: .minimum)
        var project = ProjectForm()
        project.name = "Casa"; project.coveredArea = "50"; project.semiCoveredArea = "0"
        project.rooms = [room]
        #expect(try project.calculate().project.rooms.count == 1)
        project.coveredArea = "210"
        let result = try project.calculate()
        let requirements = try RoomMinimumPointsRule.evaluate(result.project.rooms[0], grade: result.grade)
        #expect(PointComparison.compare(room.projectedPoints, with: requirements.requirements).first { $0.kind == .generalUseOutlet }?.status == .missing(1))
    }

    @Test func decimalDimensions() throws {
        var draft = RoomForm()
        draft.name = "Estar"; draft.dimension = "18,01"
        #expect(try draft.makeRoom(grade: .minimum).area?.value == 18.01)
        draft.type = .coveredHallway; draft.dimension = "5.01"
        #expect(try draft.makeRoom(grade: .medium).length?.value == 5.01)
    }

    @Test(arguments: ["", "-1", "NaN", "inf", "1.234,5"])
    func invalidDimension(input: String) {
        var draft = RoomForm()
        draft.name = "Ambiente"; draft.dimension = input
        #expect(throws: (any Error).self) { try draft.makeRoom(grade: .medium) }
        draft.type = .coveredHallway
        #expect(throws: (any Error).self) { try draft.makeRoom(grade: .medium) }
    }

    @Test(arguments: ["-1", "1.5", "", "NaN"])
    func invalidCounts(input: String) {
        var draft = RoomForm()
        draft.name = "Cocina"; draft.type = .kitchen; draft.modules = input
        #expect(throws: RoomForm.InputError.self) { try draft.makeRoom(grade: .minimum) }
    }

    @Test func garageNeedsAreaAfterGradeChange() throws {
        var draft = RoomForm()
        draft.name = "Garage"; draft.type = .vestibuleGarageDressingRoom
        let room = try draft.makeRoom(grade: .minimum)
        #expect(room.area == nil)
        #expect(throws: RoomMinimumPointsRule.EvaluationError.self) { try RoomMinimumPointsRule.evaluate(room, grade: .medium) }
    }
}
