import Foundation
import Testing
@testable import InstaladorElectricistaCBA

@Suite("Feature 006 — identidad y asignación de fase")
@MainActor struct PhaseAssignmentTests {
    @Test(arguments: [CircuitType.iug, .tug, .tue, .acu], [PowerUnit.voltAmpere, .horsepower])
    func phaseRoundTripPreservesAllOtherData(type: CircuitType, unit: PowerUnit) throws {
        var circuit = try Circuit(number: 7, type: type, destination: "Destino",
            declaredLoad: type == .acu ? DeclaredLoad(value: 3, unit: unit) : nil,
            powerFactor: type == .acu ? PowerFactor(0.8) : nil,
            knownDemand: type == .acu ? nil : ApparentPower(voltAmperes: 5000))
        let original = circuit
        for phase in [Phase.l1, .l2, .l3, nil, .l1] {
            try circuit.updatePhaseAssignment(phase)
            #expect(circuit.phaseAssignment == phase)
            var expected = original
            try expected.updatePhaseAssignment(phase)
            #expect(circuit.id == original.id)
            #expect(circuit.number == original.number)
            #expect(circuit.type == original.type)
            #expect(circuit.destination == original.destination)
            #expect(circuit.declaredLoad == original.declaredLoad)
            #expect(circuit.powerFactor == original.powerFactor)
            #expect(circuit.supplyNature == original.supplyNature)
            #expect(circuit.knownDemand == original.knownDemand)
            #expect(circuit == expected)
        }
        // El editor existente tampoco borra la asignación al reconstruir datos de carga.
        let form = CircuitDemandForm(circuit: circuit)
        try form.apply(to: &circuit)
        #expect(circuit.phaseAssignment == .l1)
        #expect(circuit.powerFactor == original.powerFactor)
    }

    @Test func natureChangesDiscardPhaseWithoutRestoringIt() throws {
        var circuit = try Circuit(number: 1, type: .acu, declaredLoad: DeclaredLoad(value: 5000, unit: .voltAmpere),
                                  powerFactor: PowerFactor(0.8), phaseAssignment: .l2)
        let original = circuit
        try circuit.updateSupplyNature(.monophase)
        #expect(circuit.phaseAssignment == .l2)
        try circuit.updateSupplyNature(.threePhase)
        #expect(circuit.phaseAssignment == nil)
        #expect(throws: Circuit.ValidationError.phaseOnThreePhaseLoad) { try circuit.updatePhaseAssignment(.l1) }
        #expect(circuit.phaseAssignment == nil)
        try circuit.updatePhaseAssignment(nil)
        try circuit.updateSupplyNature(.monophase)
        #expect(circuit.phaseAssignment == nil)
        #expect(circuit.id == original.id)
        #expect(circuit.declaredLoad == original.declaredLoad)
        #expect(circuit.powerFactor == original.powerFactor)
        #expect(throws: Circuit.ValidationError.phaseOnThreePhaseLoad) {
            try Circuit(number: 1, type: .acu, supplyNature: .threePhase, phaseAssignment: .l1)
        }
    }
}

@Suite("Feature 006 — corrientes por fase sin alterar DPMS")
struct PhaseDistributionTests {
    private func referencePlan() throws -> CircuitPlan {
        let iug = try Circuit(number: 1, type: .iug, phaseAssignment: .l1)
        let tug1 = try Circuit(number: 2, type: .tug, phaseAssignment: .l2)
        let tug2 = try Circuit(number: 3, type: .tug, phaseAssignment: .l3)
        let acu = try Circuit(number: 4, type: .acu, destination: "Motor",
            declaredLoad: DeclaredLoad(value: 3197.14, unit: .voltAmpere), supplyNature: .threePhase)
        let room = UUID()
        return CircuitPlan(selection: .init(grade: .medium, variant: .b), circuits: [iug, tug1, tug2, acu], points: [
            .init(id: UUID(), roomID: room, kind: .generalLighting, ordinal: 1, circuitID: iug.id),
            .init(id: UUID(), roomID: room, kind: .generalLighting, ordinal: 2, circuitID: iug.id)
        ])
    }

    private func complete(_ plan: CircuitPlan, grade: ElectrificationGrade = .medium) throws -> CompletePhaseDistribution {
        let result = try PhaseDistributionEngine.assess(plan: plan, grade: grade).get()
        guard case .complete(let distribution) = result.state else {
            throw TestError.expectedComplete
        }
        return distribution
    }
    private enum TestError: Error { case expectedComplete }

