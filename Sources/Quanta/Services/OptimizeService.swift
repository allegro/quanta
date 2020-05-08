import Foundation
import Vapor

import SwiftBoxLogging
import SwiftBoxMetrics

fileprivate var logger = Logging.make(#file)

public enum OptimizeServiceError: Swift.Error {
    case BadData(argument: String)
    case OptimizationError(argument: String)
    case UnknownError
}

public final class OptimizeService {
    class func optimizeJpeg(from request: OptimizeRequest) throws -> OptimizeResult {
        let inputImage = request.fileBytes
        let inputImageSize = inputImage.count

        guard let optimizedImage: Data = optimizeWithMozJpeg(jpegData: inputImage, quality: UInt(request.quality), chromaSubsampling: .q11) else {
            throw OptimizeServiceError.BadData(argument: "Cannot convert input data!")
        }
        let optimizedImageSize = optimizedImage.count
        return OptimizeResult(fileBytes: optimizedImage, afterSize: optimizedImageSize, beforeSize: inputImageSize, imageFormat: request.imageFormat, quality: request.quality)
    }

    func optimize(for optimizationRequest: OptimizeRequest) throws -> OptimizeResult {
        let metricName = getMetricName(imageFormat: optimizationRequest.imageFormat)

        let optimizationResult = try Metrics.global.withTimer(name: metricName) { () -> OptimizeResult in
            switch optimizationRequest.imageFormat {
            case .jpg:
                return try OptimizeService.optimizeJpeg(from: optimizationRequest)
            }
        }

        logger.info(
            "Optimized \(optimizationRequest.imageFormat.rawValue.uppercased()) " +
                "image from size: \(optimizationResult.beforeSize) " +
                "to size: \(optimizationResult.afterSize), " +
                "size reduction is: \(optimizationResult.ratio) % "
        )
        return optimizationResult
    }

    private func getMetricName(imageFormat: ImageFormat) -> String {
        let imageFormatMetricName = imageFormat.rawValue.replacingOccurrences(of: "/", with: "_")
        let metricName = "optimize_\(imageFormatMetricName)_finished_time"
        return metricName
    }
}
