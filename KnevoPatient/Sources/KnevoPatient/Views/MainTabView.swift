import SwiftUI

struct MainTabView: View {
    @Environment(AuthViewModel.self) private var authVM

    private var patientId: String {
        KeychainService.loadTokens().userId ?? ""
    }

    var body: some View {
        TabView {
            ActivePlanView()
                .tabItem { Label("Home", systemImage: "house.fill") }
            SessionsView()
                .tabItem { Label("Sessions", systemImage: "figure.walk") }
            PatientProgressView()
                .tabItem { Label("Progress", systemImage: "chart.line.uptrend.xyaxis") }
            MessagesView(patientId: patientId)
                .tabItem { Label("Messages", systemImage: "message.fill") }
            ProfileView()
                .tabItem { Label("Profile", systemImage: "person.fill") }
        }
        .tint(Color(red: 232/255, green: 0/255, blue: 125/255))
    }
}
