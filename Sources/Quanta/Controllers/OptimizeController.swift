import Foundation
import SwiftBoxLogging
import Vapor

private let logger = Logging.make(#file)

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

final class OptimizeController: Sendable {
    private let optimizeService: OptimizeService

    init(optimizeService: OptimizeService) {
        self.optimizeService = optimizeService
    }

    private func decodePayload<T: Content>(_ type: T.Type, req: Request) throws -> T {
        logOnReceive(request: req)
        do {
            return try req.content.decode(T.self)
        } catch let error as Vapor.AbortError {
            throw error
        } catch {
            logger.warning("Bad request \(error)")
            throw Abort(.badRequest, reason: "\(error)")
        }
    }

    private func optimizeImage(for optimizeRequest: OptimizeRequestUnvalidated) throws -> OptimizeResult {
        guard optimizeRequest.imageFormat != nil else {
            throw Abort(.badRequest, reason: "Unsupported or missing image format")
        }
        guard (1...100).contains(optimizeRequest.quality) else {
            throw Abort(.badRequest, reason: "Quality must be between 1 and 100")
        }
        do {
            return try self.optimizeService.optimize(for: OptimizeRequest(request: optimizeRequest))
        } catch let error as OptimizeServiceError {
            throw Abort(.internalServerError, reason: "Error during optimization: \(error)")
        } catch {
            throw Abort(.internalServerError, reason: "Unknown error: \(error)")
        }
    }

    // MARK: - Endpoints

    func demoEndpoint(req: Request) async throws -> DemoResponse {
        let payload = try decodePayload(OptimizeRequestUnvalidated.self, req: req)
        let result = try optimizeImage(for: payload)
        return DemoResponse(
            encodedImageData: result.fileBytes,
            optimizedSize: result.afterSize,
            originalSize: result.beforeSize,
            format: result.imageFormat
        )
    }

    func proxyEndpoint(req: Request) async throws -> Response {
        let query = try req.query.decode(ProxyRequest.self)
        let clientResponse = try await req.client.get(URI(string: query.url))
        guard clientResponse.status == .ok, let buffer = clientResponse.body, let data = buffer.getData(at: 0, length: buffer.readableBytes) else {
            throw Abort(.badRequest, reason: "Invalid URL")
        }
        let result = try optimizeImage(for: OptimizeRequestUnvalidated(fileBytes: data, quality: query.quality))
        return result.httpResponse
    }

    func optimizeEndpoint(req: Request) async throws -> Response {
        let payload = try decodePayload(OptimizeRequestUnvalidated.self, req: req)
        let result = try optimizeImage(for: payload)
        return result.httpResponse
    }
}

// MARK: - Extensions

extension OptimizeResult {
    var httpResponse: Response {
        var headers = HTTPHeaders()
        headers.add(name: "X-Quanta-Ratio", value: String(format: "%.4f", self.ratio))
        headers.add(name: "Content-Type", value: self.imageFormat.rawValue)
        return Response(status: .ok, headers: headers, body: .init(data: self.fileBytes))
    }
}

// MARK: - Routes

extension OptimizeController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        routes.post("demo", "optimize", use: self.demoEndpoint)
        routes.post("optimize", "jpg", use: self.optimizeEndpoint)
        routes.get("from", use: self.proxyEndpoint)
    }
}
