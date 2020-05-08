import Foundation
import SwiftBoxLogging
import Vapor

fileprivate var logger = Logging.make(#file)

struct ProxyRequest: Content {
    let quality: Int
    let url: String
}

struct DemoResponse: Content {
    let encodedImageData: Data
    let optimizedSize: Int
    let originalSize: Int
    let format: ImageFormat
}

final class OptimizeController {
    private let optimizeService: OptimizeService

    init(optimizeService: OptimizeService) {
        self.optimizeService = optimizeService
    }

    private func decodePayload<T: Content>(
        responseType _: T.Type,
        req: Request
    ) throws -> Future<T> {
        logOnReceive(request: req)
        return try req.content.decode(T.self).map { request in
            request
        }.catchMap { error in
            if let multipartError = error as? MultipartError {
                logger.warning("Bad request \(multipartError)")
                throw Abort(.badRequest, reason: multipartError.reason)
            } else {
                logger.error("Unhandled error \(error)")
                throw Abort(.internalServerError, reason: "Internal error")
            }
        }
    }

    private func optimizeImage(for optimizeRequest: OptimizeRequestUnvalidated, rawRequest _: Request) throws -> OptimizeResult {
        try optimizeRequest.validate()
        do {
            return try self.optimizeService.optimize(for: OptimizeRequest(request: optimizeRequest))
        } catch let error as OptimizeServiceError {
            throw Abort(.internalServerError, reason: "Error during optimization: \(error)")
        } catch {
            throw Abort(.internalServerError, reason: "Unknown error: \(error)")
        }
    }

    // MARK: - Endpoints

    func demoEndpoint(req: Request) throws -> Future<DemoResponse> {
        return try self.decodePayload(responseType: OptimizeRequestUnvalidated.self, req: req).map { request -> DemoResponse in
            let optimizationResult = try self.optimizeImage(for: request, rawRequest: req)
            return DemoResponse(
                encodedImageData: optimizationResult.fileBytes,
                optimizedSize: optimizationResult.afterSize,
                originalSize: optimizationResult.beforeSize,
                format: optimizationResult.imageFormat
            )
        }
    }

    func proxyEndpoint(req: Request) throws -> Future<HTTPResponse> {
        let query = try req.query.decode(ProxyRequest.self)
        return try req.client().get(query.url).map(to: Data.self) { response -> Data in
            if response.http.status == HTTPResponseStatus.ok {
                if let data = response.http.body.data {
                    return data
                }
            }
            throw Abort(.badRequest, reason: "Invalid URL")
        }.map { data -> HTTPResponse in
            let result = try self.optimizeImage(for: OptimizeRequestUnvalidated(fileBytes: data, quality: query.quality), rawRequest: req)
            return result.httpResponse
        }
    }

    func optimizeEndpoint(req: Request) throws -> Future<HTTPResponse> {
        return try self.decodePayload(responseType: OptimizeRequestUnvalidated.self, req: req).map { request -> HTTPResponse in
            let result = try self.optimizeImage(for: request, rawRequest: req)
            return result.httpResponse
        }
    }
}

// MARK: - Extensions

extension OptimizeResult {
    var httpResponse: HTTPResponse {
        let headers = HTTPHeaders([
            ("X-Quanta-Ratio", String(format: "%.4f", self.ratio)),
            ("Content-Type", self.imageFormat.rawValue),
        ])
        return HTTPResponse(status: .ok, headers: headers, body: Data(self.fileBytes))
    }
}

// MARK: - Routes

extension OptimizeController: RouteCollection {
    func boot(router: Router) throws {
        router.post("demo", "optimize", use: self.demoEndpoint)
        router.post("optimize", "jpg", use: self.optimizeEndpoint)
        router.get("from", use: self.proxyEndpoint)
    }
}
