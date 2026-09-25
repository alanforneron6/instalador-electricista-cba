import Testing
@testable import InstaladorElectricistaCBA

@Suite("SquareMeters — validación de superficies")
struct SquareMetersTests {
    @Test(arguments: [0.0, 50.25])
    func acceptsValidSurface(value: Double) throws {
        #expect(try SquareMeters(value).value == value)
    }

    @Test(arguments: [-1.0, -0.01, Double.nan, Double.infinity, -Double.infinity])
    func rejectsInvalidSurface(value: Double) {
        #expect(throws: SquareMeters.ValidationError.self) { try SquareMeters(value) }
    }
}
