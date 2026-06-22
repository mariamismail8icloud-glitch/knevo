import Foundation

@Observable
@MainActor
final class ProgressViewModel {
    var progress: PatientProgress?
    var isLoading = false
    var errorMessage: String?

    func fetchProgress(patientId: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            progress = try await APIClient.shared.get(path: "/api/patient/progress")
        } catch APIError.httpError(404, _) {
            progress = nil
        } catch {
            errorMessage = "Could not load progress."
        }
    }
}
