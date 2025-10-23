import SwiftUI
import RealityKit
import RealityKitContent

struct InstructionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppModel.self) private var appModel

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Background blur / panel
            RoundedRectangle(cornerRadius: 32)
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack {
                    Button(action: { 
                        appModel.currentAppState = .productDetail
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding(8)
                            .background(.gray.opacity(0.3))
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    Text("Assembly")
                        .font(.footnote)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.15))
                        .clipShape(Capsule())
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
                .padding(.horizontal)
                .padding(.top, 16)

                // Title + model
                HStack(alignment: .center, spacing: 40) {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("stove-3.14159")
                            .font(.subheadline)
                            .foregroundColor(.gray)

                        Text("Solo Stove Pi Pizza Oven")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        // 3D model preview
                        Model3D(named: "Scene", bundle: realityKitContentBundle)
                            .frame(width: 300, height: 250)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .shadow(radius: 10)
                    }

                    // Info column (Tools + Parts)
                    VStack(alignment: .leading, spacing: 20) {
                        // Tools
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Tools")
                                .font(.headline)
                                .foregroundColor(.white)
                            Text("No tools needed")
                                .foregroundColor(.gray)
                                .font(.subheadline)
                        }

                        Divider().background(Color.white.opacity(0.2))

                        // Parts
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Parts")
                                .font(.headline)
                                .foregroundColor(.white)

                            HStack(spacing: 10) {
                                ForEach(0..<5) { i in
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.white.opacity(0.1))
                                        .frame(width: 48, height: 48)
                                        .overlay(
                                            Text("\(i+1)")
                                                .foregroundColor(.white)
                                                .font(.caption)
                                        )
                                }

                                Text("2 MORE")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color.white.opacity(0.1))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    Spacer()
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Bottom stats row
                HStack(spacing: 24) {
                    infoItem(title: "PERSON", value: "1", icon: "person.fill")
                    infoItem(title: "STEPS", value: "35", icon: "list.number")
                    infoItem(title: "MINUTES", value: "15", icon: "clock")

                    Spacer()

                    Button(action: {
                        // Chuyển sang InstructionsView
                        appModel.currentAppState = .instruction
                    }) {
                        Text("Start")
                            .font(.headline)
                            .frame(width: 100, height: 44)
                            .background(Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
        }
    }

    // MARK: - Helper view
    func infoItem(title: String, value: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.white)
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.headline)
                    .foregroundColor(.white)
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
        }
    }
}

#Preview {
    InstructionView()
        .frame(width: 900, height: 600)
        .background(Color.black)
}
