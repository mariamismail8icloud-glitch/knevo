import Foundation

struct SessionResponse: Decodable, Identifiable {
    let id: String
    let patientId: String
    let therapyConfigId: String?
    let status: String
    let startedAt: String?
    let endedAt: String?
    let painBefore: Int?
    let painDuring: Int?
    let painAfter: Int?
    let setRecords: [SetRecordResponse]?
}

struct SetRecordResponse: Decodable, Identifiable {
    let id: String
    let therapySetConfigId: String
    let startDatetime: String?
    let stopDatetime: String?
    let painLevel: Int?
    let feedback: String?
    let status: String
}

// MARK: - Request Models

struct StartSessionRequest: Encodable {
    let configId: String
    let painBefore: Int
}

struct StartSetRequest: Encodable {
    let therapySetConfigId: String
}

struct StopSetRequest: Encodable {
    let therapySetRecordId: String
    let painLevel: Int
    let feedback: String
}

struct PainButtonRequest: Encodable {
    let painLevel: Int
}

struct CompleteSessionRequest: Encodable {
    let painAfter: Int
}

struct EmptyBody: Encodable {}

typealias EmptyRequest = EmptyBody
