import Foundation
import Leaf
import Vapor

import SwiftBoxConfig
import SwiftBoxLogging
import SwiftBoxMetrics

public protocol QuantaConfigurationProtocol {
    init()
    func configure(_ config: inout Config, _ env: inout Environment, _ services: inout Services) throws
}

open class QuantaConfiguration: QuantaConfigurationProtocol {
    public required init() {}

    open func configure(_ config: inout Config, _ env: inout Environment, _ services: inout Services) throws {
        /// Register providers first
        try bootstrapConfiguration(&config, &env, &services)

        try services.register(LeafProvider())

        services.register { _ -> ContentConfig in
            return ContentConfig.default()
        }

        // Set max size for requests
        services.register(
            NIOServerConfig.default(
                hostname: AppConfig.global.server.host,
                port: AppConfig.global.server.port,
                maxBodySize: AppConfig.global.optimization.maxFilesize.bytes
            )
        )

        /// Register routes to the router
        services.register(Router.self) { _ -> EngineRouter in
            let router = EngineRouter.default()
            try self.configureRoutes(router: router)
            return router
        }

        configureLogging(&config, &env, &services)
        configureMetrics(&config, &env, &services)

        /// Use Leaf for rendering views
        config.prefer(LeafRenderer.self, for: ViewRenderer.self)

        configureMiddlewares(&config, &env, &services)
    }

    open func configureRoutes(router: Router) throws {
        try routes(router)
    }

    open func getConfigurationSources(_: inout Config, _ env: inout Environment, _: inout Services) -> [ConfigSource] {
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

        // By default vapor throws an error, when there is custom commandline options passed.
        // Filter custom arguments so Vapor won't fail on start
        CommandLine.arguments = CommandLineSource.filterArguments(CommandLine.arguments, exclude: true)
        env.arguments = CommandLineSource.filterArguments(env.arguments, exclude: true)

        return sources
    }

    open func bootstrapConfiguration(_ config: inout Config, _ env: inout Environment, _ services: inout Services) throws {
        try AppConfig.bootstrap(from: getConfigurationSources(&config, &env, &services))
    }

    open func configureLogging(_ config: inout Config, _: inout Environment, _: inout Services) {
        config.prefer(PrintLogger.self, for: Logger.self)
        Logging.bootstrap({ _ in PrintLogger() })
    }

    open func configureMetrics(_: inout Config, _: inout Environment, _: inout Services) {
        if AppConfig.global.statsd.enable {
            Metrics.bootstrap(
                try! StatsDMetricsHandler(
                    baseMetricPath: AppConfig.global.statsd.basePath!,
                    client: UDPStatsDClient(
                        config: UDPConnectionConfig(
                            host: AppConfig.global.statsd.host!,
                            port: AppConfig.global.statsd.port!
                        )
                    )
                )
            )
        }
    }

    open func getMiddlewares(_: inout Config, _: inout Environment, _: inout Services) -> MiddlewareConfig {
        var middlewares = MiddlewareConfig()
        middlewares.use(FileMiddleware.self) // Serves files from `Public/` directory
        middlewares.use(ErrorMiddleware.self) // Catches errors and converts to HTTP response

        return middlewares
    }

    open func configureMiddlewares(_ config: inout Config, _ env: inout Environment, _ services: inout Services) {
        services.register(getMiddlewares(&config, &env, &services))
    }
}
