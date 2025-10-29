import Foundation

class APIClient {
    static let shared = APIClient()
    private let baseURL = "https://api.synode.ai/"
    
    private init() {}
    
    func refreshToken(refreshToken: String) async throws -> LoginResponse {
        guard let url = URL(string: "\(baseURL)/account/auth/refresh") else {
            throw APIError.invalidURL
        }
        
        let payload: [String: Any] = [
            "sent": ISO8601DateFormatter().string(from: Date()),
            "scope": "synode",
            "sender": "synode-client",
            "refreshToken": refreshToken
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload, options: [])
        } catch {
            throw APIError.encodingError
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            
            if httpResponse.statusCode == 201 {
                let refreshResponse = try JSONDecoder().decode(LoginResponse.self, from: data)
                return refreshResponse
            } else {
                print("[Refresh Token Error Response]: \(String(data: data, encoding: .utf8) ?? "N/A")")
                throw APIError.refreshTokenFailed("Refresh token failed with status code: \(httpResponse.statusCode)")
            }
            
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(error.localizedDescription)
        }
    }
    
    private func makeAuthenticatedRequest(url: URL, method: String = "POST", payload: [String: Any]? = nil) async throws -> Data {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        guard let token = UserDefaults.standard.string(forKey: "jwt_token") else {
            throw APIError.tokenExpired
        }
        
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        if let payload = payload {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload, options: [])
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
       
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        print("http response \(httpResponse.statusCode)")
        if httpResponse.statusCode == 401 {
            guard let refreshToken = UserDefaults.standard.string(forKey: "refresh_token") else {
                throw APIError.tokenExpired
            }
            
            let refreshResponse = try await self.refreshToken(refreshToken: refreshToken)
            
            if refreshResponse.success {
                if let newToken = refreshResponse.jwt {
                    UserDefaults.standard.set(newToken, forKey: "jwt_token")
                }
                if let newRefreshToken = refreshResponse.refresh {
                    UserDefaults.standard.set(newRefreshToken, forKey: "refresh_token")
                }
                
                request.setValue("Bearer \(refreshResponse.jwt!)", forHTTPHeaderField: "Authorization")
                let (retryData, retryResponse) = try await URLSession.shared.data(for: request)
                
                guard let retryHttpResponse = retryResponse as? HTTPURLResponse,
                      retryHttpResponse.statusCode == 201 || retryHttpResponse.statusCode == 200 else {
                    throw APIError.invalidResponse
                }
                return retryData
            } else {
                throw APIError.tokenExpired
            }
        }

        guard httpResponse.statusCode == 201 || httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }
        
        return data
    }
    
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
            
            if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
                let loginResponse = try JSONDecoder().decode(LoginResponse.self, from: data)
                return loginResponse
            } else {
                print("[Login Error Response]: \(String(data: data, encoding: .utf8) ?? "N/A")")
                
                if let outer = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let messageString = outer["message"] as? String {
                    if let nestedData = messageString.data(using: .utf8),
                       let nestedJson = try? JSONSerialization.jsonObject(with: nestedData, options: []) as? [String: Any] {
                        if let messages = nestedJson["message"] as? [String] {
                            let combined = messages.joined(separator: "\n• ")
                            throw APIError.loginFailed("• " + combined)
                        }
                        else if let msg = nestedJson["message"] as? String {
                            throw APIError.loginFailed(msg)
                        }
                        else {
                            throw APIError.loginFailed("Bad Request.")
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
    
    func fetchProjects(for userId: Int) async throws -> [Project] {
        guard let url = URL(string: "\(baseURL)/catalog/items/find") else {
            throw APIError.invalidURL
        }
        
        let payload: [String: Any] = [
            "sender": "synode-client",
            "scope": "synode",
            "sent": ISO8601DateFormatter().string(from: Date()),
            "data": [
                "where": ["user": userId]
            ]
        ]
        
        do {
            let data = try await makeAuthenticatedRequest(url: url, payload: payload)
            
            let decoded = try JSONDecoder().decode(ProjectResponse.self, from: data)
            guard let items = decoded.data?.items else {
                throw APIError.invalidResponse
            }
            return items
        } catch {
            throw APIError.invalidResponse
        }
    }
    
    func fetchInstructionDetails(for projectId: String) async throws -> [InstructionDetail] {
            guard let url = URL(string: "\(baseURL)/instruction/displays/find") else {
                throw APIError.invalidURL
            }
            print("project id \(projectId)")
            let payload: [String: Any] = [
                "sender": "synode-client",
                "scope": "synode",
                "sent": ISO8601DateFormatter().string(from: Date()),
                "data": [
                    "where": ["target": projectId]
                ]
            ]
            
            do {
                let data = try await makeAuthenticatedRequest(url: url, payload: payload)
                let decoded = try JSONDecoder().decode(ProjectDetailResponse.self, from: data)
                guard let items = decoded.data?.items else {
                    throw APIError.invalidResponse
                }
                
                print("Loaded \(items.count) instruction(s) for project \(projectId)")
                return items
            } catch {
                print("[Instruction Fetch Error]: \(error.localizedDescription)")
                throw APIError.invalidResponse
            }
        }
    
    func fetchAssembler(by id: String) async throws -> AssemblerModel {
            guard let url = URL(string: "\(baseURL)/instruction/assemblers/read") else {
                throw APIError.invalidURL
            }

            let payload: [String: Any] = [
                "sender": "synode-client",
                "scope": "synode",
                "sent": ISO8601DateFormatter().string(from: Date()),
                "data": [
                    "where": ["_id": id]
                ]
            ]

            do {
                let data = try await makeAuthenticatedRequest(url: url, payload: payload)
                let decoded = try JSONDecoder().decode(AssemblerReadResponse.self, from: data)
                guard let item = decoded.data else {
                    throw APIError.invalidResponse
                }
                return item
            } catch {
                print("[Assembler Read Error]: \(error.localizedDescription)")
                throw APIError.invalidResponse
            }
        }
    
    func fetchAndDecodeAnimation(from urlString: String) async throws -> AnimationModel {
            guard let url = URL(string: urlString) else {
                throw APIError.invalidURL
            }

            let (compressedData, response) = try await URLSession.shared.data(from: url)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else {
                throw APIError.invalidResponse
            }

            guard let decompressedData = compressedData.gunzipped() else {
                throw APIError.invalidResponse
            }

            do {
                let decoded = try JSONDecoder().decode(AnimationModel.self, from: decompressedData)
                return decoded
            } catch {
                print("[Animation Decode Error]: \(error)")
                throw APIError.encodingError
            }
        }
}

enum APIError: Error, LocalizedError {
    case invalidURL
    case encodingError
    case invalidResponse
    case loginFailed(String)
    case networkError(String)
    case tokenExpired
    case refreshTokenFailed(String)
    
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
            case .tokenExpired:
                return "Token expired. Please login again."
            case .refreshTokenFailed(let message):
                return "Refresh token failed: \(message)"
        }
    }
}
