import Foundation
import Testing
@testable import InstaladorElectricistaCBA

@Suite("Feature 005 — magnitudes y perfil")
struct ProjectSupplyValueTests {
    @Test(arguments: [-1.0, Double.nan, Double.infinity, -Double.infinity])
    func invalidMagnitudes(value: Double) {
        #expect(throws: ActivePower.ValidationError.self) { try ActivePower(watts: value) }
        #expect(throws: ElectricCurrent.ValidationError.self) { try ElectricCurrent(amperes: value) }
    }

    @Test func profileAndAdoptedFactorAreExplicit() {
        let profile = CordobaSupplyProfile.current
        #expect(profile.phaseNeutralVolts == 220)
        #expect(profile.phasePhaseVolts == 380)
        #expect(profile.frequencyHertz == 50)
        #expect(profile.ruleID == "PROFILE-CORDOBA-SUPPLY-001")
        #expect(profile.source.contains("pendientes de cotejo"))
        #expect(ProjectPowerFactorRule.adoptedValue == 0.85)
        #expect(ProjectPowerFactorRule.source.contains("pendientes de cotejo"))
    }

    @Test(arguments: [(0.0, CategoryThreePowerScope.withinPowerScope),
                      (10_000.0, .withinPowerScope), (10_000.0.nextUp, .outsidePowerScope)])
    func categoryThreePowerBoundary(watts: Double, expected: CategoryThreePowerScope) throws {
        let result = try CategoryThreePowerScopeRule.evaluate(ActivePower(watts: watts))
        #expect(result.scope == expected)
        #expect(result.limit.watts == 10_000)
        #expect(result.ruleID == "RULE-CATEGORY-III-SCOPE-001")
        #expect(result.source.contains("pendientes de cotejo"))
    }

    @Test(arguments: [(0.0, 0.0), (5000.0, 22.727272727272727), (7040.0, 32.0)])
    func monophaseCurrentFromVA(va: Double, amperes: Double) throws {
        let result = try SupplyCurrentCalculator.monophase(apparentPower: ApparentPower(voltAmperes: va))
        #expect(abs(result.current.amperes - amperes) < 1e-12)
        #expect(result.voltageVolts == 220)
        #expect(result.basis == .monophaseHypothesis)
        #expect(result.criterionID == "CALC-SUPPLY-CURRENT-001")
    }

    @Test(arguments: [(0.0, 0.0), (6581.793068761734, 10.0)])
    func balancedReceiverIsNotSectionalCurrent(va: Double, amperes: Double) throws {
        let result = try SupplyCurrentCalculator.balancedThreePhaseReceiver(apparentPower: ApparentPower(voltAmperes: va))
        #expect(abs(result.current.amperes - amperes) < 1e-12)
        #expect(result.basis == .balancedThreePhaseReceiver)
        #expect(result.voltageVolts == 380)
        #expect(result.apparentPower.voltAmperes == va)
    }
}

@Suite("RULE-SUPPLY-001 / RULE-THREE-PHASE-LOAD-001 — motivos")
struct SupplyReasonTests {
    @Test(arguments: [(7000.0, 32.0, false, false), (7000.0.nextUp, 32.0, true, false),
                      (7000.0, 32.0.nextUp, false, true), (7000.0.nextUp, 32.0.nextUp, true, true)])
    func independentStrictThresholds(va: Double, amperes: Double, apparentReason: Bool, currentReason: Bool) throws {
        let reasons = SupplyRecommendationRule.reasons(apparentDemand: try ApparentPower(voltAmperes: va),
                                                     hypotheticalCurrent: try ElectricCurrent(amperes: amperes))
        #expect(reasons.contains(.apparentDemandAbove7kVA) == apparentReason)
        #expect(reasons.contains(.monophaseCurrentAbove32A) == currentReason)
        #expect(reasons.count == (apparentReason ? 1 : 0) + (currentReason ? 1 : 0))
    }

    @Test func repeatedReceiverDoesNotDuplicateReason() throws {
        let circuit = try Circuit(number: 1, type: .acu, supplyNature: .threePhase)
        #expect(ThreePhaseLoadRule.reasons(circuits: [circuit, circuit]) == [.threePhaseLoad(circuitID: circuit.id)])
    }
}

