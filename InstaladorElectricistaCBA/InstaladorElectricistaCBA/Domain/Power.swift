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


nonisolated struct ActivePower: Equatable, Sendable {
    let watts: Double
    var kilowatts: Double { watts / 1000 }
    enum ValidationError: Error { case invalidValue }

    init(watts: Double) throws {
        guard watts.isFinite, watts >= 0 else { throw ValidationError.invalidValue }
        self.watts = watts
    }
}

nonisolated struct ElectricCurrent: Equatable, Sendable {
    let amperes: Double
    enum ValidationError: Error { case invalidValue }

    init(amperes: Double) throws {
        guard amperes.isFinite, amperes >= 0 else { throw ValidationError.invalidValue }
        self.amperes = amperes
    }
}
