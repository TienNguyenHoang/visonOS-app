import SwiftUI
import RealityKit

// MARK: - SceneState giữ reference cho entity & dữ liệu
@Observable
class SceneState {
    var rootEntity = Entity()
    var project: AnimationModel?
}

struct AnimationViewer: View {
    @State private var sceneState = SceneState()
    
    var body: some View {
        RealityView { content in
            // ✅ Load model 1 lần
            if sceneState.rootEntity.children.isEmpty {
                if let entity = try? await Entity.load(named: "test5.usdz") {
                    let bounds = entity.visualBounds(relativeTo: nil)
                    let maxDim = max(bounds.extents.x, bounds.extents.y, bounds.extents.z)
                    let scaleFactor = 1.0 / maxDim
                    entity.setScale(SIMD3(repeating: scaleFactor), relativeTo: nil)
                    entity.position = -bounds.center * scaleFactor

                    sceneState.rootEntity = entity
                    content.add(entity)
                    print("✅ Model loaded with \(entity.children.count) children.")
                }
            }

            // ✅ Load JSON sau khi model load xong
            if sceneState.project == nil {
                Task {
                    await loadProjectAndStart()
                }
            }
        }
    }
    
    // MARK: - Load Project
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

            // Start animation
            startAutoAnimation()
        } catch {
            print("❌ Decode error:", error)
        }
    }

    // MARK: - Auto Animate
    func startAutoAnimation() {
        Task.detached(priority: .high) {
            guard let project = sceneState.project else { return }
            let steps = project.steps
            guard steps.count > 1 else {
                print("⚠️ Not enough steps to animate")
                return
            }

            while true {
                for i in 0..<(steps.count - 1) {
                    let fromStep = steps[i]
                    let toStep = steps[i + 1]
                    print("🎬 Transition step \(i) → \(i + 1)")
                    await animateTransition(from: fromStep, to: toStep, duration: 1.5)
                }
            }
        }
    }

    // MARK: - Transition Animation
    func animateTransition(from: AnimInstructionStep, to: AnimInstructionStep, duration: Double) async {
        print("▶️ Start transition")
        guard let project = sceneState.project else { return }
        let startTime = Date()

        while Date().timeIntervalSince(startTime) < duration {
            let t = Float(Date().timeIntervalSince(startTime) / duration)
            let easedT = simd_smoothstep(0, 1, t)

            for node in project.nodes {
                guard let startStep = node.steps.first,
                      let endStep = node.steps.last,
                      let startFrame = startStep.keyframes.first,
                      let endFrame = endStep.keyframes.first
                else { continue }

                guard let entity = sceneState.rootEntity.findEntity(named: node.name) else {
                    print("⚠️ Entity not found:", node.name)
                    continue
                }

                // Position interpolation
                let p1 = SIMD3<Float>(
                    Float(startFrame.position.x),
                    Float(startFrame.position.y),
                    Float(startFrame.position.z)
                )
                let p2 = SIMD3<Float>(
                    Float(endFrame.position.x),
                    Float(endFrame.position.y),
                    Float(endFrame.position.z)
                )
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
                let s1 = SIMD3<Float>(
                    Float(startFrame.scale.x),
                    Float(startFrame.scale.y),
                    Float(startFrame.scale.z)
                )
                let s2 = SIMD3<Float>(
                    Float(endFrame.scale.x),
                    Float(endFrame.scale.y),
                    Float(endFrame.scale.z)
                )
                let scl = simd_mix(s1, s2, SIMD3<Float>(repeating: easedT))

                let visible = (t < 0.5) ? startFrame.visible : endFrame.visible

                // ✅ Update transform gộp lại (fix RealityKit not updating)
                await MainActor.run {
                    entity.transform = Transform(scale: scl, rotation: rot, translation: pos)
                    entity.isEnabled = visible
                }

                // Debug log
                print("Animating:", node.name, "pos:", pos)
            }

            try? await Task.sleep(nanoseconds: 16_000_000) // 60fps
        }

        print("⏹ Transition end")
    }
}
