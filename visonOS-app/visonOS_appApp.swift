import SwiftUI

@main
@MainActor
struct VisionOSApp: App {
    @State private var appModel = AppModel()
    @State private var headsetPositionManager = HeadsetPositionManager()
    
    var body: some Scene {
        
        WindowGroup {
            RootView()
                .environment(appModel)
                .onAppear {
                    appModel.checkStoredTokens()
                }
        }
        .windowStyle(.plain)
        
        WindowGroup(id: "volume3D") {
            Model3DR(modelName: "test5.usdz")
                .onDisappear {
                    appModel.isVolumeShown = false
                }
        }
        .windowStyle(.volumetric)
        .defaultSize(width: 1.5, height: 1.0, depth: 1.5, in: .meters)
    }
}
