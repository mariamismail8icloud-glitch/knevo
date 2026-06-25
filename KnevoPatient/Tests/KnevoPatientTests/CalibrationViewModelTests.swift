import Foundation
@testable import KnevoPatient
import Testing

@Suite("CalibrationViewModel")
@MainActor
struct CalibrationViewModelTests {
    @Test("begin() moves intro → instructions(.unloaded)")
    func beginEntersStepOne() {
        let viewModel = CalibrationViewModel(transport: MockBLETransport(), countdownSeconds: 0)

        #expect(viewModel.phase == .intro)
        viewModel.begin()
        #expect(viewModel.phase == .instructions(.unloaded))
    }

    @Test("sendCalibration() for step 1 writes .calibrateUnloaded and ends in confirm(.unloaded)")
    func stepOneSendsUnloadedOpcode() async {
        let mock = MockBLETransport()
        let viewModel = CalibrationViewModel(transport: mock, countdownSeconds: 0)

        viewModel.begin()
        await viewModel.sendCalibration()

        #expect(mock.lastControl == .calibrateUnloaded)
        #expect(viewModel.phase == .confirm(.unloaded))
    }

    @Test("confirmSuccess() advances to step 2, which writes .calibrateStatic, then to .done")
    func confirmAdvancesThroughBothSteps() async {
        let mock = MockBLETransport()
        let viewModel = CalibrationViewModel(transport: mock, countdownSeconds: 0)

        viewModel.begin()
        await viewModel.sendCalibration()
        viewModel.confirmSuccess()
        #expect(viewModel.phase == .instructions(.staticWeight))

        await viewModel.sendCalibration()
        #expect(mock.lastControl == .calibrateStatic)
        #expect(viewModel.phase == .confirm(.staticWeight))

        viewModel.confirmSuccess()
        #expect(viewModel.phase == .done)
    }

    @Test("retry() re-enters the current step only and re-sends its opcode")
    func retryRepeatsCurrentStep() async {
        let mock = MockBLETransport()
        let viewModel = CalibrationViewModel(transport: mock, countdownSeconds: 0)

        viewModel.begin()
        await viewModel.sendCalibration()
        #expect(viewModel.phase == .confirm(.unloaded))

        viewModel.retry()
        #expect(viewModel.phase == .instructions(.unloaded))

        await viewModel.sendCalibration()
        #expect(mock.lastControl == .calibrateUnloaded)
        #expect(viewModel.phase == .confirm(.unloaded))
    }
}
