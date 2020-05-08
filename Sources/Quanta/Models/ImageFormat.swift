import Foundation

let pngHeader = Data(bytes: [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])
let jpegHeader = Data(bytes: [0xFF, 0xD8])

enum ImageFormat: String {
    case jpg = "image/jpeg"
}

extension ImageFormat: Codable {}

func detectImageFormat(from data: Data) -> ImageFormat? {
    if data.subdata(in: data.startIndex ..< data.startIndex + jpegHeader.count) == jpegHeader {
        return .jpg
    }
    if data.subdata(in: data.startIndex ..< data.startIndex + pngHeader.count) == pngHeader {
        // It's png but currently there is no support for this type of file, so return nil
        return nil
    }
    return nil
}
