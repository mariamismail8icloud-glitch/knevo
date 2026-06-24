import Foundation
import Observation
import OSLog

private let planLogger = Logger(subsystem: "com.knevo.patient", category: "ActivePlan")

@Observable
@MainActor
final class ActivePlanViewModel {
    var plan: ActivePlan?
    var isLoading = false
    var errorMessage: String?
    var hasNoPlan = false

    func fetchActivePlan() async {
        planLogger.debug("fetchActivePlan: starting, url=\(NetworkConfig.baseURL)/api/patient/active-plan")
        isLoading = true
        errorMessage = nil
        hasNoPlan = false
        defer { isLoading = false }

        do {
            plan = try await APIClient.shared.get(path: "/api/patient/active-plan")
            planLogger.debug("fetchActivePlan: success")
        } catch APIError.httpError(404, _) {
            planLogger.debug("fetchActivePlan: 404, no active plan")
            hasNoPlan = true
        } catch {
            planLogger.error("fetchActivePlan error: \(error.localizedDescription)")
            planLogger.error("fetchActivePlan error type: \(String(describing: type(of: error)))")
            errorMessage = "Could not load your plan. Pull down to try again."
        }
    }
}
