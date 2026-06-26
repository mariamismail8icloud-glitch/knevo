import Foundation

struct SensorSample: Codable, Equatable {
    let timestampUs: Int64
    let sampleId: Int

    let footAxG: Double
    let footAyG: Double
    let footAzG: Double
    let footGxRadS: Double
    let footGyRadS: Double
    let footGzRadS: Double

    let shankAxG: Double
    let shankAyG: Double
    let shankAzG: Double
    let shankGxRadS: Double
    let shankGyRadS: Double
    let shankGzRadS: Double

    let thighAxG: Double
    let thighAyG: Double
    let thighAzG: Double
    let thighGxRadS: Double
    let thighGyRadS: Double
    let thighGzRadS: Double

    let heelFsrRaw: Int
    let midfootFsrRaw: Int
}
