import Vapor

final class HomeController {
    func index(_ req: Request) throws -> Future<View> {
        return try req.view().render("welcome")
    }
}

// MARK: - Routes

extension HomeController: RouteCollection {
    func boot(router: Router) throws {
        router.get("/", use: self.index)
    }
}
