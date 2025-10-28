import SwiftUI

@Observable
@MainActor
class AppModel {
    // Auth
    var isLoggedIn: Bool = false
    var jwtToken: String? = nil
    var refreshToken: String? = nil
    var userID: Int? = nil
    
    // App navigation state
    enum Screen {
        case login
        case projectList
        case projectDetail
        case instruction
    }
    
    var currentScreen: Screen = .login
    
    // Instruction
    var isVolumeShown: Bool = false
    var currentStepIndex: Int = 0
    var isPlaying: Bool = false
    var modelName: String? = "test5.usdz"
    var steps: [Model3DInstructionStep] = []
    
    // Data
    var projects: [Project] = []
    var selectedProject: Project? = nil
    var selectedVersionId: String?  = nil
    
    func login(jwt_token: String, refresh_token: String, userID: Int) {
        self.jwtToken = jwt_token
        self.refreshToken = refresh_token
        self.userID = userID
        self.isLoggedIn = true
        self.currentScreen = .projectList
        UserDefaults.standard.set(jwt_token, forKey: "jwt_token")
        UserDefaults.standard.set(refresh_token, forKey: "refresh_token")
    }

    func logout() {
        self.isLoggedIn = false
        self.jwtToken = nil
        self.refreshToken = nil
        self.userID = nil
        self.projects = []
        self.currentScreen = .login
        self.selectedProject = nil
        self.selectedVersionId = nil
        UserDefaults.standard.removeObject(forKey: "jwt_token")
        UserDefaults.standard.removeObject(forKey: "refresh_token")
    }
    
    @MainActor
    func checkStoredTokens() {
        guard let storedToken = UserDefaults.standard.string(forKey: "jwt_token"),
              let storedRefreshToken = UserDefaults.standard.string(forKey: "refresh_token") else {
            return
        }

        guard let payload = decodeJWT(storedToken),
              let exp = payload.exp else {
            Task { await refreshToken() }
            return
        }

        let currentTime = Date().timeIntervalSince1970
        let bufferTime: Double = 300

        if Double(exp) > currentTime + bufferTime {
            if let id = payload.id {
                login(jwt_token: storedToken, refresh_token: storedRefreshToken, userID: id)
            } else {
                Task { await refreshToken() }
            }
        } else {
            Task { await refreshToken() }
        }
    }
    
    @MainActor
    func refreshToken() async {
        guard let currentRefreshToken = UserDefaults.standard.string(forKey: "refresh_token") else {
            logout()
            return
        }

        do {
            let response = try await APIClient.shared.refreshToken(refreshToken: currentRefreshToken)
            
            if response.success {
                guard let newToken = response.jwt,
                      let newRefreshToken = response.refresh else {
                    logout()
                    return
                }
                
                guard let payload = decodeJWT(newToken),
                      let id = payload.id else {
                    logout()
                    return
                }

                login(jwt_token: newToken, refresh_token: newRefreshToken, userID: id)
                
            } else {
                logout()
            }

        } catch {
            logout()
        }
    }

    
    func selectProject(_ project: Project) {
        self.selectedProject = project
        self.currentScreen = .projectDetail
    }
    
    func selectVersion(_ versionId: String) {
        self.selectedVersionId = versionId
        self.currentScreen = .instruction
    }
    
}
