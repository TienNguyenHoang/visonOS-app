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
                    ProjectDetailView()
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
//    @Environment(\.openWindow) private var openWindow
//        
//        var body: some View {
//            VStack {
//                Text("Main Menu")
//                Button("Open 3D Viewer") {
//                    openWindow(id: VisionOSApp.viewModel3D)
//                }
//            }
//        }
}

#Preview {
    RootView()
}
