import SwiftUI
import RealityKit
import RealityKitContent

struct Model3DView: View {
    @Environment(AppModel.self) private var appModel
    @State private var stepIndex = 0
    
    private let steps: [Model3DInstructionStep] = [
        Model3DInstructionStep(
            title: "Step 1",
            description: "This procedure will assist you with assembling the desk.",
            modelName: "Scene"
        )
    ]

    var body: some View {
        ZStack {
            // NỀN CHÍNH
            RoundedRectangle(cornerRadius: 36)
                .fill(.ultraThinMaterial)
                .frame(width: 950, height: 580)
                .shadow(radius: 20)
                .overlay(
                    RoundedRectangle(cornerRadius: 36)
                        .stroke(.white.opacity(0.15))
                )

            VStack(spacing: 28) {
                // MARK: - HEADER
                HStack {
                    Button {
                        appModel.currentScreen = .instruction
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.title3)
                            .foregroundColor(.white)
                            .padding(8)
                            .background(.gray.opacity(0.25))
                            .clipShape(Circle())
                    }

                    Spacer()

                    Text("Assembly Instructions")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)

                    Spacer()

                    Button {
                        appModel.logout()
                    } label: {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .font(.title3)
                            .foregroundColor(.white)
                            .padding(8)
                            .background(.red.opacity(0.8))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 36)
                .padding(.top, 16)

                // MARK: - CONTENT
                HStack(alignment: .center, spacing: 40) {
                    // PANEL TRÁI (Text)
                    VStack(alignment: .leading, spacing: 20) {
                        Text(steps[stepIndex].title)
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("DESCRIPTION")
                            .font(.headline)
                            .foregroundStyle(.secondary)

                        Text(steps[stepIndex].description)
                            .font(.body)
                            .foregroundStyle(.primary)
                            .padding(.bottom, 20)

                        Spacer()

                        // Nút điều hướng step
                        HStack(spacing: 18) {
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
                                if stepIndex < steps.count - 1 { stepIndex += 1 }
                            } label: {
                                Image(systemName: "chevron.right")
                                    .font(.title3)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.cyan)
                            .disabled(stepIndex == steps.count - 1)
                        }
                    }
                    .padding(32)
                    .frame(width: 340, height: 480, alignment: .topLeading)
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(.white.opacity(0.1))
                    )
                    .shadow(radius: 6, y: 4)

                    // PANEL PHẢI (3D)
                    ZStack {
                        RoundedRectangle(cornerRadius: 24)
                            .fill(.thinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 24)
                                    .stroke(.white.opacity(0.1))
                            )

                        Model3DR(modelName: steps[stepIndex].modelName)
                            .frame(width: 440, height: 440)
                            .clipShape(RoundedRectangle(cornerRadius: 24))
                    }
                    .frame(width: 500, height: 480)
                    .shadow(radius: 8, y: 6)
                }
                .padding(.horizontal, 36)
                .padding(.bottom, 20)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    Model3DView()
        .environment(AppModel())
}

// MARK: - Model3DView Component
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

// MARK: - Step Data Model
struct Model3DInstructionStep {
    let title: String
    let description: String
    let modelName: String
}
