import SwiftUI

struct ContentView: View {
    @State private var flow = ProjectFlowState()

    var body: some View {
        NavigationStack(path: $flow.path) {
            ProjectStepView(flow: $flow)
                .navigationDestination(for: ProjectStep.self) { step in
                    ProjectDestinationView(step: step, flow: $flow)
                }
        }
    }

}

// El destino lee el binding vigente, sin capturar una evaluación del contenedor.
private struct ProjectDestinationView: View {
    let step: ProjectStep
    @Binding var flow: ProjectFlowState

    var body: some View {
        if let result = flow.result {
            Form {
                ProjectStepHeader(step: step)
                switch step {
                case .project: EmptyView()
                case .rooms:
                    RoomsView(rooms: $flow.form.rooms, grade: result.grade)
                case .circuits:
                    CircuitsView(plan: $flow.form.circuitPlan, rooms: flow.form.rooms, grade: result.grade,
                                 synchronizationFailed: flow.form.pointSynchronizationFailed)
                case .demand:
                    DemandStepView(plan: $flow.form.circuitPlan, grade: result.grade,
                                   synchronizationFailed: flow.form.pointSynchronizationFailed)
                }
                Section {
                    if step == .rooms {
                        Button("Continuar a circuitos") { flow.advance() }.buttonStyle(.borderedProminent)
                    } else if step == .circuits {
                        Button("Continuar a demanda") { flow.advance() }.buttonStyle(.borderedProminent)
                    }
                    Button("Volver a \(ProjectStep(rawValue: step.rawValue - 1)?.name ?? "Proyecto")") { flow.goBack() }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(step.title)
        } else {
            ContentUnavailableView("Revisá los datos del proyecto", systemImage: "exclamationmark.circle",
                                   description: Text("Volvé al primer paso y revisá el nombre y las superficies."))
        }
    }
}

#Preview { ContentView() }
