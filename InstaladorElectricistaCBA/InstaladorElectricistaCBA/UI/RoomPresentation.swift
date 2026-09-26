import Foundation

// MARK: - Estados visuales derivados de la comparación existente

enum RoomCompletion: Equatable {
    case complete, incomplete(bocas: Int, modules: Int), needsInformation, invalid

    var text: String {
        switch self {
        case .complete: return "Cumple"
        case let .incomplete(bocas, modules):
            let quantities = [(UtilizationPointKind.generalLighting, bocas), (.fixedApplianceModule, modules)]
                .filter { $0.1 > 0 }.map { $0.0.quantityText($0.1) }.joined(separator: " y ")
            let singular = (bocas == 1 && modules == 0) || (bocas == 0 && modules == 1)
            return "Incompleto · \(singular ? "falta" : "faltan") \(quantities)"
        case .needsInformation: return "Pendiente · completá la dimensión del ambiente"
        case .invalid: return "Revisá la dimensión o las cantidades ingresadas"
        }
    }
    var tone: StatusTone {
        switch self { case .complete: .complete; case .incomplete, .needsInformation: .pending; case .invalid: .invalid }
    }
}

struct RoomPresentation {
    let comparisons: [PointComparison]
    let notes: [RoomMinimumPointsRule.Note]
    let completion: RoomCompletion

    init(room: Room, grade: ElectrificationGrade) {
        do {
            let evaluation = try RoomMinimumPointsRule.evaluate(room, grade: grade)
            comparisons = PointComparison.compare(room.projectedPoints, with: evaluation.requirements)
            notes = evaluation.notes
            // Los módulos no se suman como bocas en el resumen de faltantes.
            var bocas = 0
            var modules = 0
            for item in comparisons {
                guard case .missing(let count) = item.status else { continue }
                if item.kind == .fixedApplianceModule { modules = count }
                else {
                    let sum = bocas.addingReportingOverflow(count)
                    bocas = sum.overflow ? Int.max : sum.partialValue
                }
            }
            completion = bocas == 0 && modules == 0 ? .complete : .incomplete(bocas: bocas, modules: modules)
        } catch RoomMinimumPointsRule.EvaluationError.missingArea {
            comparisons = []; notes = []; completion = .needsInformation
        } catch RoomMinimumPointsRule.EvaluationError.missingLength {
            comparisons = []; notes = []; completion = .needsInformation
        } catch {
            comparisons = []; notes = []; completion = .invalid
        }
    }

    init(draft: RoomForm, grade: ElectrificationGrade) {
        // El nombre no interviene en los mínimos; permite anticiparlos antes de escribirlo.
        var preview = draft
        if preview.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { preview.name = "Ambiente" }
        if let room = try? preview.makeRoom(grade: grade) {
            self = RoomPresentation(room: room, grade: grade)
        } else {
            comparisons = []; notes = []
            completion = draft.dimension.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .needsInformation : .invalid
        }
    }

    static func summary(_ room: Room) -> String {
        let points = room.projectedPoints
        var text = "\(points.count(for: .generalLighting)) IUG · \(points.count(for: .generalUseOutlet)) TUG"
        let fixed = points.count(for: .fixedApplianceModule)
        if fixed > 0 { text += " · \(UtilizationPointKind.fixedApplianceModule.quantityText(fixed)) para equipos fijos" }
        return text
    }
}

extension UtilizationPointKind {
    func quantityText(_ count: Int) -> String {
        let unit = self == .fixedApplianceModule
            ? (count == 1 ? "módulo" : "módulos")
            : (count == 1 ? "boca" : "bocas")
        return "\(count) \(unit)"
    }

    func projectedText(_ count: Int) -> String {
        "\(self == .fixedApplianceModule ? "Módulos proyectados" : "Bocas proyectadas"): \(count)"
    }

    func missingText(_ count: Int) -> String {
        "\(count == 1 ? "Falta" : "Faltan") \(quantityText(count))"
    }


    var inputTitle: String {
        switch self {
        case .generalLighting: "Iluminación general (IUG)"
        case .generalUseOutlet: "Tomacorrientes de uso general (TUG)"
        case .fixedApplianceModule: "Módulos adicionales para electrodomésticos de ubicación fija"
        }
    }
}
