import Foundation
import Testing
@testable import InstaladorElectricistaCBA

@Suite("CALC-APPARENT-POWER-001 — dominio y conversión")
struct PowerTests {
    @Test(arguments: [1.0, 0.8, Double.leastNonzeroMagnitude])
    func validPowerFactor(value: Double) throws { #expect(try PowerFactor(value).value == value) }

    @Test(arguments: [0.0, -1, 1.01, Double.nan, Double.infinity, -Double.infinity])
    func invalidPowerFactor(value: Double) {
        #expect(throws: PowerFactor.ValidationError.self) { try PowerFactor(value) }
    }

    @Test(arguments: [-1.0, Double.nan, Double.infinity, -Double.infinity])
    func invalidApparentPower(value: Double) {
        #expect(throws: ApparentPower.ValidationError.self) { try ApparentPower(voltAmperes: value) }
    }

    @Test(arguments: [
        (1000.0, PowerUnit.voltAmpere, nil as Double?, 1000.0),
        (1000, .watt, 1, 1000), (1000, .watt, 0.8, 1250),
        (1, .kilowatt, 0.8, 1250), (1, .horsepower, 1, 746), (1, .horsepower, 0.8, 932.5)
    ])
    func conversion(value: Double, unit: PowerUnit, factor: Double?, expected: Double) throws {
        let original = try DeclaredLoad(value: value, unit: unit)
        let fp = try factor.map { try PowerFactor($0) }
        let result = try ApparentPowerCalculator.calculate(original, powerFactor: fp).get()
        #expect(abs(result.apparentPower.voltAmperes - expected) < 1e-9)
        #expect(result.declaredLoad == original)
        #expect(result.powerFactorUsed == fp)
        #expect(result.criterionID == "CALC-APPARENT-POWER-001")
        if unit == .horsepower {
            #expect(result.wattsPerDeclaredUnit == 746)
            #expect(result.activePowerWatts == 746)
        }
    }

    @Test(arguments: [PowerUnit.watt, .kilowatt, .horsepower], [0.0, 1000.0])
    func missingPowerFactor(unit: PowerUnit, value: Double) throws {
        let result = ApparentPowerCalculator.calculate(try DeclaredLoad(value: value, unit: unit))
        #expect(result == .failure(.missingPowerFactor))
    }

    @Test func vaIgnoresUnnecessaryFactor() throws {
        let result = try ApparentPowerCalculator.calculate(DeclaredLoad(value: 1000, unit: .voltAmpere), powerFactor: PowerFactor(0.8)).get()
        #expect(result.apparentPower.voltAmperes == 1000)
        #expect(result.powerFactorUsed == nil)
        #expect(result.activePowerWatts == nil)
    }

    @Test(arguments: PowerUnit.allCases)
    func zeroPowerIsValid(unit: PowerUnit) throws {
        let result = try ApparentPowerCalculator.calculate(DeclaredLoad(value: 0, unit: unit), powerFactor: PowerFactor(1)).get()
        #expect(result.apparentPower.voltAmperes == 0)
    }

    @Test(arguments: [PowerUnit.kilowatt, .horsepower])
    func conversionOverflow(unit: PowerUnit) throws {
        #expect(ApparentPowerCalculator.calculate(try DeclaredLoad(value: .greatestFiniteMagnitude, unit: unit),
                powerFactor: try PowerFactor(1)) == .failure(.numericOverflow))
    }

    @Test func divisionOverflow() throws {
        #expect(ApparentPowerCalculator.calculate(try DeclaredLoad(value: 1, unit: .watt),
                powerFactor: try PowerFactor(.leastNonzeroMagnitude)) == .failure(.numericOverflow))
    }
}

@Suite("RULE-DPMS-IUG-001 / RULE-DPMS-TUG-001 / RULE-DPMS-TUE-001")
struct CircuitDemandRuleTests {
    @Test(arguments: [(0, 0.0), (1, 40), (5, 200), (15, 600), (16, 640)])
    func iug(points: Int, expected: Double) throws {
        let result = try IUGDemandRule.evaluate(pointCount: points)
        #expect(result.ruleID == "RULE-DPMS-IUG-001")
        #expect(result.basePower.voltAmperes == Double(points) * 60)
        #expect(abs(result.minimumDemand.voltAmperes - expected) < 1e-9)
        #expect(abs(result.adoptedDemand.voltAmperes - expected) < 1e-9)
        #expect(result.knownDemand == nil)
    }

