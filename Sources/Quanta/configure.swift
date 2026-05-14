import Foundation
import Leaf
import Vapor

import SwiftBoxConfig
import SwiftBoxLogging
import SwiftBoxMetrics

import Logging
import Metrics

public protocol QuantaConfigurationProtocol {
    init()
    func configure(_ app: Application) async throws
}

public func configure(_ app: Application) async throws {
    try await QuantaConfiguration().configure(app)
}

open class QuantaConfiguration: QuantaConfigurationProtocol {
    public required init() {}

    open func configure(_ app: Application) async throws {
        try bootstrapConfiguration(app)

        // Use Leaf for rendering views
        app.views.use(.leaf)

        // Configure server
        app.http.server.configuration.hostname = AppConfig.global.server.host
        app.http.server.configuration.port = AppConfig.global.server.port
        app.routes.defaultMaxBodySize = ByteCount(value: AppConfig.global.optimization.maxFilesize.bytes)

        configureLogging(app)
        configureMetrics(app)
        configureMiddlewares(app)

        try configureRoutes(app)
    }

    open func configureRoutes(_ app: Application) throws {
        try routes(app)
    }

    open func getConfigurationSources(_ app: Application) -> [ConfigSource] {
        let sources: [ConfigSource] = [
            DictionarySource(dataSource: [
                "statsd": [
                    "enable": false,
                    "basePath": "stats.tech.quanta",
                ],
                "optimization": [
                    "quality": 95,
                    "speed": 1,
                    "fastCompression": false,
                    "maxFilesize": BytesAmount.megabytes(5).bytes,
                ],
                "server": [
                    "host": "0.0.0.0",
                    "port": 8080,
                ],
            ]),
            EnvSource(prefix: "quanta"),
            CommandLineSource(),
        ]

        // By default Vapor throws an error when there are custom command line options passed.
        // Filter custom arguments so Vapor won't fail on start.
        CommandLine.arguments = CommandLineSource.filterArguments(CommandLine.arguments, exclude: true)
        app.environment.arguments = CommandLineSource.filterArguments(app.environment.arguments, exclude: true)

        return sources
    }

    open func bootstrapConfiguration(_ app: Application) throws {
        guard AppConfig.configuration == nil else { return }
        try AppConfig.bootstrap(from: getConfigurationSources(app))
    }

    open func configureLogging(_ app: Application) {
        Logging.bootstrap({ _ in PrintLogger() })
    }

    open func configureMetrics(_ app: Application) {
        guard AppConfig.global.statsd.enable else { return }
        let basePath = AppConfig.global.statsd.basePath!
        let host = AppConfig.global.statsd.host!
        let port = AppConfig.global.statsd.port!
        let factory = QuantaStatsDMetricsFactory(
            baseMetricPath: basePath,
            handlerFactory: { path in
                StatsDMetricsHandler(
                    path: path,
                    client: UDPStatsDClient(config: UDPConnectionConfig(host: host, port: port))
                )
            }
        )
        MetricsSystem.bootstrap(factory)
    }

    open func configureMiddlewares(_ app: Application) {
        app.middleware = .init()
        app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
        app.middleware.use(ErrorMiddleware.default(environment: app.environment))
    }
}
