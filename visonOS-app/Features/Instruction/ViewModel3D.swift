//
//  TriceratopsVolumeView.swift
//  Dinopedia
//

import SwiftUI
import RealityKit
import RealityKitContent

struct ViewModel3D: View {
    var body: some View {
        TimelineView(.animation) { context in
            Model3D(named: "Scene", bundle: realityKitContentBundle) { model in
                model
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(0.7)
                    .rotation3DEffect(.degrees(context.date.timeIntervalSinceReferenceDate * 10 ), axis: .y)
                    .shadow(radius: 10)
            } placeholder: {
                ProgressView()
            }
        }
        .frame(depth: 200, alignment: .center)
        .frame(width: 200, height: 200)
        .padding()
    }
}

#Preview {
    ViewModel3D()
}
