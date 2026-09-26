import SwiftUI

struct DemandStepView: View {
    @Binding var plan: CircuitPlan
    let grade: ElectrificationGrade
    let synchronizationFailed: Bool

    var body: some View {
        if synchronizationFailed {
            Section { StatusMessage(text: "Demanda pendiente: revisá las bocas de los ambientes; no se pudieron sincronizar.", tone: .pending) }
        } else if plan.circuits.isEmpty {
            Section { StatusMessage(text: "Demanda pendiente: agregá los circuitos en el paso anterior.", tone: .pending) }
        } else {
            let result = DemandEngine.project(plan: plan, grade: grade)
            Section("Circuitos de uso general y especial") {
                ForEach($plan.circuits) { $circuit in
                    if circuit.type != .acu, let demand = result.circuits.first(where: { $0.circuitID == circuit.id }) {
                        DemandCircuitRow(circuit: $circuit, result: demand)
                    }
                }
            }
            ProjectDemandView(result: result)
            Section("Cargas específicas") {
                if result.specificLoads.isEmpty { Text("Sin cargas específicas.").foregroundStyle(.secondary) }
                ForEach($plan.circuits) { $circuit in
                    if circuit.type == .acu, let demand = result.specificLoads.first(where: { $0.circuitID == circuit.id }) {
                        DemandCircuitRow(circuit: $circuit, result: demand)
                    }
                }
                DemandPowerRow(title: "Cargas específicas resolubles", value: result.resolvedSpecificDemand)
                Text("Se suman por separado, sin aplicarles el factor del grado.").font(.footnote).foregroundStyle(.secondary)
            }
            Section("DPMS total") {
                let presentation = DemandTotalPresentation(result: result)
                StatusMessage(text: presentation.statusText, tone: presentation.tone)
                if case .pending(let error, _) = presentation {
                    Text(error.displayMessage)
                }
                DemandPowerRow(title: presentation.valueTitle, value: presentation.value, emphasized: true)
                RegulatoryDisclosure {
                    Text(result.totalSource)
                    Text("Referencia interna: \(result.totalRuleID)").foregroundStyle(.secondary)
                    Text("DPMS total = DPMS del GE + demandas consideradas de cargas específicas.")
                    Text("Completa se refiere a los datos de este cálculo, no a la conformidad integral de la instalación. Revisá también los pendientes de ambientes y circuitos.")
                    Text("Ku/Ks específicos quedan pendientes; no se verifica todavía el grado definitivo ni el suministro.")
                }
            }
        }
    }
}

private struct DemandCircuitRow: View {
    @Binding var circuit: Circuit
    let result: CircuitDemandResult

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("C\(circuit.number) · \(circuit.type.rawValue.uppercased())").font(.headline)
            Text(circuit.destination.isEmpty ? circuit.type.displayName : circuit.destination)
            if let count = result.pointCount { Text("\(count) bocas").foregroundStyle(.secondary) }
            if circuit.type == .acu {
                if let load = circuit.declaredLoad { Text("\(PowerPresentation.number(load.value)) \(load.unit.rawValue)") }
                if let load = circuit.declaredLoad, load.unit != .voltAmpere {
                    Text("Factor de potencia: \(circuit.powerFactor?.displayValue ?? "pendiente")")
                }
            }
            CircuitDemandDetails(result: result, destination: circuit.destination)
            CircuitDemandEditor(circuit: $circuit)
        }.padding(.vertical, 6)
    }
}

// MARK: - Se conservan los formularios y resultados de Feature 004

struct CircuitDemandEditor: View {
    @Binding var circuit: Circuit
    @State private var form: CircuitDemandForm
    @State private var errorMessage: String?
    @State private var saved = false
    let embedded: Bool

    init(circuit: Binding<Circuit>, embedded: Bool = false) {
        self.embedded = embedded
        _circuit = circuit
        _form = State(initialValue: CircuitDemandForm(circuit: circuit.wrappedValue))
    }

    var body: some View {
        Group {
            if embedded { fields }
            else { DisclosureGroup("Editar datos de carga") { fields } }
        }
        .onAppear { form = CircuitDemandForm(circuit: circuit); saved = false }
        .onChange(of: form.destination) { saved = false }
        .onChange(of: form.declaredValue) { saved = false }
        .onChange(of: form.unit) { saved = false }
        .onChange(of: form.powerFactor) { saved = false }
        .onChange(of: form.knownDemandVA) { saved = false }
    }