@Suite("Feature 005 — total completo y regresión Feature 004")
@MainActor struct ProjectSupplyEngineTests {
    private func plan(va: Double, nature: SupplyNature = .monophase) throws -> CircuitPlan {
        CircuitPlan(circuits: [try Circuit(number: 1, type: .acu, destination: "Equipo",
                                          declaredLoad: DeclaredLoad(value: va, unit: .voltAmpere), supplyNature: nature)])
    }

    private func mediumKitchen() throws -> ProjectForm {
        var form = ProjectForm()
        form.name = "Casa"; form.coveredArea = "70"; form.semiCoveredArea = "0"
        var counts = UtilizationPoints()
        try counts.setCount(2, for: .generalLighting)
        try counts.setCount(3, for: .generalUseOutlet)
        try counts.setCount(2, for: .fixedApplianceModule)
        form.rooms = [Room(name: "Cocina", type: .kitchen, projectedPoints: counts)]
        form.circuitPlan.selection = .init(grade: .medium, variant: .b)
        try CircuitEngine.generateMissing(in: &form.circuitPlan, grade: .medium)
        for point in form.circuitPlan.points {
            let type: CircuitType = point.kind == .generalLighting ? .iug : .tug
            let id = try #require(form.circuitPlan.circuits.first { $0.type == type }?.id)
            try CircuitEngine.assign(pointID: point.id, to: id, in: &form.circuitPlan)
        }
        return form
    }

    @Test(arguments: [(0.0, 0.0), (5000.0, 4250.0), (6781.14, 5763.969), (1.23456789, 1.0493827065)])
    func activePowerWithoutPrematureRounding(va: Double, expected: Double) throws {
        let result = try ProjectSupplyEngine.assess(plan: plan(va: va), grade: .minimum).get()
        #expect(result.power.apparentDemand.voltAmperes == va)
        #expect(result.power.adoptedPowerFactor.value == 0.85)
        #expect(abs(result.power.estimatedActivePower.watts - expected) < 1e-10)
        #expect(abs(result.power.estimatedActivePower.kilowatts - expected / 1000) < 1e-12)
        #expect(result.power.ruleID == "RULE-PROJECT-POWER-FACTOR-001")
    }

    @Test func monophaseIbUsesApparentNotActivePower() throws {
        let result = try ProjectSupplyEngine.assess(plan: plan(va: 5000), grade: .minimum).get()
        #expect(result.supply.status == .monophase)
        #expect(result.supply.reasons.isEmpty)
        guard case .determined(let current) = result.supply.sectionalCurrentState else {
            Issue.record("Ib monofásica debe ser calculable"); return
        }
        #expect(abs(current.amperes - 22.727272727272727) < 1e-12)
        #expect(current.amperes != result.power.estimatedActivePower.watts / 220)
    }

