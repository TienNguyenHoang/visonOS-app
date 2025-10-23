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

// MARK: - API Service
class APIClient {
    static let shared = APIClient()
    private let baseURL = "https://rc-api.synode.ai"
    
    private init() {}
    
    func login(email: String, password: String) async throws -> LoginResponse {
        guard let url = URL(string: "\(baseURL)/account/auth/login") else {
            throw APIError.invalidURL
        }
        
        let loginRequest = LoginRequest(
            scope: "synode",
            email: email,
            password: password
        )
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONEncoder().encode(loginRequest)
        } catch {
            throw APIError.encodingError
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            
            if httpResponse.statusCode == 201 {
                let loginResponse = try JSONDecoder().decode(LoginResponse.self, from: data)
                return loginResponse
            } else {
                // Try to decode error response for different formats
                if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let message = json["message"] as? String {
                    // Handle nested error message
                    if let nestedJson = message.data(using: .utf8),
                       let nestedError = try? JSONSerialization.jsonObject(with: nestedJson, options: []) as? [String: Any],
                       let nestedMessage = nestedError["message"] as? String {
                        throw APIError.loginFailed(nestedMessage)
                    } else {
                        throw APIError.loginFailed(message)
                    }
                } else if let errorResponse = try? JSONDecoder().decode(LoginResponse.self, from: data) {
                    print("test1")
                    throw APIError.loginFailed("Login failed")
                } else {
                    throw APIError.loginFailed("Login failed with status code: \(httpResponse.statusCode)")
                }
            }
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(error.localizedDescription)
        }
    }
}

// MARK: - API Errors
enum APIError: Error, LocalizedError {
    case invalidURL
    case encodingError
    case invalidResponse
    case loginFailed(String)
    case networkError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .encodingError:
            return "Failed to encode request"
        case .invalidResponse:
            return "Invalid response"
        case .loginFailed(let message):
            return message
        case .networkError(let message):
            return "Network error: \(message)"
        }
    }
}
