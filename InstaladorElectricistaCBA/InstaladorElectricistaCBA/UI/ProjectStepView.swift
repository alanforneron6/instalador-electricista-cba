import SwiftUI

struct ProjectStepView: View {
    @Binding var flow: ProjectFlowState

    var body: some View {
        Form {
            ProjectStepHeader(step: .project)
            Section {
                LabeledInput(title: "Nombre del proyecto", text: $flow.form.name, prompt: "Por ejemplo: Casa familiar")
                LabeledInput(title: "Superficie cubierta", text: $flow.form.coveredArea, unit: "m²", decimalInput: true)
                LabeledInput(title: "Superficie semicubierta", text: $flow.form.semiCoveredArea, unit: "m²", decimalInput: true)
                Text("Se considera el 50 % de esta superficie para calcular la SLA.").font(.footnote).foregroundStyle(.secondary)
                Text("Usá coma o punto decimal, sin separador de miles. Si no hay superficie semicubierta, ingresá 0.").font(.footnote)
                if let error = flow.errorMessage { StatusMessage(text: error, tone: .invalid) }
            }
            if let result = flow.result {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Superficie límite de aplicación (SLA)").font(.headline)
                        Text("\(result.sla.value.formatted()) m²").font(.title2.bold())
                        // Sólo cambia la escritura de la explicación, no el cálculo de SLA.
                        Text("\(result.project.coveredArea.value.formatted()) m² + (\(result.project.semiCoveredArea.value.formatted()) m² ÷ 2) = \(result.sla.value.formatted()) m²")
                        Divider()
                        Text("Grado de electrificación según superficie").font(.headline)
                        Text(result.grade.displayName).font(.title2.bold())
                        Text("Determinado a partir de la superficie límite de aplicación (SLA).")
                    }.padding(.vertical, 4)
                }
            }
            Section {
                RegulatoryDisclosure {
                    Text("SLA y grado de electrificación según superficie").font(.headline)
                    Text(PreliminaryElectrificationRule.source)
                    Text("Referencia interna: \(PreliminaryElectrificationRule.slaRuleID) · \(PreliminaryElectrificationRule.ruleID)").foregroundStyle(.secondary)
                    Text("SLA = superficie cubierta + la mitad de la superficie semicubierta. El grado inicial se obtiene de la SLA.")
                }
            }
            Section {
                Button("Continuar") { flow.advance() }
                    .buttonStyle(.borderedProminent).disabled(!flow.canContinue)
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle(ProjectStep.project.title)
    }
}
