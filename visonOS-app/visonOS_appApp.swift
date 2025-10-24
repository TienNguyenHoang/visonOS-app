import SwiftUI

@main
@MainActor
struct VisionOSApp: App {
    @State private var appModel = AppModel()
    @State private var headsetPositionManager = HeadsetPositionManager()
    
    // ID cho cửa sổ 3D
    public static let viewModel3D = "viewModel3D"
    
    var body: some Scene {
        
        // 🔹 Scene 3D (Volumetric Window)
        WindowGroup(id: Self.viewModel3D) {
            AnimationViewer()
                .environment(appModel)
                .environment(headsetPositionManager)
        }
        .windowStyle(.volumetric)
        .defaultSize(width: 2, height: 1.2, depth: 2, in: .meters)
        
        
        // 🔹 Scene chính (2D Window)
        WindowGroup {
            RootView()
                .environment(appModel)
                .onAppear {
                    appModel.checkStoredTokens()
                }
        }
        .windowStyle(.plain) // 👈 kiểu 2D phẳng
    }
}
