import SwiftUI

struct PhaseDistributionView: View {
    let assessment: PhaseDistributionAssessment
    @Binding var circuits: [Circuit]
    @State private var assignmentError: String?

    var body: some View {
        Section("Distribución de fases") {
            Text("Asigná los circuitos monofásicos entre L1, L2 y L3.")
            ForEach($circuits) { $circuit in
                VStack(alignment: .leading, spacing: 8) {
                    Text("C\(circuit.number) · \(circuit.type.rawValue.uppercased())").font(.headline)
                    if !circuit.destination.isEmpty { Text(circuit.destination) }
                    if circuit.type == .acu {
                        Text(circuit.supplyNature == .threePhase ? "ACU · Trifásico" : "ACU · Monofásico")
                            .font(.subheadline).foregroundStyle(.secondary)
                    }
                    if let power = assessment.circuitPowers.first(where: { $0.circuitID == circuit.id }) {
                        Text("\(power.simultaneousDemand.displayValue)\(circuit.type == .acu ? "" : " simultáneos")")
                    }
                    if PhaseDistributionPresentation.showsSelector(circuit) {
                        HStack {
                            Text("Fase")
                            Spacer()
                            Menu {
                                phaseAction(nil, circuit: $circuit)
                                ForEach(Phase.allCases, id: \.self) { phase in
                                    phaseAction(phase, circuit: $circuit)
                                }
                            } label: {
                                HStack {
                                    Text(circuit.phaseAssignment?.displayName ?? "Sin asignar")
                                    Image(systemName: "chevron.up.chevron.down")
                                }.frame(minHeight: 44).contentShape(Rectangle())
                            }
                            .buttonStyle(.borderless)
                            .accessibilityLabel("Fase de C\(circuit.number), \(circuit.destination)")
                        }
                    } else {
                        Text(PhaseDistributionPresentation.phases(Set(Phase.allCases))).font(.subheadline.bold())
                        Text("Potencia total del receptor, compartida entre las tres fases.")
                            .font(.footnote).foregroundStyle(.secondary)
                    }
                }.padding(.vertical, 4)
            }
            if let assignmentError { StatusMessage(text: assignmentError, tone: .invalid) }
            RegulatoryDisclosure {
                Text(PhaseSectionalCurrentRule.source)
                Text("Se suman las corrientes por fase y se adopta la mayor como corriente seccional.")
                Text("Para distribuir la demanda del grado, se aplica su coeficiente a cada contribución IUG/TUG/TUE. Es una decisión de modelado; no cambia la DPMS del proyecto. ACU conserva su demanda considerada.")
                Text("Referencias internas: \(PhaseSectionalCurrentRule.ruleID) · \(PhaseContributionCriterion.criterionID)").foregroundStyle(.secondary)
            }
        }
        Section {
            switch assessment.state {
            case .incomplete(let ids):
                Text("Corriente del circuito seccional").font(.headline)
                StatusMessage(text: "Pendiente de distribución de fases", tone: .pending)
                Text(PhaseDistributionPresentation.pendingCount(ids.count))
            case .complete(let result):
                Text("Corrientes por fase").font(.headline)
                ForEach(Phase.allCases, id: \.self) { phase in
                    LabeledContent(phase.displayName, value: PhaseDistributionPresentation.current(phase, in: result))
                }
                LabeledContent(PhaseDistributionPresentation.maximumTitle(result),
                               value: PhaseDistributionPresentation.phases(result.mostLoadedPhases))
                Divider()
                LabeledContent("Ib seccional", value: PhaseDistributionPresentation.sectional(result)).font(.headline)
                StatusMessage(text: "Distribución completa", tone: .complete)
            case .monophase: EmptyView()
            }
        }
    }

    // El circuito del estado compartido cambia de fase sin copias locales ni navegación.
    private func phaseAction(_ phase: Phase?, circuit: Binding<Circuit>) -> some View {
        Button {
            do {
                try circuit.wrappedValue.updatePhaseAssignment(phase)
                assignmentError = nil
            } catch { assignmentError = "Este receptor trifásico participa de las tres fases y no admite una fase individual." }
        } label: {
            let title = phase?.displayName ?? "Sin asignar"
            if circuit.wrappedValue.phaseAssignment == phase { Label(title, systemImage: "checkmark") }
            else { Text(title) }
        }
    }
}