    @Test func negativeIUGCountRejected() {
        #expect(throws: DemandCalculationError.invalidPointCount) { try IUGDemandRule.evaluate(pointCount: -1) }
    }

    @Test func outletMinimums() throws {
        let tug = try TUGDemandRule.evaluate()
        let tue = try TUEDemandRule.evaluate()
        #expect(tug.ruleID == "RULE-DPMS-TUG-001"); #expect(tug.minimumDemand.voltAmperes == 2200)
        #expect(tue.ruleID == "RULE-DPMS-TUE-001"); #expect(tue.minimumDemand.voltAmperes == 3300)
    }

    @Test(arguments: [0.0, 600, 2200, 3300, 5000])
    func knownDemandCannotReduceMinimum(value: Double) throws {
        let known = try ApparentPower(voltAmperes: value)
        for (result, minimum) in [
            (try IUGDemandRule.evaluate(pointCount: 15, knownDemand: known), 600.0),
            (try TUGDemandRule.evaluate(knownDemand: known), 2200),
            (try TUEDemandRule.evaluate(knownDemand: known), 3300)
        ] {
            #expect(result.knownDemand == known)
            #expect(result.minimumDemand.voltAmperes == minimum)
            #expect(result.adoptedDemand.voltAmperes == max(minimum, value))
        }
    }
}

@Suite("RULE-SIMULTANEITY-001 / RULE-TOTAL-DEMAND-001 — integración")
struct DemandEngineTests {
    private func mediumProject() throws -> ElectricalProject {
        var project = ElectricalProject(id: UUID(), name: "Casa", coveredArea: try SquareMeters(100), semiCoveredArea: try SquareMeters(0))
        let sla = try SLACalculator.calculate(covered: project.coveredArea, semiCovered: project.semiCoveredArea)
        let grade = PreliminaryElectrificationRule.grade(for: sla)
        #expect(grade == .medium)
        project.circuitPlan.selection = .init(grade: grade, variant: .b)
        try CircuitEngine.generateMissing(in: &project.circuitPlan, grade: grade)
        var points = UtilizationPoints()
        try points.setCount(15, for: .generalLighting)
        try points.setCount(17, for: .generalUseOutlet)
        let room = Room(name: "Estar", type: .livingDiningStudy, area: try SquareMeters(100), projectedPoints: points)
        project.rooms = [room]
        try CircuitEngine.synchronize(&project.circuitPlan, rooms: project.rooms)
        let id = try #require(project.circuitPlan.circuits.first { $0.type == .iug }?.id)
        let tugIDs = project.circuitPlan.circuits.filter { $0.type == .tug }.map(\.id)
        for point in project.circuitPlan.points {
            let target = point.kind == .generalLighting ? id : tugIDs[point.ordinal <= 9 ? 0 : 1]
            try CircuitEngine.assign(pointID: point.id, to: target, in: &project.circuitPlan)
        }
        #expect(CircuitEngine.validate(project.circuitPlan, grade: grade).issues.isEmpty)
        #expect(MinimumCircuitsRule.evaluate(project.circuitPlan, grade: grade) == .conforming)
        return project
    }

    @Test(arguments: [(ElectrificationGrade.minimum, 1.0), (.medium, 0.8), (.elevated, 0.7), (.superior, 0.6)])
    func coefficients(grade: ElectrificationGrade, expected: Double) {
        #expect(GradeSimultaneityRule.coefficient(for: grade) == expected)
    }

