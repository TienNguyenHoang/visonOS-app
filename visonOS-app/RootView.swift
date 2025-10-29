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
                    .onDisappear{
                        appModel.resetInstructionState()
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
