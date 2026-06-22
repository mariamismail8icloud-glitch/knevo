import SwiftUI

struct SessionFlowView: View {
    @State private var viewModel: SessionViewModel
    @Environment(\.dismiss) private var dismiss

    init(plan: ActivePlan) {
        _viewModel = State(initialValue: SessionViewModel(plan: plan))
    }

    var body: some View {
        ZStack {
            Color(red: 0.992, green: 0.961, blue: 0.976)
                .ignoresSafeArea()

            phaseView

            if let error = viewModel.errorMessage {
                VStack {
                    Spacer()
                    Text(error)
                        .padding()
                        .background(.red.opacity(0.9))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding()
                        .onTapGesture { viewModel.errorMessage = nil }
                }
            }
        }
        .navigationBarBackButtonHidden(isBackButtonHidden)
    }

    @ViewBuilder
    private var phaseView: some View {
        switch viewModel.phase {
        case .prePainCheck:
            PreSessionPainView(viewModel: viewModel)
        case .running:
            RunningSessionView(viewModel: viewModel, dismiss: dismiss)
        case .setActive(let index):
            ActiveSetView(viewModel: viewModel, setIndex: index)
        case .restTimer(let index):
            RestTimerView(viewModel: viewModel, setIndex: index)
        case .postSession:
            PostSessionView(viewModel: viewModel)
        case .summary:
            SessionSummaryView(viewModel: viewModel, dismiss: dismiss)
        }
    }

    private var isBackButtonHidden: Bool {
        switch viewModel.phase {
        case .prePainCheck, .summary:
            return false
        default:
            return true
        }
    }
}
