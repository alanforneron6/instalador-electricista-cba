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

    var body: some View {
        Section("Circuitos del proyecto") {
            Text("GE preliminar: \(grade.displayName)")
            let configurations = MinimumCircuitsRule.configurations(for: grade)
            Text("Mínimo: \(configurations[0].total) circuitos. Se permiten adicionales.")
            ForEach(configurations, id: \.variant) { configuration in
                Text("\(configurations.count > 1 ? "Variante " + configuration.variant.rawValue.uppercased() + ": " : "")\(configuration.iug) IUG + \(configuration.tug) TUG\(configuration.free > 0 ? " + 1 libre" : "")")
            }
            if configurations.count > 1 {
                Picker("Variante", selection: Binding<CircuitVariant?>(
                    get: { plan.selection?.grade == grade ? plan.selection?.variant : nil },
                    set: { plan.selection = $0.map { CircuitSelection(grade: grade, variant: $0) } }
                )) {
                    Text("Elegir variante").tag(nil as CircuitVariant?)
                    ForEach(CircuitVariant.allCases, id: \.self) { Text($0.rawValue.uppercased()).tag(Optional($0)) }
                }
            }
            Button("Completar estructura mínima") {
                perform { try CircuitEngine.generateMissing(in: &plan, grade: grade) }
            }
            .disabled(MinimumCircuitsRule.configuration(grade: grade, selection: plan.selection) == nil)
            if configurations[0].free > 0 {
                Picker("Circuito de libre elección", selection: $plan.freeChoiceCircuitID) {
                    Text("Sin definir").tag(nil as UUID?)
                    ForEach(plan.circuits) { circuit in
                        Text("C\(circuit.number) · \(circuit.type.rawValue.uppercased())").tag(Optional(circuit.id))
                    }
                }
                Text("Creá o seleccioná un circuito adicional para esta posición. TUE/ACU quedan pendientes de confirmar sus condiciones particulares de admisibilidad.").font(.caption)
            }
            Text(MinimumCircuitsRule.ruleID + " · " + MinimumCircuitsRule.source).font(.caption)
        }
        Section("Agregar circuito") {
            Picker("Tipo de circuito", selection: $type) {
                ForEach(CircuitType.allCases, id: \.self) { Text($0.rawValue.uppercased()).tag($0) }
            }
            TextField("Destino / nombre de la carga", text: $destination)
            if type == .acu {
                TextField("Potencia declarada", text: $power)
                Picker("Unidad", selection: $unit) {
                    ForEach(PowerUnit.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                if unit != .voltAmpere {
                    TextField("Factor de potencia (vacío = pendiente)", text: $powerFactor)
                }
                Text("La declaración original se conserva. W/kW/HP requieren fp explícito para calcular VA; HP usa el criterio del proyecto indicado en el resultado.").font(.caption)
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
            }
            if let errorMessage { Text(errorMessage).foregroundStyle(.red) }
        }
        Section("Resumen de circuitos") {
            Text("Circuito · Tipo · Destino · Bocas · Carga declarada · DPMS").font(.caption)
            ForEach($plan.circuits) { $circuit in
                VStack(alignment: .leading) {
                    Text("C\(circuit.number) · \(circuit.type.rawValue.uppercased())").font(.headline)
                    TextField("Destino", text: $circuit.destination)
                    if circuit.type == .acu {
                        Text(circuit.declaredLoad == nil ? "Carga pendiente" : "1 carga")
                    } else {
                        Text("\(plan.points.filter { $0.circuitID == circuit.id && $0.kind != .fixedApplianceModule }.count) bocas")
                    }
                    if let load = circuit.declaredLoad { Text("\(load.value.formatted()) \(load.unit.rawValue)") }
                    else { Text("Carga declarada: —") }
                    if circuit.type == .acu, circuit.declaredLoad?.unit != .voltAmpere {
                        Text("Factor de potencia: \(circuit.powerFactor.map { $0.value.formatted() } ?? "pendiente")")
                    }
                    CircuitDemandEditor(circuit: $circuit)
                    if !synchronizationFailed {
                        CircuitDemandDetails(result: DemandEngine.circuit(circuit, points: plan.points))
                    } else { Text("DPMS pendiente: no se pudieron sincronizar los puntos.") }
                    Button("Quitar C\(circuit.number)", role: .destructive) { CircuitEngine.removeCircuit(circuit.id, from: &plan) }
                }
            }
        }
        if !synchronizationFailed && !plan.circuits.isEmpty {
            ProjectDemandView(result: DemandEngine.project(plan: plan, grade: grade),
                              hasUnassignedPoints: CircuitEngine.validate(plan, grade: grade).issues.contains {
                if case .pointUnassigned = $0 { return true }; return false
            })
        }
        Section("Distribución de puntos") {
            if synchronizationFailed {
                Text("No se pudo individualizar la cantidad de puntos: supera la capacidad técnica de esta versión. Reducí las cantidades para continuar; no es un límite normativo.")
            } else {
                Text("Sin asignar: \(CircuitEngine.validate(plan, grade: grade).issues.filter { if case .pointUnassigned = $0 { return true }; return false }.count)")
                ForEach(plan.points) { point in
                    VStack(alignment: .leading) {
                        Text("\(rooms.first { $0.id == point.roomID }?.name ?? "Ambiente") · \(point.kind.displayName) #\(point.ordinal)")
                        if point.kind == .fixedApplianceModule {
                            Text("Pendiente de regla de asignación; no se cuenta como boca TUG.")
                        } else {
                            Picker("Circuito", selection: Binding<UUID?>(get: { point.circuitID }, set: { id in
                                perform { try CircuitEngine.assign(pointID: point.id, to: id, in: &plan) }
                            })) {
                                Text("Sin asignar").tag(nil as UUID?)
                                ForEach(plan.circuits.filter { CircuitPointCompatibilityRule.evaluate(kind: point.kind, type: $0.type) == .compatible }) { circuit in
                                    Text("C\(circuit.number) · \(circuit.destination)").tag(Optional(circuit.id))
                                }
                            }
                        }
                    }
                }
            }
        }
        Section("Validación de circuitos") {
            if !synchronizationFailed {
                let validation = CircuitEngine.validate(plan, grade: grade)
                Text(minimumMessage(validation.minimum))
                ForEach(validation.issues.indices, id: \.self) { index in Text(issueMessage(validation.issues[index])) }
                Text("La revisión de mínimos no implica conformidad integral de la instalación. TUE se puede crear; sus puntos específicos quedan para una etapa posterior.").font(.caption)
                Text(CircuitPointLimitRule.ruleID + " · " + CircuitPointCompatibilityRule.ruleID).font(.caption)
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
        case .selectionRequired: "Pendiente: elegí la variante para el GE actual."
        case .conforming: "Conforme: cumple el mínimo de circuitos de la configuración."
        case let .missing(iug, tug, total): "Faltan circuitos: \(iug) IUG, \(tug) TUG; déficit total: \(total). Revisá también la posición libre."
        case .freeChoiceUndefined: "Pendiente: posición de libre elección sin definir."
        case .freeChoicePendingInterpretation: "Pendiente normativo: confirmar admisibilidad del TUE/ACU elegido para la posición libre."
        }
    }
    private func issueMessage(_ issue: CircuitIssue) -> String {
        func circuitName(_ id: UUID) -> String { "C\(plan.circuits.first { $0.id == id }?.number ?? 0)" }
        func pointName(_ id: UUID) -> String {
            guard let point = plan.points.first(where: { $0.id == id }) else { return "Punto" }
            return "\(rooms.first { $0.id == point.roomID }?.name ?? "Ambiente") · \(point.kind.displayName) #\(point.ordinal)"
        }
        switch issue {
        case .pointUnassigned(let id): return "Sin asignar: \(pointName(id))."
        case .pointRulePending(let id): return "Regla pendiente: \(pointName(id))."
        case .missingCircuit(let id): return "Circuito inexistente: \(pointName(id))."
        case let .incompatibleAssignment(point, circuit): return "Asignación incompatible: \(pointName(point)) → \(circuitName(circuit))."
        case let .pointLimit(circuit, maximum, actual): return "Excede máximo: \(circuitName(circuit)), \(actual) bocas / \(maximum) permitidas."
        case .acuLoadMissing(let id): return "Carga ACU pendiente: \(circuitName(id))."
        case .acuDestinationMissing(let id): return "Identificación de carga ACU pendiente: \(circuitName(id))."
        }
    }
    private enum CircuitInputError: Error { case invalidLoad }
}
