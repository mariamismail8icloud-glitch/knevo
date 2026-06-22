import Testing
@testable import KnevoPatient

@Suite("MessagesViewModel")
@MainActor
struct MessagesViewModelTests {

    @Test("starts with empty messages and no doctor")
    func initialStateIsEmpty() {
        let viewModel = MessagesViewModel()
        #expect(viewModel.messages.isEmpty)
        #expect(viewModel.doctorId == nil)
        #expect(!viewModel.isLoading)
    }

    @Test("empty input does not trigger send")
    func emptyInputDoesNotTriggerSend() async {
        let viewModel = MessagesViewModel()
        viewModel.doctorId = "doctor-1"
        viewModel.messageInput = ""
        await viewModel.sendMessage(patientId: "patient-1")
        #expect(viewModel.messages.isEmpty)
    }

    @Test("whitespace-only input does not trigger send")
    func whitespaceInputDoesNotTriggerSend() async {
        let viewModel = MessagesViewModel()
        viewModel.doctorId = "doctor-1"
        viewModel.messageInput = "   "
        await viewModel.sendMessage(patientId: "patient-1")
        #expect(viewModel.messages.isEmpty)
    }

    @Test("setDoctorFromPlan sets doctorId from plan issuedById")
    func setDoctorFromPlanWithIssuedById() {
        let viewModel = MessagesViewModel()
        let plan = ActivePlan(
            id: "plan-1",
            patientId: "patient-1",
            issuedById: "doctor-42",
            sessionsPerWeek: nil,
            schedule: nil,
            totalSessionsNum: nil,
            maxFlexionAngleDeg: nil,
            maxExtensionAngleDeg: nil,
            maxSpeed: nil,
            status: "ACTIVE",
            sets: []
        )
        viewModel.setDoctorFromPlan(plan)
        #expect(viewModel.doctorId == "doctor-42")
    }

    @Test("setDoctorFromPlan with nil issuedById leaves doctorId nil")
    func setDoctorFromPlanWithNilIssuedById() {
        let viewModel = MessagesViewModel()
        let plan = ActivePlan(
            id: "plan-1",
            patientId: "patient-1",
            issuedById: nil,
            sessionsPerWeek: nil,
            schedule: nil,
            totalSessionsNum: nil,
            maxFlexionAngleDeg: nil,
            maxExtensionAngleDeg: nil,
            maxSpeed: nil,
            status: "ACTIVE",
            sets: []
        )
        viewModel.setDoctorFromPlan(plan)
        #expect(viewModel.doctorId == nil)
    }
}
