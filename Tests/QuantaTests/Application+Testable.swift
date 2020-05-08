import Vapor
@testable import Quanta


internal extension Application {
    static func testable(args: [String]) throws -> Application {
        var config = Config.default()
        var services = Services.default()
        var env = Environment.testing
        env.arguments = args

        try QuantaConfiguration().configure(&config, &env, &services)

        let app = try Application(config: config, environment: env, services: services)
        try Quanta.boot(app)
        return app
    }

    func sendRequest(request: Request) throws -> Response {
        let responder = try self.make(Responder.self)
        return try responder.respond(to: request).wait()
    }

    func sendRequest(request: HTTPRequest) throws -> Response {
        return try sendRequest(request: Request(http: request, using: self))
    }

    func sendRequest(at path: String, to method: HTTPMethod = .GET, headers: HTTPHeaders = [:]) throws -> Response {
        let request = HTTPRequest(method: method, url: URL(string: path)!, headers: headers)
        let wrappedRequest = Request(http: request, using: self)
        return try sendRequest(request: wrappedRequest)
    }
}
