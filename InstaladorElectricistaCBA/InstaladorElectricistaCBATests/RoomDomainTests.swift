import Testing
@testable import InstaladorElectricistaCBA

@Suite("RULE-ROOM-POINTS-001 — dominio y comparación")
struct RoomDomainTests {
    @Test(arguments: [-1.0, Double.nan, Double.infinity, -Double.infinity])
    func invalidMeters(value: Double) {
        #expect(throws: Meters.ValidationError.self) { try Meters(value) }
    }
    @Test(arguments: [0.0, 2.01])
    func validMeters(value: Double) throws { #expect(try Meters(value).value == value) }

    @Test(arguments: [(3, ComplianceStatus.conforming), (5, .conforming), (2, .missing(1))])
    func applicableMinimum(projected: Int, expected: ComplianceStatus) throws {
        var points = UtilizationPoints()
        try points.setCount(projected, for: .generalUseOutlet)
        let result = PointComparison.compare(points, with: [.init(kind: .generalUseOutlet, minimumCount: 3)])
        let tug = try #require(result.first { $0.kind == .generalUseOutlet })
        #expect(tug.required == 3)
        #expect(tug.projected == projected)
        #expect(tug.status == expected)
    }

    @Test func absentRequirementIsNotApplicableAndDoesNotProhibitPoints() throws {
        var points = UtilizationPoints()
        try points.setCount(5, for: .generalUseOutlet)
        let result = PointComparison.compare(points, with: [])
        let tug = try #require(result.first { $0.kind == .generalUseOutlet })
        #expect(tug.required == nil)
        #expect(tug.status == .notApplicable)
        #expect(tug.projected == 5)
    }

    @Test func modulesAreNotOutletBocas() throws {
        var points = UtilizationPoints()
        try points.setCount(10, for: .fixedApplianceModule)
        let room = Room(name: "Cocina", type: .kitchen, projectedPoints: points)
        let result = PointComparison.compare(points, with: try RoomMinimumPointsRule.evaluate(room, grade: .medium).requirements)
        #expect(result.first { $0.kind == .generalUseOutlet }?.status == .missing(3))
        #expect(result.first { $0.kind == .fixedApplianceModule }?.status == .conforming)
        #expect(throws: UtilizationPoints.ValidationError.self) { try points.setCount(-1, for: .generalLighting) }
    }
}
