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
    // Only an explicitly declared apparent power is available for now.
    var declaredVoltAmperes: Double? { unit == .voltAmpere ? value : nil }
}

nonisolated struct Circuit: Identifiable, Equatable {
    let id: UUID
    let number: Int
    let type: CircuitType
    var destination: String
    // A single optional declaration, never an array of loads or a boca count.
    private(set) var declaredLoad: DeclaredLoad?
    enum ValidationError: Error { case invalidNumber, loadOnNonACU }
    init(id: UUID = UUID(), number: Int, type: CircuitType, destination: String = "", declaredLoad: DeclaredLoad? = nil) throws {
        guard number > 0 else { throw ValidationError.invalidNumber }
        guard type == .acu || declaredLoad == nil else { throw ValidationError.loadOnNonACU }
        self.id = id; self.number = number; self.type = type
        self.destination = destination; self.declaredLoad = declaredLoad
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
