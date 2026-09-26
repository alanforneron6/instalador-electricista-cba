import Foundation

struct RoomForm {
    var name = ""
    var type: RoomType = .livingDiningStudy
    var dimension = ""
    var iug = "0"
    var tug = "0"
    var modules = "0"

    enum InputError: LocalizedError {
        case invalidName, invalidDimension, invalidCount, missingDimension, outOfRange
        var errorDescription: String? {
            switch self {
            case .invalidName: "Ingresá el nombre del ambiente."
            case .invalidDimension: "Ingresá una dimensión finita mayor o igual a cero, sin separador de miles."
            case .invalidCount: "Las cantidades proyectadas deben ser enteros mayores o iguales a cero."
            case .missingDimension: "Falta la dimensión requerida para evaluar este ambiente con el grado actual."
            case .outOfRange: "La dimensión excede el rango de cálculo admitido."
            }
        }
    }

    func makeRoom(grade: ElectrificationGrade) throws -> Room {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { throw InputError.invalidName }
        var area: SquareMeters?
        var length: Meters?
        switch RoomMinimumPointsRule.dimension(for: type, grade: grade) {
        case .none: break
        case .area: area = try SquareMeters(parseDimension())
        case .length: length = try Meters(parseDimension())
        }
        var points = UtilizationPoints()
        try points.setCount(parseCount(iug), for: .generalLighting)
        try points.setCount(parseCount(tug), for: .generalUseOutlet)
        if type == .kitchen { try points.setCount(parseCount(modules), for: .fixedApplianceModule) }
        let room = Room(name: name.trimmingCharacters(in: .whitespacesAndNewlines), type: type,
                        area: area, length: length, projectedPoints: points)
        do { _ = try RoomMinimumPointsRule.evaluate(room, grade: grade) }
        catch { throw InputError.outOfRange }
        return room
    }

    private func parseDimension() throws -> Double {
        let normalized = dimension.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: ",", with: ".")
        guard normalized.range(of: #"^[0-9]+(?:\.[0-9]+)?$"#, options: .regularExpression) != nil,
              let value = Double(normalized), value.isFinite else { throw InputError.invalidDimension }
        return value
    }

    private func parseCount(_ text: String) throws -> Int {
        let value = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard value.range(of: #"^[0-9]+$"#, options: .regularExpression) != nil,
              let count = Int(value) else { throw InputError.invalidCount }
        return count
    }
}

extension RoomType {
    var displayName: String {
        switch self {
        case .livingDiningStudy: "Estar / comedor / escritorio"
        case .bedroom: "Dormitorio"
        case .kitchen: "Cocina"
        case .bathroom: "Baño"
        case .vestibuleGarageDressingRoom: "Vestíbulo / garage / vestidor"
        case .coveredHallway: "Pasillo cubierto"
        case .laundry: "Lavadero"
        case .semiCoveredOrOutdoorPassage: "Balcón / galería / semicubierto"
        }
    }
}
