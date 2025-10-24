import SwiftUI
import RealityKit

struct AnimationViewer: View {
    @State private var rootEntity = Entity()
    @State private var project: BuilderProject?
    @State private var currentStep = 0
    
    var body: some View {
        RealityView { content in
            // Load USDZ model
            if let entity = try? await Entity.load(named: "scene.usdz") {
                rootEntity = entity
                content.add(rootEntity)
            }
            
            // Load JSON builder data
            if let url = Bundle.main.url(forResource: "builder", withExtension: "json"),
               let data = try? Data(contentsOf: url),
               let decoded = try? JSONDecoder().decode(BuilderProject.self, from: data) {
                project = decoded
                startAutoAnimation()
            }
        }
    }
    
    /// Tự động chạy qua tất cả các step
    func startAutoAnimation() {
        Task {
            guard let project = project else { return }
            let steps = project.instruction.steps
            
            // 🔁 Lặp vô hạn
            while true {
                for i in 0..<steps.count - 1 {
                    print("Animation step \(i)")
                    let fromStep = steps[i]
                    let toStep = steps[i + 1]
                    await animateTransition(from: fromStep, to: toStep, duration: 1.0)
                }
            }
        }
    }
    
    /// Nội suy mượt giữa 2 step
    func animateTransition(from: InstructionStep2, to: InstructionStep2, duration: Double) async {
        guard let project = project else { return }
        guard let startFrame = from.keyframes.first,
              let endFrame = to.keyframes.first else { return }
        
        let start = Date()
        while Date().timeIntervalSince(start) < duration {
            let t = Float(Date().timeIntervalSince(start) / duration)
            
            for nodeIndex in 0..<startFrame.nodes.count {
                guard nodeIndex < project.world.nodes.count else { continue }
                let nodeName = project.world.nodes[nodeIndex].name
                guard let entity = rootEntity.findEntity(named: nodeName),
                      nodeIndex < endFrame.nodes.count else { continue }
                
                let startNode = startFrame.nodes[nodeIndex]
                let endNode = endFrame.nodes[nodeIndex]
                
                let p1 = SIMD3(startNode.position)
                let p2 = SIMD3(endNode.position)
                let pos = simd_mix(p1, p2, SIMD3<Float>(repeating: t))
                
                let q1 = simd_quatf(ix: startNode.quaternion[0],
                                    iy: startNode.quaternion[1],
                                    iz: startNode.quaternion[2],
                                    r: startNode.quaternion[3])
                let q2 = simd_quatf(ix: endNode.quaternion[0],
                                    iy: endNode.quaternion[1],
                                    iz: endNode.quaternion[2],
                                    r: endNode.quaternion[3])
                let rot = simd_slerp(q1, q2, t)
                
                let s1 = SIMD3(startNode.scale)
                let s2 = SIMD3(endNode.scale)
                let scl = simd_mix(s1, s2, SIMD3<Float>(repeating: t))
                
                await MainActor.run {
                    entity.position = pos
                    entity.orientation = rot
                    entity.scale = scl
                    entity.isEnabled = endNode.visible
                }
            }
            print("zoo")
            try? await Task.sleep(nanoseconds: 16_000_000) // 60fps
        }
    }
}
