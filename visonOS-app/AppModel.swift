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
        case detail
        case immersive
    }

    var immersiveSpaceState = ImmersiveSpaceState.closed
    var isLoggedIn: Bool = false
    var userEmail: String = ""
    var currentAuthState: AuthState = .login
    var currentAppState: AppState = .productDetail
    
    func logout() {
        isLoggedIn = false
        currentAppState = .productDetail
        UserDefaults.standard.removeObject(forKey: "auth_token")
    }
}
