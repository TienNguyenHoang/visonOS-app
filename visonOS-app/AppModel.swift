import SwiftUI

/// Maintains app-wide state
@Observable
@MainActor
class AppModel {
    let immersiveSpaceID = "ImmersiveSpace"

    enum ImmersiveSpaceState {
        case closed
        case inTransition
        case open
    }
    
    enum AuthState {
        case login
    }
    
    enum AppState {
        case productDetail
        case instructionDetail  // Đây là InstructionView (preview)
        case instruction        // Đây là InstructionsView (tương tác)
        case immersive
        case productView
    }

    var immersiveSpaceState = ImmersiveSpaceState.closed
    var isLoggedIn: Bool = false
    var userEmail: String = ""
    var jwtToken: String? = nil
    var userID: Int? = nil
    var currentAuthState: AuthState = .login
    var currentAppState: AppState = .productView
    
    // Data model
    var projects: [Project] = []
    var selectedProject: Project? = nil
    func logout() {
        isLoggedIn = false
        currentAppState = .productDetail
        UserDefaults.standard.removeObject(forKey: "auth_token")
    }
}
