import SwiftUI
import RealityKit
import RealityKitContent

struct ContentView: View {
    @Environment(AppModel.self) private var appModel

    var body: some View {
        Group {
            if appModel.isLoggedIn {
                // Sau khi đăng nhập thì vào màn 3D
                ImmersiveView()
            } else {
                // Hiển thị Login hoặc Signup dựa trên currentAuthState
                switch appModel.currentAuthState {
                case .login:
                    LoginView()
                case .signup:
                    SignUpView()
                }
            }
        }
    }
}

#Preview(windowStyle: .automatic) {
    ContentView()
        .environment(AppModel())
}
