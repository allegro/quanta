import Vapor

public func routes(_ app: Application) throws {
    let optimizeService = OptimizeService()
    let homeController = HomeController()
    try app.register(collection: homeController)
    try app.register(collection: OptimizeController(optimizeService: optimizeService))
}
