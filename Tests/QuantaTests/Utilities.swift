import Foundation
import XCTest
import Multipart

import Vapor
@testable import Quanta


public func getFixture(fileNamePath: String) -> Data {
    let fixturesPath = ProcessInfo.processInfo.environment["TEST_FIXTURES_DIR"] ?? "./Resources/Samples/"

    let finalURL = URL(fileURLWithPath: "\(fixturesPath)/\(fileNamePath)")
    guard let file = try? Data.init(contentsOf: finalURL) else {
        fatalError("Cannot open: \(finalURL.absoluteString)")
    }
    return file
}

public enum CompressionType: String {
    case jpg = "/optimize/jpg/"
    case demo = "/demo/optimize/"
}

public func makeCompressRequest(for type: CompressionType, quality: Int, fixtureName: String) throws -> HTTPRequest {
    let file = getFixture(fileNamePath: fixtureName)
    let optimizeRequest = OptimizeRequestUnvalidated(fileBytes: file, quality: quality)
    let requestBody = try FormDataEncoder().encode(optimizeRequest, boundary: "TEST")
    let headers = HTTPHeaders([("Content-Type", "multipart/form-data; boundary=TEST")])
    return HTTPRequest(method: .POST, url: type.rawValue, headers: headers, body: requestBody)
}

class TestCase: XCTestCase {
    /// Share application instance between tests
    static let _app = try! Application.testable(args: ["serve", "-p", "8888"])
    var app: Application {
        get {
            return TestCase._app
        }
    }

    override func setUp() {
        do {
            try app.asyncRun().wait()
        } catch {
            fatalError("Failed to launch server.")
        }

    }

    override func tearDown() {
        try? app.runningServer?.close().wait()
    }
}

struct ErrorResponse: Content {
    let reason: String
    let error: Bool
}
