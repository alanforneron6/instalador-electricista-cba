import Foundation

// MARK: - Magnitudes y motivos humanos, sin repetir cálculos eléctricos

enum SupplyPresentation {
    static func apparent(_ value: ApparentPower) -> String {
        "\(PowerPresentation.number(value.voltAmperes / 1000)) kVA"
    }
    static func active(_ value: ActivePower) -> String {
        "\(PowerPresentation.number(value.kilowatts)) kW"
    }
    static func current(_ value: ElectricCurrent) -> String {
        "\(PowerPresentation.number(value.amperes)) A"
    }
    static func reason(_ reason: SupplyReason, assessment: SupplyAssessment) -> String {
        switch reason {
        case .threePhaseLoad: "El proyecto contiene uno o más receptores trifásicos."
        case .apparentDemandAbove7kVA:
            "La demanda aparente supera \(apparent(assessment.apparentRecommendationThreshold))."
        case .monophaseCurrentAbove32A:
            "La corriente resultante en una hipótesis monofásica supera \(current(assessment.currentRecommendationThreshold))."
        }
    }
    static func receivers(assessment: SupplyAssessment, circuits: [Circuit]) -> [Circuit] {
        circuits.filter { assessment.reasons.contains(.threePhaseLoad(circuitID: $0.id)) }
    }
    static func receiverName(_ circuit: Circuit) -> String {
        circuit.destination.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "C\(circuit.number) · ACU" : circuit.destination
    }
    static func sectional(_ state: SectionalCurrentState) -> (title: String, value: String) {
        switch state {
        case .determined(let current): ("Corriente de proyecto", self.current(current))
        case .pendingPhaseDistribution: ("Corriente del circuito seccional", "Pendiente de distribución de fases")
        }
    }
    static let hypotheticalTitle = "Corriente si se alimentara en monofásico"
}

extension SupplyStatus {
    var displayTitle: String {
        switch self {
        case .monophase: "Monofásico según criterio evaluado"
        case .threePhaseRecommended: "Trifásico recomendado"
        case .threePhaseRequired: "Alimentación trifásica requerida"
        }
    }
    var tone: StatusTone { self == .monophase ? .complete : .pending }
}

extension CategoryThreePowerScope {
    var displayTitle: String {
        self == .withinPowerScope ? "Dentro del alcance de potencia Cat. III" : "Fuera del alcance de potencia Cat. III"
    }
    var tone: StatusTone { self == .withinPowerScope ? .complete : .invalid }
}
