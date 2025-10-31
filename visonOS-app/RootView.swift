import SwiftUI
import RealityKit

struct RootView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(SceneState.self) private var sceneState

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
                    .onDisappear{
                        appModel.resetInstructionState()
                        sceneState.rootEntity.removeFromParent()
                        sceneState.rootEntity = Entity()
                        sceneState.project = nil
                    }
            }
        }
        .environment(appModel)
        .animation(.easeInOut, value: appModel.currentScreen)
        .transition(.opacity)
    }
}

#Preview {
    RootView()
}
