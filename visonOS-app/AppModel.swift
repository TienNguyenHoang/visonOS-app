import SwiftUI

/// Maintains app-wide state
@Observable
@MainActor
class AppModel {
    // Auth
    var isLoggedIn: Bool = false
    var userEmail: String = ""
    var jwtToken: String? = nil
    var refreshToken: String? = nil
    var userID: Int? = nil
    
    // App navigation state
    enum Screen {
        case login
        case projectList
        case projectDetail
        case instruction
        case model3D
    }
    
    var currentScreen: Screen = .login

    // Data
    var projects: [Project] = []
    var selectedProject: Project? = nil
    var selectedInstructionId: Int?  = nil
    
    func login(token: String, userID: Int) {
        self.jwtToken = token
        self.userID = userID
        self.isLoggedIn = true
        self.currentScreen = .projectList
    }

    func logout() {
        self.isLoggedIn = false
        self.jwtToken = nil
        self.userID = nil
        self.projects = []
        self.currentScreen = .login
        UserDefaults.standard.removeObject(forKey: "auth_token")
        UserDefaults.standard.removeObject(forKey: "refresh_token")
        jwtToken = nil
        refreshToken = nil
        userID = nil
    }
    
    func checkStoredTokens() {
        if let storedToken = UserDefaults.standard.string(forKey: "auth_token"),
           let storedRefreshToken = UserDefaults.standard.string(forKey: "refresh_token") {
            
            // Check if token is still valid
            if let payload = decodeJWT(storedToken),
               let exp = payload.exp {
                let currentTime = Date().timeIntervalSince1970
                
                // If token expires in more than 5 minutes, use it
                if Double(exp) > currentTime + 300 {
                    jwtToken = storedToken
                    refreshToken = storedRefreshToken
                    isLoggedIn = true
                    
                    if let id = payload.id {
                        userID = id
                    }
                    return
                }
            }
            
            // Token expired, try refresh
            Task {
                await refreshTokenIfNeeded()
            }
        }
    }
    
    @MainActor
    func refreshTokenIfNeeded() async {
        guard let currentRefreshToken = UserDefaults.standard.string(forKey: "refresh_token") else {
            logout()
            return
        }
        
        do {
            let response = try await APIClient.shared.refreshToken(refreshToken: currentRefreshToken)
            
            if response.success {
                if let newToken = response.jwt {
                    UserDefaults.standard.set(newToken, forKey: "auth_token")
                    jwtToken = newToken
                    
                    if let payload = decodeJWT(newToken),
                       let id = payload.id {
                        userID = id
                    }
                }
                
                if let newRefreshToken = response.refresh {
                    UserDefaults.standard.set(newRefreshToken, forKey: "refresh_token")
                    refreshToken = newRefreshToken
                }
                
                isLoggedIn = true
            } else {
                logout()
            }
        } catch {
            print("Failed to refresh token: \(error)")
            logout()
        }
    }
    
    func selectProject(_ project: Project) {
        self.selectedProject = project
        self.currentScreen = .projectDetail
    }
    
    func selectInstruction(_ instructionId: Int) {
        self.selectedInstructionId = instructionId
        self.currentScreen = .instruction
    }

    func openModel3D() {
        self.currentScreen = .model3D
    }
    
}
