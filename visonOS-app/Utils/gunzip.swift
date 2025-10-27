import Foundation
import Compression

extension Data {
    func gunzipped() -> Data? {
        guard !self.isEmpty else { return nil }

        return self.withUnsafeBytes { (sourcePointer: UnsafeRawBufferPointer) in
            guard let sourceBaseAddress = sourcePointer.baseAddress else { return nil }

            let bufferSize = self.count * 4
            let destinationBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
            defer { destinationBuffer.deallocate() }

            let decompressedSize = compression_decode_buffer(
                destinationBuffer,
                bufferSize,
                sourceBaseAddress.assumingMemoryBound(to: UInt8.self),
                self.count,
                nil,
                COMPRESSION_ZLIB
            )

            guard decompressedSize > 0 else { return nil }

            return Data(bytes: destinationBuffer, count: decompressedSize)
        }
    }
}
