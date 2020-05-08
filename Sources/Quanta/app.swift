import Vapor

/// Creates an instance of Application. This is called from main.swift in the run target.
public func app(_ env: Environment, configurationClass: QuantaConfigurationProtocol.Type = QuantaConfiguration.self) throws -> Application {
    var config = Config.default()
    var env = env
    var services = Services.default()

    try configurationClass.init().configure(&config, &env, &services)

    let app = try Application(config: config, environment: env, services: services)
    try boot(app)

    return app
}
