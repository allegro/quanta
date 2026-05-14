import XCTest
import Vapor
import XCTVapor

@testable import Quanta

final class OptimizeControllerTests: XCTestCase {
    var app: Application!

    override func setUp() async throws {
        app = try await Application.testable()
    }

    override func tearDown() async throws {
        try await app.asyncShutdown()
        app = nil
    }

    func testDemoOptimize() async throws {
        let file = getFixture(fileNamePath: "typical_banner_1.jpg")
        let (headers, body) = makeMultipartBody(quality: 90, fileBytes: file)
        try await app.test(.POST, "/demo/optimize", headers: headers, body: body) { res async throws in
            XCTAssertEqual(res.status, .ok)
            let demo = try res.content.decode(DemoResponse.self)
            XCTAssertEqual(88466, demo.originalSize)
            XCTAssertNotNil(demo.encodedImageData)
            XCTAssertGreaterThan(demo.originalSize, demo.optimizedSize)
        }
    }

    func testRequestOptimizeJpgWithMaximumCompression() async throws {
        let file = getFixture(fileNamePath: "typical_banner_1.jpg")
        let (headers, body) = makeMultipartBody(quality: 90, fileBytes: file)
        try await app.test(.POST, "/optimize/jpg", headers: headers, body: body) { res async in
            XCTAssertEqual(res.status, .ok)
            XCTAssertEqual(res.headers.first(name: "Content-Type"), "image/jpeg")
            XCTAssertNotNil(res.headers.first(name: "X-Quanta-Ratio"))
        }
    }

    func testRequestOptimizeWithQualityOutOfRangeShouldReturnBadRequest() async throws {
        let file = getFixture(fileNamePath: "typical_banner_1.jpg")
        let (headers, body) = makeMultipartBody(quality: 9000, fileBytes: file)
        try await app.test(.POST, "/optimize/jpg", headers: headers, body: body) { res async in
            XCTAssertEqual(res.status, .badRequest)
        }
    }

    func testRequestOptimizeJpgWithoutFileShouldReturnBadRequest() async throws {
        let (headers, body) = makeMultipartBody(quality: 50, fileBytes: nil)
        try await app.test(.POST, "/optimize/jpg", headers: headers, body: body) { res async in
            XCTAssertEqual(res.status, .badRequest)
        }
    }

    func testRequestOptimizeJpgWithoutQualityShouldReturnBadRequest() async throws {
        let file = getFixture(fileNamePath: "typical_banner_1.jpg")
        let (headers, body) = makeMultipartBody(quality: nil, fileBytes: file)
        try await app.test(.POST, "/optimize/jpg", headers: headers, body: body) { res async in
            XCTAssertEqual(res.status, .badRequest)
        }
    }

    func testRequestOptimizeJpgWithoutFormDataShouldReturnBadRequest() async throws {
        let (headers, body) = makeMultipartBody(quality: nil, fileBytes: nil)
        try await app.test(.POST, "/optimize/jpg", headers: headers, body: body) { res async in
            XCTAssertEqual(res.status, .badRequest)
        }
    }
}
