import Foundation

// MARK: - El subtotal nunca se presenta como total completo

enum DemandTotalPresentation {
    case complete(ApparentPower)
    case pending(DemandCalculationError, subtotal: Result<ApparentPower, DemandCalculationError>)

    init(result: ProjectDemandResult) {
        switch result.total {
        case .success(let power): self = .complete(power)
        case .failure(let error): self = .pending(error, subtotal: result.resolvedSubtotal)
        }
    }
    var statusText: String {
        switch self { case .complete: "Completa"; case .pending: "Demanda pendiente" }
    }
    var tone: StatusTone {
        switch self { case .complete: .complete; case .pending: .pending }
    }
    var valueTitle: String {
        switch self { case .complete: "DPMS total"; case .pending: "Subtotal resoluble (incompleto)" }
    }
    var value: Result<ApparentPower, DemandCalculationError> {
        switch self { case .complete(let power): .success(power); case .pending(_, let subtotal): subtotal }
    }
}

extension ApparentPower {
    var displayValue: String { "\(PowerPresentation.number(voltAmperes)) VA" }
}

extension PowerFactor {
    var displayValue: String { PowerPresentation.factor(value) }
}

extension DemandCalculationError {
    var displayMessage: String {
        switch self {
        case .missingDeclaredLoad: "Falta indicar la potencia del equipo."
        case .missingPowerFactor: "Falta el factor de potencia."
        case .invalidPointCount: "La cantidad de bocas es inválida."
        case .incompatibleAssignments: "Hay bocas asignadas a un circuito incompatible."
        case .unassignedPoints: "Todavía hay bocas sin asignar a un circuito."
        case .numericOverflow: "El valor excede el rango de cálculo. Revisá los datos."
        }
    }
    var tone: StatusTone {
        switch self {
        case .invalidPointCount, .incompatibleAssignments, .numericOverflow: .invalid
        default: .pending
        }
    }
    func message(for destination: String) -> String {
        guard !destination.isEmpty else { return displayMessage }
        switch self {
        case .missingPowerFactor: return "Falta el factor de potencia de «\(destination)»."
        case .missingDeclaredLoad: return "Falta indicar la potencia de «\(destination)»."
        default: return displayMessage
        }
    }
}
