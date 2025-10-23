import SwiftUI

struct RootView: View {
    @Environment(AppModel.self) private var appModel

    var body: some View {
        Group {
            switch appModel.currentScreen {
                case .login:
                    LoginView()
                case .projectList:
                    ProjectView()
                case .projectDetail:
                    ProductDetailView()
                case .instruction:
                    InstructionView()
                case .model3D:
                    Model3DView()
            }
        }
        .environment(appModel)
        .animation(.easeInOut, value: appModel.isLoggedIn)
        .transition(.opacity)
    }
}

#Preview {
    RootView()
}
