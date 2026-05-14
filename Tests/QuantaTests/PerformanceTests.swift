import XCTest
import Vapor
import XCTVapor

@testable import Quanta

struct PerformanceSample {
    let quality: Int
    let size: Int
    let ratio: Float
    let elapsedTime: Int
}

final class PerformanceTests: XCTestCase {
    var app: Application!

    override func setUp() async throws {
        app = try await Application.testable()
    }

    override func tearDown() async throws {
        try await app.asyncShutdown()
        app = nil
    }

    private func makePerformanceSample(quality: Int, filename: String) async throws -> PerformanceSample {
        let file = getFixture(fileNamePath: filename)
        let (headers, body) = makeMultipartBody(quality: quality, fileBytes: file)
        var sample = PerformanceSample(quality: quality, size: 0, ratio: 0, elapsedTime: 0)
        let start = DispatchTime.now()
        try await app.test(.POST, "/optimize/jpg", headers: headers, body: body) { res async in
            let end = DispatchTime.now()
            let size = Int(res.headers.first(name: "content-length") ?? "0") ?? 0
            let ratio = Float(res.headers.first(name: "X-Quanta-Ratio") ?? "0") ?? 0
            let elapsedTime = Int((end.uptimeNanoseconds - start.uptimeNanoseconds) / 1_000_000)
            sample = PerformanceSample(quality: quality, size: size, ratio: ratio, elapsedTime: elapsedTime)
        }
        return sample
    }

    func testJpgPerformance() async throws {
        let qualityList = [65, 70, 75, 80, 85, 90]
        let files = ["typical_banner_1.jpg", "typical_banner_2.jpg", "typical_banner_3.jpg"]
        for filename in files {
            print("### \(filename)")
            print("Quality | Size kb | Ratio | Elapsed ms")
            for q in qualityList {
                let s = try await makePerformanceSample(quality: q, filename: filename)
                let ratio = String(format: "%.1f", s.ratio)
                print("\(s.quality) | \(s.size / 1024) | \(ratio)% | \(s.elapsedTime)")
            }
        }
    }
}
