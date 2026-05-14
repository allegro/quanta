import Vapor

final class HomeController: Sendable {
    func index(_ req: Request) async throws -> View {
        try await req.view.render("welcome")
    }
}

// MARK: - Routes

extension HomeController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        routes.get("", use: self.index)
    }
}
