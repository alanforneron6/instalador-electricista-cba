import SwiftUI

struct ContentView: View {
    @State private var form = ProjectForm()
    @State private var attemptedCalculation = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Datos del proyecto") {
                    TextField("Nombre del proyecto", text: $form.name)
                    TextField("Superficie cubierta (m²)", text: $form.coveredArea)
                    TextField("Superficie semicubierta (m²)", text: $form.semiCoveredArea)
                    Text("Usá coma o punto decimal, sin separador de miles. Si no hay superficie semicubierta, ingresá 0.")
                        .font(.caption)
                    Button("Calcular") { attemptedCalculation = true }
                }
                if attemptedCalculation {
                    results
                }
            }
            .navigationTitle("Proyecto eléctrico")
        }
    }

    @ViewBuilder private var results: some View {
        switch Result(catching: { try form.calculate() }) {
        case .success(let result):
            Section("Resultado preliminar") {
                Text(result.project.name)
                LabeledContent("SLA", value: "\(result.sla.value.formatted()) m²")
                LabeledContent("Grado de electrificación", value: result.grade.displayName)
                Text("SLA = cubierta + 0,5 × semicubierta")
                Text("\(result.project.coveredArea.value.formatted()) m² + 0,5 × \(result.project.semiCoveredArea.value.formatted()) m² = \(result.sla.value.formatted()) m²")
                Text("Grado preliminar; deberá verificarse en etapas posteriores.")
                    .font(.caption)
            }
            RoomsView(rooms: $form.rooms, grade: result.grade)
            Section("Referencia normativa") {
                Text("\(PreliminaryElectrificationRule.slaRuleID) · \(PreliminaryElectrificationRule.ruleID)")
                Text(PreliminaryElectrificationRule.source)
            }
        case .failure(let error):
            Section("Revisá los datos") {
                Text(error.localizedDescription).foregroundStyle(.red)
            }
        }
    }
}

#Preview { ContentView() }