    @Test func coherentMediumVariantBWithoutACU() throws {
        let project = try mediumProject()
        let result = DemandEngine.project(plan: project.circuitPlan, grade: .medium)
        #expect(result.grade == .medium); #expect(result.coefficient == 0.8)
        #expect(result.coefficientRuleID == "RULE-SIMULTANEITY-001")
        #expect(try result.generalBase.get().voltAmperes == 5000)
        #expect(try result.gradeDemand.get().voltAmperes == 4000)
        #expect(try result.resolvedSpecificDemand.get().voltAmperes == 0)
        #expect(try result.total.get().voltAmperes == 4000)
        #expect(result.specificLoads.isEmpty); #expect(result.pendingCircuitIDs.isEmpty)
        let iug = try #require(result.circuits.first { $0.type == .iug })
        #expect(iug.pointCount == 15)
        #expect(try iug.calculation.get().basePower.voltAmperes == 900)
        #expect(try iug.calculation.get().adoptedDemand.voltAmperes == 600)
    }

    @Test func multipleACUAreNotReducedByGECoefficient() throws {
        var project = try mediumProject()
        let vaID = try CircuitEngine.addCircuit(to: &project.circuitPlan, type: .acu, destination: "Equipo",
                                                load: DeclaredLoad(value: 1000, unit: .voltAmpere))
        let hpID = try CircuitEngine.addCircuit(to: &project.circuitPlan, type: .acu, destination: "Bomba",
                                                load: DeclaredLoad(value: 1, unit: .horsepower), powerFactor: PowerFactor(0.8))
        let result = DemandEngine.project(plan: project.circuitPlan, grade: .medium)
        #expect(result.specificLoads.map(\.id) == [vaID, hpID])
        #expect(try result.generalBase.get().voltAmperes == 5000)
        #expect(try result.gradeDemand.get().voltAmperes == 4000)
        #expect(abs(try result.resolvedSpecificDemand.get().voltAmperes - 1932.5) < 1e-9)
        #expect(abs(try result.total.get().voltAmperes - 5932.5) < 1e-9)
        #expect(result.specificLoads.allSatisfy { $0.pointCount == nil })
        for item in result.specificLoads {
            guard case .specific(let demand) = try item.calculation.get() else { Issue.record("Debe ser carga específica"); return }
            #expect(demand.consideredDemand == demand.power.apparentPower)
        }
    }

    @Test(arguments: [false, true])
    func missingACUDataDoesNotBecomeZero(hasLoad: Bool) throws {
        var project = try mediumProject()
        let load = hasLoad ? try DeclaredLoad(value: 1000, unit: .watt) : nil
        let pendingID = try CircuitEngine.addCircuit(to: &project.circuitPlan, type: .acu, load: load)
        try CircuitEngine.addCircuit(to: &project.circuitPlan, type: .acu, load: DeclaredLoad(value: 500, unit: .voltAmpere))
        let result = DemandEngine.project(plan: project.circuitPlan, grade: .medium)
        let expected: DemandCalculationError = hasLoad ? .missingPowerFactor : .missingDeclaredLoad
        #expect(result.specificLoads[0].calculation == .failure(expected))
        #expect(result.total == .failure(expected))
        #expect(result.pendingCircuitIDs == [pendingID])
        #expect(try result.gradeDemand.get().voltAmperes == 4000)
        #expect(try result.resolvedSpecificDemand.get().voltAmperes == 500)
        #expect(try result.resolvedSubtotal.get().voltAmperes == 4500)
    }

    @Test func additionalTUEUsesGEAndKnownDemand() throws {
        var project = try mediumProject()
        try CircuitEngine.addCircuit(to: &project.circuitPlan, type: .tue, knownDemand: ApparentPower(voltAmperes: 4000))
        let result = DemandEngine.project(plan: project.circuitPlan, grade: .medium)
        #expect(result.coefficient == 0.8)
        #expect(try result.generalBase.get().voltAmperes == 9000)
        #expect(try result.total.get().voltAmperes == 7200)
        #expect(result.specificLoads.isEmpty)
    }

