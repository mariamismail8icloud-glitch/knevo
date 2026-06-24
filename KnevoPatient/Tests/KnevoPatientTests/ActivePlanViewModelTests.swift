import Testing
@testable import KnevoPatient

@Suite("ActivePlanViewModel")
@MainActor
struct ActivePlanViewModelTests {

    @Test("starts with nil plan and no loading")
    func initialState() {
        let viewModel = ActivePlanViewModel()
        #expect(viewModel.plan == nil)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.hasNoPlan == false)
    }

    @Test("hasNoPlan flag can be set independently")
    func hasNoPlanStateOnEmptyPlan() {
        let viewModel = ActivePlanViewModel()
        viewModel.hasNoPlan = true
        #expect(viewModel.hasNoPlan == true)
        #expect(viewModel.plan == nil)
    }
}
