import SwiftUI
import RealityKit
import RealityKitContent

struct InstructionsView: View {
    @Environment(AppModel.self) private var appModel
    @State private var stepIndex = 0
    
    private let steps: [InstructionStep] = [
        InstructionStep(
            title: "Step 1",
            description: "This procedure will assist you with assembling the desk.",
            modelName: "Scene" // sử dụng Scene.usda có sẵn
        )
        // bạn có thể thêm Step 2, 3 ở đây
    ]
    
    var body: some View {
        ZStack {
            // Nền mờ bo tròn kiểu VisionOS
            RoundedRectangle(cornerRadius: 32)
                .fill(.regularMaterial)
                .opacity(0.8)
                .frame(width: 900, height: 600)
                .shadow(radius: 10)
            
            VStack(spacing: 20) {
                // Header với nút Back
                HStack {
                    Button(action: {
                        // Quay về InstructionView (DetailView)
                        appModel.currentAppState = .instructionDetail
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding(8)
                            .background(.gray.opacity(0.3))
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    Text("Assembly Instructions")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button(action: {
                        appModel.logout()
                    }) {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding(8)
                            .background(.red.opacity(0.7))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 40)
                .padding(.top, 20)
                
                HStack(spacing: 40) {
                    // LEFT PANEL - Text info
                    VStack(alignment: .leading, spacing: 16) {
                        Text(steps[stepIndex].title)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                    
                    Text("DESCRIPTION")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    
                    Text(steps[stepIndex].description)
                        .font(.body)
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                    
                    // Nút điều hướng step
                    HStack(spacing: 20) {
                        Button {
                            if stepIndex > 0 { stepIndex -= 1 }
                        } label: {
                            Image(systemName: "chevron.left")
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(stepIndex == 0)
                        
                        Button {
                            if stepIndex < steps.count - 1 { stepIndex += 1 }
                        } label: {
                            Image(systemName: "chevron.right")
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(stepIndex == steps.count - 1)
                    }
                }
                .padding(40)
                .frame(width: 350, alignment: .topLeading)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24))
                
                // RIGHT PANEL - 3D model
                ZStack {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(.thinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(.white.opacity(0.2))
                        )
                    
                    Model3DView(modelName: steps[stepIndex].modelName)
                        .frame(width: 450, height: 450)
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                }
                .frame(width: 500, height: 500)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

#Preview {
    InstructionsView()
        .environment(AppModel())
}

// MARK: - Model3DView Component
struct Model3DView: View {
    let modelName: String
    
    var body: some View {
        RealityView { content in
            if let entity = try? await Entity(named: modelName, in: realityKitContentBundle) {
                content.add(entity)
            }
        }
        .gesture(
            RotationGesture()
                .onChanged { angle in
                    // cho phép xoay model bằng tay
                }
        )
    }
}

// MARK: - Step Data Model
struct InstructionStep {
    let title: String
    let description: String
    let modelName: String
}
