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

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(fileBytes, forKey: .fileBytes)
        try container.encode(quality, forKey: .quality)
    }
}

// MARK: - Validatable conformance

extension OptimizeRequestUnvalidated: Validatable {
    static func validations(_ validations: inout Validations) {
        validations.add("quality", as: Int.self, is: .range(1...100), required: true)
        validations.add("fileBytes", as: Data.self, required: true)
    }
}

struct OptimizeRequest {
    let fileBytes: Data
    let quality: Int
    let imageFormat: ImageFormat

    init(request: OptimizeRequestUnvalidated) throws {
        guard let format = request.imageFormat else {
            throw Abort(.badRequest, reason: "Unsupported image format")
        }
        self.fileBytes = request.fileBytes
        self.quality = request.quality
        self.imageFormat = format
    }

    init(fileBytes: Data, quality: Int, imageFormat: ImageFormat) {
        self.fileBytes = fileBytes
        self.quality = quality
        self.imageFormat = imageFormat
    }
}
