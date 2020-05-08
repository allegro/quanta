import Foundation
import Vapor

struct OptimizeRequestUnvalidated {
    let fileBytes: Data
    let quality: Int
    let imageFormat: ImageFormat?

    init(fileBytes: Data, quality: Int) {
        self.fileBytes = fileBytes
        self.quality = quality
        self.imageFormat = detectImageFormat(from: fileBytes)
    }
}

extension OptimizeRequestUnvalidated: Content {
    enum CodingKeys: String, CodingKey {
        case fileBytes
        case quality
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let fileBytes: Data = try container.decode(Data.self, forKey: .fileBytes)
        let quality: Int = try container.decode(Int.self, forKey: .quality)

        self.init(fileBytes: fileBytes, quality: quality)
    }
}

// MARK: - Validatable conformance

extension OptimizeRequestUnvalidated: Validatable {
    static func validations() throws -> Validations<OptimizeRequestUnvalidated> {
        var validations = Validations(OptimizeRequestUnvalidated.self)
        validations.add(\.quality, at: ["quality"], "invalid value") { quality throws in
            if !(1 ... 100).contains(quality) {
                throw BasicValidationError("is incorrect, must be between 1 and 100 not \(quality)")
            }
        }
        validations.add(\.imageFormat, at: ["imageFormat"], "invalid format") { imageFormat throws in
            guard imageFormat != nil else {
                throw BasicValidationError("is not supported")
            }
        }
        return validations
    }
}

struct OptimizeRequest {
    let fileBytes: Data
    let quality: Int
    let imageFormat: ImageFormat

    init(request: OptimizeRequestUnvalidated) {
        self.fileBytes = request.fileBytes
        self.quality = request.quality
        self.imageFormat = request.imageFormat!
    }
}
