//
//  ImmersiveView.swift
//  visonOS-app
//
//  Created by Ploggvn on 22/10/25.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct ImmersiveView: View {
    @Environment(AppModel.self) private var appModel

    var body: some View {
        RealityView { content in
            if let immersiveContentEntity = try? await Entity(named: "Immersive", in: realityKitContentBundle) {
                content.add(immersiveContentEntity)
            } else {
                print("⚠️ Could not load 'Immersive' entity from RealityKitContent bundle.")
            }
        }
        .ignoresSafeArea()
    }
}

#Preview(immersionStyle: .full) {
    ImmersiveView()
        .environment(AppModel())
}
