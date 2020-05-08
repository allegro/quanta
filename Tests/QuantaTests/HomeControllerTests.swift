import XCTest

@testable import Quanta


class HomeControllerTests: TestCase {
    func testWelcome() throws {
        let response = try app.sendRequest(at: "/")
        XCTAssertEqual(response.http.status, .ok)
    }
}

// MARK: Manifest

extension HomeControllerTests {
    /// This is a requirement for XCTest on Linux
    /// to function properly.
    /// See ./Tests/LinuxMain.swift for examples
    static let allTests = [
        ("testWelcome", testWelcome),
    ]
}
