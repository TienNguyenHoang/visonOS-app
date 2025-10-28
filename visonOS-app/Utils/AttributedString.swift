import Foundation
import SwiftUI

extension String {
    /// Chuyển HTML string thành AttributedString (SwiftUI). Trả về nil nếu thất bại.
    func htmlToAttributedString() -> AttributedString? {
        guard let data = self.data(using: .utf8) else { return nil }
        do {
            let ns = try NSAttributedString(
                data: data,
                options: [
                    .documentType: NSAttributedString.DocumentType.html,
                    .characterEncoding: String.Encoding.utf8.rawValue
                ],
                documentAttributes: nil
            )
            return try AttributedString(ns, including: \.uiKit) // macOS / iOS compatible
        } catch {
            print("⚠️ HTML -> AttributedString error:", error)
            return nil
        }
    }

    /// Nếu chỉ muốn strip HTML tags (fallback)
    func stripHTML() -> String {
        guard let data = self.data(using: .utf8) else { return self }
        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
        ]
        if let attr = try? NSAttributedString(data: data, options: options, documentAttributes: nil) {
            return attr.string
        }
        return self
    }
}
