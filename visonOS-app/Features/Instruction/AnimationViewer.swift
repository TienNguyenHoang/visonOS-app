import SwiftUI
import RealityKit

@Observable
class SceneState {
    var rootEntity = Entity()
    var project: AnimationModel?
}

struct AnimationViewer: View {
    @State private var scale: CGFloat = 1.0
    @State private var rotation: Angle = .zero
    @State private var offset: CGSize = .zero
    
    @State private var sceneState = SceneState()
    @State private var modelAdded = false
        
        var body: some View {
            RealityView { content in
                if !modelAdded {
                    if let entity = try? Entity.load(named: "test5.usdz") {
                        let bounds = entity.visualBounds(relativeTo: nil)
                        let maxDim = max(bounds.extents.x, bounds.extents.y, bounds.extents.z)
                        let scaleFactor = 1.0 / maxDim
                        entity.setScale(SIMD3(repeating: scaleFactor), relativeTo: nil)
                        entity.position = -bounds.center * scaleFactor
                        
                        sceneState.rootEntity = entity
                        content.add(entity)
                        modelAdded = true
                    }
                }
            }
            .gesture(TapGesture().onEnded {
                print("👆 tapped model")
            })
            .onAppear {
                Task { await loadProjectAndStart() }
            }
        }

    @MainActor
    func loadProjectAndStart() async {
        guard let url = Bundle.main.url(forResource: "test5anim", withExtension: "json") else {
            print("❌ JSON not found")
            return
        }
        do {
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode(AnimationModel.self, from: data)
            sceneState.project = decoded
            print("✅ JSON decoded with \(decoded.nodes.count) nodes and \(decoded.steps.count) steps")

            // ✅ Start animation
            startAutoAnimation()
        } catch {
            print("❌ Decode error:", error)
        }
    }

    // MARK: - Auto Animate
    // MARK: - Auto Animate
    func startAutoAnimation() {
        Task { @MainActor in
            guard let project = sceneState.project else { return }
            let steps = project.steps
            guard steps.count > 1 else {
                print("⚠️ Not enough steps to animate")
                return
            }

            // Lặp vô hạn qua các step
            while true {
                for i in 0..<(steps.count - 1) {
                    print("🎬 Transition step \(i) → \(i + 1)")

                    // ✅ Tính duration dựa trên khoảng cách giữa các node
                    var maxDistance: Float = 0
                    for node in project.nodes {
                        guard let startFrame = node.steps[safe: i]?.keyframes.first,
                              let endFrame   = node.steps[safe: i + 1]?.keyframes.first else { continue }

                        let p1 = SIMD3<Float>(Float(startFrame.position.x),
                                              Float(startFrame.position.y),
                                              Float(startFrame.position.z))
                        let p2 = SIMD3<Float>(Float(endFrame.position.x),
                                              Float(endFrame.position.y),
                                              Float(endFrame.position.z))
                        let dist = simd_distance(p1, p2)
                        if dist > maxDistance { maxDistance = dist }
                    }
                    
                    let speed: Float = 0.1  // units per second, bạn chỉnh theo nhu cầu
                    let stepDuration = max(0.1, Double(maxDistance / speed)) // đảm bảo >0
                    print("⏱ Calculated duration: \(stepDuration)s")

                    await animateTransition(fromStepIndex: i, toStepIndex: i + 1, duration: stepDuration)
                }
            }
        }
    }


    func animateTransition(fromStepIndex: Int, toStepIndex: Int, duration: Double) async {
        guard let project = sceneState.project else { return }
        let startTime = Date()

        while Date().timeIntervalSince(startTime) < duration {
            let t = Float(Date().timeIntervalSince(startTime) / duration)
            let easedT = simd_smoothstep(0, 1, t)

            // Cập nhật transform cho tất cả nodes đệ quy
            func updateNode(_ node: Node) async {
                guard let startFrame = node.steps[safe: fromStepIndex]?.keyframes.first,
                      let endFrame   = node.steps[safe: toStepIndex]?.keyframes.first else { return }

                guard let entity = sceneState.rootEntity.findEntity(named: node.name) else {
                    print("⚠️ Entity not found:", node.name)
                    return
                }

                // Position interpolation
                let p1 = SIMD3<Float>(Float(startFrame.position.x),
                                      Float(startFrame.position.y),
                                      Float(startFrame.position.z))
                let p2 = SIMD3<Float>(Float(endFrame.position.x),
                                      Float(endFrame.position.y),
                                      Float(endFrame.position.z))
                let pos = simd_mix(p1, p2, SIMD3<Float>(repeating: easedT))

                // Rotation interpolation
                let q1 = simd_quatf(ix: Float(startFrame.quaternion[0]),
                                    iy: Float(startFrame.quaternion[1]),
                                    iz: Float(startFrame.quaternion[2]),
                                    r: Float(startFrame.quaternion[3]))
                let q2 = simd_quatf(ix: Float(endFrame.quaternion[0]),
                                    iy: Float(endFrame.quaternion[1]),
                                    iz: Float(endFrame.quaternion[2]),
                                    r: Float(endFrame.quaternion[3]))
                let rot = simd_slerp(q1, q2, easedT)

                // Scale interpolation
                let s1 = SIMD3<Float>(Float(startFrame.scale.x),
                                      Float(startFrame.scale.y),
                                      Float(startFrame.scale.z))
                let s2 = SIMD3<Float>(Float(endFrame.scale.x),
                                      Float(endFrame.scale.y),
                                      Float(endFrame.scale.z))
                let scl = simd_mix(s1, s2, SIMD3<Float>(repeating: easedT))

                let visible = (t < 0.5) ? startFrame.visible : endFrame.visible

                await MainActor.run {
                    entity.transform = Transform(scale: scl, rotation: rot, translation: pos)
                    entity.isEnabled = visible
                }

                // Đệ quy update children
                for child in node.children {
                    await updateNode(child)
                }
            }

            for node in project.nodes {
                await updateNode(node)
            }

            try? await Task.sleep(nanoseconds: 16_000_000) // ~60fps
        }
    }


}

// MARK: - Extension helper: Tìm entity con theo tên
extension Entity {
    func findEntity(named name: String) -> Entity? {
        if self.name == name { return self }
        for child in children {
            if let found = child.findEntity(named: name) { return found }
        }
        return nil
    }
}

// MARK: - Array safe index
extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
