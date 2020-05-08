import Foundation
import Vapor

import SwiftBoxConfig

public struct AppConfig: Configuration {
    let statsd: StatsDConfiguration
    let optimization: OptimizationConfiguration
    let server: ServerConfiguration
}

extension AppConfig: ConfigManager {
    public static var configuration: AppConfig?
}

public struct StatsDConfiguration: Configuration {
    var enable: Bool
    let basePath: String?
    let host: String?
    let port: Int?
}

public struct ServerConfiguration: Configuration {
    var host: String
    let port: Int
}

public struct OptimizationConfiguration: Configuration {
    var quality: Int
    let speed: Int
    let fastCompression: Bool
    let maxFilesize: BytesAmount
}

public struct BytesAmount {
    public typealias Value = Int
    public let bytes: Value

    private init(_ bytes: Value) {
        self.bytes = bytes
    }

    public static func bytes(_ amount: Value) -> BytesAmount {
        return BytesAmount(amount)
    }

    public static func kilobytes(_ amount: Value) -> BytesAmount {
        return BytesAmount(amount * 1024)
    }

    public static func megabytes(_ amount: Value) -> BytesAmount {
        return BytesAmount(amount * 1024 * 1024)
    }
}

extension BytesAmount: Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.bytes = try container.decode(Int.self)
    }
}
