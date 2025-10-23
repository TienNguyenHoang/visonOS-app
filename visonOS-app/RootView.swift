import SwiftUI

struct RootView: View {
    @Environment(AppModel.self) private var appModel

    var body: some View {
        Group {
            if appModel.isLoggedIn {
                ContentView()
            } else {
                switch appModel.currentAuthState {
                    case .login:
                    LoginView()
                        .environment(appModel)
                }
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
