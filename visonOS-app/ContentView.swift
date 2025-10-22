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
                // Nếu chưa đăng nhập thì vào login
                LoginView()
            }
        }
    }
}

#Preview(windowStyle: .automatic) {
    ContentView()
        .environment(AppModel())
}
