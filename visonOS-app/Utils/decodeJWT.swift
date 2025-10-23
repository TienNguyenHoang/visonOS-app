import Foundation

struct JWTPayload: Codable {
    let id: Int?
    let email: String?
    let exp: Int?
}

func decodeJWT(_ token: String) -> JWTPayload? {
    let segments = token.split(separator: ".")
    guard segments.count > 1 else { return nil }

    var base64 = String(segments[1])
        .replacingOccurrences(of: "-", with: "+")
        .replacingOccurrences(of: "_", with: "/")

    while base64.count % 4 != 0 {
        base64 += "="
    }

    guard let data = Data(base64Encoded: base64),
          let payload = try? JSONDecoder().decode(JWTPayload.self, from: data) else {
        return nil
    }

    return payload
}
