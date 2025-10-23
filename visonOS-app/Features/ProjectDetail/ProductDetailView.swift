import SwiftUI
import RealityKit
import RealityKitContent

// MARK: - Model (single definition)
struct InstructionRow: Identifiable {
    let id = UUID()
    let index: Int
    let instructionID: Int
    let guideID: String
    let variantID: Int
}

// MARK: - Main View
struct ProductDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppModel.self) private var appModel

    // ✅ Dữ liệu mẫu — sau này bạn có thể load từ API
    let rows: [InstructionRow] = [
        InstructionRow(index: 0, instructionID: 187, guideID: "67d3efb8ac45b03180b3d0c1", variantID: 1)
    ]

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
                paginationView
            }
        }
        .background(Color.black)
    }
}

// MARK: - Header Section
private extension ProductDetailView {
    var headerSection: some View {
        HStack {
            Text("Instruction Table")
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

// MARK: - Table Header
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
        ScrollView {
            VStack(spacing: 0) {
                ForEach(rows) { row in
                    InstructionRowView(row: row)
                }
            }
        }
    }
}

// MARK: - Pagination Section
private extension ProductDetailView {
    var paginationView: some View {
        HStack {
            Text("Rows per page:")
                .foregroundColor(.gray)
                .font(.footnote)

            Picker("", selection: .constant(10)) {
                Text("10").tag(10)
                Text("25").tag(25)
                Text("50").tag(50)
            }
            .pickerStyle(.menu)
            .frame(width: 60)

            Spacer()

            Text("1–1 of 1")
                .foregroundColor(.gray)
                .font(.footnote)

            HStack(spacing: 12) {
                Button(action: {}) {
                    Image(systemName: "chevron.left")
                }
                Button(action: {}) {
                    Image(systemName: "chevron.right")
                }
            }
            .foregroundColor(.gray)
        }
        .padding(.horizontal)
        .padding(.bottom, 20)
    }
}

// MARK: - Reusable Table Row View
struct InstructionRowView: View {
    let row: InstructionRow
    @Environment(AppModel.self) private var appModel

    var body: some View {
        HStack {
            tableCell("\(row.index)")
            tableCell("\(row.instructionID)")
            tableCell(row.guideID)
            tableCell("\(row.variantID)")

            Spacer()

            Menu {
                Button("Instruction Details") {
                    appModel.currentAppState = .instruction
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

// MARK: - Preview
#Preview {
    ProductDetailView()
        .environment(AppModel())
        .frame(width: 1000, height: 600)
        .background(Color.black)
}
