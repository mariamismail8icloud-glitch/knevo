import XCTest
@testable import KnevoPatient

final class NetworkConfigTests: XCTestCase {
    func testDefaultBaseURL() {
        let url = NetworkConfig.baseURL
        XCTAssertEqual(url, "http://127.0.0.1:8080")
    }
}
