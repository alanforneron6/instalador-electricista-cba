import Foundation

nonisolated enum RoomType: CaseIterable, Hashable {
    case livingDiningStudy, bedroom, kitchen, bathroom
    case vestibuleGarageDressingRoom, coveredHallway, laundry, semiCoveredOrOutdoorPassage
}

nonisolated struct Room: Identifiable {
    let id: UUID
    let name: String
    let type: RoomType
    let area: SquareMeters?
    let length: Meters?
    let projectedPoints: UtilizationPoints

    init(id: UUID = UUID(), name: String, type: RoomType,
         area: SquareMeters? = nil, length: Meters? = nil,
         projectedPoints: UtilizationPoints = UtilizationPoints()) {
        self.id = id
        self.name = name
        self.type = type
        self.area = area
        self.length = length
        self.projectedPoints = projectedPoints
    }
}
