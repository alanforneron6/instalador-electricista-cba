import Foundation

struct CircuitDemandForm {
    let supportsSupplyNature: Bool
    var supplyNature: SupplyNature
    var destination: String
    var declaredValue = ""
    var unit: PowerUnit = .voltAmpere
    var powerFactor = ""
    var knownDemandVA = ""

    init(circuit: Circuit) {
        supportsSupplyNature = circuit.type == .acu
        supplyNature = circuit.supplyNature ?? .monophase
        destination = circuit.destination
        if let load = circuit.declaredLoad {
            declaredValue = String(load.value)
            unit = load.unit
        }
        powerFactor = circuit.powerFactor.map { String($0.value) } ?? ""
        knownDemandVA = circuit.knownDemand.map { String($0.voltAmperes) } ?? ""
    }

    enum InputError: LocalizedError {
        case invalidPower, invalidPowerFactor
        var errorDescription: String? {
            switch self {
            case .invalidPower: "Ingresá una potencia finita mayor o igual a cero, sin separador de miles."
            case .invalidPowerFactor: "El factor de potencia debe ser finito, mayor que 0 y menor o igual a 1. Podés dejarlo vacío como pendiente."
            }
        }
    }

    func apply(to circuit: inout Circuit) throws {
        let load: DeclaredLoad?
        let factor: PowerFactor?
        let known: ApparentPower?
        if circuit.type == .acu {
            load = try Self.optionalNumber(declaredValue).map { try DeclaredLoad(value: $0, unit: unit) }
            // Editar una carga ya declarada en VA conserva su fp; cambiar a VA mantiene la limpieza previa.
            if unit == .voltAmpere {
                factor = circuit.declaredLoad?.unit == .voltAmpere ? circuit.powerFactor : nil
            } else {
                factor = try Self.parsePowerFactor(powerFactor)
            }
            known = nil
        } else {
            load = nil; factor = nil
            known = try Self.optionalNumber(knownDemandVA).map { try ApparentPower(voltAmperes: $0) }
        }
        try circuit.updateDemand(declaredLoad: load, powerFactor: factor, knownDemand: known)
        if circuit.type == .acu {
            try circuit.updateSupplyNature(supplyNature)
            circuit.destination = destination
        }
    }

    static func parsePowerFactor(_ text: String) throws -> PowerFactor? {
        do { return try optionalNumber(text).map { try PowerFactor($0) } }
        catch { throw InputError.invalidPowerFactor }
    }

    private static func optionalNumber(_ text: String) throws -> Double? {
        let value = text.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: ",", with: ".")
        if value.isEmpty { return nil }
        guard let number = Double(value), number.isFinite, number >= 0 else { throw InputError.invalidPower }
        return number
    }
}
