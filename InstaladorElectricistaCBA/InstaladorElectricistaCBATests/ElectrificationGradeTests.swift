import Testing
@testable import InstaladorElectricistaCBA

@Suite("RULE-GE-001")
struct ElectrificationGradeTests {
    @Test(arguments: [
        (0.0, ElectrificationGrade.minimum), (60, .minimum), (60.01, .medium),
        (130, .medium), (130.01, .elevated), (200, .elevated), (200.01, .superior)
    ])
    func boundary(area: Double, expected: ElectrificationGrade) throws {
        #expect(PreliminaryElectrificationRule.grade(for: try SquareMeters(area)) == expected)
    }
}
