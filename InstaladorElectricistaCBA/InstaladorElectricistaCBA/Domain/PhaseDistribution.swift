import Foundation

nonisolated enum Phase: CaseIterable, Hashable { case l1, l2, l3 }

nonisolated struct PhaseCurrents {
    let currentL1: ElectricCurrent
    let currentL2: ElectricCurrent
    let currentL3: ElectricCurrent

    subscript(_ phase: Phase) -> ElectricCurrent {
        switch phase {
        case .l1: currentL1
        case .l2: currentL2
        case .l3: currentL3
        }
    }
}

// Potencia disponible aun sin fase; no representa una corriente parcial definitiva.
nonisolated struct PhaseCircuitPower {
    let circuitID: UUID
    let adoptedDemand: ApparentPower
    let simultaneousDemand: ApparentPower
    let appliedCoefficient: Double
}

nonisolated struct PhaseCircuitContribution {
    let circuitID: UUID
    let adoptedDemand: ApparentPower
    // Potencia total del circuito, contada una sola vez incluso para receptores trifásicos.
    let simultaneousDemand: ApparentPower
    let appliedCoefficient: Double
    let phases: Set<Phase>
    let currentCalculation: SupplyCurrentCalculation
}

nonisolated struct CompletePhaseDistribution {
    let currents: PhaseCurrents
    let contributions: [PhaseCircuitContribution]
    var sectionalIb: ElectricCurrent { PhaseSectionalCurrentRule.maximum(currents) }
    var mostLoadedPhases: Set<Phase> { PhaseSectionalCurrentRule.mostLoaded(currents) }
    let decompositionCriterionID: String
    let decompositionSource: String
    let sectionalRuleID: String
    let sectionalSource: String
}

nonisolated enum PhaseDistributionState {
    case monophase(sectionalCurrent: ElectricCurrent)
    case incomplete(circuitIDsWithoutPhase: Set<UUID>)
    case complete(CompletePhaseDistribution)
}

nonisolated struct PhaseDistributionAssessment {
    // La demanda y decisión de suministro originales se conservan sin sustituciones.
    let project: ProjectElectricalAssessment
    let state: PhaseDistributionState
    let circuitPowers: [PhaseCircuitPower]
}

nonisolated enum PhaseDistributionError: Error, Equatable {
    case projectAssessment(ProjectAssessmentError)
    case numericOverflow
}
