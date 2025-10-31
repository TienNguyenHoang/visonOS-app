import SwiftUI
import RealityKit
import RealityKitContent
import Combine

enum ViewerMode {
    case plain
    case volumetric
}

struct InstructionView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(SceneState.self) private var sceneState
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
                                   
                                   sceneState.rootEntity.removeFromParent()
                                   sceneState.rootEntity = Entity()
                                   sceneState.project = nil

                                   if appModel.isVolumeShown {
                                       dismissWindow(id: "volume3D")
                                       appModel.isVolumeShown = false
                                   }

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
                                    .environment(sceneState)
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
        .task {
            if appModel.steps.isEmpty {
                isLoading = true
                await loadProjectJson()
            }
        }
    }

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
                    appModel.isPlaying = false
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
    @Environment(SceneState.self) private var sceneState

    @State private var startTime: TimeInterval = 0
    @State private var isAnimating: Bool = false
    @State private var frameDuration: TimeInterval = 1.0
    @State private var updateCancellable: Cancellable?

    var body: some View {
        
        RealityView { content in
            if sceneState.rootEntity.children.isEmpty || sceneState.currentMode != mode {
                if let loaded = try? Entity.load(named: appModel.modelName ?? "Scene") {
                    sceneState.currentMode = mode
                    
                    let bounds = loaded.visualBounds(relativeTo: nil)
                    let maxDim = max(bounds.extents.x, bounds.extents.y, bounds.extents.z)
                    let baseScale: Float = 0.5 / maxDim
                    let scale: Float = (mode == .plain) ? baseScale * 0.3 : baseScale

                    loaded.setScale(SIMD3(repeating: scale), relativeTo: nil)
                    loaded.position = -bounds.center * scale

                    sceneState.rootEntity = loaded
                    content.add(loaded)
                    
                    if let step = appModel.steps[safe: appModel.currentStepIndex] {
                        applyInitialPoses(
                            nodes: step.nodes,
                            parentEntity: loaded,
                            stepIndex: appModel.currentStepIndex
                        )

//                        if let cameraPos = step.cameraPos,
//                           let cameraTarget = step.cameraTarget {
//                            let cameraEntity = PerspectiveCamera()
//                            cameraEntity.position = cameraPos
//                            cameraEntity.look(at: cameraTarget, from: cameraPos, relativeTo: nil)
//                            content.add(cameraEntity)
//                        }

                        if appModel.isPlaying {
                            startTimeline(
                                nodes: step.nodes,
                                on: loaded,
                                stepIndex: appModel.currentStepIndex
                            )
                        }
                    }
                }
            }

//            if let step = appModel.steps[safe: appModel.currentStepIndex],
//               let cameraPos = step.cameraPos,
//               let cameraTarget = step.cameraTarget {
//
//                content.entities
//                    .filter { $0 is PerspectiveCamera }
//                    .forEach { $0.removeFromParent() }
//
//                let cameraEntity = PerspectiveCamera()
//                cameraEntity.position = cameraPos
//                cameraEntity.look(at: cameraTarget, from: cameraPos, relativeTo: nil)
//                content.add(cameraEntity)
//            }
        }
        .onChange(of: appModel.currentStepIndex) { _, newIndex in
            guard appModel.isPlaying else { return }
            let root = sceneState.rootEntity
            stopTimeline()
            startTimeline(nodes: appModel.steps[safe: newIndex]?.nodes ?? [], on: root, stepIndex: newIndex)
            // update camera
//            if let step = appModel.steps[safe: newIndex],
//               let cameraPos = step.cameraPos,
//               let cameraTarget = step.cameraTarget,
//               let cam = sceneState.rootEntity.findEntity(named: "InstructionCamera") as? PerspectiveCamera {
//                cam.position = cameraPos
//                cam.look(at: cameraTarget, from: cameraPos, relativeTo: nil)
//            }
        }
        .onChange(of: appModel.isPlaying) { _, newValue in
            let root = sceneState.rootEntity
            let nodes = appModel.steps[safe: appModel.currentStepIndex]?.nodes ?? []

            if newValue {
                if isAnimating {
                    return
                } else if startTime > 0 {
                    print("resume nè \(startTime)")
                    resumeTimeline(nodes: nodes, on: root, stepIndex: appModel.currentStepIndex)
                } else {
                    print("start lại nè \(startTime)")
                    startTimeline(nodes: nodes, on: root, stepIndex: appModel.currentStepIndex)
                }
            } else {
                print("pasue nè \(startTime)")
                pauseTimeline()
            }
        }

        .onDisappear {
            stopTimeline()
        }
    }

    func startTimeline(nodes: [Node], on entity: Entity, stepIndex: Int) {
        guard entity.scene != nil else {
            return
        }

        stopTimeline()
        
        applyInitialPoses(nodes: nodes, parentEntity: entity, stepIndex: stepIndex)

        startTime = 0
        isAnimating = true

        frameDuration = 1.0
        
        // Subscribe to SceneEvents.Update
        if let scene = entity.scene {
            updateCancellable = scene.subscribe(to: SceneEvents.Update.self) { event in
                guard isAnimating else { return }
                startTime += event.deltaTime
                
                let keyframeCount = nodes.first?.steps[safe: stepIndex]?.keyframes.count ?? 1
                let totalSegments = max(1, keyframeCount - 1)
                
                let totalDuration = frameDuration * Double(totalSegments)

                if totalDuration <= 0 { return }

                let elapsedInStep = min(startTime, totalDuration)
                let progress = Float(elapsedInStep / totalDuration)

                updateNodes(nodes: nodes, parentEntity: entity, stepIndex: stepIndex, progress: progress)
                if elapsedInStep >= totalDuration {
                    isAnimating = false
                    applyFinalPoses(nodes: nodes, parentEntity: entity, stepIndex: stepIndex)
                    startTime = 0
                    Task { @MainActor in
                        appModel.isPlaying = false
                    }
                }
            }
        }
    }

    func stopTimeline() {
        isAnimating = false
        startTime = 0
        updateCancellable?.cancel()
        updateCancellable = nil
    }
    
    func pauseTimeline() {
        guard isAnimating else { return }
        isAnimating = false
        updateCancellable?.cancel()
        updateCancellable = nil
    }

    func resumeTimeline(nodes: [Node], on entity: Entity, stepIndex: Int) {
        guard entity.scene != nil else { return }
        guard !isAnimating else { return }

        isAnimating = true

        if let scene = entity.scene {
            updateCancellable = scene.subscribe(to: SceneEvents.Update.self) { event in
                guard isAnimating else { return }
                startTime += event.deltaTime
                
                let keyframeCount = nodes.first?.steps[safe: stepIndex]?.keyframes.count ?? 1
                let totalSegments = max(1, keyframeCount - 1)
                let totalDuration = frameDuration * Double(totalSegments)
                if totalDuration <= 0 { return }

                let elapsedInStep = min(startTime, totalDuration)
                let progress = Float(elapsedInStep / totalDuration)

                updateNodes(nodes: nodes, parentEntity: entity, stepIndex: stepIndex, progress: progress)

                if elapsedInStep >= totalDuration {
                    isAnimating = false
                    startTime = 0
                    applyFinalPoses(nodes: nodes, parentEntity: entity, stepIndex: stepIndex)
                    Task { @MainActor in appModel.isPlaying = false }
                }
            }
        }
    }


    private func applyInitialPoses(nodes: [Node], parentEntity: Entity, stepIndex: Int) {
        for node in nodes {
            guard stepIndex < node.steps.count,
                  let childEntity = parentEntity.findEntity(named: node.name) else {
                    if !node.children.isEmpty {
                        applyInitialPoses(nodes: node.children, parentEntity: parentEntity, stepIndex: stepIndex)
                    }
                    continue
            }

            let keyframes = node.steps[stepIndex].keyframes
            guard let first = keyframes.first else { continue }

            childEntity.isEnabled = first.visible
            childEntity.transform = convertKeyframeToTransform(first)
            if !node.children.isEmpty {
                applyInitialPoses(nodes: node.children, parentEntity: parentEntity, stepIndex: stepIndex)
            }
        }
    }

    private func applyFinalPoses(nodes: [Node], parentEntity: Entity, stepIndex: Int) {
        for node in nodes {
            guard stepIndex < node.steps.count,
                  let childEntity = parentEntity.findEntity(named: node.name) else {
                if !node.children.isEmpty {
                    applyFinalPoses(nodes: node.children, parentEntity: parentEntity, stepIndex: stepIndex)
                }
                continue
            }
            let keyframes = node.steps[stepIndex].keyframes
            if let last = keyframes.last {
                childEntity.transform = convertKeyframeToTransform(last)
            }
            if !node.children.isEmpty {
                applyFinalPoses(nodes: node.children, parentEntity: parentEntity, stepIndex: stepIndex)
            }
        }
    }

    private func updateNodes(nodes: [Node], parentEntity: Entity, stepIndex: Int, progress: Float) {
        for node in nodes {
            guard stepIndex < node.steps.count,
                  let childEntity = parentEntity.findEntity(named: node.name) else {
                if !node.children.isEmpty {
                    updateNodes(nodes: node.children, parentEntity: parentEntity, stepIndex: stepIndex, progress: progress)
                }
                continue
            }

            let keyframes = node.steps[stepIndex].keyframes
            guard keyframes.count > 1 else {
                if let only = keyframes.first {
                    childEntity.transform = convertKeyframeToTransform(only)
                }
                if !node.children.isEmpty {
                    updateNodes(nodes: node.children, parentEntity: parentEntity, stepIndex: stepIndex, progress: progress)
                }
                continue
            }

            let totalSegments = keyframes.count - 1
            
            let scaled = progress * Float(totalSegments)
            var segmentIndex = Int(floor(scaled))
            if segmentIndex < 0 { segmentIndex = 0 }
            if segmentIndex >= totalSegments { segmentIndex = totalSegments - 1 }

            let localT = (scaled - Float(segmentIndex)).clamped(to: 0...1)

            let startKF = keyframes[segmentIndex]
            let endKF = keyframes[segmentIndex + 1]

            let interpolated = interpolateTransform(from: startKF, to: endKF, t: localT)
            childEntity.transform = interpolated

            if !node.children.isEmpty {
                updateNodes(nodes: node.children, parentEntity: parentEntity, stepIndex: stepIndex, progress: progress)
            }
        }
    }

    private func convertKeyframeToTransform(_ kf: PurpleKeyframe) -> Transform {

        let translation = SIMD3<Float>(
            -Float(kf.position.z),
            Float(kf.position.x),
            Float(kf.position.y)
        )

        let scale = SIMD3<Float>(
            Float(kf.scale.x),
            Float(kf.scale.y),
            Float(kf.scale.z)
        )

        let rotation = simd_quatf(
            ix: Float(kf.quaternion[0]),
            iy: Float(kf.quaternion[2]),
            iz: -Float(kf.quaternion[1]),
            r: Float(kf.quaternion[3])
        )

        return Transform(scale: scale, rotation: rotation, translation: translation)
    }

    private func interpolateTransform(from: PurpleKeyframe, to: PurpleKeyframe, t: Float) -> Transform {

        let px0 = -Float(from.position.z); let px1 = -Float(to.position.z)
        let py0 = Float(from.position.x);  let py1 = Float(to.position.x)
        let pz0 = Float(from.position.y);  let pz1 = Float(to.position.y)

        let pos = SIMD3<Float>(lerp(px0, px1, t), lerp(py0, py1, t), lerp(pz0, pz1, t))

        let sx = lerp(Float(from.scale.x), Float(to.scale.x), t)
        let sy = lerp(Float(from.scale.y), Float(to.scale.y), t)
        let sz = lerp(Float(from.scale.z), Float(to.scale.z), t)
        let scale = SIMD3<Float>(sx, sy, sz)

        let rotFrom = simd_quatf(
            ix: Float(from.quaternion[0]),
            iy: Float(from.quaternion[2]),
            iz: -Float(from.quaternion[1]),
            r: Float(from.quaternion[3])
        )
        let rotTo = simd_quatf(
            ix: Float(to.quaternion[0]),
            iy: Float(to.quaternion[2]),
            iz: -Float(to.quaternion[1]),
            r: Float(to.quaternion[3])
        )

        let rotation = simd_slerp(rotFrom, rotTo, t)

        return Transform(scale: scale, rotation: rotation, translation: pos)
    }

    private func lerp(_ a: Float, _ b: Float, _ t: Float) -> Float {
        return a + (b - a) * t
    }
}

extension Float {
    func clamped(to range: ClosedRange<Float>) -> Float {
        min(max(self, range.lowerBound), range.upperBound)
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
