import XCTest
import Vapor

@testable import Quanta

extension OptimizeRequest {
    init(fileBytes: Data, quality: Int, imageFormat: ImageFormat) {
        self.fileBytes = fileBytes
        self.quality = quality
        self.imageFormat = imageFormat
    }
    static func fromFile(filename: String, quality: Int) -> OptimizeRequest {
        let fileBytes = getFixture(fileNamePath: filename)
        let format = detectImageFormat(from: fileBytes)
        return OptimizeRequest(fileBytes: fileBytes, quality: quality, imageFormat: format!)
    }
}

struct PerformanceSample {
    let quality: Int
    let size: Int
    let ratio: Float
    let elapsedTime: Int
}

final class PerformanceTests: TestCase {
    private func makePerformanceSample(format: CompressionType, quality: Int, filename: String) throws -> PerformanceSample {
        let request = try makeCompressRequest(for: format, quality: quality, fixtureName: filename)
        let start = DispatchTime.now()
        let response = try app.sendRequest(request: request)
        let end = DispatchTime.now()
        let size = Int(response.http.headers.firstValue(name: HTTPHeaderName("content-length"))!)!
        let ratio = Float(response.http.headers.firstValue(name: HTTPHeaderName("X-Quanta-Ratio"))!)!
        let elapsedTime = Int((end.uptimeNanoseconds - start.uptimeNanoseconds) / 1_000_000)
        return PerformanceSample(quality: quality, size: size, ratio: ratio, elapsedTime: elapsedTime)
    }

    private func run(for format: CompressionType, files: [String], qualityList: [Int]) throws -> [String: [PerformanceSample]] {
        var results: [String: [PerformanceSample]] = [:]
        for filename in files {
            let result = try qualityList.map { quality -> PerformanceSample in
                return try makePerformanceSample(format: .jpg, quality: quality, filename: filename)
            }
            results[filename] = result
        }
        return results
    }

    private func printHeader(_ titles: [String], paddingLength: Int = 25) {
        for title in titles {
            print(" \(title)".padding(toLength: paddingLength, withPad: " ", startingAt: 0), terminator: "|")
        }
        print("")
        for _ in titles {
            print("-".padding(toLength: paddingLength, withPad: "-", startingAt: 0), terminator: "|")
        }
        print("")
    }
    private func printRow(sample: PerformanceSample, paddingLength: Int = 25) {
        let ratio = String(format: "%.1f", sample.ratio)
        print(" \(sample.quality)".padding(toLength: paddingLength, withPad: " ", startingAt: 0), terminator: "|")
        print(" \(sample.size / 1024) kb".padding(toLength: paddingLength, withPad: " ", startingAt: 0), terminator: "|")
        print(" \(ratio)%".padding(toLength: paddingLength, withPad: " ", startingAt: 0), terminator: "|")
        print(" \(sample.elapsedTime) ms".padding(toLength: paddingLength, withPad: " ", startingAt: 0), terminator: "|")
        print("")
    }

    private func printTable(for samples: [String: [PerformanceSample]]) {
        for (filename, result) in samples.sorted(by: { $0.0 < $1.0 }) {
            print("### \(filename)")
            printHeader(["Quality", "Optimized size", "Ratio", "Elapsed time"])
            result.forEach {printRow(sample: $0)}
            print("\n")
        }
    }

    func testJpgPerformance() throws {
        let qualityList = [65, 70, 75, 80, 85, 90]
        let files = ["typical_banner_1.jpg", "typical_banner_2.jpg", "typical_banner_3.jpg"]
        let results = try run(for: .jpg, files: files, qualityList: qualityList)
        printTable(for: results)
    }
}

// MARK: Manifest

extension PerformanceTests {
    static let allTests = [
        ("testJpgPerformance", testJpgPerformance)
    ]
}
