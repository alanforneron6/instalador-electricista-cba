import Foundation

// MARK: - Navegación sin reemplazar el proyecto compartido

enum ProjectStep: Int, Hashable {
    case project = 1, rooms, circuits, demand

    var name: String {
        switch self {
        case .project: "Proyecto"
        case .rooms: "Ambientes"
        case .circuits: "Circuitos"
        case .demand: "Demanda"
        }
    }
    var title: String {
        switch self {
        case .project: "Datos del proyecto"
        case .rooms: "Ambientes y bocas"
        case .circuits: "Circuitos"
        case .demand: "Demanda del proyecto"
        }
    }
    var subtitle: String {
        switch self {
        case .project: "Empezá por los datos básicos de la vivienda."
        case .rooms: "Agregá los ambientes y las bocas (puntos de utilización) que tendrá la instalación."
        case .circuits: "Definí cómo se distribuirán las bocas de la instalación."
        case .demand: "Revisá cómo se obtiene la demanda máxima simultánea."
        }
    }
    var indicator: String { "Paso \(rawValue) de 4 · \(name)" }
}

struct ProjectFlowState {
    var form = ProjectForm()
    var path: [ProjectStep] = []
    var step: ProjectStep { path.last ?? .project }

    // Una sola evaluación del formulario actual, sin confirmación ni copia de entradas.
    private var evaluation: Result<ProjectForm.Result, Error> { Result { try form.calculate() } }
    var result: ProjectForm.Result? { try? evaluation.get() }
    var canContinue: Bool { result != nil }
    var errorMessage: String? {
        guard case .failure(let error) = evaluation else { return nil }
        // Un formulario recién abierto no es todavía un error de carga.
        guard !form.name.isEmpty || !form.coveredArea.isEmpty || !form.semiCoveredArea.isEmpty else { return nil }
        return error.localizedDescription
    }

    mutating func advance() {
        guard canContinue, let next = ProjectStep(rawValue: step.rawValue + 1) else { return }
        path.append(next)
    }

    mutating func goBack() {
        if !path.isEmpty { path.removeLast() }
    }
}
