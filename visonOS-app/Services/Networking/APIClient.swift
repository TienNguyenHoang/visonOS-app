import Foundation

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
                print("❌ [Login Error Response]: \(String(data: data, encoding: .utf8) ?? "N/A")")
                
                // Parse JSON ngoài cùng
                if let outer = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let messageString = outer["message"] as? String {
                    // Parse JSON lồng bên trong
                    if let nestedData = messageString.data(using: .utf8),
                       let nestedJson = try? JSONSerialization.jsonObject(with: nestedData, options: []) as? [String: Any] {
                        // Nếu có mảng message
                        if let messages = nestedJson["message"] as? [String] {
                            let combined = messages.joined(separator: "\n• ")
                            throw APIError.loginFailed("• " + combined)
                        }
                        // Nếu chỉ có message đơn
                        else if let msg = nestedJson["message"] as? String {
                            throw APIError.loginFailed(msg)
                        }
                        // Nếu không có message rõ ràng
                        else {
                            throw APIError.loginFailed("Yêu cầu không hợp lệ (Bad Request).")
                        }
                    } else {
                        throw APIError.loginFailed(messageString)
                    }
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
    func fetchProjects(for userId: Int, token: String) async throws -> [Project] {
            guard let url = URL(string: "\(baseURL)/instruction/master_project/find") else {
                throw APIError.invalidURL
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            print("token nè \(token)")
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

            let payload: [String: Any] = [
                "sender": "synode-client",
                "scope": "synode",
                "sent": ISO8601DateFormatter().string(from: Date()),
                "data": [
                    "where": ["user": userId]
                ]
            ]
            
            request.httpBody = try JSONSerialization.data(withJSONObject: payload, options: [])

            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 201 else {
                throw APIError.invalidResponse
            }
            print("data nè:  \(data)")
            do {
                let decoded = try JSONDecoder().decode(ProjectResponse.self, from: data)
                guard let items = decoded.data?.items else {
                    throw APIError.invalidResponse
                }
                return items
            } catch {
                throw APIError.invalidResponse
            }
        }
}

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
