import Foundation

nonisolated enum RoomMinimumPointsRule {
    static let ruleID = "RULE-ROOM-POINTS-001"
    static let source = "AEA 90364-7-770 · Edición 2017 · 770.7.5 — Tabla 770.7.III"

    enum Dimension { case none, area, length }
    enum EvaluationError: Error { case missingArea, missingLength, countOutOfRange }
    enum Note { case largeBedroomElevatedCriterion }
    struct Evaluation {
        let requirements: [UtilizationPointRequirement]
        let notes: [Note]
    }

    static func dimension(for type: RoomType, grade: ElectrificationGrade) -> Dimension {
        switch type {
        case .livingDiningStudy, .bedroom: .area
        case .vestibuleGarageDressingRoom: grade == .minimum ? .none : .area
        case .coveredHallway, .semiCoveredOrOutdoorPassage: .length
        case .kitchen, .bathroom, .laundry: .none
        }
    }

    static func evaluate(_ room: Room, grade: ElectrificationGrade) throws -> Evaluation {
        let area: Double
        let length: Double
        switch dimension(for: room.type, grade: grade) {
        case .area:
            guard let value = room.area else { throw EvaluationError.missingArea }
            area = value.value; length = 0
        case .length:
            guard let value = room.length else { throw EvaluationError.missingLength }
            length = value.value; area = 0
        case .none: area = 0; length = 0
        }
        var iug: Int
        var tug: Int?
        var modules: Int?
        var notes: [Note] = []
        switch room.type {
        case .livingDiningStudy:
            iug = try roundedCount(area, per: 18, minimum: 1)
            tug = try roundedCount(area, per: 6, minimum: 2)
        case .bedroom:
            iug = area > 36 ? 2 : 1
            tug = area < 10 ? 2 : 3
            if area > 36 { notes.append(.largeBedroomElevatedCriterion) }
        case .kitchen:
            iug = grade == .minimum ? 1 : 2
            tug = grade == .superior ? 4 : 3
            modules = (grade == .minimum || grade == .medium) ? 2 : 3
        case .bathroom: iug = 1; tug = 1
        case .vestibuleGarageDressingRoom:
            iug = grade == .minimum ? 1 : try roundedCount(area, per: 12, minimum: 1)
            tug = iug
        case .coveredHallway:
            iug = try roundedCount(length, per: 5, minimum: 1)
            if grade != .minimum { tug = length > 2 ? try roundedCount(length, per: 5) : 0 }
        case .laundry: iug = 1; tug = grade == .minimum ? 1 : 2
        case .semiCoveredOrOutdoorPassage:
            iug = try roundedCount(length, per: 5)
        }
        var requirements = [UtilizationPointRequirement(kind: .generalLighting, minimumCount: iug)]
        if let tug { requirements.append(.init(kind: .generalUseOutlet, minimumCount: tug)) }
        if let modules { requirements.append(.init(kind: .fixedApplianceModule, minimumCount: modules)) }
        return Evaluation(requirements: requirements, notes: notes)
    }

    private static func roundedCount(_ value: Double, per interval: Double, minimum: Int = 0) throws -> Int {
        guard let count = Int(exactly: (value / interval).rounded(.up)) else {
            throw EvaluationError.countOutOfRange
        }
        return max(minimum, count)
    }
}
