import CMozJpeg
import Foundation

public enum ChromaSubsampling: String {
    public typealias RawValue = String

    // depending on image type (e.g. text image), you can get much better compression with chroma settings.
    case q11 = "1x1" // best quality
    case q21 = "2x1" // medium
    case q22 = "2x2" // worst
}

public func optimizeWithMozJpeg(jpegData: Data, quality: UInt, chromaSubsampling: ChromaSubsampling) -> Data? {
    var jpegDataCopy = jpegData
    var optimizedData: Data?

    jpegDataCopy.withUnsafeMutableBytes { (rawBuffer: UnsafeMutableRawBufferPointer) in
        guard let jpegDataPtr = rawBuffer.baseAddress else { return }

        var data: UnsafeMutablePointer<Int8>?
        var size: Int = 0

        withUnsafeMutablePointer(to: &size) { sizePointer in
            let fromFile = fmemopen(jpegDataPtr, jpegData.count, "r")
            let destFile = open_memstream(&data, sizePointer)
            compressCJPEG(Int32(quality), fromFile, destFile, chromaSubsampling.rawValue)
            if fromFile != nil { fclose(fromFile) }
            if destFile != nil { fclose(destFile) }
            guard let dataPtr = data else { return }
            dataPtr.withMemoryRebound(to: UInt8.self, capacity: sizePointer.pointee) { pointer in
                optimizedData = Data(bytes: pointer, count: sizePointer.pointee)
            }
            free(data)
        }
    }
    return optimizedData
}
