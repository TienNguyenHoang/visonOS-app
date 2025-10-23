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
        ZStack(alignment: .topLeading) {
            RealityView { content in
                if let immersiveContentEntity = try? await Entity(named: "Immersive", in: realityKitContentBundle) {
                    content.add(immersiveContentEntity)
                } else {
                    print("⚠️ Could not load 'Immersive' entity from RealityKitContent bundle.")
                }
            }
            .ignoresSafeArea()
            
            // Back button to return to DetailView
            VStack {
                HStack {
                    Button(action: {
                        appModel.currentAppState = .productDetail
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding(12)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                    .padding(.leading, 20)
                    .padding(.top, 20)
                    
                    Spacer()
                }
                
                Spacer()
            }
        }
    }
}

#Preview(immersionStyle: .full) {
    ImmersiveView()
        .environment(AppModel())
}
