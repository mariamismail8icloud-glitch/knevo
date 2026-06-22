import SwiftUI

@main
struct KnevoPatientApp: App {
    @State private var authViewModel = AuthViewModel()

    var body: some Scene {
        WindowGroup {
            if authViewModel.isAuthenticated {
                MainTabView()
                    .environment(authViewModel)
            } else {
                LoginView()
                    .environment(authViewModel)
            }
        }
    }
}
