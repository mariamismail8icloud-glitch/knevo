import XCTest
@testable import KnevoPatient

final class NetworkConfigTests: XCTestCase {
    func testDefaultBaseURL() {
        // Tracks the fallback in NetworkConfig.baseURL (used when Info.plist has no
        // API_BASE_URL). Points at the deployed demo server.
        let url = NetworkConfig.baseURL
        XCTAssertEqual(url, "https://knevo.appscorner.com")
    }
}
