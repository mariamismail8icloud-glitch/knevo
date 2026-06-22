import Foundation
import Observation

@Observable
@MainActor
final class ActivePlanViewModel {
    var plan: ActivePlan?
    var isLoading = false
    var errorMessage: String?
    var hasNoPlan = false

    func fetchActivePlan() async {
        isLoading = true
        errorMessage = nil
        hasNoPlan = false
        defer { isLoading = false }

        do {
            plan = try await APIClient.shared.get(path: "/api/patient/active-plan")
        } catch APIError.httpError(404, _) {
            hasNoPlan = true
        } catch {
            errorMessage = "Could not load your plan. Pull down to try again."
        }
    }
}
