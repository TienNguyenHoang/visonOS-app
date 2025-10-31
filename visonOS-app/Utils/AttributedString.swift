import Foundation
import SwiftUI

extension String {
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
            return try AttributedString(ns, including: \.uiKit)
        } catch {
            print("HTML -> AttributedString error:", error)
            return nil
        }
    }
}
