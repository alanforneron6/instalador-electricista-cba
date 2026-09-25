import SwiftUI

// MARK: - Datos de cálculo editables por circuito

struct CircuitDemandEditor: View {
    @Binding var circuit: Circuit
    @State private var form: CircuitDemandForm
    @State private var errorMessage: String?
    @State private var saved = false

    init(circuit: Binding<Circuit>) {
        _circuit = circuit
        _form = State(initialValue: CircuitDemandForm(circuit: circuit.wrappedValue))
    }

    var body: some View {
        DisclosureGroup("Editar datos de carga") {
            if circuit.type == .acu {
                TextField("Potencia declarada (vacío = pendiente)", text: $form.declaredValue)
                Picker("Unidad declarada", selection: $form.unit) {
                    ForEach(PowerUnit.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                if form.unit != .voltAmpere {
                    TextField("Factor de potencia (sin valor por defecto)", text: $form.powerFactor)
                }
            } else {
                TextField("Demanda conocida opcional (VA)", text: $form.knownDemandVA)
                Text("Ingresá una demanda conocida comparable con el mínimo. No es la suma de potencias de placa ni permite reducir el mínimo.").font(.caption)
            }
            Button("Aplicar datos de carga") {
                do { try form.apply(to: &circuit); errorMessage = nil; saved = true }
                catch { errorMessage = error.localizedDescription; saved = false }
            }
            if let errorMessage { Text(errorMessage).foregroundStyle(.red) }
            if saved { Text("Datos aplicados.").font(.caption) }
        }
        .onChange(of: form.declaredValue) { saved = false }
        .onChange(of: form.unit) { saved = false }
        .onChange(of: form.powerFactor) { saved = false }
        .onChange(of: form.knownDemandVA) { saved = false }
    }
}

// MARK: - Trazabilidad de DPMS

struct CircuitDemandDetails: View {
    let result: CircuitDemandResult

    var body: some View {
        switch result.calculation {
        case .failure(let error):
            Text("DPMS pendiente: \(error.displayMessage)")
        case .success(let calculation):
            LabeledContent("DPMS adoptada", value: calculation.adoptedDemand.displayValue)
            switch calculation {
            case .regulated(let demand):
                if result.type == .iug, let count = result.pointCount {
                    Text("Base: \(count) bocas × \(IUGDemandRule.voltAmperesPerPoint.formatted()) VA/boca = \(demand.basePower.displayValue)")
                    Text("Mínimo: \(demand.basePower.displayValue) × \(IUGDemandRule.factorNumerator.formatted())/\(IUGDemandRule.factorDenominator.formatted()) = \(demand.minimumDemand.displayValue)")
                } else {
                    Text("Mínimo reglamentario: \(demand.minimumDemand.displayValue)")
                }
                if let known = demand.knownDemand { Text("Demanda conocida: \(known.displayValue)") }
                Text("Se adopta el mayor entre mínimo y demanda conocida.").font(.caption)
                if result.type == .iug { Text("IUG sin tomacorrientes derivados; cálculo sobre las bocas asignadas.").font(.caption) }
                Text("\(demand.ruleID) · \(demand.source)").font(.caption)
            case .specific(let demand):
                if let watts = demand.power.activePowerWatts, let multiplier = demand.power.wattsPerDeclaredUnit,
                   let factor = demand.power.powerFactorUsed {
                    Text("\(demand.power.declaredLoad.value.formatted()) \(demand.power.declaredLoad.unit.rawValue) × \(multiplier.formatted()) = \(watts.formatted()) W")
                    Text("S = \(watts.formatted()) W / fp \(factor.value.formatted()) = \(demand.power.apparentPower.displayValue)")
                } else {
                    Text("Potencia aparente declarada: \(demand.power.apparentPower.displayValue). No requiere fp.")
                }
                Text("Demanda considerada sin reducciones Ku/Ks. \(demand.power.criterionID)").font(.caption)
            }
        }
    }
}

struct ProjectDemandView: View {
    let result: ProjectDemandResult
    let hasUnassignedPoints: Bool

    var body: some View {
        Section("DPMS del proyecto") {
            Text("GE utilizado: \(result.grade.displayName) (preliminar)")
            powerRow("Base IUG/TUG/TUE", result.generalBase)
            LabeledContent("Coeficiente GE", value: result.coefficient.formatted())
            powerRow("DPMS GE", result.gradeDemand)
            powerRow("Cargas específicas resolubles", result.resolvedSpecificDemand)
            powerRow("DPMS total", result.total)
            if !result.pendingCircuitIDs.isEmpty {
                Text("Pendiente de datos/correcciones en \(result.pendingCircuitIDs.count) circuito(s).")
            }
            if case .failure = result.total {
                powerRow("Subtotal resoluble (incompleto)", result.resolvedSubtotal)
            }
            if hasUnassignedPoints {
                Text("La DPMS total queda pendiente: hay puntos sin asignar. El subtotal sólo considera los circuitos y bocas actualmente asignados.")
            }
            Text("DPMS GE = base × coeficiente GE. Total = DPMS GE + cargas específicas. El coeficiente GE no se aplica a ACU.").font(.caption)
            Text("Cálculo del proyecto modelado, sujeto a la validación de circuitos y reglas pendientes. Ku/Ks específicos quedan pendientes; no se verifica todavía el GE definitivo ni el suministro.").font(.caption)
            Text("\(result.coefficientRuleID) · \(result.coefficientSource)").font(.caption)
            Text("\(result.totalRuleID) · \(result.totalSource)").font(.caption)
        }
    }

    @ViewBuilder private func powerRow(_ title: String, _ value: Result<ApparentPower, DemandCalculationError>) -> some View {
        switch value {
        case .success(let power): LabeledContent(title, value: power.displayValue)
        case .failure(let error): LabeledContent(title, value: "Pendiente: \(error.displayMessage)")
        }
    }
}

extension ApparentPower {
    var displayValue: String { "\(voltAmperes.formatted()) VA" }
}

extension DemandCalculationError {
    var displayMessage: String {
        switch self {
        case .missingDeclaredLoad: "falta la carga declarada"
        case .missingPowerFactor: "falta el factor de potencia"
        case .invalidPointCount: "cantidad de bocas inválida"
        case .incompatibleAssignments: "corregí las asignaciones incompatibles o a circuitos inexistentes"
        case .unassignedPoints: "hay puntos sin asignar; completá la distribución"
        case .numericOverflow: "el valor excede el rango de cálculo"
        }
    }
}
