import Foundation
import Vapor

import SwiftBoxLogging

private let logger = Logging.make(#file)

/// Function that is responsible for logging data included in request header "X-Debug-Info"
func logOnReceive(request: Request) {
    guard let data = request.headers.first(name: "X-Debug-Info") else {
        return
    }
    logger.info("Received file with \(data).")
}
