import Foundation
import Testing
@testable import InstaladorElectricistaCBA

@Suite("UX-001.1 — ajustes de presentación")
@MainActor struct UXRefinementTests {
    @Test(arguments: ["Flia Alvarez", "Casa de Juan", "Vivienda 1", "Proyecto López", "Casa - ampliación", "  Flia. Álvarez (1)\n"])
    func humanNamesAllowContinuing(name: String) throws {
        var flow = ProjectFlowState()
        flow.form.name = name; flow.form.coveredArea = "60"; flow.form.semiCoveredArea = "10"
        #expect(flow.canContinue)
        let original = try #require(flow.result)
        #expect(original.project.name == name.trimmingCharacters(in: .whitespacesAndNewlines))
        // Editar la etiqueta después de calcular no invalida los datos eléctricos.
        flow.form.name = "Flia Alvarez - ampliación"
        #expect(flow.canContinue)
        #expect(flow.result?.project.id == original.project.id)
        #expect(flow.result?.sla == original.sla)
        #expect(flow.result?.grade == original.grade)
        flow.advance()
        #expect(flow.step == .rooms)
    }

    @Test(arguments: ["", "   ", " \n\t "])
    func emptyNamesStillBlockContinuing(name: String) {
        var flow = ProjectFlowState()
        flow.form.name = name; flow.form.coveredArea = "60"; flow.form.semiCoveredArea = "0"
        #expect(!flow.canContinue)
        #expect(flow.errorMessage == "Ingresá el nombre del proyecto.")
        flow.form.name = "Casa de Juan"
        #expect(flow.canContinue)
        flow.form.name = name
        #expect(!flow.canContinue)
        #expect(flow.errorMessage == "Ingresá el nombre del proyecto.")
        flow.form.name = "Flia Alvarez"
        #expect(flow.canContinue)
    }

    @Test func creationFeedbackIsIdempotentAndCompletesMissingCircuits() throws {
        var plan = CircuitPlan(selection: .init(grade: .medium, variant: .b))
        #expect(MinimumCircuitAction.title(for: plan) == "Crear circuitos mínimos")
        #expect(try MinimumCircuitAction.perform(plan: &plan, grade: .medium) == "3 circuitos creados")
        let original = plan.circuits
        #expect(MinimumCircuitAction.title(for: plan) == "Completar circuitos mínimos")
        for _ in 0..<3 {
            #expect(try MinimumCircuitAction.perform(plan: &plan, grade: .medium) == "La estructura mínima ya está completa")
            #expect(plan.circuits == original)
        }
        CircuitEngine.removeCircuit(original[2].id, from: &plan)
        #expect(try MinimumCircuitAction.perform(plan: &plan, grade: .medium) == "Circuitos mínimos completados")
        #expect(plan.circuits.count == 3)
        #expect(Array(plan.circuits.prefix(2)) == Array(original.prefix(2)))
    }

    @Test func freeChoiceIsNeverReportedAsCompleteByGeneration() throws {
        var plan = CircuitPlan(selection: .init(grade: .superior, variant: .a))
        let feedback = try MinimumCircuitAction.perform(plan: &plan, grade: .superior)
        #expect(feedback.contains("Revisá los pendientes"))
        #expect(plan.circuits.count == 5)
        #expect(plan.freeChoiceCircuitID == nil)
        #expect(try MinimumCircuitAction.perform(plan: &plan, grade: .superior).contains("Revisá los pendientes"))
        #expect(plan.circuits.count == 5)
    }

    @Test func assignmentChoicesAppearOnlyForCompatibleCircuits() throws {
        let point = UtilizationPoint(id: UUID(), roomID: UUID(), kind: .generalUseOutlet, ordinal: 3)
        var plan = CircuitPlan()
        #expect(point.assignmentTitle == "Tomacorriente 3 · TUG")
        #expect(point.compatibleCircuits(in: plan).isEmpty)
        try CircuitEngine.addCircuit(to: &plan, type: .iug)
        #expect(point.compatibleCircuits(in: plan).isEmpty)
        let tug = try CircuitEngine.addCircuit(to: &plan, type: .tug)
        #expect(point.compatibleCircuits(in: plan).map(\.id) == [tug])
        #expect(point.circuitID == nil)
    }

    @Test func editingACUPreservesIdentityAndRelatedPlanState() throws {
        let circuit = try Circuit(number: 7, type: .acu, destination: "ACUaire",
                                  declaredLoad: DeclaredLoad(value: 3, unit: .horsepower), powerFactor: PowerFactor(0.7))
        var plan = CircuitPlan(selection: .init(grade: .superior, variant: .b), freeChoiceCircuitID: circuit.id, circuits: [circuit])
        let selection = plan.selection
        let points = plan.points
        var form = CircuitDemandForm(circuit: circuit)
        form.destination = "Aire acondicionado"
        form.declaredValue = "2,5"; form.unit = .kilowatt; form.powerFactor = "0,85"
        try form.apply(to: &plan.circuits[0])
        #expect(plan.circuits[0].id == circuit.id)
        #expect(plan.circuits[0].number == 7)
        #expect(plan.circuits[0].destination == "Aire acondicionado")
        #expect(plan.circuits[0].declaredLoad == (try DeclaredLoad(value: 2.5, unit: .kilowatt)))
        #expect(plan.circuits[0].powerFactor == (try PowerFactor(0.85)))
        #expect(plan.selection == selection)
        #expect(plan.freeChoiceCircuitID == circuit.id)
        #expect(plan.points == points)
        let saved = plan.circuits[0]
        form.destination = "No aplicar"; form.powerFactor = "0"
        #expect(throws: CircuitDemandForm.InputError.self) { try form.apply(to: &plan.circuits[0]) }
        #expect(plan.circuits[0] == saved)
        form.unit = .voltAmpere; form.declaredValue = "4000"
        try form.apply(to: &plan.circuits[0])
        #expect(plan.circuits[0].id == circuit.id)
        #expect(plan.circuits[0].powerFactor == nil)
    }

    @Test(arguments: [(3197.142857, "3.197,14"), (6749.142857, "6.749,14"), (4000.0, "4.000")])
    func apparentPowerFormatting(value: Double, expected: String) throws {
        let power = try ApparentPower(voltAmperes: value)
        #expect(PowerPresentation.number(value) == expected)
        #expect(power.displayValue == "\(expected) VA")
        #expect(power.voltAmperes == value)
    }

    @Test func hpExplanationUsesEngineTrace() throws {
        let load = try DeclaredLoad(value: 3, unit: .horsepower)
        let calculation = try ApparentPowerCalculator.calculate(load, powerFactor: PowerFactor(0.7)).get()
        #expect(PowerPresentation.expression(calculation) == "3 HP × 746 W/HP ÷ 0,70")
        #expect(calculation.apparentPower.displayValue == "3.197,14 VA")
    }
}
