import Foundation
import Vapor

struct OptimizeResult: Content {
    let fileBytes: Data
    let afterSize: Int
    let beforeSize: Int
    let imageFormat: ImageFormat
    let quality: Int
    var ratio: Float {
        return 100 - Float(afterSize * 100) / Float(beforeSize)
    }
}
