import XCTest
import Vapor
import XCTVapor

@testable import Quanta

final class HomeControllerTests: XCTestCase {
    var app: Application!

    override func setUp() async throws {
        app = try await Application.testable()
    }

    override func tearDown() async throws {
        try await app.asyncShutdown()
        app = nil
    }

    func testWelcome() async throws {
        try await app.test(.GET, "/") { res async in
            XCTAssertEqual(res.status, .ok)
        }
    }
}
