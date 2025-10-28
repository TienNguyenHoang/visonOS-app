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
    
    @State private var steps: [Model3DInstructionStep] = []
    @State private var isLoading = true
    
    var cleanDescription: AttributedString {
        var attr = steps[appModel.currentStepIndex].description ?? AttributedString("")
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
                    .background(
                        LinearGradient(
                            colors: [Color.black.opacity(0.9), Color.gray.opacity(0.7)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .ignoresSafeArea()

                } else if steps.isEmpty {
                    Text("No steps found in project")
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    HStack(spacing: 0) {
                        VStack(alignment: .leading, spacing: 20) {
                            // Header
                            HStack(spacing: 12) {
                                Button {
                                    appModel.currentScreen = .projectDetail
                                } label: {
                                    Image(systemName: "chevron.left")
                                        .font(.title3)
                                        .foregroundColor(.white)
                                        .padding(8)
                                        .clipShape(Circle())
                                }
                                Spacer()
                            }
                            .overlay(
                                Text(steps[appModel.currentStepIndex].title)
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
                                
                                // ⬅️ Previous Step
                                Button {
                                    if appModel.currentStepIndex > 0 { appModel.currentStepIndex -= 1 }
                                } label: {
                                    Image(systemName: "chevron.left")
                                        .font(.title3)
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.cyan)
                                .disabled(appModel.currentStepIndex == 0)
                                
                                // ▶️ Play/Pause
                                Button {
                                    if appModel.isPlaying {
                                        appModel.isPlaying = false
                                    } else {
                                        appModel.isPlaying = true
                                        Task {
                                            while appModel.isPlaying {
                                                if appModel.currentStepIndex < steps.count - 1 {
                                                    appModel.currentStepIndex += 1
                                                } else {
                                                    appModel.currentStepIndex = 0
                                                }
                                                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1s mỗi step
                                            }
                                        }
                                    }
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
                                
                                // ➡️ Next Step
                                Button {
                                    if appModel.currentStepIndex < steps.count - 1 { appModel.currentStepIndex += 1 }
                                } label: {
                                    Image(systemName: "chevron.right")
                                        .font(.title3)
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.cyan)
                                .disabled(appModel.currentStepIndex == steps.count - 1)
                                
                                Spacer()
                                
                                // 🔹 Toggle Volumetric 3D window
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
                        .padding(.horizontal, 24)
                        .padding(.vertical, 20)
                        .frame(width: appModel.isVolumeShown ? geo.size.width : geo.size.width * 0.35)
                        .animation(.easeInOut(duration: 0.3), value: appModel.isVolumeShown)
                        
                        // RIGHT PANEL (Preview Placeholder)
                        if !appModel.isVolumeShown {
                            ZStack {
                                Color.gray.opacity(0.15)
                                Model3DStepViewer(modelName: appModel.modelName ?? "Scene",
                                                  currentStep: appModel.currentStepIndex,
                                                  mode: .plain)
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
            print("test1")
            await loadProjectJson()
        }
    }
    
    @MainActor
    func loadProjectJson() async {
        print("test2")
        guard let url = Bundle.main.url(forResource: "test5anim", withExtension: "json") else {
            print("❌ JSON not found")
            isLoading = false
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode(AnimationModel.self, from: data)
            
            print("✅ Loaded \(decoded.steps.count) steps")
            
            // 🔹 Map sang Model3DInstructionStep cho UI
            steps = decoded.steps.enumerated().map { index, step in
                let title = "Step \(index + 1)"
                let rawHTML = step.descriptionText.text.en
                let attr = rawHTML.htmlToAttributedString()
                return Model3DInstructionStep(
                    title: title,
                    description: attr,
                    modelName: appModel.modelName ?? "Scene"
                )
            }
            
        } catch {
            print("❌ Decode error:", error)
            steps = []
        }
        print("test3")
        isLoading = false
    }
}


struct Model3DStepViewer: View {
    let modelName: String
    let currentStep: Int
    let mode: ViewerMode
    
    @State private var sceneState = SceneState()
    @State private var project: AnimationModel?
    
    var body: some View {
        RealityView { content in
            if let entity = try? Entity.load(named: modelName) {
                let bounds = entity.visualBounds(relativeTo: nil)
                let maxDim = max(bounds.extents.x, bounds.extents.y, bounds.extents.z)
                
                let baseScale = 1.0 / maxDim
                let adjustedScale: Float = switch mode {
                    case .volumetric: Float(baseScale)
                    case .plain: Float(baseScale * 0.3) // giảm kích thước khi ở plain
                }
                
                entity.setScale(SIMD3(repeating: adjustedScale), relativeTo: nil)
                entity.position = -bounds.center * adjustedScale
                
                sceneState.rootEntity = entity
                content.add(entity)
            }
        }
    }
}


// MARK: - Data Model
struct Model3DInstructionStep {
    let title: String
    let description: AttributedString?
    let modelName: String
}
