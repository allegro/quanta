import Quanta
import SwiftBoxLogging

fileprivate let loggerMain = Logging.make("main")
loggerMain.info("Startup...")

try app(.detect()).run()
