import Testing
@testable import InstaladorElectricistaCBA

@Suite("RULE-SLA-001")
struct SLACalculatorTests {
    @Test(arguments: [(80.0, 0.0, 80.0), (80, 20, 90), (0, 20, 10), (0, 0, 0), (50.25, 10.5, 55.5), (100, 0, 100), (100, 20, 110), (50.25, 20.5, 60.5)])
    func surface(covered: Double, semiCovered: Double, expected: Double) throws {
        let result = try SLACalculator.calculate(covered: SquareMeters(covered), semiCovered: SquareMeters(semiCovered))
        #expect(result.value == expected)
    }

    @Test func rejectsOverflow() throws {
        let area = try SquareMeters(Double.greatestFiniteMagnitude)
        #expect(throws: SquareMeters.ValidationError.self) {
            try SLACalculator.calculate(covered: area, semiCovered: area)
        }
    }
}
