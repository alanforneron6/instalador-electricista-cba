import Foundation

nonisolated enum DemandCalculationError: Error, Equatable {
    case missingDeclaredLoad
    case missingPowerFactor
    case invalidPointCount
    case incompatibleAssignments
    case unassignedPoints
    case numericOverflow
}

// MARK: - Conversión sin pérdida de la declaración original

nonisolated struct LoadPowerCalculation: Equatable {
    let declaredLoad: DeclaredLoad
    let wattsPerDeclaredUnit: Double?
    let activePowerWatts: Double?
    let powerFactorUsed: PowerFactor?
    let apparentPower: ApparentPower
    let criterionID: String
}

nonisolated struct SpecificLoadDemandCalculation: Equatable {
    let power: LoadPowerCalculation
    // Separada de la potencia aparente para incorporar el tratamiento futuro de Ku/Ks.
    let consideredDemand: ApparentPower
}

// MARK: - Resultados por circuito y por proyecto

nonisolated enum CircuitDemandCalculation: Equatable {
    case regulated(RegulatoryDemandCalculation)
    case specific(SpecificLoadDemandCalculation)

    var basePower: ApparentPower {
        switch self {
        case .regulated(let result): result.basePower
        case .specific(let result): result.power.apparentPower
        }
    }
    var adoptedDemand: ApparentPower {
        switch self {
        case .regulated(let result): result.adoptedDemand
        case .specific(let result): result.consideredDemand
        }
    }
}

nonisolated struct CircuitDemandResult: Identifiable, Equatable {
    let circuitID: UUID
    let type: CircuitType
    let pointCount: Int?
    let calculation: Result<CircuitDemandCalculation, DemandCalculationError>
    var id: UUID { circuitID }
}

nonisolated struct ProjectDemandResult {
    let circuits: [CircuitDemandResult]
    let grade: ElectrificationGrade
    let coefficient: Double
    let coefficientRuleID: String
    let coefficientSource: String
    let totalRuleID: String
    let totalSource: String
    let generalBase: Result<ApparentPower, DemandCalculationError>
    let gradeDemand: Result<ApparentPower, DemandCalculationError>
    let resolvedSpecificDemand: Result<ApparentPower, DemandCalculationError>
    let resolvedSubtotal: Result<ApparentPower, DemandCalculationError>
    // Sin asignaciones completas o datos de carga/fp, sólo puede informarse un subtotal.
    let total: Result<ApparentPower, DemandCalculationError>

    var specificLoads: [CircuitDemandResult] { circuits.filter { $0.type == .acu } }
    var pendingCircuitIDs: [UUID] {
        circuits.compactMap { if case .failure = $0.calculation { return $0.circuitID }; return nil }
    }
}
