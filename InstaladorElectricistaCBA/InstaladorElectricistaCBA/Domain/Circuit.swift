import Foundation

nonisolated enum SupplyNature: CaseIterable { case monophase, threePhase }

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
    private(set) var supplyNature: SupplyNature?
    private(set) var phaseAssignment: Phase?
    enum ValidationError: Error { case invalidNumber, loadOnNonACU, knownDemandOnACU, supplyNatureOnNonACU, phaseOnThreePhaseLoad }
    init(id: UUID = UUID(), number: Int, type: CircuitType, destination: String = "",
         declaredLoad: DeclaredLoad? = nil, powerFactor: PowerFactor? = nil, knownDemand: ApparentPower? = nil, supplyNature: SupplyNature? = nil, phaseAssignment: Phase? = nil) throws {
        guard number > 0 else { throw ValidationError.invalidNumber }
        guard type == .acu || (declaredLoad == nil && powerFactor == nil) else { throw ValidationError.loadOnNonACU }
        guard type != .acu || knownDemand == nil else { throw ValidationError.knownDemandOnACU }
        guard type == .acu || supplyNature == nil else { throw ValidationError.supplyNatureOnNonACU }
        guard supplyNature != .threePhase || phaseAssignment == nil else { throw ValidationError.phaseOnThreePhaseLoad }
        self.phaseAssignment = phaseAssignment
        self.id = id; self.number = number; self.type = type
        self.destination = destination; self.declaredLoad = declaredLoad
        self.powerFactor = powerFactor; self.knownDemand = knownDemand
        // Compatibilidad con ACU existentes; no describe el suministro de la vivienda.
        self.supplyNature = type == .acu ? (supplyNature ?? .monophase) : nil
    }

    mutating func updateSupplyNature(_ nature: SupplyNature) throws {
        guard type == .acu else { throw ValidationError.supplyNatureOnNonACU }
        supplyNature = nature
        // Un receptor trifásico no pertenece a una fase; no restauramos una asignación anterior.
        if nature == .threePhase { phaseAssignment = nil }
    }

    mutating func updatePhaseAssignment(_ phase: Phase?) throws {
        guard supplyNature != .threePhase || phase == nil else { throw ValidationError.phaseOnThreePhaseLoad }
        phaseAssignment = phase
    }

    // La edición reutiliza las validaciones y conserva la identidad y las asignaciones.
    mutating func updateDemand(declaredLoad: DeclaredLoad?, powerFactor: PowerFactor?, knownDemand: ApparentPower?) throws {
        self = try Circuit(id: id, number: number, type: type, destination: destination,
                           declaredLoad: declaredLoad, powerFactor: powerFactor, knownDemand: knownDemand, supplyNature: supplyNature, phaseAssignment: phaseAssignment)
    }
}

nonisolated enum CircuitVariant: String, CaseIterable { case a, b }
nonisolated struct CircuitSelection: Equatable {
    let grade: ElectrificationGrade
    let variant: CircuitVariant
}
// Sólo bocas físicas distribuibles; los módulos se conservan en el resumen del ambiente.
nonisolated enum CircuitPointKind: CaseIterable, Hashable {
    case generalLighting, generalUseOutlet, specialUseOutlet

    var roomKind: UtilizationPointKind {
        switch self {
        case .generalLighting: .generalLighting
        case .generalUseOutlet: .generalUseOutlet
        case .specialUseOutlet: .specialUseOutlet
        }
    }
}

nonisolated struct UtilizationPoint: Identifiable, Equatable {
    let id: UUID
    let roomID: UUID
    let kind: CircuitPointKind
    let ordinal: Int
    var circuitID: UUID?
}
nonisolated struct CircuitPlan {
    var selection: CircuitSelection?
    var freeChoiceCircuitID: UUID?
    var circuits: [Circuit] = []
    var points: [UtilizationPoint] = []
}