    @Test func referenceExampleConservesDemandAndTwoMaximumPhases() throws {
        let plan = try referencePlan()
        let previous = DemandEngine.project(plan: plan, grade: .medium)
        let result = try PhaseDistributionEngine.assess(plan: plan, grade: .medium).get()
        let distribution = try complete(plan)
        let receiver = 3197.14 / (sqrt(3) * 380)
        #expect(abs(distribution.currents.currentL1.amperes - (64 / 220 + receiver)) < 1e-12)
        #expect(abs(distribution.currents.currentL2.amperes - (8 + receiver)) < 1e-12)
        #expect(abs(distribution.currents.currentL3.amperes - (8 + receiver)) < 1e-12)
        #expect(distribution.mostLoadedPhases == [.l2, .l3])
        #expect(abs(distribution.sectionalIb.amperes - (8 + receiver)) < 1e-12)
        #expect(distribution.contributions.map { $0.simultaneousDemand.voltAmperes } == [64, 1760, 1760, 3197.14])
        #expect(distribution.contributions.map(\.circuitID) == plan.circuits.map(\.id))
        #expect(distribution.contributions.last?.phases == Set(Phase.allCases))
        #expect(distribution.sectionalRuleID == "RULE-THREE-PHASE-CURRENT-001")
        #expect(distribution.sectionalSource.contains("770.8.3.1, Nota 1"))
        #expect(result.project.demand.total == previous.total)
        #expect(result.project.demand.circuits == previous.circuits)
        #expect(abs(distribution.contributions.reduce(0) { $0 + $1.simultaneousDemand.voltAmperes } - (try previous.total.get().voltAmperes)) < 1e-9)
        #expect(plan.circuits.map(\.phaseAssignment) == [.l1, .l2, .l3, nil])
    }

    @Test func onlyMonophaseCircuitsCanBeDistributedWithoutBalancingRestriction() throws {
        let plan = CircuitPlan(circuits: [
            try Circuit(number: 1, type: .iug, knownDemand: ApparentPower(voltAmperes: 5000), phaseAssignment: .l1),
            try Circuit(number: 2, type: .tug, phaseAssignment: .l1),
            try Circuit(number: 3, type: .tue, phaseAssignment: .l1)
        ])
        let result = try complete(plan, grade: .minimum)
        #expect(abs(result.currents.currentL1.amperes - 10500.0 / 220) < 1e-12)
        #expect(result.currents.currentL2.amperes == 0)
        #expect(result.currents.currentL3.amperes == 0)
        #expect(result.mostLoadedPhases == [.l1])
    }

    @Test func balancedReceiverNeedsNoPhaseAndHasThreeMaxima() throws {
        let circuit = try Circuit(number: 1, type: .acu, declaredLoad: DeclaredLoad(value: 3197.14, unit: .voltAmpere), supplyNature: .threePhase)
        let result = try complete(CircuitPlan(circuits: [circuit]))
        #expect(result.currents.currentL1 == result.currents.currentL2)
        #expect(result.currents.currentL2 == result.currents.currentL3)
        #expect(result.mostLoadedPhases == Set(Phase.allCases))
        #expect(result.contributions.count == 1)
        #expect(result.contributions[0].simultaneousDemand.voltAmperes == 3197.14)
    }

    @Test(arguments: [CircuitType.iug, .tug, .tue, .acu])
    func missingMonophaseAssignmentIsIncomplete(type: CircuitType) throws {
        var plan = try referencePlan()
        let missing = try Circuit(number: 5, type: type,
                                  declaredLoad: type == .acu ? DeclaredLoad(value: 1000, unit: .voltAmpere) : nil)
        plan.circuits.append(missing)
        try plan.circuits[1].updatePhaseAssignment(nil)
        let result = try PhaseDistributionEngine.assess(plan: plan, grade: .medium).get()
        guard case .incomplete(let ids) = result.state else { Issue.record("No se permite Ib parcial"); return }
        #expect(ids == [missing.id, plan.circuits[1].id])
    }

    @Test func monoTriMonoChangesPhaseRequirement() throws {
        var circuit = try Circuit(number: 1, type: .acu, declaredLoad: DeclaredLoad(value: 8000, unit: .voltAmpere), phaseAssignment: .l1)
        #expect(try complete(CircuitPlan(circuits: [circuit])).mostLoadedPhases == [.l1])
        try circuit.updateSupplyNature(.threePhase)
        #expect(circuit.phaseAssignment == nil)
        #expect(try complete(CircuitPlan(circuits: [circuit])).mostLoadedPhases == Set(Phase.allCases))
        try circuit.updateSupplyNature(.monophase)
        let result = try PhaseDistributionEngine.assess(plan: CircuitPlan(circuits: [circuit]), grade: .medium).get()
        guard case .incomplete(let ids) = result.state else { Issue.record("Debe pedir fase nuevamente"); return }
        #expect(ids == [circuit.id])
    }

