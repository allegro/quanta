import Vapor

public func routes(_ router: Router) throws {
    let optimizeService = OptimizeService()
    let homeController = HomeController()
    try router.register(collection: homeController)
    try router.register(collection: OptimizeController(optimizeService: optimizeService))
}
