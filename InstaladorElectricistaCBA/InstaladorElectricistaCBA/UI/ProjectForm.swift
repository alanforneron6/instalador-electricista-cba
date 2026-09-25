import Foundation

struct ProjectForm {
    var name = ""
    var coveredArea = ""
    var semiCoveredArea = ""
    private let projectID = UUID()

    struct Result {
        let project: ElectricalProject
        let sla: SquareMeters
        let grade: ElectrificationGrade
    }

    enum InputError: LocalizedError {
        case missingName, invalidArea(String), calculationOutOfRange

        var errorDescription: String? {
            switch self {
            case .missingName: "Ingresá el nombre del proyecto."
            case .invalidArea(let field): "\(field): ingresá una superficie válida mayor o igual a cero, sin separador de miles."
            case .calculationOutOfRange: "Las superficies exceden el rango de cálculo admitido."
            }
        }
    }

    func calculate() throws -> Result {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { throw InputError.missingName }
        let project = ElectricalProject(
            id: projectID, name: trimmedName,
            coveredArea: try parse(coveredArea, field: "Superficie cubierta"),
            semiCoveredArea: try parse(semiCoveredArea, field: "Superficie semicubierta")
        )
        let sla: SquareMeters
        do {
            sla = try SLACalculator.calculate(covered: project.coveredArea, semiCovered: project.semiCoveredArea)
        } catch { throw InputError.calculationOutOfRange }
        return Result(project: project, sla: sla, grade: PreliminaryElectrificationRule.grade(for: sla))
    }

    private func parse(_ text: String, field: String) throws -> SquareMeters {
        let normalized = text.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: ",", with: ".")
        guard normalized.range(of: #"^-?[0-9]+(?:\.[0-9]+)?$"#, options: .regularExpression) != nil,
              let value = Double(normalized), let area = try? SquareMeters(value) else {
            throw InputError.invalidArea(field)
        }
        return area
    }
}

extension ElectrificationGrade {
    var displayName: String {
        switch self {
        case .minimum: "Mínimo"
        case .medium: "Medio"
        case .elevated: "Elevado"
        case .superior: "Superior"
        }
    }
}
