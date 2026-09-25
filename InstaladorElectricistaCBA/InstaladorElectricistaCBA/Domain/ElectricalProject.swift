import Foundation

nonisolated struct ElectricalProject: Identifiable {
    let id: UUID
    let name: String
    let coveredArea: SquareMeters
    let semiCoveredArea: SquareMeters
    var rooms: [Room] = []
    var circuitPlan = CircuitPlan()
}

nonisolated enum ElectrificationGrade {
    case minimum, medium, elevated, superior
}
