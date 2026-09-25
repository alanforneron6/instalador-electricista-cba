import Testing
@testable import InstaladorElectricistaCBA

@Suite("RULE-ROOM-POINTS-001 — mínimos por ambiente")
struct RoomMinimumPointsRuleTests {
    private func check(_ type: RoomType, grade: ElectrificationGrade = .minimum,
                       area: Double? = nil, length: Double? = nil,
                       iug: Int, tug: Int?, modules: Int? = nil) throws {
        let room = Room(name: "Ambiente", type: type,
                        area: try area.map { try SquareMeters($0) },
                        length: try length.map { try Meters($0) })
        let result = try RoomMinimumPointsRule.evaluate(room, grade: grade)
        #expect(result.requirements.first { $0.kind == .generalLighting }?.minimumCount == iug)
        #expect(result.requirements.first { $0.kind == .generalUseOutlet }?.minimumCount == tug)
        #expect(result.requirements.first { $0.kind == .fixedApplianceModule }?.minimumCount == modules)
    }

    @Test(arguments: [(0.0, 1, 2), (5, 1, 2), (6, 1, 2), (6.01, 1, 2), (18, 1, 3), (18.01, 2, 4), (36, 2, 6)])
    func living(area: Double, iug: Int, tug: Int) throws {
        try check(.livingDiningStudy, area: area, iug: iug, tug: tug)
    }

    @Test(arguments: [(9.99, 1, 2), (10, 1, 3), (10.01, 1, 3), (35.99, 1, 3), (36, 1, 3), (36.01, 2, 3)])
    func bedroom(area: Double, iug: Int, tug: Int) throws {
        try check(.bedroom, area: area, iug: iug, tug: tug)
    }

    @Test(arguments: [(ElectrificationGrade.minimum, 1, 3, 2), (.medium, 2, 3, 2), (.elevated, 2, 3, 3), (.superior, 2, 4, 3)])
    func kitchen(grade: ElectrificationGrade, iug: Int, tug: Int, modules: Int) throws {
        try check(.kitchen, grade: grade, iug: iug, tug: tug, modules: modules)
    }

    @Test func bathroomWithoutDimensions() throws { try check(.bathroom, iug: 1, tug: 1) }
    @Test func minimumGarageWithoutDimensions() throws { try check(.vestibuleGarageDressingRoom, iug: 1, tug: 1) }

    @Test(arguments: [(0.0, 1), (5, 1), (12, 1), (12.01, 2)])
    func garage(area: Double, count: Int) throws {
        try check(.vestibuleGarageDressingRoom, grade: .medium, area: area, iug: count, tug: count)
    }

    @Test(arguments: [(0.0, 1, 0), (2, 1, 0), (2.01, 1, 1), (5, 1, 1), (5.01, 2, 2)])
    func hallway(length: Double, iug: Int, tug: Int) throws {
        try check(.coveredHallway, length: length, iug: iug, tug: nil)
        for grade in [ElectrificationGrade.medium, .elevated, .superior] {
            try check(.coveredHallway, grade: grade, length: length, iug: iug, tug: tug)
        }
    }

    @Test(arguments: [(ElectrificationGrade.minimum, 1), (.medium, 2), (.elevated, 2), (.superior, 2)])
    func laundry(grade: ElectrificationGrade, tug: Int) throws {
        try check(.laundry, grade: grade, iug: 1, tug: tug)
    }

    @Test(arguments: [(0.0, 0), (2, 1), (5, 1), (5.01, 2)])
    func semiCovered(length: Double, iug: Int) throws {
        try check(.semiCoveredOrOutdoorPassage, length: length, iug: iug, tug: nil)
    }

    @Test func largeBedroomNoteDoesNotChangeGrade() throws {
        let room = Room(name: "Dormitorio", type: .bedroom, area: try SquareMeters(36.01))
        let result = try RoomMinimumPointsRule.evaluate(room, grade: .minimum)
        #expect(result.notes == [.largeBedroomElevatedCriterion])
        #expect(result.requirements.first { $0.kind == .generalLighting }?.minimumCount == 2)
    }

    @Test(arguments: [RoomType.livingDiningStudy, .bedroom, .vestibuleGarageDressingRoom, .coveredHallway, .semiCoveredOrOutdoorPassage])
    func missingDimensions(type: RoomType) {
        #expect(throws: RoomMinimumPointsRule.EvaluationError.self) {
            try RoomMinimumPointsRule.evaluate(Room(name: "Sin dimensión", type: type), grade: .medium)
        }
    }

    @Test func oversizedDimensionDoesNotTrap() throws {
        let room = Room(name: "Grande", type: .livingDiningStudy, area: try SquareMeters(.greatestFiniteMagnitude))
        #expect(throws: RoomMinimumPointsRule.EvaluationError.self) {
            try RoomMinimumPointsRule.evaluate(room, grade: .minimum)
        }
    }
}
