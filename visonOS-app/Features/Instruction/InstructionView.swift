import SwiftUI
import RealityKit
import RealityKitContent

enum ViewerMode {
    case plain
    case volumetric
}

struct InstructionView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow
    
    @State private var isMuted = false
    @State private var isTransitioning = false
    
    @State private var isLoading = true
    
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
                if isLoading {
                    VStack {
                        Spacer()
                        ProgressView("Loading 3D Steps...")
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.black.opacity(0.7))
                } else if appModel.steps.isEmpty {
                    Text("No steps found in project")
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    HStack(spacing: 0) {
                        // LEFT PANEL
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
                            
                            // CONTROL BUTTONS
                            controlButtons
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 20)
                        .frame(width: appModel.isVolumeShown ? geo.size.width : geo.size.width * 0.35)
                        .animation(.easeInOut(duration: 0.3), value: appModel.isVolumeShown)
                        
                        // RIGHT PANEL (Model Preview)
                        if !appModel.isVolumeShown {
                            ZStack {
                                Color.gray.opacity(0.15)
                                Model3DStepViewer(
                                    modelName: appModel.modelName ?? "Scene",
                                    mode: .plain
                                )
                                .padding(40)
                            }
                            .frame(width: geo.size.width * 0.65)
                            .transition(.opacity.combined(with: .scale))
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 36))
                    .shadow(radius: 20)
                }
            }
        }
        .task {
            await loadProjectJson()
        }
    }
    
    // MARK: - Control Buttons
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
    
    // MARK: - JSON Loader
    @MainActor
    func loadProjectJson() async {
        guard let url = Bundle.main.url(forResource: "test5anim", withExtension: "json") else {
            print("❌ JSON not found")
            isLoading = false
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode(AnimationModel.self, from: data)
            
            // Map steps + nodes
            appModel.steps = decoded.steps.enumerated().map { index, step in
                let title = "Step \(index + 1)"
                let attr = step.descriptionText.text.en.htmlToAttributedString()
                return Model3DInstructionStep(
                    title: title,
                    description: attr,
                    modelName: appModel.modelName ?? "Scene",
                    nodes: decoded.nodes // truyền toàn bộ nodes để animation theo step
                )
            }
        } catch {
            print("❌ Decode error:", error)
            appModel.steps = []
        }
        isLoading = false
    }
}

// MARK: - Model Viewer
struct Model3DStepViewer: View {
    let modelName: String
    let mode: ViewerMode
    
    @Environment(AppModel.self) private var appModel
    @State private var sceneState = SceneState()
    @State private var entity: Entity?
    
    var body: some View {
        RealityView { content in
            if let entity = try? Entity.load(named: modelName) {
                // Setup scale & position
                let bounds = entity.visualBounds(relativeTo: nil)
                let maxDim = max(bounds.extents.x, bounds.extents.y, bounds.extents.z)

                // ✅ scale vừa khung, đảm bảo không quá to
                let baseScale: Float = 0.5 / maxDim
                let scale: Float = (mode == .plain) ? baseScale * 0.3 : baseScale

                entity.setScale(SIMD3(repeating: scale), relativeTo: nil)

                // ✅ căn giữa mô hình theo tâm
                entity.position = SIMD3(
                    -bounds.center.x * scale,
                    -bounds.center.y * scale,
                    -bounds.center.z * scale
                )

                sceneState.rootEntity = entity
                content.add(entity)
                self.entity = entity
                
                // Lấy nodes tại thời điểm hiện tại
                let nodes = appModel.steps[safe: appModel.currentStepIndex]?.nodes ?? []
                
                // Tự động play step hiện tại nếu đang play
                if appModel.isPlaying {
                    playNodeAnimations(nodes: nodes, on: entity, stepIndex: appModel.currentStepIndex)
                }
            }
        }
        .onChange(of: appModel.currentStepIndex) { _, _ in
            let nodes = appModel.steps[safe: appModel.currentStepIndex]?.nodes ?? []
            if appModel.isPlaying {
                playNodeAnimations(nodes: nodes, on: entity, stepIndex: appModel.currentStepIndex)
            }
        }
        .onChange(of: appModel.isPlaying) { _, newValue in
            let nodes = appModel.steps[safe: appModel.currentStepIndex]?.nodes ?? []
            if newValue {
                playNodeAnimations(nodes: nodes, on: entity, stepIndex: appModel.currentStepIndex)
            } else {
                stopAllAnimations(entity: entity)
            }
        }
    }
    
    func playNodeAnimations(nodes: [Node], on entity: Entity?, stepIndex: Int) {
        guard let entity else { return }

        func traverse(nodeList: [Node], parentEntity: Entity) {
            for node in nodeList {
                guard stepIndex < node.steps.count else { continue }
                let keyframes = node.steps[stepIndex].keyframes
                guard let first = keyframes.first, let last = keyframes.last else { continue }

                if let childEntity = parentEntity.findEntity(named: node.name) {

                    childEntity.isEnabled = first.visible
                    
                    // transform bắt đầu & kết thúc
                    let start = Transform(
                        scale: SIMD3(Float(first.scale.x), Float(first.scale.y), Float(first.scale.z)),
                        rotation: simd_quatf(ix: Float(first.quaternion[0]),
                                             iy: Float(first.quaternion[1]),
                                             iz: Float(first.quaternion[2]),
                                             r: Float(first.quaternion[3])),
                        translation: SIMD3(Float(first.position.x),
                                           Float(first.position.y),
                                           Float(first.position.z))
                    )

                    let end = Transform(
                        scale: SIMD3(Float(last.scale.x), Float(last.scale.y), Float(last.scale.z)),
                        rotation: simd_quatf(ix: Float(last.quaternion[0]),
                                             iy: Float(last.quaternion[1]),
                                             iz: Float(last.quaternion[2]),
                                             r: Float(last.quaternion[3])),
                        translation: SIMD3(Float(last.position.x),
                                           Float(last.position.y),
                                           Float(last.position.z))
                    )

                    // 🪄 Tạo animation
                    let anim = FromToByAnimation<Transform>(
                        from: start,
                        to: end,
                        duration: 1.5, // hoặc tính từ dữ liệu JSON
                        bindTarget: .transform
                    )
                    if let resource = try? AnimationResource.generate(with: anim) {
                        childEntity.playAnimation(resource, transitionDuration: 0.1)
                    }
                }

                if !node.children.isEmpty {
                    traverse(nodeList: node.children, parentEntity: parentEntity)
                }
            }
        }

        traverse(nodeList: nodes, parentEntity: entity)
    }

    
    func stopAllAnimations(entity: Entity?) {
        entity?.stopAllAnimations()
    }
}


// MARK: - Data Model
struct Model3DInstructionStep {
    let title: String
    let description: AttributedString?
    let modelName: String
    let nodes: [Node]
}

// MARK: - Safe Array Access
extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
