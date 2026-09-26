import SwiftUI

struct CircuitsView: View {
    @Binding var plan: CircuitPlan
    let rooms: [Room]
    let grade: ElectrificationGrade
    let synchronizationFailed: Bool
    @State private var type: CircuitType = .iug
    @State private var destination = ""
    @State private var power = ""
    @State private var unit: PowerUnit = .voltAmpere
    @State private var powerFactor = ""
    @State private var errorMessage: String?
    @State private var generationFeedback: String?
    @State private var feedbackID = UUID()

    var body: some View {
        minimumStructure
        ForEach($plan.circuits) { $circuit in
            Section {
                CircuitCardView(circuit: $circuit, points: plan.points)
                DisclosureGroup("Editar circuito") {
                    if circuit.type == .acu {
                        CircuitDemandEditor(circuit: $circuit, embedded: true)
                    } else {
                        LabeledInput(title: "Destino", text: $circuit.destination, prompt: "Por ejemplo: Estar y dormitorios")
                    }
                    Button("Quitar C\(circuit.number)", role: .destructive) { CircuitEngine.removeCircuit(circuit.id, from: &plan) }
                }
            }
        }
        addCircuit
        if let errorMessage { Section { StatusMessage(text: errorMessage, tone: .invalid) } }
        distribution
        Section {
            if !synchronizationFailed {
                let validation = CircuitEngine.validate(plan, grade: grade)
                StatusMessage(text: minimumMessage(validation.minimum), tone: validation.minimum == .conforming ? .complete : .pending)
                if validation.minimum == .conforming && validation.issues.isEmpty {
                    StatusMessage(text: "Distribución completa", tone: .complete)
                }
                if !validation.issues.isEmpty {
                    DisclosureGroup("Ver pendientes de circuitos") {
                        ForEach(validation.issues.indices, id: \.self) { index in
                            StatusMessage(text: issueMessage(validation.issues[index]), tone: issueTone(validation.issues[index]))
                        }
                    }
                }
            }
            RegulatoryDisclosure {
                Text("Cantidad mínima de circuitos").font(.headline)
                Text(MinimumCircuitsRule.source)
                Text("Para grado \(grade.displayName) se requieren como mínimo \(MinimumCircuitsRule.configurations(for: grade)[0].total) circuitos.")
                ForEach(MinimumCircuitsRule.configurations(for: grade), id: \.variant) { configuration in
                    Text("Variante \(configuration.variant.rawValue.uppercased()): \(configurationText(configuration))")
                }
                Text("Referencia interna: \(MinimumCircuitsRule.ruleID)").foregroundStyle(.secondary)
                Text("Máximo de bocas por circuito").font(.headline)
                Text(CircuitPointLimitRule.source)
                Text("Referencia normativa puntual pendiente de verificación.")
                Text("Referencia interna: \(CircuitPointLimitRule.ruleID)").foregroundStyle(.secondary)
                Text("Asignación de bocas").font(.headline)
                Text("Las bocas de iluminación general se asignan a circuitos IUG.")
                Text("Las bocas de tomacorrientes de uso general se asignan a circuitos TUG.")
                Text("AEA 90364-7-770 · Edición 2017 · Clasificación de bocas: 770.7.5, Tabla 770.7.III")
                Text("Referencia interna: \(CircuitPointCompatibilityRule.ruleID)").foregroundStyle(.secondary)
                Text("La revisión de mínimos no implica conformidad integral. TUE se puede crear; sus bocas específicas quedan para una etapa posterior.")
                Text("La reducción del máximo de bocas por canalización compartida continúa pendiente; esta versión no modela canalizaciones.")
            }
        }
    }

    // MARK: - Selección explícita y generación existente