    @ViewBuilder private var fields: some View {
        if circuit.type == .acu {
            LabeledInput(title: "Destino / nombre de la carga", text: $form.destination)
            LabeledInput(title: "Potencia declarada", text: $form.declaredValue, unit: form.unit.rawValue, prompt: "Vacío = pendiente", decimalInput: true)
            Picker("Unidad declarada", selection: $form.unit) {
                ForEach(PowerUnit.allCases, id: \.self) { Text($0.rawValue).tag($0) }
            }
            if form.unit != .voltAmpere {
                LabeledInput(title: "Factor de potencia", text: $form.powerFactor, prompt: "Sin valor por defecto", decimalInput: true)
            }
        } else {
            LabeledInput(title: "Demanda conocida opcional", text: $form.knownDemandVA, unit: "VA", prompt: "Dejá vacío si no se conoce", decimalInput: true)
            Text("Ingresá una demanda conocida comparable con el mínimo. No es la suma de potencias de placa ni permite reducir el mínimo.").font(.footnote)
        }
        Button("Aplicar datos de carga") {
            do { try form.apply(to: &circuit); errorMessage = nil; saved = true }
            catch { errorMessage = error.localizedDescription; saved = false }
        }.buttonStyle(.bordered)
        if let errorMessage { StatusMessage(text: errorMessage, tone: .invalid) }
        if saved { StatusMessage(text: "Datos aplicados", tone: .complete) }
    }
}

struct CircuitDemandDetails: View {
    let result: CircuitDemandResult
    let destination: String

    var body: some View {
        switch result.calculation {
        case .failure(let error):
            StatusMessage(text: error.message(for: destination), tone: error.tone)
        case .success(let calculation):
            switch calculation {
            case .regulated(let demand):
                if result.type == .iug, let count = result.pointCount {
                    Text("\(count) × \(IUGDemandRule.voltAmperesPerPoint.formatted()) VA × \(IUGDemandRule.factorNumerator.formatted())/\(IUGDemandRule.factorDenominator.formatted())")
                } else { Text("Demanda mínima") }
                Text(demand.minimumDemand.displayValue).font(.title3.bold())
                if let known = demand.knownDemand {
                    LabeledContent("Demanda conocida", value: known.displayValue)
                    LabeledContent("DPMS adoptada", value: demand.adoptedDemand.displayValue)
                }
                RegulatoryDisclosure {
                    Text(demand.source)
                    Text("Referencia interna: \(demand.ruleID)").foregroundStyle(.secondary)
                    Text("Base: \(demand.basePower.displayValue) · Factor: \(demand.factor.formatted())")
                    Text("Se adopta el mayor entre el mínimo y la demanda conocida.")
                    if result.type == .iug { Text("IUG sin tomacorrientes derivados. Se consideran las bocas asignadas; si faltan asignaciones, el total del proyecto permanece pendiente.") }
                }
            case .specific(let demand):
                Text(PowerPresentation.expression(demand.power))
                Text(demand.power.apparentPower.displayValue).font(.title3.bold())
                RegulatoryDisclosure {
                    Text("Conversión de la carga declarada").font(.headline)
                    Text("Referencia interna: \(demand.power.criterionID)").foregroundStyle(.secondary)
                    Text("Criterio de cálculo adoptado para esta aplicación. No se atribuye a una prescripción AEA/ERSeP.")
                    if let watts = demand.power.activePowerWatts { Text("Potencia activa obtenida: \(watts.formatted()) W") }
                    Text("VA no requiere factor de potencia. W/kW/HP requieren fp explícito. Se conserva el valor y la unidad originales, sin rendimiento supuesto.")
                    Text("Demanda considerada: \(demand.consideredDemand.displayValue), sin reducciones Ku/Ks.")
                }
            }
        }
    }
}

struct ProjectDemandView: View {
    let result: ProjectDemandResult

    var body: some View {
        Section("Resumen del grado") {
            DemandPowerRow(title: "Base IUG + TUG + TUE", value: result.generalBase)
            Text("Grado \(result.grade.displayName)").font(.headline)
            Text("Factor de simultaneidad × \(result.coefficient.formatted())")
            DemandPowerRow(title: "DPMS del GE", value: result.gradeDemand, emphasized: true)
            RegulatoryDisclosure {
                Text(result.coefficientSource)
                    Text("Referencia interna: \(result.coefficientRuleID)").foregroundStyle(.secondary)
                Text("DPMS GE = base × coeficiente del grado. El coeficiente no se aplica a ACU.")
            }
        }
    }
}

private struct DemandPowerRow: View {
    let title: String
    let value: Result<ApparentPower, DemandCalculationError>
    var emphasized = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.subheadline)
            switch value {
            case .success(let power): Text(power.displayValue).font(emphasized ? .title2.bold() : .headline)
            case .failure(let error): StatusMessage(text: error.displayMessage, tone: .pending)
            }
        }.padding(.vertical, 4)
    }
}
