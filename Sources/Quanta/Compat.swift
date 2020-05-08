import CoreFoundation
import Foundation

/**
 Creates c-compatible list of strings, living during execution of the given closure.

 - Attention: Don't free it manually, it will be fred automatically when
 done with the closure.

 - parameters:
 - args: list of strings to convert
 - body: execution closure where given c-array lives in
 */
public func withArrayOfCStrings<R>(
    _ args: [String],
    _ body: ([UnsafeMutablePointer<CChar>?]) -> R
) -> R {
    var cStrings = args.map { strdup($0) }
    cStrings.append(nil)
    defer {
        cStrings.forEach { free($0) }
    }
    return body(cStrings)
}
