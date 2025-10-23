import SwiftUI

@main
@MainActor
struct visonOS_appApp: App {
    @State private var appModel = AppModel()
    @State var headsetPositionManager = HeadsetPositionManager()
    
    public static let viewModel3D = "viewModel3D"
    
    var body: some Scene {
        
        WindowGroup(id: Self.viewModel3D) {
            ViewModel3D()
        }
            .windowStyle(.volumetric)
            .defaultSize(width: 2, height: 1.2, depth: 2, in: .meters)
            .defaultSize(width: 600, height: 650)
        
        WindowGroup {
            RootView()
                .environment(appModel)
                .onAppear {
                    // Check for stored tokens when app launches
                    appModel.checkStoredTokens()
                }
        }
    }
}
