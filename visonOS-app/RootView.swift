import SwiftUI

struct RootView: View {
    @State private var appModel = AppModel()

    var body: some View {
        ZStack {
            if appModel.isLoggedIn {
                ContentView()
                    .environment(appModel)
            } else {
                switch appModel.currentAuthState {
                case .login:
                    LoginView()
                        .environment(appModel)
                case .signup:
                    SignUpView()
                        .environment(appModel)
                }
            }
        }
    }
}

#Preview {
    RootView()
}