    @Test(arguments: [UtilizationPointKind.generalLighting, .generalUseOutlet])
    func unassignedPointsPreventCompleteTotalWithoutMutatingPlan(kind: UtilizationPointKind) throws {
        var project = try mediumProject()
        let completePlan = project.circuitPlan
        #expect(try DemandEngine.project(plan: completePlan, grade: .medium).total.get().voltAmperes == 4000)
        let point = try #require(completePlan.points.first { $0.kind == kind })
        let circuitID = try #require(point.circuitID)
        try CircuitEngine.assign(pointID: point.id, to: nil, in: &project.circuitPlan)
        let incompletePlan = project.circuitPlan

        let result = DemandEngine.project(plan: project.circuitPlan, grade: .medium)
        #expect(result.total == .failure(.unassignedPoints))
        #expect(result.pendingCircuitIDs.isEmpty)
        #expect(try result.resolvedSubtotal.get().voltAmperes == (kind == .generalLighting ? 3968 : 4000))
        #expect(project.circuitPlan.points == incompletePlan.points)
        #expect(project.circuitPlan.circuits == incompletePlan.circuits)
        #expect(project.circuitPlan.selection == incompletePlan.selection)
        #expect(project.circuitPlan.freeChoiceCircuitID == incompletePlan.freeChoiceCircuitID)

        try CircuitEngine.assign(pointID: point.id, to: circuitID, in: &project.circuitPlan)
        #expect(try DemandEngine.project(plan: project.circuitPlan, grade: .medium).total.get().voltAmperes == 4000)
        #expect(project.circuitPlan.points == completePlan.points)
        #expect(project.circuitPlan.circuits == completePlan.circuits)
    }

    @Test func pointReferencingMissingCircuitPreventsCompleteTotal() throws {
        var project = try mediumProject()
        project.circuitPlan.points[0].circuitID = UUID()
        let originalPoints = project.circuitPlan.points
        let result = DemandEngine.project(plan: project.circuitPlan, grade: .medium)
        #expect(result.total == .failure(.incompatibleAssignments))
        #expect(project.circuitPlan.points == originalPoints)
    }

    @Test(arguments: [false, true])
    func incompatiblePointDoesNotBecomeLightingDemand(hasUnassignedPoint: Bool) throws {
        var project = try mediumProject()
        if hasUnassignedPoint {
            try CircuitEngine.assign(pointID: project.circuitPlan.points[0].id, to: nil, in: &project.circuitPlan)
        }
        let id = project.circuitPlan.circuits[0].id
        project.circuitPlan.points.append(.init(id: UUID(), roomID: UUID(), kind: .generalUseOutlet, ordinal: 1, circuitID: id))
        let result = DemandEngine.project(plan: project.circuitPlan, grade: .medium)
        #expect(result.circuits[0].calculation == .failure(.incompatibleAssignments))
        #expect(result.total == .failure(.incompatibleAssignments))
    }

    @Test func pendingModuleDoesNotAddBocasOrInventACULoad() throws {
        var project = try mediumProject()
        project.circuitPlan.points.append(.init(id: UUID(), roomID: UUID(), kind: .fixedApplianceModule, ordinal: 1))
        let originalPlan = project.circuitPlan
        let result = DemandEngine.project(plan: project.circuitPlan, grade: .medium)
        #expect(try result.total.get().voltAmperes == 4000)
        #expect(try result.generalBase.get().voltAmperes == 5000)
        #expect(result.specificLoads.isEmpty)
        #expect(project.circuitPlan.points == originalPlan.points)
        #expect(project.circuitPlan.circuits == originalPlan.circuits)
    }

    @Test func aggregateOverflowIsStructured() throws {
        let load = try DeclaredLoad(value: .greatestFiniteMagnitude, unit: .voltAmpere)
        let plan = CircuitPlan(circuits: [try Circuit(number: 1, type: .acu, declaredLoad: load),
                                          try Circuit(number: 2, type: .acu, declaredLoad: load)])
        let result = DemandEngine.project(plan: plan, grade: .minimum)
        #expect(result.pendingCircuitIDs.isEmpty)
        #expect(result.resolvedSpecificDemand == .failure(.numericOverflow))
        #expect(result.total == .failure(.numericOverflow))
    }

    @Test func emptyPlanHasNoInventedCircuits() throws {
        let result = DemandEngine.project(plan: CircuitPlan(), grade: .minimum)
        #expect(result.circuits.isEmpty)
        #expect(try result.total.get().voltAmperes == 0)
    }
}