    private var minimumStructure: some View {
        Section {
            Text("Grado de electrificación según superficie: \(grade.displayName)").font(.headline)
            let configurations = MinimumCircuitsRule.configurations(for: grade)
            Text("Tu proyecto requiere como mínimo \(configurations[0].total) circuitos.")
            Text("Podés agregar circuitos adicionales.").font(.footnote).foregroundStyle(.secondary)
            ForEach(configurations, id: \.variant) { configuration in
                if configurations.count > 1 {
                    let selection = CircuitSelection(grade: grade, variant: configuration.variant)
                    let isSelected = plan.selection == selection
                    Button {
                        plan.selection = selection
                    } label: {
                        HStack(alignment: .top) {
                            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Variante \(configuration.variant.rawValue.uppercased())").font(.headline)
                                Text(configurationText(configuration))
                            }
                            Spacer()
                        }.padding(.vertical, 6)
                    }
                    .buttonStyle(.bordered)
                    .accessibilityValue(isSelected ? "Seleccionada" : "Sin seleccionar")
                } else { Text(configurationText(configuration)) }
            }
            if configurations.count > 1, let selected = MinimumCircuitsRule.configuration(grade: grade, selection: plan.selection) {
                StatusMessage(text: "Variante \(selected.variant.rawValue.uppercased()) seleccionada", tone: .complete)
                Text(configurationText(selected))
            }
            Button(MinimumCircuitAction.title(for: plan)) {
                perform {
                    generationFeedback = try MinimumCircuitAction.perform(plan: &plan, grade: grade)
                    feedbackID = UUID()
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(MinimumCircuitsRule.configuration(grade: grade, selection: plan.selection) == nil)
            if let generationFeedback { StatusMessage(text: generationFeedback, tone: .complete) }
            if configurations[0].free > 0 {
                Picker("Circuito de libre elección", selection: $plan.freeChoiceCircuitID) {
                    Text("Sin definir").tag(nil as UUID?)
                    ForEach(plan.circuits) { circuit in
                        Text("C\(circuit.number) · \(circuit.type.rawValue.uppercased())").tag(Optional(circuit.id))
                    }
                }
                Text("Creá o seleccioná un circuito adicional para esta posición. TUE/ACU quedan pendientes de confirmar sus condiciones particulares de admisibilidad.").font(.footnote)
            }
        }
        .task(id: feedbackID) {
            guard generationFeedback != nil else { return }
            do { try await Task.sleep(for: .milliseconds(1500)) }
            catch { return }
            generationFeedback = nil
        }
    }

    private func configurationText(_ configuration: MinimumCircuitsRule.Configuration) -> String {
        "\(configuration.iug) IUG + \(configuration.tug) TUG" + (configuration.free > 0 ? " + \(configuration.free) libre" : "")
    }

    private var addCircuit: some View {
        Section {
            DisclosureGroup {
                Picker("Tipo de circuito", selection: $type) {
                    ForEach(CircuitType.allCases, id: \.self) { Text("\($0.rawValue.uppercased()) · \($0.displayName)").tag($0) }
                }
                LabeledInput(title: "Destino / nombre de la carga", text: $destination, prompt: "Por ejemplo: Aire acondicionado")
                if type == .acu {
                    LabeledInput(title: "Potencia declarada", text: $power, unit: unit.rawValue, decimalInput: true)
                    Picker("Unidad", selection: $unit) {
                        ForEach(PowerUnit.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }
                    if unit != .voltAmpere { LabeledInput(title: "Factor de potencia", text: $powerFactor, prompt: "Vacío = pendiente", decimalInput: true) }
                    Text("W/kW/HP requieren factor de potencia explícito. Podés completar estos datos en Demanda.").font(.footnote)
                }
                Button("Agregar circuito") {
                    perform {
                        let load: DeclaredLoad?
                        if type == .acu {
                            guard !destination.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                                  let value = Double(power.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: ",", with: ".")) else {
                                throw CircuitInputError.invalidLoad
                            }
                            load = try DeclaredLoad(value: value, unit: unit)
                        } else { load = nil }
                        let factor = type == .acu && unit != .voltAmpere ? try CircuitDemandForm.parsePowerFactor(powerFactor) : nil
                        try CircuitEngine.addCircuit(to: &plan, type: type, destination: destination, load: load, powerFactor: factor)
                        destination = ""; power = ""; powerFactor = ""
                    }
                }.buttonStyle(.borderedProminent)
            } label: { Label("Agregar circuito adicional", systemImage: "plus") }
        }
    }

    // MARK: - Puntos agrupados por ambiente, sin inferir compatibilidades

    @ViewBuilder private var distribution: some View {
        Section("Distribución de bocas") {
            if synchronizationFailed {
                StatusMessage(text: "No se pudo individualizar la cantidad de bocas: supera la capacidad técnica de esta versión. Reducí las cantidades para continuar; no es un límite normativo.", tone: .pending)
            } else {
                let progress = AssignmentProgress(plan: plan, validation: CircuitEngine.validate(plan, grade: grade))
                Text("\(progress.assigned) de \(progress.total) bocas asignadas").font(.headline)
                if progress.unassigned > 0 {
                    StatusMessage(text: progress.unassigned == 1 ? "Falta 1 boca por asignar" : "Faltan \(progress.unassigned) bocas por asignar", tone: .pending)
                }
                if progress.total > 0 && progress.assigned == progress.total {
                    StatusMessage(text: "Bocas asignadas · distribución completa", tone: .complete)
                }

            }
        }
        if !synchronizationFailed {
            ForEach(rooms) { room in
                let points = plan.points.filter { $0.roomID == room.id }
                if !points.isEmpty {
                    Section(room.name) {
                        Text("Asigná cada boca a un circuito compatible.").font(.footnote).foregroundStyle(.secondary)
                        ForEach(points) { point in
                            let compatible = point.compatibleCircuits(in: plan)
                            VStack(alignment: .leading, spacing: 6) {
                                Text(point.assignmentTitle)
                                if compatible.isEmpty {
                                    Text(plan.circuits.isEmpty
                                         ? "Primero creá los circuitos mínimos para poder distribuir las bocas."
                                         : "Creá un circuito compatible para asignar esta boca.")
                                        .font(.footnote).foregroundStyle(.secondary)
                                } else {
                                    Picker("Circuito", selection: Binding<UUID?>(get: { point.circuitID }, set: { id in
                                        perform { try CircuitEngine.assign(pointID: point.id, to: id, in: &plan) }
                                    })) {
                                        Text("Sin asignar").tag(nil as UUID?)
                                        ForEach(compatible) { circuit in
                                            Text("C\(circuit.number) · \(circuit.type.rawValue.uppercased())").tag(Optional(circuit.id))
                                        }
                                    }
                                    .labelsHidden()
                                    .accessibilityLabel("\(room.name), \(point.assignmentTitle), circuito")
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private func perform(_ action: () throws -> Void) {
        do { try action(); errorMessage = nil }
        catch let error as CircuitDemandForm.InputError { errorMessage = error.localizedDescription }
        catch { errorMessage = "No se pudo completar. Revisá selección, destino y potencia finita mayor o igual a cero." }
    }
    private func minimumMessage(_ status: MinimumCircuitsRule.Status) -> String {
        switch status {
        case .selectionRequired: "Pendiente: elegí la variante para el grado actual."
        case .conforming: "Cumple el mínimo de circuitos de la configuración."
        case let .missing(iug, tug, total): "Faltan circuitos: \(iug) IUG, \(tug) TUG; déficit total: \(total). Revisá también la posición libre."
        case .freeChoiceUndefined: "Pendiente: posición de libre elección sin definir."
        case .freeChoicePendingInterpretation: "Pendiente normativo: confirmar admisibilidad del TUE/ACU elegido para la posición libre."
        }
    }
    private func issueTone(_ issue: CircuitIssue) -> StatusTone {
        switch issue {
        case .pointLimit, .incompatibleAssignment, .missingCircuit: .invalid
        default: .pending
        }
    }
    private func issueMessage(_ issue: CircuitIssue) -> String {
        func circuitName(_ id: UUID) -> String { "C\(plan.circuits.first { $0.id == id }?.number ?? 0)" }
        func pointName(_ id: UUID) -> String {
            guard let point = plan.points.first(where: { $0.id == id }) else { return "Boca" }
            return "\(rooms.first { $0.id == point.roomID }?.name ?? "Ambiente") · \(point.assignmentTitle)"
        }
        switch issue {
        case .pointUnassigned(let id): return "Sin asignar: \(pointName(id))."
        case .missingCircuit(let id): return "Circuito inexistente: \(pointName(id))."
        case let .incompatibleAssignment(point, circuit): return "Asignación incompatible: \(pointName(point)) → \(circuitName(circuit))."
        case let .pointLimit(circuit, maximum, actual): return "Excede máximo: \(circuitName(circuit)), \(actual) bocas / \(maximum) permitidas."
        case .acuLoadMissing(let id): return "Falta indicar la potencia del equipo en \(circuitName(id))."
        case .acuDestinationMissing(let id): return "Falta identificar el equipo en \(circuitName(id))."
        }
    }
    private enum CircuitInputError: Error { case invalidLoad }
}

private struct CircuitCardView: View {
    @Binding var circuit: Circuit
    let points: [UtilizationPoint]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("C\(circuit.number) · \(circuit.type.rawValue.uppercased())").font(.headline)
            Text(circuit.destination.isEmpty ? circuit.type.displayName : circuit.destination)
            if circuit.type == .acu {
                if let load = circuit.declaredLoad { Text("1 carga · \(PowerPresentation.number(load.value)) \(load.unit.rawValue)") }
                else { StatusMessage(text: "Falta indicar la potencia del equipo.", tone: .pending) }
            } else {
                let count = points.filter { $0.circuitID == circuit.id }.count
                if let maximum = CircuitPointLimitRule.maximum(for: circuit.type) {
                    Text("\(count) / \(maximum) bocas")
                }
                switch CircuitPointLimitRule.evaluate(type: circuit.type, count: count) {
                case .valid: StatusMessage(text: "Dentro del máximo de bocas", tone: .complete)
                case .exceeded: StatusMessage(text: "Excede el máximo de bocas", tone: .invalid)
                case .invalidCount: StatusMessage(text: "Cantidad inválida", tone: .invalid)
                case .notApplicable: EmptyView()
                }
            }
        }.padding(.vertical, 4)
    }
}
