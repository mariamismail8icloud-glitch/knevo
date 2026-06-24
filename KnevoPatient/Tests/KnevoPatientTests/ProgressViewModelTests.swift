import Testing
@testable import KnevoPatient

@MainActor
struct ProgressViewModelTests {
    @Test func initialStateHasNoProgress() {
        let viewModel = ProgressViewModel()
        #expect(viewModel.progress == nil)
        #expect(!viewModel.isLoading)
        #expect(viewModel.errorMessage == nil)
    }
}
