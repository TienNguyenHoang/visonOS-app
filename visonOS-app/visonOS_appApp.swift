import SwiftUI

@main
@MainActor
struct VisionOSApp: App {
    @State private var appModel = AppModel()
    @State private var sceneState = SceneState()
    
    var body: some Scene {
        
        WindowGroup {
            RootView()
                .environment(appModel)
                .environment(sceneState)
                .onAppear {
                    appModel.checkStoredTokens()
                }
        }
        .windowStyle(.plain)
        
        WindowGroup(id: "volume3D") {
            Model3DStepViewer(mode: .volumetric)
            .environment(appModel)
            .environment(sceneState)
            .onDisappear {
                appModel.isVolumeShown = false
            }
        }
        .windowStyle(.volumetric)
    }
}
