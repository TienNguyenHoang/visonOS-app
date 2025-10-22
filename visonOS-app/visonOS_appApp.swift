//
//  visonOS_appApp.swift
//  visonOS-app
//
//  Created by Ploggvn  on 22/10/25.
//

import SwiftUI

@main
struct visonOS_appApp: App {

    @State private var appModel = AppModel()

    var body: some Scene {
        WindowGroup {
            LoginView()
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
