import Foundation

struct TextDetectionResult {
    let text: String
    let encoding: String.Encoding
}

/// Detects whether a file contains readable text and decodes it.
///
/// Replicates the `file --mime --brief` approach from the original qlstephen
/// but purely in-process, safe for App Extension sandboxing.
enum TextFileDetector {

    /// Read at most this many bytes. Keeps previews snappy for huge files.
    static let maxBytes = 512 * 1024  // 512 KB

    static func detect(at url: URL) -> TextDetectionResult? {
        guard url.lastPathComponent != ".DS_Store" else { return nil }

        guard let data = readData(at: url, limit: maxBytes) else { return nil }
        guard !data.isEmpty else { return TextDetectionResult(text: "", encoding: .utf8) }

        // BOM-based detection first — must come before null-byte check because
        // UTF-16/UTF-32 encoded text legitimately contains null bytes.
        if let result = detectViaBOM(data) { return result }

        // No BOM: scan the first 8 KB for null bytes. A single null is a strong
        // binary signal for non-UTF-16/32 content.
        guard !containsNullBytes(data.prefix(8192)) else { return nil }

        // Strict UTF-8 — if the file is valid UTF-8 we're done.
        if let text = String(data: data, encoding: .utf8) {
            return TextDetectionResult(text: text, encoding: .utf8)
        }

        // Lossy fall-through encodings used by legacy plain-text files.
        for encoding: String.Encoding in [.isoLatin1, .windowsCP1252, .macOSRoman] {
            if let text = String(data: data, encoding: encoding) {
                return TextDetectionResult(text: text, encoding: encoding)
            }
        }

        return nil
    }

    // MARK: - Private helpers

    private static func readData(at url: URL, limit: Int) -> Data? {
        guard let handle = try? FileHandle(forReadingFrom: url) else { return nil }
        defer { try? handle.close() }
        return handle.readData(ofLength: limit)
    }

    private static func containsNullBytes(_ data: some Sequence<UInt8>) -> Bool {
        data.contains(0)
    }

    /// Returns a result if the data starts with a recognised byte-order mark.
    private static func detectViaBOM(_ data: Data) -> TextDetectionResult? {
        // UTF-8 BOM: EF BB BF
        if data.starts(with: [0xEF, 0xBB, 0xBF]) {
            let payload = data.dropFirst(3)
            if let text = String(data: payload, encoding: .utf8) {
                return TextDetectionResult(text: text, encoding: .utf8)
            }
        }
        // UTF-32 LE BOM: FF FE 00 00  (must check before UTF-16 LE)
        if data.starts(with: [0xFF, 0xFE, 0x00, 0x00]) {
            if let text = String(data: data, encoding: .utf32LittleEndian) {
                return TextDetectionResult(text: text, encoding: .utf32LittleEndian)
            }
        }
        // UTF-32 BE BOM: 00 00 FE FF
        if data.starts(with: [0x00, 0x00, 0xFE, 0xFF]) {
            if let text = String(data: data, encoding: .utf32BigEndian) {
                return TextDetectionResult(text: text, encoding: .utf32BigEndian)
            }
        }
        // UTF-16 LE BOM: FF FE
        if data.starts(with: [0xFF, 0xFE]) {
            if let text = String(data: data, encoding: .utf16LittleEndian) {
                return TextDetectionResult(text: text, encoding: .utf16LittleEndian)
            }
        }
        // UTF-16 BE BOM: FE FF
        if data.starts(with: [0xFE, 0xFF]) {
            if let text = String(data: data, encoding: .utf16BigEndian) {
                return TextDetectionResult(text: text, encoding: .utf16BigEndian)
            }
        }
        return nil
    }
}
