import Testing
@testable import InstaladorElectricistaCBA

@MainActor
struct ProjectFormTests {
    @Test func endToEnd() throws {
        var form = ProjectForm()
        form.name = "Casa"
        form.coveredArea = "50,25"
        form.semiCoveredArea = "20.5"
        let result = try form.calculate()
        #expect(result.sla.value == 60.5)
        #expect(result.grade == .medium)
        #expect(result.project.id == (try form.calculate()).project.id)
        form.coveredArea = "-1"
        #expect(throws: ProjectForm.InputError.self) { try form.calculate() }
    }

    @Test(arguments: ["", "abc", "NaN", "inf", "1.234,56", "-0.1"])
    func rejectsInvalidInput(input: String) {
        var form = ProjectForm()
        form.name = "Casa"
        form.coveredArea = input
        form.semiCoveredArea = "0"
        #expect(throws: ProjectForm.InputError.self) { try form.calculate() }
        form.coveredArea = "10"
        form.semiCoveredArea = input
        #expect(throws: ProjectForm.InputError.self) { try form.calculate() }
    }

    @Test func requiresName() {
        var form = ProjectForm()
        form.name = "   "
        form.coveredArea = "0"
        form.semiCoveredArea = "0"
        #expect(throws: ProjectForm.InputError.self) { try form.calculate() }
    }
}
