import Foundation

nonisolated enum CircuitCategory { case generalUse, specialUse, specificUse }
nonisolated enum CircuitType: String, CaseIterable, Hashable {
    case iug, tug, tue, acu
    var category: CircuitCategory {
        switch self {
        case .iug, .tug: .generalUse
        case .tue: .specialUse
        case .acu: .specificUse
        }
    }
}

nonisolated enum PowerUnit: String, CaseIterable { case voltAmpere = "VA", watt = "W", kilowatt = "kW", horsepower = "HP" }
nonisolated struct DeclaredLoad: Equatable {
    let value: Double
    let unit: PowerUnit
    enum ValidationError: Error { case invalidValue }
    init(value: Double, unit: PowerUnit) throws {
        guard value.isFinite, value >= 0 else { throw ValidationError.invalidValue }
        self.value = value
        self.unit = unit
    }
    // Sólo refleja VA declarados; las conversiones no reemplazan el dato original.
    var declaredVoltAmperes: Double? { unit == .voltAmpere ? value : nil }
}

nonisolated struct Circuit: Identifiable, Equatable {
    let id: UUID
    let number: Int
    let type: CircuitType
    var destination: String
    // Una única carga ACU; su potencia no representa una cantidad de bocas.
    private(set) var declaredLoad: DeclaredLoad?
    private(set) var powerFactor: PowerFactor?
    private(set) var knownDemand: ApparentPower?
    enum ValidationError: Error { case invalidNumber, loadOnNonACU, knownDemandOnACU }
    init(id: UUID = UUID(), number: Int, type: CircuitType, destination: String = "",
         declaredLoad: DeclaredLoad? = nil, powerFactor: PowerFactor? = nil, knownDemand: ApparentPower? = nil) throws {
        guard number > 0 else { throw ValidationError.invalidNumber }
        guard type == .acu || (declaredLoad == nil && powerFactor == nil) else { throw ValidationError.loadOnNonACU }
        guard type != .acu || knownDemand == nil else { throw ValidationError.knownDemandOnACU }
        self.id = id; self.number = number; self.type = type
        self.destination = destination; self.declaredLoad = declaredLoad
        self.powerFactor = powerFactor; self.knownDemand = knownDemand
    }

    // La edición reutiliza las validaciones y conserva la identidad y las asignaciones.
    mutating func updateDemand(declaredLoad: DeclaredLoad?, powerFactor: PowerFactor?, knownDemand: ApparentPower?) throws {
        self = try Circuit(id: id, number: number, type: type, destination: destination,
                           declaredLoad: declaredLoad, powerFactor: powerFactor, knownDemand: knownDemand)
    }
}

nonisolated enum CircuitVariant: String, CaseIterable { case a, b }
nonisolated struct CircuitSelection: Equatable {
    let grade: ElectrificationGrade
    let variant: CircuitVariant
}
nonisolated struct UtilizationPoint: Identifiable, Equatable {
    let id: UUID
    let roomID: UUID
    let kind: UtilizationPointKind
    let ordinal: Int
    var circuitID: UUID?
}
nonisolated struct CircuitPlan {
    var selection: CircuitSelection?
    var freeChoiceCircuitID: UUID?
    var circuits: [Circuit] = []
    var points: [UtilizationPoint] = []
}
