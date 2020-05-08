import XCTest

import Multipart
import HTTP

@testable import Quanta

extension ProxyRequest {
    func asGetQuery() -> String {
        return "quality=\(quality)&url=\(url)"
    }
}

class OptimizeControllerTests: TestCase {
    struct OptimizeRequestQuality: Encodable {
        let quality: Int
    }

    struct OptimizeRequestFile: Encodable {
        let fileBytes: Data
    }

    private func makeProxyRequest(image: String, quality: Int) -> HTTPRequest {
        let optimizeRequest = ProxyRequest(quality: quality, url: "http://localhost:8888/images/\(image)")
        return HTTPRequest(method: .GET, url: "/from?\(optimizeRequest.asGetQuery())")
    }

    func testDemoOptimize() throws {
        let request = try makeCompressRequest(for: .demo, quality: 90, fixtureName: "typical_banner_1.jpg")
        let response = try app.sendRequest(request: request)
        guard let httpData = response.http.body.data else {
            fatalError("Response data is empty")
        }
        let jsonResponse = try JSONDecoder().decode(DemoResponse.self, from: httpData)

        XCTAssertEqual(response.http.status, .ok)
        XCTAssertEqual(88466, jsonResponse.originalSize)
        XCTAssertEqual(73525, jsonResponse.optimizedSize)
        XCTAssertNotNil(jsonResponse.encodedImageData)
    }

    func testRequestOptimizeJpgWithMaximumCompression() throws {
        let request = try makeCompressRequest(for: .jpg, quality: 90, fixtureName: "typical_banner_1.jpg")
        let response = try app.sendRequest(request: request)

        XCTAssertEqual(response.http.status, .ok)
        XCTAssertEqual(response.http.headers.firstValue(name: HTTPHeaderName("Content-Type")), "image/jpeg")
        XCTAssertEqual(response.http.headers.firstValue(name: HTTPHeaderName("X-Quanta-Ratio")), "16.8890")
        let expectedFile = getFixture(fileNamePath: "typical_banner_1_opimized_90.jpg")
        XCTAssertEqual(response.http.body.data!, expectedFile)
    }

    func testRequestOptimizeWithQualityOutOfRangeShouldReturnBadRequest() throws {
        let request = try makeCompressRequest(for: .jpg, quality: 9000, fixtureName: "typical_banner_1.jpg")
        let response = try app.sendRequest(request: request)

        XCTAssertEqual(response.http.status, .badRequest)
    }

    func testRequestOptimizeJpgWithoutFileShouldReturnBadRequest() throws {
        let optimizeRequest = OptimizeRequestQuality(quality: 50)
        let requestBody = try FormDataEncoder().encode(optimizeRequest, boundary: "TEST")
        let headers = HTTPHeaders([("Content-Type", "multipart/form-data; boundary=TEST")])
        let request = HTTPRequest(method: .POST, url: CompressionType.jpg.rawValue, headers: headers, body: requestBody)
        let response = try app.sendRequest(request: request)

        XCTAssertEqual(response.http.status, .badRequest)
        let errorResponse = try response.content.syncDecode(ErrorResponse.self)
        XCTAssertEqual(errorResponse.error, true)
        XCTAssertEqual(errorResponse.reason, "No multipart part named 'fileBytes' was found.")
    }

    func testRequestOptimizeJpgWithoutQualityShouldReturnBadRequest() throws {
        let file = getFixture(fileNamePath: "typical_banner_1.jpg")
        let optimizeRequest = OptimizeRequestFile(fileBytes: file)
        let requestBody = try FormDataEncoder().encode(optimizeRequest, boundary: "TEST")
        let headers = HTTPHeaders([("Content-Type", "multipart/form-data; boundary=TEST")])
        let request = HTTPRequest(method: .POST, url: CompressionType.jpg.rawValue, headers: headers, body: requestBody)

        let response = try app.sendRequest(request: request)
        XCTAssertEqual(response.http.status, .badRequest)
        let errorResponse = try response.content.syncDecode(ErrorResponse.self)
        XCTAssertEqual(errorResponse.error, true)
        XCTAssertEqual(errorResponse.reason, "No multipart part named 'quality' was found.")
    }

    func testRequestOptimizeJpgWithoutFormDataShouldReturnBadRequest() throws {
        let headers = HTTPHeaders([("Content-Type", "multipart/form-data; boundary=TEST")])
        let request = HTTPRequest(method: .POST, url: CompressionType.jpg.rawValue, headers: headers)
        let response = try app.sendRequest(request: request)

        XCTAssertEqual(response.http.status, .badRequest)
        let errorResponse = try response.content.syncDecode(ErrorResponse.self)
        XCTAssertEqual(errorResponse.error, true)
        XCTAssertEqual(errorResponse.reason, "No multipart part named 'fileBytes' was found.")
    }

    func testRequestOptimizeExternalResource() throws {
        let request = makeProxyRequest(image: "quanta.jpg", quality: 10)
        let response = try app.sendRequest(request: request)

        XCTAssertEqual(response.http.status, .ok)
        XCTAssertEqual(response.http.headers.firstValue(name: HTTPHeaderName("X-Quanta-Ratio")), "70.0936")
    }

}

// MARK: Manifest

extension OptimizeControllerTests {
    // This is a requirement for XCTest on Linux
    // to function properly.
    // See ./Tests/LinuxMain.swift for examples
    static let allTests = [
        ("testDemoOptimize", testDemoOptimize),
        ("testRequestOptimizeJpgWithMaximumCompression", testRequestOptimizeJpgWithMaximumCompression),
        ("testRequestOptimizeWithQualityOutOfRangeShouldReturnBadRequest", testRequestOptimizeWithQualityOutOfRangeShouldReturnBadRequest),
        ("testRequestOptimizeJpgWithoutFileShouldReturnBadRequest", testRequestOptimizeJpgWithoutFileShouldReturnBadRequest),
        ("testRequestOptimizeJpgWithoutQualityShouldReturnBadRequest", testRequestOptimizeJpgWithoutQualityShouldReturnBadRequest),
        ("testRequestOptimizeExternalResource", testRequestOptimizeExternalResource),
    ]
}