@Suite("Feature 004 — edición de datos de carga")
@MainActor struct CircuitDemandFormTests {
    @Test func explicitFactorAndOriginalDeclarationSurviveEditing() throws {
        var circuit = try Circuit(number: 1, type: .acu, declaredLoad: DeclaredLoad(value: 1, unit: .horsepower))
        let id = circuit.id
        var form = CircuitDemandForm(circuit: circuit)
        #expect(form.powerFactor.isEmpty)
        form.powerFactor = "0,8"
        try form.apply(to: &circuit)
        #expect(circuit.id == id)
        #expect(circuit.declaredLoad == (try DeclaredLoad(value: 1, unit: .horsepower)))
        #expect(circuit.powerFactor == (try PowerFactor(0.8)))
        #expect(abs(try DemandEngine.circuit(circuit, points: []).calculation.get().adoptedDemand.voltAmperes - 932.5) < 1e-9)
        form.powerFactor = ""
        try form.apply(to: &circuit)
        #expect(DemandEngine.circuit(circuit, points: []).calculation == .failure(.missingPowerFactor))
    }

    @Test(arguments: ["0", "-1", "1.1", "nan", "inf", "abc"])
    func invalidFactorDoesNotOverwriteCircuit(input: String) throws {
        var circuit = try Circuit(number: 1, type: .acu, declaredLoad: DeclaredLoad(value: 1000, unit: .watt), powerFactor: PowerFactor(1))
        let original = circuit
        var form = CircuitDemandForm(circuit: circuit)
        form.powerFactor = input
        #expect(throws: CircuitDemandForm.InputError.self) { try form.apply(to: &circuit) }
        #expect(circuit == original)
    }

    @Test func vaDoesNotRequireOrApplyFactor() throws {
        var circuit = try Circuit(number: 1, type: .acu)
        var form = CircuitDemandForm(circuit: circuit)
        form.declaredValue = "1000"; form.unit = .voltAmpere; form.powerFactor = "incorrecto"
        try form.apply(to: &circuit)
        #expect(circuit.powerFactor == nil)
        #expect(try DemandEngine.circuit(circuit, points: []).calculation.get().adoptedDemand.voltAmperes == 1000)
        form.declaredValue = ""
        try form.apply(to: &circuit)
        #expect(DemandEngine.circuit(circuit, points: []).calculation == .failure(.missingDeclaredLoad))
    }

    @Test func knownDemandCanBeSetAndCleared() throws {
        var circuit = try Circuit(number: 1, type: .tug)
        var form = CircuitDemandForm(circuit: circuit)
        form.knownDemandVA = "3000,5"
        try form.apply(to: &circuit)
        #expect(try DemandEngine.circuit(circuit, points: []).calculation.get().adoptedDemand.voltAmperes == 3000.5)
        form.knownDemandVA = ""
        try form.apply(to: &circuit)
        #expect(circuit.knownDemand == nil)
        #expect(try DemandEngine.circuit(circuit, points: []).calculation.get().adoptedDemand.voltAmperes == 2200)
    }

    @Test func loadParametersStaySpecificToCircuitType() throws {
        #expect(throws: Circuit.ValidationError.loadOnNonACU) { try Circuit(number: 1, type: .iug, powerFactor: PowerFactor(1)) }
        #expect(throws: Circuit.ValidationError.knownDemandOnACU) { try Circuit(number: 1, type: .acu, knownDemand: ApparentPower(voltAmperes: 1)) }
    }

    @Test func projectRetainsPowerFactorAcrossRecalculation() throws {
        var form = ProjectForm()
        form.name = "Casa"; form.coveredArea = "100"; form.semiCoveredArea = "0"
        try CircuitEngine.addCircuit(to: &form.circuitPlan, type: .acu, load: DeclaredLoad(value: 1, unit: .kilowatt), powerFactor: PowerFactor(0.8))
        let project = try form.calculate().project
        #expect(project.circuitPlan.circuits[0].powerFactor == (try PowerFactor(0.8)))
        #expect(project.circuitPlan.circuits == (try form.calculate().project.circuitPlan.circuits))
    }
}
