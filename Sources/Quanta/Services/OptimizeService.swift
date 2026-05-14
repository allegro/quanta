import Foundation
import Metrics
import Vapor

import SwiftBoxLogging
import SwiftBoxMetrics

private let logger = Logging.make(#file)

public enum OptimizeServiceError: Swift.Error {
    case BadData(argument: String)
    case OptimizationError(argument: String)
    case UnknownError
}

final class OptimizeService: Sendable {
    init() {}

    static func optimizeJpeg(from request: OptimizeRequest) throws -> OptimizeResult {
        let inputImage = request.fileBytes
        let inputImageSize = inputImage.count

        guard let optimizedImage: Data = optimizeWithMozJpeg(
            jpegData: inputImage,
            quality: UInt(request.quality),
            chromaSubsampling: .q11
        ) else {
            throw OptimizeServiceError.BadData(argument: "Cannot convert input data!")
        }
        let optimizedImageSize = optimizedImage.count
        return OptimizeResult(
            fileBytes: optimizedImage,
            afterSize: optimizedImageSize,
            beforeSize: inputImageSize,
            imageFormat: request.imageFormat,
            quality: request.quality
        )
    }

    func optimize(for optimizationRequest: OptimizeRequest) throws -> OptimizeResult {
        let metricName = getMetricName(imageFormat: optimizationRequest.imageFormat)
        let timer = Metrics.Timer(label: metricName)
        let start = DispatchTime.now()
        let result: OptimizeResult
        do {
            switch optimizationRequest.imageFormat {
            case .jpg:
                result = try OptimizeService.optimizeJpeg(from: optimizationRequest)
            }
        } catch {
            timer.recordNanoseconds(Int64(DispatchTime.now().uptimeNanoseconds - start.uptimeNanoseconds))
            throw error
        }
        timer.recordNanoseconds(Int64(DispatchTime.now().uptimeNanoseconds - start.uptimeNanoseconds))

        logger.info(
            "Optimized \(optimizationRequest.imageFormat.rawValue.uppercased()) " +
                "image from size: \(result.beforeSize) " +
                "to size: \(result.afterSize), " +
                "size reduction is: \(result.ratio) % "
        )
        return result
    }

    private func getMetricName(imageFormat: ImageFormat) -> String {
        let imageFormatMetricName = imageFormat.rawValue.replacingOccurrences(of: "/", with: "_")
        return "optimize_\(imageFormatMetricName)_finished_time"
    }
}
