import SwiftUI
import RealityKit
import RealityKitContent

enum ViewerMode {
    case plain
    case volumetric
}

@Observable
class SceneState {
    var rootEntity = Entity()
    var project: AnimationModel?
}

struct InstructionView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow
    
    @State private var isMuted = false
    @State private var isTransitioning = false
    @State private var isLoading = false
    
    var cleanDescription: AttributedString {
        var attr = appModel.steps[safe: appModel.currentStepIndex]?.description ?? AttributedString("")
        attr.foregroundColor = .white
        attr.font = .body
        return attr
    }
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 36)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.black.opacity(0.85),
                            Color(red: 0.05, green: 0.1, blue: 0.12)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(radius: 20)
                .ignoresSafeArea()
            
            GeometryReader { geo in
                HStack(spacing: 0) {
                    if isLoading {
                        VStack {
                            Spacer()
                            ProgressView("Loading 3D Steps...")
                                .foregroundColor(.white)
                            Spacer()
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if appModel.steps.isEmpty {
                        Text("No steps found in project")
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        VStack(alignment: .leading, spacing: 20) {
                            HStack(spacing: 12) {
                                Button {
                                    appModel.currentScreen = .projectDetail
                                } label: {
                                    Image(systemName: "chevron.left")
                                        .font(.title3)
                                        .foregroundColor(.white)
                                        .padding(8)
                                }
                                Spacer()
                            }
                            .overlay(
                                Text(appModel.steps[safe: appModel.currentStepIndex]?.title ?? "")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            )
                            
                            Text("DESCRIPTION")
                                .font(.headline)
                                .foregroundColor(.white.opacity(0.7))
                            Text(cleanDescription)
                                .padding(.bottom, 20)
                            
                            Spacer()
                            controlButtons
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 20)
                        .frame(width: appModel.isVolumeShown ? geo.size.width : geo.size.width * 0.35)
                        .animation(.easeInOut(duration: 0.3), value: appModel.isVolumeShown)
                        
                        if !appModel.isVolumeShown {
                            ZStack {
                                Color.gray.opacity(0.15)
                                Model3DStepViewer(mode: .plain)
                                    .padding(40)
                            }
                            .frame(width: geo.size.width * 0.65)
                            .transition(.opacity.combined(with: .scale))
                            .animation(.easeInOut(duration: 0.3), value: appModel.isVolumeShown)
                        }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 36))
                .shadow(radius: 20)
            }
        }
        // ✅ chỉ load khi chưa có data
        .task {
            if appModel.steps.isEmpty {
                isLoading = true
                await loadProjectJson()
            }
        }
    }
    
    // MARK: - Control buttons
    private var controlButtons: some View {
        HStack(spacing: 18) {
            Spacer()
            
            Button {
                isMuted.toggle()
            } label: {
                Image(systemName: isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                    .font(.title2)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.bordered)
            .tint(isMuted ? .gray : .indigo)
            
            Spacer()
            
            Button {
                if appModel.currentStepIndex > 0 {
                    appModel.currentStepIndex -= 1
                    appModel.isPlaying = true
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title3)
            }
            .buttonStyle(.borderedProminent)
            .tint(.cyan)
            .disabled(appModel.currentStepIndex == 0)
            
            Button {
                appModel.isPlaying.toggle()
            } label: {
                Image(systemName: appModel.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                    .padding(16)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.cyan.opacity(0.9),
                                Color.blue.opacity(0.8)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(Circle())
                    .shadow(color: .cyan.opacity(0.6), radius: 8, y: 2)
            }
            .buttonStyle(.plain)
            
            Button {
                if appModel.currentStepIndex < appModel.steps.count - 1 {
                    appModel.currentStepIndex += 1
                    appModel.isPlaying = true
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.title3)
            }
            .buttonStyle(.borderedProminent)
            .tint(.cyan)
            .disabled(appModel.currentStepIndex == appModel.steps.count - 1)
            
            Spacer()
            
            Button {
                Task {
                    guard !isTransitioning else { return }
                    isTransitioning = true
                    
                    if appModel.isVolumeShown {
                        dismissWindow(id: "volume3D")
                    } else {
                        openWindow(id: "volume3D")
                    }
                    
                    withAnimation(.easeInOut(duration: 0.3)) {
                        appModel.isVolumeShown.toggle()
                    }
                    
                    try? await Task.sleep(nanoseconds: 400_000_000)
                    isTransitioning = false
                }
            } label: {
                Image(systemName: appModel.isVolumeShown ? "cube.transparent.fill" : "cube.transparent")
                    .font(.title2)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.borderedProminent)
            .tint(appModel.isVolumeShown ? .orange : .purple)
            
            Spacer()
        }
    }
    
    // MARK: - Load JSON
    func loadProjectJson() async {
        do {
            let decoded: AnimationModel = try await Task.detached(priority: .background) {
                guard let url = Bundle.main.url(forResource: "test5anim", withExtension: "json") else {
                    throw APIError.invalidResponse
                }

                let data = try Data(contentsOf: url)
                return try JSONDecoder().decode(AnimationModel.self, from: data)
            }.value

            let steps = decoded.steps.enumerated().map { index, step in
                let title = "Step \(index + 1)"
                let attr = step.descriptionText.text.en.htmlToAttributedString()

                let firstKeyframe = step.keyframes.first
                let camPos = firstKeyframe?.cameraPos
                let camTarget = firstKeyframe?.cameraTarget

                return Model3DInstructionStep(
                    title: title,
                    description: attr,
                    modelName: appModel.modelName ?? "Scene",
                    nodes: decoded.nodes,
                    cameraPos: camPos.map { SIMD3(Float($0.x), Float($0.y), Float($0.z)) },
                    cameraTarget: camTarget.map { SIMD3(Float($0.x), Float($0.y), Float($0.z)) }
                )
            }

            await MainActor.run {
                appModel.steps = steps
                isLoading = false
            }

        } catch {
            await MainActor.run {
                appModel.steps = []
                isLoading = false
            }
        }
    }

}


struct Model3DStepViewer: View {
    let mode: ViewerMode
    
    @Environment(AppModel.self) private var appModel
    @State private var sceneState = SceneState()
    @State private var entity: Entity?
    
    var body: some View {
        RealityView { content in
            // ✅ Chỉ load 1 lần
            if sceneState.rootEntity.children.isEmpty {
                if let entity = try? Entity.load(named: appModel.modelName ?? "Scene") {
                    
                    let bounds = entity.visualBounds(relativeTo: nil)
                    let maxDim = max(bounds.extents.x, bounds.extents.y, bounds.extents.z)
                    let baseScale: Float = 0.5 / maxDim
                    let scale: Float = (mode == .plain) ? baseScale * 0.3 : baseScale

                    entity.setScale(SIMD3(repeating: scale), relativeTo: nil)
                    entity.position = -bounds.center * scale

                    sceneState.rootEntity = entity
                    content.add(entity)
                    self.entity = entity
                }
            }

            // ✅ Setup camera cho step hiện tại
            if let step = appModel.steps[safe: appModel.currentStepIndex],
               let cameraPos = step.cameraPos,
               let cameraTarget = step.cameraTarget {

                // Xóa camera cũ (nếu có)
                content.entities
                    .filter { $0 is PerspectiveCamera }
                    .forEach { $0.removeFromParent() }

                let cameraEntity = PerspectiveCamera()
                cameraEntity.position = cameraPos
                cameraEntity.look(at: cameraTarget, from: cameraPos, relativeTo: nil)
                content.add(cameraEntity)
            }

            // ✅ Update animation khi state thay đổi
            if appModel.isPlaying {
                let nodes = appModel.steps[safe: appModel.currentStepIndex]?.nodes ?? []
                playNodeAnimations(
                    nodes: nodes,
                    on: sceneState.rootEntity,
                    stepIndex: appModel.currentStepIndex
                )
            }

        }
        .onChange(of: appModel.currentStepIndex) { _, _ in
            guard appModel.isPlaying else { return }
            let nodes = appModel.steps[safe: appModel.currentStepIndex]?.nodes ?? []
            playNodeAnimations(
                nodes: nodes,
                on: sceneState.rootEntity,
                stepIndex: appModel.currentStepIndex
            )
            
            // 🧭 Cập nhật camera mỗi khi đổi step
            if let step = appModel.steps[safe: appModel.currentStepIndex],
               let cameraPos = step.cameraPos,
               let cameraTarget = step.cameraTarget {
                if let cam = sceneState.rootEntity.findEntity(named: "InstructionCamera") as? PerspectiveCamera {
                    cam.position = cameraPos
                    cam.look(at: cameraTarget, from: cameraPos, relativeTo: nil)
                }
            }
        }
        .onChange(of: appModel.isPlaying) { _, newValue in
            let nodes = appModel.steps[safe: appModel.currentStepIndex]?.nodes ?? []
            if newValue {
                playNodeAnimations(
                    nodes: nodes,
                    on: sceneState.rootEntity,
                    stepIndex: appModel.currentStepIndex
                )
            } else {
                stopAllAnimations(entity: sceneState.rootEntity)
            }
        }
    }
    
    func playNodeAnimations(nodes: [Node], on entity: Entity?, stepIndex: Int) {
        guard let entity else { return }

        var controllers: [AnimationPlaybackController] = []

        func traverse(nodeList: [Node], parentEntity: Entity) {
            for node in nodeList {
                guard stepIndex < node.steps.count else { continue }
                
                let keyframes = node.steps[stepIndex].keyframes
                guard keyframes.count > 1 else { continue }
                print("\(node.name) keyframes-\(keyframes.count)")
                guard let childEntity = parentEntity.findEntity(named: node.name) else { continue }
                childEntity.isEnabled = keyframes.first?.visible ?? true

                for i in 0 ..< keyframes.count - 1 {
                    let firstMove = keyframes[i]
                    let lastMove = keyframes[i + 1]

                    let start = Transform(
                        scale: SIMD3(
                            Float(firstMove.scale.x),
                            Float(firstMove.scale.y),
                            Float(firstMove.scale.z)
                        ),
                        rotation: simd_quatf(
                            ix: Float(firstMove.quaternion[0]),
                            iy: Float(firstMove.quaternion[2]),
                            iz: -Float(firstMove.quaternion[1]),
                            r: Float(firstMove.quaternion[3])
                        ),
                        translation: SIMD3(
                            -Float(firstMove.position.z),
                            Float(firstMove.position.x),
                            Float(firstMove.position.y)
                        )
                    )

                    let end = Transform(
                        scale: SIMD3(
                            Float(lastMove.scale.x),
                            Float(lastMove.scale.y),
                            Float(lastMove.scale.z)
                        ),
                        rotation: simd_quatf(
                            ix: Float(lastMove.quaternion[0]),
                            iy: Float(lastMove.quaternion[2]),
                            iz: -Float(lastMove.quaternion[1]),
                            r: Float(lastMove.quaternion[3])
                        ),
                        translation: SIMD3(
                            -Float(lastMove.position.z),
                            Float(lastMove.position.x),
                            Float(lastMove.position.y)
                        )
                    )

                    let anim = FromToByAnimation<Transform>(
                        from: start,
                        to: end,
                        duration: 1.5,
                        bindTarget: .transform
                    )

                    if let resource = try? AnimationResource.generate(with: anim) {
                        // 🚀 tạo controller nhưng tạm dừng ngay
                        let controller = childEntity.playAnimation(resource, transitionDuration: 0, startsPaused: true)
                        controllers.append(controller)
                    }
                }
                
                if !node.children.isEmpty {
                    traverse(nodeList: node.children, parentEntity: parentEntity)
                }
            }
        }

        traverse(nodeList: nodes, parentEntity: entity)

        // 🎬 Sau khi đã setup hết → resume đồng thời tất cả
        controllers.forEach { $0.resume() }
    }





    func stopAllAnimations(entity: Entity?) {
        entity?.stopAllAnimations()
    }
}


struct Model3DInstructionStep {
    let title: String
    let description: AttributedString?
    let modelName: String
    let nodes: [Node]
    let cameraPos: SIMD3<Float>?
    let cameraTarget: SIMD3<Float>?
}

extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

extension Entity {
    func findEntity(named name: String) -> Entity? {
        if self.name == name { return self }
        for child in children {
            if let found = child.findEntity(named: name) { return found }
        }
        return nil
    }
}