    @Test(arguments: [PowerUnit.voltAmpere, .watt, .kilowatt, .horsepower], [SupplyNature.monophase, .threePhase])
    func specificLoadUsesExistingDemandWithoutAnySecondFactor(unit: PowerUnit, nature: SupplyNature) throws {
        var plan = try referencePlan()
        plan.circuits[3] = try Circuit(number: 4, type: .acu, declaredLoad: DeclaredLoad(value: 3, unit: unit),
            powerFactor: PowerFactor(0.7), supplyNature: nature, phaseAssignment: nature == .monophase ? .l1 : nil)
        // Mantener análisis trifásico incluso con una carga específica pequeña monofásica.
        try plan.circuits[2].updateDemand(declaredLoad: nil, powerFactor: nil, knownDemand: ApparentPower(voltAmperes: 9000))
        let before = DemandEngine.project(plan: plan, grade: .medium)
        let result = try complete(plan)
        let contribution = try #require(result.contributions.last)
        #expect(contribution.appliedCoefficient == 1)
        #expect(contribution.simultaneousDemand == (try before.specificLoads[0].calculation.get().adoptedDemand))
        #expect(abs(result.contributions.reduce(0) { $0 + $1.simultaneousDemand.voltAmperes } - (try before.total.get().voltAmperes)) < 1e-9)
        let expected = nature == .monophase
            ? try SupplyCurrentCalculator.monophase(apparentPower: contribution.simultaneousDemand)
            : try SupplyCurrentCalculator.balancedThreePhaseReceiver(apparentPower: contribution.simultaneousDemand)
        #expect(contribution.currentCalculation.current == expected.current)
    }

    @Test func monophaseProjectDoesNotRequirePhaseAssignment() throws {
        let plan = CircuitPlan(circuits: [try Circuit(number: 1, type: .acu, declaredLoad: DeclaredLoad(value: 5000, unit: .voltAmpere))])
        let previous = try ProjectSupplyEngine.assess(plan: plan, grade: .medium).get()
        let result = try PhaseDistributionEngine.assess(plan: plan, grade: .medium).get()
        guard case .monophase(let current) = result.state else { Issue.record("No exigir fase en monofásico"); return }
        #expect(previous.supply.sectionalCurrentState == .determined(current))
        #expect(result.project.demand.total == previous.demand.total)
    }

    @Test(arguments: [false, true])
    func incompleteDemandNeverBecomesPhaseCurrent(missingFactor: Bool) throws {
        let circuit = try Circuit(number: 1, type: .acu,
            declaredLoad: missingFactor ? DeclaredLoad(value: 1, unit: .watt) : nil, supplyNature: .threePhase)
        let result = PhaseDistributionEngine.assess(plan: CircuitPlan(circuits: [circuit]), grade: .medium)
        guard case .failure(let error) = result else { Issue.record("Demanda incompleta"); return }
        #expect(error == .projectAssessment(.incompleteDemand(missingFactor ? .missingPowerFactor : .missingDeclaredLoad)))
    }

    @Test func unassignedBocaPreventsDistributionEvenWithPhases() throws {
        var plan = try referencePlan()
        plan.points[0].circuitID = nil
        guard case .failure(let error) = PhaseDistributionEngine.assess(plan: plan, grade: .medium) else {
            Issue.record("Una fase asignada no resuelve una boca sin circuito"); return
        }
        #expect(error == .projectAssessment(.incompleteDemand(.unassignedPoints)))
    }

    @Test func zeroBalancedReceiverKeepsThreeMaximumPhases() throws {
        let circuit = try Circuit(number: 1, type: .acu, declaredLoad: DeclaredLoad(value: 0, unit: .voltAmpere), supplyNature: .threePhase)
        let result = try complete(CircuitPlan(circuits: [circuit]))
        #expect(result.sectionalIb.amperes == 0)
        #expect(result.mostLoadedPhases == Set(Phase.allCases))
    }

    @Test func threeEqualMonophaseCurrentsKeepAllMaxima() throws {
        let circuits = try Phase.allCases.enumerated().map { index, phase in
            try Circuit(number: index + 1, type: .tue, phaseAssignment: phase)
        }
        let result = try complete(CircuitPlan(circuits: circuits), grade: .minimum)
        #expect(result.mostLoadedPhases == Set(Phase.allCases))
        #expect(result.sectionalIb.amperes == 15)
    }
}
