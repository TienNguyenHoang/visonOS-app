import SwiftUI

/// Maintains app-wide state
@Observable
@MainActor
class AppModel {
    // Auth
    var isLoggedIn: Bool = false
    var userEmail: String = ""
    var jwtToken: String? = nil
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