    @Test(arguments: [7000.0, 7000.0.nextUp, 7040.0, 7040.0.nextUp, 8000.0])
    func actualSupplyThresholds(va: Double) throws {
        let result = try ProjectSupplyEngine.assess(plan: plan(va: va), grade: .minimum).get().supply
        #expect(result.reasons.contains(.apparentDemandAbove7kVA) == (va > 7000))
        #expect(result.reasons.contains(.monophaseCurrentAbove32A) == (va > 7040))
        #expect(result.status == (va > 7000 ? .threePhaseRecommended : .monophase))
        if va > 7000 { #expect(result.sectionalCurrentState == .pendingPhaseDistribution) }
        #expect(result.recommendationSource == "AEA 90364-7-770:2017 · 770.8.3.3")
        #expect(result.apparentRecommendationThreshold.voltAmperes == 7000)
        #expect(result.currentRecommendationThreshold.amperes == 32)
    }

    @Test(arguments: [1000.0, 7001.0, 8000.0], [1, 2])
    func threePhaseLoadsOverrideButPreserveRecommendations(va: Double, count: Int) throws {
        var plan = CircuitPlan()
        for index in 0..<count {
            try CircuitEngine.addCircuit(to: &plan, type: .acu, destination: "Equipo \(index)",
                                         load: DeclaredLoad(value: va / Double(count), unit: .voltAmpere), supplyNature: .threePhase)
        }
        let result = try ProjectSupplyEngine.assess(plan: plan, grade: .minimum).get().supply
        var expected = Set(plan.circuits.map { SupplyReason.threePhaseLoad(circuitID: $0.id) })
        if va > 7000 { expected.insert(.apparentDemandAbove7kVA) }
        if va > 7040 { expected.insert(.monophaseCurrentAbove32A) }
        #expect(result.reasons == expected)
        #expect(result.status == .threePhaseRequired)
        #expect(result.sectionalCurrentState == .pendingPhaseDistribution)
        #expect(result.threePhaseLoadRuleID == "RULE-THREE-PHASE-LOAD-001")
        #expect(result.sectionalCurrentRuleID == "RULE-THREE-PHASE-CURRENT-001")
    }

    @Test func categoryExcessDoesNotInvalidateElectricalAssessment() throws {
        let result = try ProjectSupplyEngine.assess(plan: plan(va: 12000), grade: .minimum).get()
        #expect(result.power.estimatedActivePower.watts == 10200)
        #expect(result.power.categoryThreePowerScope.scope == .outsidePowerScope)
        #expect(result.supply.status == .threePhaseRecommended)
    }

    @Test func kitchenModulesAndIndividualFactorAreNotAppliedAgain() throws {
        var form = try mediumKitchen()
        let beforeACU = try ProjectSupplyEngine.assess(plan: form.circuitPlan, grade: .medium).get()
        #expect(try beforeACU.demand.total.get().voltAmperes == 3584)
        #expect(form.circuitPlan.points.count == 5)
        let id = try CircuitEngine.addCircuit(to: &form.circuitPlan, type: .acu, destination: "Aire acondicionado",
                                             load: DeclaredLoad(value: 3, unit: .horsepower), powerFactor: PowerFactor(0.7))
        let original = form.circuitPlan
        let feature004 = DemandEngine.project(plan: original, grade: .medium)
        let result = try ProjectSupplyEngine.assess(plan: original, grade: .medium).get()
        #expect(result.demand.total == feature004.total)
        #expect(result.demand.circuits == feature004.circuits)
        #expect(try result.demand.gradeDemand.get().voltAmperes == 3584)
        #expect(abs(result.power.apparentDemand.voltAmperes - 6781.142857142857) < 1e-9)
        #expect(abs(result.power.estimatedActivePower.watts - 5763.971428571429) < 1e-9)
        #expect(abs(result.supply.hypotheticalMonophaseCurrent.current.amperes - 30.82337662337662) < 1e-9)
        #expect(result.demand.specificLoads.count == 1)
        #expect(result.demand.specificLoads[0].circuitID == id)
        #expect(form.circuitPlan.circuits == original.circuits)
        #expect(form.circuitPlan.points == original.points)
        #expect(form.circuitPlan.selection == original.selection)
    }

    @Test(arguments: [DemandCalculationError.unassignedPoints, .missingDeclaredLoad, .missingPowerFactor, .incompatibleAssignments, .numericOverflow])
    func incompleteDemandHasNoDefinitiveAssessment(reason: DemandCalculationError) throws {
        var form = try mediumKitchen()
        switch reason {
        case .unassignedPoints:
            try CircuitEngine.assign(pointID: form.circuitPlan.points[0].id, to: nil, in: &form.circuitPlan)
        case .missingDeclaredLoad:
            try CircuitEngine.addCircuit(to: &form.circuitPlan, type: .acu, supplyNature: .threePhase)
        case .missingPowerFactor:
            try CircuitEngine.addCircuit(to: &form.circuitPlan, type: .acu, load: DeclaredLoad(value: 1000, unit: .watt), supplyNature: .threePhase)
        case .incompatibleAssignments:
            form.circuitPlan.points[0].circuitID = try #require(form.circuitPlan.circuits.first { $0.type == .tug }?.id)
        case .numericOverflow:
            for _ in 0..<2 {
                try CircuitEngine.addCircuit(to: &form.circuitPlan, type: .acu,
                                             load: DeclaredLoad(value: .greatestFiniteMagnitude, unit: .voltAmpere))
            }
        default: Issue.record("Caso no preparado"); return
        }
        let demand = DemandEngine.project(plan: form.circuitPlan, grade: .medium)
        #expect(demand.total == .failure(reason))
        guard case .failure(let error) = ProjectSupplyEngine.assess(plan: form.circuitPlan, grade: .medium) else {
            Issue.record("No se puede promover un subtotal a una evaluación definitiva"); return
        }
        #expect(error == .incompleteDemand(reason))
    }

    @Test func natureDefaultsAndEditingPreserveFeature004() throws {
        var form = try mediumKitchen()
        let id = try CircuitEngine.addCircuit(to: &form.circuitPlan, type: .acu, destination: "Equipo",
                                             load: DeclaredLoad(value: 3, unit: .horsepower), powerFactor: PowerFactor(0.7))
        let index = try #require(form.circuitPlan.circuits.firstIndex { $0.id == id })
        let before = form.circuitPlan.circuits[index]
        #expect(before.supplyNature == .monophase)
        let demand = DemandEngine.project(plan: form.circuitPlan, grade: .medium)
        try form.circuitPlan.circuits[index].updateSupplyNature(.threePhase)
        #expect(form.circuitPlan.circuits[index].id == id)
        #expect(form.circuitPlan.circuits[index].declaredLoad == before.declaredLoad)
        #expect(form.circuitPlan.circuits[index].powerFactor == before.powerFactor)
        #expect(DemandEngine.project(plan: form.circuitPlan, grade: .medium).circuits == demand.circuits)
        #expect(try ProjectSupplyEngine.assess(plan: form.circuitPlan, grade: .medium).get().supply.status == .threePhaseRequired)
        var editor = CircuitDemandForm(circuit: form.circuitPlan.circuits[index])
        editor.declaredValue = "2"
        try editor.apply(to: &form.circuitPlan.circuits[index])
        #expect(form.circuitPlan.circuits.count == 4)
        #expect(form.circuitPlan.circuits[index].id == id)
        #expect(form.circuitPlan.circuits[index].supplyNature == .threePhase)
        #expect(form.circuitPlan.circuits[index].declaredLoad == (try DeclaredLoad(value: 2, unit: .horsepower)))
        #expect(form.circuitPlan.circuits[index].powerFactor == before.powerFactor)
        let after = try ProjectSupplyEngine.assess(plan: form.circuitPlan, grade: .medium).get()
        #expect(abs(after.power.apparentDemand.voltAmperes - 5715.428571428572) < 1e-9)
    }

    @Test func supplyNatureRoundTripPreservesACUIdentityAndLoad() throws {
        let load = try DeclaredLoad(value: 3, unit: .horsepower)
        let factor = try PowerFactor(0.7)
        var circuit = try Circuit(number: 4, type: .acu, destination: "Aire acondicionado",
                                  declaredLoad: load, powerFactor: factor)
        let originalID = circuit.id
        #expect(circuit.supplyNature == .monophase)

        try circuit.updateSupplyNature(.threePhase)
        #expect(circuit.supplyNature == .threePhase)
        try circuit.updateSupplyNature(.monophase)

        #expect(circuit.id == originalID)
        #expect(circuit.number == 4)
        #expect(circuit.type == .acu)
        #expect(circuit.destination == "Aire acondicionado")
        #expect(circuit.declaredLoad == load)
        #expect(circuit.powerFactor == factor)
        #expect(circuit.supplyNature == .monophase)
    }

    @Test(arguments: [CircuitType.iug, .tug, .tue])
    func supplyNatureBelongsOnlyToACU(type: CircuitType) throws {
        var circuit = try Circuit(number: 1, type: type)
        #expect(circuit.supplyNature == nil)
        #expect(throws: Circuit.ValidationError.supplyNatureOnNonACU) { try circuit.updateSupplyNature(.threePhase) }
        #expect(circuit.supplyNature == nil)
        #expect(throws: Circuit.ValidationError.supplyNatureOnNonACU) { try Circuit(number: 1, type: type, supplyNature: .monophase) }
    }
}
