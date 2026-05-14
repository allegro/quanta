import Vapor
import XCTVapor
@testable import Quanta

extension Application {
    static func testable() async throws -> Application {
        let app = try await Application.make(.testing)
        try await QuantaConfiguration().configure(app)
        return app
    }
}
