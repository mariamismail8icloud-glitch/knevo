import XCTest
@testable import KnevoPatient

final class NetworkConfigTests: XCTestCase {
    func testDefaultBaseURL() {
        let url = NetworkConfig.baseURL
        XCTAssertEqual(url, "http://localhost:8080")
    }
}
