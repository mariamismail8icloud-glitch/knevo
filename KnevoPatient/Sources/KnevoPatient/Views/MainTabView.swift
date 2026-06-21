import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
            SessionsView()
                .tabItem {
                    Label("Sessions", systemImage: "figure.walk")
                }
            PatientProgressView()
                .tabItem {
                    Label("Progress", systemImage: "chart.line.uptrend.xyaxis")
                }
            MessagesView()
                .tabItem {
                    Label("Messages", systemImage: "message.fill")
                }
        }
        .tint(Color(red: 232/255, green: 0/255, blue: 125/255))
    }
}
