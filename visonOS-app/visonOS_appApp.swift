import SwiftUI

@main
@MainActor
struct VisionOSApp: App {
    @State private var appModel = AppModel()
    
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
            Model3DStepViewer(mode: .volumetric)
            .environment(appModel)
            .onDisappear {
                appModel.isVolumeShown = false
            }
        }
        .windowStyle(.volumetric)
        .defaultSize(width: 1.5, height: 1.0, depth: 1.5, in: .meters)
    }
}
