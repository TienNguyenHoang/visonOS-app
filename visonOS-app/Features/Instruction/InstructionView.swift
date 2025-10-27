import SwiftUI
import RealityKit
import RealityKitContent

struct InstructionView: View {
    @Environment(AppModel.self) private var appModel
    @State private var stepIndex = 0
    @State private var isPlaying = false

    
    private let steps: [Model3DInstructionStep] = [
        Model3DInstructionStep(
            title: "Step 1",
            description: "This procedure will assist you with assembling the Solo Stove Pi Pizza Oven.",
            modelName: "Immersive"
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
                    VStack(alignment: .leading, spacing: 20) {
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

                        // Điều hướng step
                        HStack(spacing: 18) {
                            Spacer()
                            
                            Button {
                                if stepIndex > 0 { stepIndex -= 1 }
                            } label: {
                                Image(systemName: "chevron.left")
                                    .font(.title3)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.cyan)
                            .disabled(stepIndex == 0)
                            
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
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)
                    .frame(width: geo.size.width * 0.35)

                    ZStack {
                        Color.white
                        Model3DR(modelName: steps[stepIndex].modelName)
                            .padding(40)
                    }
                    .frame(width: geo.size.width * 0.65)
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
            if let entity = try? await Entity(named: modelName, in: realityKitContentBundle) {
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
