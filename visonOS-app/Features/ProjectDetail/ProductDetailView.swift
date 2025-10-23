import SwiftUI
import RealityKit
import RealityKitContent


struct ProductDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppModel.self) private var appModel
    @State private var rowsPerPage: Int = 10

    var body: some View {
        ZStack {
            // Nền blur kiểu VisionOS
            RoundedRectangle(cornerRadius: 32)
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 16) {
                headerSection
                tableHeaderRow
                tableBody
            }
        }
        .background(Color.black)
    }
}

// MARK: - Header Section
private extension ProductDetailView {
    var headerSection: some View {
        HStack(spacing: 16) {
            Button {
                appModel.currentScreen = .projectList
            } label: {
                Label("Back", systemImage: "chevron.left")
                    .foregroundColor(.white)
                    .padding(8)
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(8)
            }

            Text(appModel.selectedProject?.properties?.title?["en"] ?? "Project Detail")
                .font(.title2)
                .bold()
                .foregroundColor(.white)

            Spacer()

            Button(action: {
                appModel.logout()
            }) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .foregroundColor(.white)
                    .padding(8)
                    .background(Color.red.opacity(0.8))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal)
        .padding(.top, 24)
    }
}

private extension ProductDetailView {
    var tableHeaderRow: some View {
        HStack {
            tableHeader("Index")
            tableHeader("Instruction ID")
            tableHeader("Guide ID")
            tableHeader("Variant ID")
            tableHeader("Actions", alignTrailing: true)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.08))
        .cornerRadius(12)
        .padding(.horizontal)
    }

    func tableHeader(_ text: String, alignTrailing: Bool = false) -> some View {
        HStack {
            if alignTrailing { Spacer() }
            Text(text)
                .font(.caption)
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity, alignment: alignTrailing ? .trailing : .leading)
        }
    }
}

// MARK: - Table Body
private extension ProductDetailView {
    var tableBody: some View {
        let instructions = appModel.selectedProject?.properties?.linkProject ?? []

        return ScrollView {
            if instructions.isEmpty {
                Text("No instructions found for this project.")
                    .foregroundColor(.gray)
                    .padding()
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(instructions.enumerated()), id: \.offset) { (index, instruction) in
                        InstructionRowView(index: index, instruction: instruction)
                    }
                }
            }
        }
    }
}

struct InstructionRowView: View {
    let index: Int
    let instruction: LinkInstruction
    @Environment(AppModel.self) private var appModel

    var body: some View {
        HStack {
            tableCell("\(index + 1)")
            tableCell("\(instruction.linkInstruction ?? 0)")
            tableCell(instruction.id ?? "-")
            tableCell(instruction.variantId ?? "-")

            Spacer()

            Menu {  
                Button("Instruction Details") {
                    if let id = instruction.linkInstruction {
                        appModel.selectInstruction(id)
                    } else {
                        print("instruction.linkInstruction nil")
                    }
                }
            } label: {
                Image(systemName: "ellipsis")
                    .foregroundColor(.white.opacity(0.8))
                    .frame(width: 32, height: 32)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal)
        .frame(height: 44)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.04)))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.05)))
        .padding(.horizontal)
        .padding(.vertical, 4)
    }

    private func tableCell(_ text: String) -> some View {
        Text(text)
            .font(.subheadline)
            .foregroundColor(.white)
            .lineLimit(1)
            .truncationMode(.middle)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

