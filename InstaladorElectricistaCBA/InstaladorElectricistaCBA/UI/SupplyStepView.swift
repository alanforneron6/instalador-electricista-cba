import SwiftUI

struct SupplyStepView: View {
    let distribution: PhaseDistributionAssessment
    @Binding var circuits: [Circuit]
    private var assessment: ProjectElectricalAssessment { distribution.project }

    var body: some View {
        powerSection
        categorySection
        supplySection
        if PhaseDistributionPresentation.isVisible(assessment.supply.status) {
            PhaseDistributionView(assessment: distribution, circuits: $circuits)
        }
    }

    private var powerSection: some View {
        Section("Potencia del proyecto") {
            LabeledContent("Demanda máxima simultánea", value: SupplyPresentation.apparent(assessment.power.apparentDemand))
            LabeledContent("Factor de potencia adoptado", value: PowerPresentation.number(assessment.power.adoptedPowerFactor.value))
            Text("Criterio aproximado adoptado para el proyecto.").font(.footnote).foregroundStyle(.secondary)
            LabeledContent("Potencia activa estimada", value: SupplyPresentation.active(assessment.power.estimatedActivePower))
            RegulatoryDisclosure {
                Text("Potencia activa estimada = demanda aparente × factor de potencia adoptado.")
                Text("Criterio aproximado de la Guía AEA 770. Edición y referencia puntual pendientes de verificación.")
                Text("No reemplaza el factor de potencia individual de los equipos.")
                Text("Referencia interna: \(assessment.power.ruleID)").foregroundStyle(.secondary)
            }
        }
    }

    private var categorySection: some View {
        let category = assessment.power.categoryThreePowerScope
        return Section("Alcance de potencia Cat. III") {
            StatusMessage(text: category.scope.displayTitle, tone: category.scope.tone)
            LabeledContent("Potencia calculada", value: SupplyPresentation.active(assessment.power.estimatedActivePower))
            LabeledContent("Límite", value: SupplyPresentation.active(category.limit))
            Text("Esta evaluación verifica únicamente el límite de potencia.").font(.footnote)
            if category.scope == .outsidePowerScope {
                Text("El proyecto supera el límite de potencia considerado para Categoría III.").font(.footnote)
            }
            RegulatoryDisclosure {
                Text("Límite de potencia adoptado para Categoría III en Córdoba. La referencia oficial de ERSeP continúa pendiente de verificación.")
                Text("No certifica las demás incumbencias ni determina la validez eléctrica de la instalación.")
                Text("Referencia interna: \(category.ruleID)").foregroundStyle(.secondary)
            }
        }
    }

    private var supplySection: some View {
        let supply = assessment.supply
        let current = SupplyPresentation.sectional(supply.sectionalCurrentState)
        return Section("Sistema de alimentación") {
            StatusMessage(text: supply.status.displayTitle, tone: supply.status.tone)
            LabeledContent("Demanda aparente", value: SupplyPresentation.apparent(supply.apparentDemand))
            if supply.status == .threePhaseRequired {
                Text("Requerimiento").font(.headline)
                Text("El proyecto contiene uno o más receptores trifásicos.")
                Text("Receptores trifásicos:").font(.subheadline)
                ForEach(SupplyPresentation.receivers(assessment: supply, circuits: circuits)) { circuit in
                    Label(SupplyPresentation.receiverName(circuit), systemImage: "bolt.fill")
                }
            }
            if supply.status == .monophase {
                Text("No se superan los criterios evaluados para recomendar alimentación trifásica.").font(.footnote)
            } else {
                if supply.reasons.contains(.apparentDemandAbove7kVA) || supply.reasons.contains(.monophaseCurrentAbove32A) {
                    Text("Recomendaciones AEA").font(.headline)
                    ForEach([SupplyReason.apparentDemandAbove7kVA, .monophaseCurrentAbove32A], id: \.self) { reason in
                        if supply.reasons.contains(reason) {
                            StatusMessage(text: SupplyPresentation.reason(reason, assessment: supply), tone: .pending)
                        }
                    }
                }
                LabeledContent(SupplyPresentation.hypotheticalTitle,
                               value: SupplyPresentation.current(supply.hypotheticalMonophaseCurrent.current))
            }
            if case .determined = supply.sectionalCurrentState {
                Text(current.title).font(.headline)
                Text(current.value).font(.title2.bold())
            }
            Text("Las condiciones particulares de conexión deben verificarse con la distribuidora correspondiente.")
                .font(.footnote).foregroundStyle(.secondary)
            RegulatoryDisclosure {
                Text(supply.recommendationSource)
                Text("Los umbrales son recomendaciones; el receptor trifásico determina una necesidad eléctrica independiente.")
                Text(PhaseSectionalCurrentRule.source)
                Text("Perfil adoptado: \(PowerPresentation.number(supply.profile.phaseNeutralVolts)) V fase-neutro; \(PowerPresentation.number(supply.profile.phasePhaseVolts)) V fase-fase; \(PowerPresentation.number(supply.profile.frequencyHertz)) Hz. Referencia puntual pendiente de verificación.")
                Text("La corriente monofásica usa la demanda aparente y la tensión fase-neutro, sin aplicar nuevamente el factor de potencia.")
                Text("Referencias internas: \(supply.recommendationRuleID) · \(supply.threePhaseLoadRuleID) · \(supply.sectionalCurrentRuleID)").foregroundStyle(.secondary)
            }
        }
    }
}
