import Foundation

nonisolated struct SquareMeters: Equatable, Sendable {
    let value: Double

    enum ValidationError: Error { case invalidValue }

    init(_ value: Double) throws {
        guard value.isFinite, value >= 0 else { throw ValidationError.invalidValue }
        self.value = value
    }
}
