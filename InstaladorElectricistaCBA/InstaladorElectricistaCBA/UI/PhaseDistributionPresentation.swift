import Foundation

extension Phase {
    var displayName: String {
        switch self { case .l1: "L1"; case .l2: "L2"; case .l3: "L3" }
    }
}

enum PhaseDistributionPresentation {
    static func isVisible(_ status: SupplyStatus) -> Bool { status != .monophase }
    static func showsSelector(_ circuit: Circuit) -> Bool { circuit.supplyNature != .threePhase }
    static func phases(_ phases: Set<Phase>) -> String {
        Phase.allCases.filter { phases.contains($0) }.map(\.displayName).joined(separator: " · ")
    }
    static func pendingCount(_ count: Int) -> String {
        count == 1 ? "1 circuito monofásico sin asignar." : "\(count) circuitos monofásicos sin asignar."
    }
    static func maximumTitle(_ result: CompletePhaseDistribution) -> String {
        result.mostLoadedPhases.count == 1 ? "Fase más cargada" : "Fases más cargadas"
    }
    static func current(_ phase: Phase, in result: CompletePhaseDistribution) -> String {
        SupplyPresentation.current(result.currents[phase])
    }
    static func sectional(_ result: CompletePhaseDistribution) -> String {
        SupplyPresentation.current(result.sectionalIb)
    }
}
