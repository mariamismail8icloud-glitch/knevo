import Foundation

struct ExerciseInfo: Decodable {
    let id: String
    let name: String
    let category: String?
    let activityType: String?
    let mode: String?
    let difficulty: String?
    let description: String?
    let patientInstructions: String?
    let safetyNotes: String?
    let defaultSets: Int?
    let defaultReps: Int?
    let defaultRestSeconds: Int?
    let targetJoint: String?
}

struct TherapySetInfo: Decodable, Identifiable {
    let id: String
    let exercise: ExerciseInfo
    let deviceAssisted: Bool
    let durationMin: Int?
    let restDurationMin: Int?
    let setOrder: Int
}

struct ActivePlan: Decodable {
    let id: String
    let patientId: String
    let issuedById: String?
    let sessionsPerWeek: Int?
    let schedule: String?
    let totalSessionsNum: Int?
    let maxFlexionAngleDeg: Double?
    let maxExtensionAngleDeg: Double?
    let maxSpeed: Double?
    let status: String
    let sets: [TherapySetInfo]
}
