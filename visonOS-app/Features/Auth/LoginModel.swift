import Foundation

struct LoginRequest: Codable {
    let scope: String
    let email: String
    let password: String
}

struct LoginResponse: Codable {
    let jwt: String?
    let refresh: String?
    let firstTimeLogin: Bool?
    
    var success: Bool { jwt != nil }
    var token: String? { jwt }
}

struct User: Codable {
    let id: String?
    let email: String?
    let name: String?
}
