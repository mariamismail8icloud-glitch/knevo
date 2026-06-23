import Testing
@testable import KnevoPatient

@Suite("SessionViewModel")
@MainActor
struct SessionViewModelTests {

    private func makePlan() -> ActivePlan {
        ActivePlan(
            id: "config-1",
            patientId: "patient-1",
            issuedById: nil,
            sessionsPerWeek: 3,
            schedule: "MON,WED,FRI",
            totalSessionsNum: 12,
            maxFlexionAngleDeg: nil,
            maxExtensionAngleDeg: nil,
            maxSpeed: nil,
            status: "INPROGRESS",
            sets: [
                TherapySetInfo(
                    id: "set-1",
                    exercise: ExerciseInfo(
                        id: "ex-1", name: "Test Exercise",
                        category: "Strength", activityType: "SEATED",
                        mode: "MOBILE_ONLY", difficulty: "BEGINNER",
                        description: "Test", patientInstructions: "Do it",
                        safetyNotes: nil, defaultSets: 3, defaultReps: 10,
                        defaultRestSeconds: 60, targetJoint: "KNEE"
                    ),
                    deviceAssisted: false,
                    durationMin: 10,
                    restDurationMin: 2,
                    setOrder: 0
                )
            ]
        )
    }

    @Test("starts in prePainCheck phase")
    func startsInPrePainCheckPhase() {
        let viewModel = SessionViewModel(plan: makePlan())
        if case .prePainCheck = viewModel.phase { } else {
            Issue.record("Expected prePainCheck phase")
        }
    }

    @Test("high pain level sets error and keeps prePainCheck phase")
    func highPainSetsErrorWithoutChangingPhase() async {
        let viewModel = SessionViewModel(plan: makePlan())
        viewModel.prePainLevel = 9
        await viewModel.startSession()
        #expect(viewModel.errorMessage != nil)
        if case .prePainCheck = viewModel.phase { } else {
            Issue.record("Phase should remain prePainCheck")
        }
    }

    @Test("formattedTime formats mm:ss correctly")
    func formattedTimeFormatsCorrectly() {
        let viewModel = SessionViewModel(plan: makePlan())
        viewModel.secondsElapsed = 125
        #expect(viewModel.formattedTime == "02:05")
    }

    @Test("initial pain levels are zero")
    func initialPainLevels() {
        let viewModel = SessionViewModel(plan: makePlan())
        #expect(viewModel.prePainLevel == 0)
        #expect(viewModel.postPainLevel == 0)
        #expect(viewModel.inSetPainLevel == 0)
    }

    @Test("isLoading starts false")
    func initialLoadingState() {
        let viewModel = SessionViewModel(plan: makePlan())
        #expect(viewModel.isLoading == false)
    }

    @Test("plan is stored on init")
    func planStoredOnInit() {
        let plan = makePlan()
        let viewModel = SessionViewModel(plan: plan)
        #expect(viewModel.plan.id == "config-1")
        #expect(viewModel.plan.sets.count == 1)
    }

    @Test("formattedTime zero pads both fields")
    func formattedTimeZeroPads() {
        let viewModel = SessionViewModel(plan: makePlan())
        viewModel.secondsElapsed = 5
        #expect(viewModel.formattedTime == "00:05")
    }

    @Test("pain level 6 does not block session start attempt")
    func painLevel6DoesNotBlock() async {
        let viewModel = SessionViewModel(plan: makePlan())
        viewModel.prePainLevel = 6
        // Will fail the network call but should NOT set a pain-block error
        await viewModel.startSession()
        // If it was blocked by pain, errorMessage contains "Pain level is too high"
        // A network failure is a different error
        if let msg = viewModel.errorMessage {
            #expect(!msg.contains("Pain level is too high"))
        }
    }
}
