import Quanta
import SwiftBoxLogging
import Vapor

let loggerMain = Logging.make("main")
loggerMain.info("Startup...")

var env = try Environment.detect()
let app = try await Application.make(env)
do {
    try await configure(app)
    try await app.execute()
} catch {
    app.logger.report(error: error)
    try? await app.asyncShutdown()
    throw error
}
try await app.asyncShutdown()
