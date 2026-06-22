import SwiftUI

struct MessagesView: View {
    @State private var viewModel = MessagesViewModel()
    @State private var activePlanVM = ActivePlanViewModel()
    private let patientId: String

    init(patientId: String) {
        self.patientId = patientId
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.992, green: 0.961, blue: 0.976).ignoresSafeArea()

                if viewModel.isLoading && viewModel.messages.isEmpty {
                    ProgressView().tint(Color(red: 0.91, green: 0, blue: 0.49))
                } else if viewModel.doctorId == nil {
                    noDoctorView
                } else {
                    chatView
                }
            }
            .navigationTitle("Messages")
            .navigationBarTitleDisplayMode(.large)
        }
        .task {
            await activePlanVM.fetchActivePlan()
            if let plan = activePlanVM.plan {
                viewModel.setDoctorFromPlan(plan)
                await viewModel.loadConversation(patientId: patientId)
            }
        }
    }

    private var noDoctorView: some View {
        VStack(spacing: 12) {
            Image(systemName: "message.badge.circle")
                .font(.system(size: 48))
                .foregroundStyle(Color(red: 0.91, green: 0, blue: 0.49).opacity(0.4))
            Text("No doctor linked")
                .font(.title3).fontWeight(.semibold)
            Text("Once your doctor links your account, you can message them here.")
                .font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
        }
        .padding()
    }

    private var chatView: some View {
        VStack(spacing: 0) {
            // Doctor header
            HStack(spacing: 10) {
                ZStack {
                    Circle().fill(Color(red: 0.91, green: 0, blue: 0.49).opacity(0.15)).frame(width: 40, height: 40)
                    Text("Dr").font(.caption).fontWeight(.bold).foregroundStyle(Color(red: 0.91, green: 0, blue: 0.49))
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(viewModel.doctorName).font(.subheadline).fontWeight(.semibold).foregroundStyle(Color(red: 0.06, green: 0.09, blue: 0.16))
                    Text("Your doctor").font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding()
            .background(.white)
            .overlay(alignment: .bottom) {
                Divider()
            }

            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(viewModel.messages) { msg in
                            messageBubble(msg)
                                .id(msg.id)
                        }
                        if viewModel.messages.isEmpty {
                            Text("No messages yet. Say hello!")
                                .font(.subheadline).foregroundStyle(.secondary).padding(.top, 40)
                        }
                    }
                    .padding()
                }
                .onChange(of: viewModel.messages.count) { _, _ in
                    if let last = viewModel.messages.last {
                        withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                    }
                }
            }
            .refreshable {
                await viewModel.loadConversation(patientId: patientId)
            }

            // Input bar
            HStack(spacing: 10) {
                TextField("Message\u{2026}", text: $viewModel.messageInput)
                    .padding(.horizontal, 16).padding(.vertical, 10)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color(red: 0.94, green: 0.84, blue: 0.91), lineWidth: 1))

                Button {
                    Task { await viewModel.sendMessage(patientId: patientId) }
                } label: {
                    Image(systemName: viewModel.isSending ? "hourglass" : "arrow.up.circle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(viewModel.messageInput.trimmingCharacters(in: .whitespaces).isEmpty
                            ? Color(.systemGray3)
                            : Color(red: 0.91, green: 0, blue: 0.49))
                }
                .disabled(viewModel.messageInput.trimmingCharacters(in: .whitespaces).isEmpty || viewModel.isSending)
            }
            .padding(.horizontal, 16).padding(.vertical, 10)
            .background(.white)
            .overlay(alignment: .top) { Divider() }
        }
    }

    private func messageBubble(_ msg: ChatMessage) -> some View {
        let isFromPatient = msg.senderId == patientId
        return HStack {
            if isFromPatient { Spacer(minLength: 60) }
            VStack(alignment: isFromPatient ? .trailing : .leading, spacing: 3) {
                Text(msg.body)
                    .padding(.horizontal, 14).padding(.vertical, 8)
                    .background(isFromPatient ? Color(red: 0.91, green: 0, blue: 0.49) : Color.white)
                    .foregroundStyle(isFromPatient ? .white : Color(red: 0.06, green: 0.09, blue: 0.16))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(!isFromPatient ? RoundedRectangle(cornerRadius: 16).stroke(Color(red: 0.94, green: 0.84, blue: 0.91), lineWidth: 1) : nil)
                Text(formatTime(msg.sentAt))
                    .font(.caption2).foregroundStyle(.secondary)
            }
            if !isFromPatient { Spacer(minLength: 60) }
        }
    }

    private func formatTime(_ iso: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: iso) {
            let display = DateFormatter()
            display.timeStyle = .short
            return display.string(from: date)
        }
        return ""
    }
}
