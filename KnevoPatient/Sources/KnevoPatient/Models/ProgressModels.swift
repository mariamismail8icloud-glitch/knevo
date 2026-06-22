import Foundation

struct WeeklyCount: Decodable, Identifiable {
    var id: String { weekLabel }
    let weekLabel: String
    let count: Int
}

struct PainPoint: Decodable, Identifiable {
    var id: String { sessionDate }
    let sessionDate: String
    let avgPainBefore: Double
}

struct PatientProgress: Decodable {
    let sessionsPerWeek: [WeeklyCount]
    let painTrend: [PainPoint]
    let adherenceRate: Double
    let missedSessionsCount: Int
    let totalSessionsCompleted: Int
    let totalSessionsPrescribed: Int
}
