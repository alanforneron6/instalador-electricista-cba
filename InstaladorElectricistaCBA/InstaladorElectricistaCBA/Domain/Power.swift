// MARK: - Magnitudes de potencia

nonisolated struct PowerFactor: Equatable, Sendable {
    let value: Double
    enum ValidationError: Error { case invalidValue }

    init(_ value: Double) throws {
        guard value.isFinite, value > 0, value <= 1 else { throw ValidationError.invalidValue }
        self.value = value
    }
}

nonisolated struct ApparentPower: Equatable, Sendable {
    let voltAmperes: Double
    enum ValidationError: Error { case invalidValue }

    init(voltAmperes: Double) throws {
        guard voltAmperes.isFinite, voltAmperes >= 0 else { throw ValidationError.invalidValue }
        self.voltAmperes = voltAmperes
    }
}
