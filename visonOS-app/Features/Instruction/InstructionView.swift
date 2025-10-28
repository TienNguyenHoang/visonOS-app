import SwiftUI
import RealityKit
import RealityKitContent

struct InstructionView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow
    
    @State private var stepIndex = 0
    @State private var isPlaying = false
    @State private var isMuted = false
    @State private var isTransitioning = false

    private let steps: [Model3DInstructionStep] = [
        Model3DInstructionStep(
            title: "Step 1",
            description: "This procedure will assist you with assembling the Solo Stove Pi Pizza Oven.",
            modelName: "test5.usdz"
        )
    ]
    
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
                    // LEFT PANEL (Instruction)
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
                            Text(steps[stepIndex].title)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        )
                        
                        Text("DESCRIPTION")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.7))
                        Text(steps[stepIndex].description)
                            .font(.body)
                            .foregroundColor(.white)
                            .padding(.bottom, 20)
                        
                        Spacer()
                        
                        // CONTROL BUTTONS
                        HStack(spacing: 18) {
                            Spacer()
                            
                            // 🔈 Mute/Unmute
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
                                if stepIndex > 0 { stepIndex -= 1 }
                            } label: {
                                Image(systemName: "chevron.left")
                                    .font(.title3)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.cyan)
                            .disabled(stepIndex == 0)
                            
                            // ▶️ Play/Pause
                            Button {
                                isPlaying.toggle()
                            } label: {
                                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
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
                                if stepIndex < steps.count - 1 { stepIndex += 1 }
                            } label: {
                                Image(systemName: "chevron.right")
                                    .font(.title3)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.cyan)
                            .disabled(stepIndex == steps.count - 1)
                            
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
                            Model3DR(modelName: steps[stepIndex].modelName)
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
}

// MARK: - Model3DView
struct Model3DR: View {
    let modelName: String
    var body: some View {
        RealityView { content in
            if let entity = try? await Entity(named: modelName) {
                content.add(entity)
            }
        }
    }
}

// MARK: - Data Model
struct Model3DInstructionStep {
    let title: String
    let description: String
    let modelName: String
}
