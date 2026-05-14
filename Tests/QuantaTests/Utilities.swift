import Foundation
import XCTest
import Vapor
import XCTVapor
@testable import Quanta

public func getFixture(fileNamePath: String) -> Data {
    let fixturesPath = ProcessInfo.processInfo.environment["TEST_FIXTURES_DIR"] ?? "./Resources/Samples/"
    let finalURL = URL(fileURLWithPath: "\(fixturesPath)/\(fileNamePath)")
    guard let file = try? Data(contentsOf: finalURL) else {
        fatalError("Cannot open: \(finalURL.absoluteString)")
    }
    return file
}

public enum CompressionType: String {
    case jpg = "/optimize/jpg"
    case demo = "/demo/optimize"
}

/// Build a multipart/form-data body for the given fixture file and quality.
public func makeMultipartBody(quality: Int?, fileBytes: Data?, boundary: String = "TEST") -> (headers: HTTPHeaders, body: ByteBuffer) {
    var body = ""
    if let q = quality {
        body += "--\(boundary)\r\n"
        body += "Content-Disposition: form-data; name=\"quality\"\r\n\r\n"
        body += "\(q)\r\n"
    }
    var buffer = ByteBufferAllocator().buffer(capacity: 0)
    buffer.writeString(body)
    if let fileBytes = fileBytes {
        var filePart = "--\(boundary)\r\n"
        filePart += "Content-Disposition: form-data; name=\"fileBytes\"; filename=\"file.bin\"\r\n"
        filePart += "Content-Type: application/octet-stream\r\n\r\n"
        buffer.writeString(filePart)
        buffer.writeBytes(fileBytes)
        buffer.writeString("\r\n")
    }
    buffer.writeString("--\(boundary)--\r\n")
    var headers = HTTPHeaders()
    headers.add(name: "Content-Type", value: "multipart/form-data; boundary=\(boundary)")
    return (headers, buffer)
}

struct ErrorResponse: Content {
    let reason: String
    let error: Bool
}
