import SwiftUI

extension Notification.Name {
    static let sessionExpired = Notification.Name("sessionExpired")
}

@main
struct KnevoPatientApp: App {
    @State private var authViewModel = AuthViewModel()
    @State private var deviceViewModel = DeviceConnectionViewModel()

    init() {
        APIClient.shared.unauthorizedHandler = {
            NotificationCenter.default.post(name: .sessionExpired, object: nil)
        }
    }

    var body: some Scene {
        WindowGroup {
            if authViewModel.isAuthenticated {
                MainTabView()
                    .environment(authViewModel)
                    .environment(deviceViewModel)
                    .onReceive(NotificationCenter.default.publisher(for: .sessionExpired)) { _ in
                        authViewModel.logout()
                    }
            } else {
                LoginView()
                    .environment(authViewModel)
            }
        }
    }
}
