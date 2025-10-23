//
//  visonOS_appApp.swift
//  visonOS-app
//
//  Created by Ploggvn  on 22/10/25.
//

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
            ContentView()
                .environment(appModel)
        }

        ImmersiveSpace(id: appModel.immersiveSpaceID) {
            ImmersiveView()
                .environment(appModel)
                .onAppear {
                    appModel.immersiveSpaceState = .open
                }
                .onDisappear {
                    appModel.immersiveSpaceState = .closed
                }
        }
        .immersionStyle(selection: .constant(.full), in: .full)
    }
}
