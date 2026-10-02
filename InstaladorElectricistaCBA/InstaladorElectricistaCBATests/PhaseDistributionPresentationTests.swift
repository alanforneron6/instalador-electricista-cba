import Foundation
import Testing
@testable import InstaladorElectricistaCBA

@Suite("Feature 006 — presentación y estado compartido")
@MainActor struct PhaseDistributionPresentationTests {
    private func flow() throws -> ProjectFlowState {
        var flow = ProjectFlowState()
        flow.form.name = "Casa"; flow.form.coveredArea = "70"; flow.form.semiCoveredArea = "0"
        flow.path = [.rooms, .circuits, .demand, .supply]
        flow.form.circuitPlan.circuits = [try Circuit(number: 1, type: .acu, destination: "Aire",
            declaredLoad: DeclaredLoad(value: 8000, unit: .voltAmpere), powerFactor: PowerFactor(0.8))]
        return flow
    }

    private func assessment(_ flow: ProjectFlowState) throws -> PhaseDistributionAssessment {
        try #require(flow.phaseDistribution).get()
    }

    @Test(arguments: [(5000.0, SupplyNature.monophase, false), (8000.0, .monophase, true), (5000.0, .threePhase, true)])
    func sectionVisibilityFollowsSupply(va: Double, nature: SupplyNature, visible: Bool) throws {
        let circuit = try Circuit(number: 1, type: .acu, declaredLoad: DeclaredLoad(value: va, unit: .voltAmpere), supplyNature: nature)
        let result = try PhaseDistributionEngine.assess(plan: CircuitPlan(circuits: [circuit]), grade: .medium).get()
        #expect(PhaseDistributionPresentation.isVisible(result.project.supply.status) == visible)
    }

    @Test(arguments: [CircuitType.iug, .tug, .tue, .acu])
    func monophaseRowsOfferSelector(type: CircuitType) throws {
        #expect(PhaseDistributionPresentation.showsSelector(try Circuit(number: 1, type: type)))
    }

    @Test func trifasicReceiverHasNoSelectorAndOnePower() throws {
        let circuit = try Circuit(number: 1, type: .acu, declaredLoad: DeclaredLoad(value: 3197.14, unit: .voltAmpere), supplyNature: .threePhase)
        let result = try PhaseDistributionEngine.assess(plan: CircuitPlan(circuits: [circuit]), grade: .medium).get()
        #expect(!PhaseDistributionPresentation.showsSelector(circuit))
        #expect(result.circuitPowers.count == 1)
        #expect(result.circuitPowers[0].simultaneousDemand.voltAmperes == 3197.14)
        #expect(PhaseDistributionPresentation.phases(Set(Phase.allCases)) == "L1 · L2 · L3")
    }

    @Test func incompleteKeepsPowersButNoDefinitiveCurrent() throws {
        var flow = try flow()
        flow.form.circuitPlan.circuits.append(try Circuit(number: 2, type: .tug))
        let result = try assessment(flow)
        guard case .incomplete(let ids) = result.state else { Issue.record("Se esperaba incompleto"); return }
        #expect(ids.count == 2)
        #expect(PhaseDistributionPresentation.pendingCount(ids.count) == "2 circuitos monofásicos sin asignar.")
        #expect(PhaseDistributionPresentation.pendingCount(1) == "1 circuito monofásico sin asignar.")
        #expect(result.circuitPowers.map { $0.simultaneousDemand.voltAmperes } == [8000, 1760])
    }

    @Test(arguments: [1, 2, 3])
    func maximumLabelsAndCurrentsUseEngine(count: Int) throws {
        let circuits = try (0..<count).map { index in
            try Circuit(number: index + 1, type: .acu, declaredLoad: DeclaredLoad(value: 8000, unit: .voltAmpere), phaseAssignment: Phase.allCases[index])
        }
        let assessment = try PhaseDistributionEngine.assess(plan: CircuitPlan(circuits: circuits), grade: .medium).get()
        guard case .complete(let result) = assessment.state else { Issue.record("Se esperaba completo"); return }
        #expect(PhaseDistributionPresentation.maximumTitle(result) == (count == 1 ? "Fase más cargada" : "Fases más cargadas"))
        #expect(PhaseDistributionPresentation.phases(result.mostLoadedPhases) == ["L1", "L1 · L2", "L1 · L2 · L3"][count - 1])
        for phase in Phase.allCases {
            #expect(PhaseDistributionPresentation.current(phase, in: result) == SupplyPresentation.current(result.currents[phase]))
        }
        #expect(PhaseDistributionPresentation.sectional(result) == SupplyPresentation.current(result.sectionalIb))
        #expect(PhaseDistributionPresentation.sectional(result) == "36,36 A")
    }

    @Test func phaseChangesAndNavigationPreserveProjectAndDemand() throws {
        var flow = try flow()
        let original = flow.form.circuitPlan.circuits[0]
        let originalProjectID = try #require(flow.result?.project.id)
        let total = try assessment(flow).project.demand.total
        for phase in [Phase.l1, .l2, .l3, nil, .l2] {
            try flow.form.circuitPlan.circuits[0].updatePhaseAssignment(phase)
            #expect(flow.step == .supply)
            #expect(flow.result?.project.id == originalProjectID)
            #expect(try assessment(flow).project.demand.total == total)
            let circuit = flow.form.circuitPlan.circuits[0]
            #expect(circuit.id == original.id)
            #expect(circuit.destination == original.destination)
            #expect(circuit.declaredLoad == original.declaredLoad)
            #expect(circuit.powerFactor == original.powerFactor)
            #expect(circuit.supplyNature == original.supplyNature)
        }
        flow.goBack(); flow.advance()
        #expect(flow.step == .supply)
        #expect(flow.form.circuitPlan.circuits[0].phaseAssignment == .l2)
        flow.goBack(); flow.goBack()
        #expect(flow.step == .circuits)
        flow.advance(); flow.advance()
        #expect(flow.step == .supply)
        #expect(flow.form.circuitPlan.circuits[0].phaseAssignment == .l2)
        #expect(try assessment(flow).project.demand.total == total)
    }

    @Test func editingNatureChangesSelectorAndCompleteness() throws {
        var flow = try flow()
        try flow.form.circuitPlan.circuits[0].updatePhaseAssignment(.l2)
        let total = try assessment(flow).project.demand.total
        var editor = CircuitDemandForm(circuit: flow.form.circuitPlan.circuits[0])
        editor.supplyNature = .threePhase
        try editor.apply(to: &flow.form.circuitPlan.circuits[0])
        #expect(flow.form.circuitPlan.circuits[0].phaseAssignment == nil)
        #expect(!PhaseDistributionPresentation.showsSelector(flow.form.circuitPlan.circuits[0]))
        guard case .complete = try assessment(flow).state else { Issue.record("Trifásico no requiere fase"); return }
        editor = CircuitDemandForm(circuit: flow.form.circuitPlan.circuits[0])
        editor.supplyNature = .monophase
        try editor.apply(to: &flow.form.circuitPlan.circuits[0])
        #expect(flow.form.circuitPlan.circuits[0].phaseAssignment == nil)
        #expect(PhaseDistributionPresentation.showsSelector(flow.form.circuitPlan.circuits[0]))
        guard case .incomplete = try assessment(flow).state else { Issue.record("Debe pedir fase"); return }
        #expect(try assessment(flow).project.demand.total == total)
        #expect(flow.form.circuitPlan.circuits[0].powerFactor == (try PowerFactor(0.8)))
    }
}
