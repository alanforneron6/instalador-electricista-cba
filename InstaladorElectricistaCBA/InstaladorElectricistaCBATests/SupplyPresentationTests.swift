import Foundation
import Testing
@testable import InstaladorElectricistaCBA

@Suite("Feature 005 — presentación de alimentación")
@MainActor struct SupplyPresentationTests {
    private func assessment(va: Double = 8000, nature: SupplyNature = .monophase) throws -> ProjectElectricalAssessment {
        let circuit = try Circuit(number: 1, type: .acu, destination: "Motor bomba",
                                  declaredLoad: DeclaredLoad(value: va, unit: .voltAmpere), supplyNature: nature)
        return try ProjectSupplyEngine.assess(plan: CircuitPlan(circuits: [circuit]), grade: .minimum).get()
    }

    @Test(arguments: [(SupplyStatus.monophase, "Monofásico según criterio evaluado"),
                      (.threePhaseRecommended, "Trifásico recomendado"),
                      (.threePhaseRequired, "Alimentación trifásica requerida")])
    func humanStatus(status: SupplyStatus, title: String) {
        #expect(status.displayTitle == title)
        #expect(status.tone == (status == .monophase ? .complete : .pending))
    }

    @Test func humanReasonsAndCurrentLabelsStaySeparate() throws {
        let supply = try assessment().supply
        #expect(SupplyPresentation.reason(.apparentDemandAbove7kVA, assessment: supply) == "La demanda aparente supera 7 kVA.")
        #expect(SupplyPresentation.reason(.monophaseCurrentAbove32A, assessment: supply) == "La corriente resultante en una hipótesis monofásica supera 32 A.")
        #expect(SupplyPresentation.reason(.threePhaseLoad(circuitID: UUID()), assessment: supply) == "El proyecto contiene uno o más receptores trifásicos.")
        let sectional = SupplyPresentation.sectional(supply.sectionalCurrentState)
        #expect(sectional.title == "Corriente del circuito seccional")
        #expect(sectional.value == "Pendiente de distribución de fases")
        #expect(SupplyPresentation.hypotheticalTitle == "Corriente si se alimentara en monofásico")
        #expect(SupplyPresentation.current(supply.hypotheticalMonophaseCurrent.current) == "36,36 A")
        let mono = try assessment(va: 5000).supply
        #expect(SupplyPresentation.sectional(mono.sectionalCurrentState).title == "Corriente de proyecto")
        #expect(SupplyPresentation.sectional(mono.sectionalCurrentState).value == "22,73 A")
    }

    @Test func powerFormattingAndCategoryScope() throws {
        let result = try assessment()
        #expect(SupplyPresentation.apparent(result.power.apparentDemand) == "8 kVA")
        #expect(SupplyPresentation.active(result.power.estimatedActivePower) == "6,8 kW")
        #expect(SupplyPresentation.active(result.power.categoryThreePowerScope.limit) == "10 kW")
        #expect(CategoryThreePowerScope.withinPowerScope.displayTitle == "Dentro del alcance de potencia Cat. III")
        #expect(CategoryThreePowerScope.outsidePowerScope.displayTitle == "Fuera del alcance de potencia Cat. III")
        #expect(CategoryThreePowerScope.outsidePowerScope.tone == .invalid)
    }

    @Test func receiverNamesComeFromReasonIDs() throws {
        let tri = try Circuit(number: 1, type: .acu, destination: "Motor bomba", declaredLoad: DeclaredLoad(value: 1000, unit: .voltAmpere), supplyNature: .threePhase)
        let mono = try Circuit(number: 2, type: .acu, declaredLoad: DeclaredLoad(value: 1000, unit: .voltAmpere))
        let supply = try ProjectSupplyEngine.assess(plan: CircuitPlan(circuits: [mono, tri]), grade: .minimum).get().supply
        let receivers = SupplyPresentation.receivers(assessment: supply, circuits: [mono, tri])
        #expect(receivers.map(\.id) == [tri.id])
        #expect(SupplyPresentation.receiverName(tri) == "Motor bomba")
        #expect(SupplyPresentation.receiverName(mono) == "C2 · ACU")
    }

    @Test func formNatureRoundTripPreservesACUData() throws {
        var circuit = try Circuit(number: 4, type: .acu, destination: "Bomba", declaredLoad: DeclaredLoad(value: 3, unit: .horsepower), powerFactor: PowerFactor(0.7))
        let original = circuit
        for nature in [SupplyNature.threePhase, .monophase] {
            var form = CircuitDemandForm(circuit: circuit)
            #expect(form.supportsSupplyNature)
            form.supplyNature = nature
            try form.apply(to: &circuit)
            #expect(circuit.supplyNature == nature)
            #expect(circuit.id == original.id)
            #expect(circuit.number == original.number)
            #expect(circuit.type == original.type)
            #expect(circuit.destination == original.destination)
            #expect(circuit.declaredLoad == original.declaredLoad)
            #expect(circuit.powerFactor == original.powerFactor)
        }
    }

    @Test(arguments: [CircuitType.iug, .tug, .tue])
    func nonACUFormDoesNotApplyNature(type: CircuitType) throws {
        var circuit = try Circuit(number: 1, type: type)
        var form = CircuitDemandForm(circuit: circuit)
        #expect(!form.supportsSupplyNature)
        form.supplyNature = .threePhase
        try form.apply(to: &circuit)
        #expect(circuit.supplyNature == nil)
    }

    @Test func incompleteDemandCannotNavigateToSupply() throws {
        var flow = ProjectFlowState()
        flow.form.name = "Casa"; flow.form.coveredArea = "70"; flow.form.semiCoveredArea = "0"
        flow.path = [.rooms, .circuits, .demand]
        #expect(!flow.canContinueToSupply)
        let id = try CircuitEngine.addCircuit(to: &flow.form.circuitPlan, type: .acu)
        flow.advance()
        #expect(flow.step == .demand)
        #expect(flow.supplyAssessment == nil)
        try flow.form.circuitPlan.circuits[0].updateDemand(declaredLoad: DeclaredLoad(value: 8000, unit: .voltAmpere), powerFactor: nil, knownDemand: nil)
        #expect(flow.canContinueToSupply)
        flow.advance()
        #expect(flow.step == .supply)
        #expect(flow.step.indicator == "Paso 5 de 5 · Alimentación")
        flow.goBack()
        #expect(flow.step == .demand)
        #expect(flow.form.circuitPlan.circuits[0].id == id)
    }
}
