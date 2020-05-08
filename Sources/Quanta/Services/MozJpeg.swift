import CMozJpeg
import Foundation

public enum ChromaSubsampling: String {
    public typealias RawValue = String

    // depending on image type(text image?), you can get much better compression with chroma settings.
    case q11 = "1x1" // best quality
    case q21 = "2x1" // medium
    case q22 = "2x2" // worst
}

public func optimizeWithMozJpeg(jpegData: Data, quality: UInt, chromaSubsampling: ChromaSubsampling) -> Data? {
    var optimizedData: Data?

    guard #available(OSX 10.13, *) else {
        fatalError("MacOS 10.13 is required to run this function")
    }
    var jpegDataCopy = jpegData

    jpegDataCopy.withUnsafeMutableBytes { (jpegDataPtr: UnsafeMutablePointer<UInt8>) in

        var data: UnsafeMutablePointer<Int8>?
        var size: Int = 0

        withUnsafeMutablePointer(to: &size, { sizePointer in
            let fromFile = fmemopen(jpegDataPtr, jpegData.count, "r")
            let destFile = open_memstream(&data, sizePointer)
            compressCJPEG(Int32(quality), fromFile, destFile, chromaSubsampling.rawValue)
            data!.withMemoryRebound(to: UInt8.self, capacity: sizePointer.pointee) { (pointer: UnsafeMutablePointer<UInt8>) in
                defer {
                    pointer.deallocate()
                }
                optimizedData = Data(bytes: pointer, count: sizePointer.pointee)
            }
        })
    }
    return optimizedData
}
