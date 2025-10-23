import SwiftUI
import RealityKit
import RealityKitContent

struct ContentView: View {
    @Environment(AppModel.self) private var appModel

    var body: some View {
        Group {
            if appModel.isLoggedIn {
                // Sau khi đăng nhập thì điều hướng theo currentAppState
                switch appModel.currentAppState {
                case .productView:
                    ProjectView()
                case .productDetail:
                    ProductDetailView()
                case .instruction:
                    InstructionView()
                case .immersive:
                    ImmersiveView()
                }
            } else {
                // Hiển thị Login hoặc Signup dựa trên currentAuthState
                switch appModel.currentAuthState {
                case .login:
                    LoginView()
                }
            }
        }
    }
}

#Preview(windowStyle: .automatic) {
    ContentView()
        .environment(AppModel())
}
