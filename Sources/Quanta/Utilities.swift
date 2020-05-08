import Foundation
import Vapor

import SwiftBoxLogging

fileprivate var logger = Logging.make(#file)

/// Function that is responsible for logging data included in request header "X-Debug-Info"
internal func logOnReceive(request: Request) {
    guard let data = request.http.headers.firstValue(name: HTTPHeaderName("X-Debug-Info")) else {
        return
    }
    logger.info("Received file with \(data).")
}
