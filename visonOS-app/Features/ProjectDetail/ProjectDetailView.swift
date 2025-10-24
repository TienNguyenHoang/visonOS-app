import SwiftUI
import RealityKit

struct ProjectDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppModel.self) private var appModel
    
    @State private var instructions: [InstructionDetail] = []
    @State private var selectedTab: String = "Version History"
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    var body: some View {
        ZStack {
            // --- Background ---
            RoundedRectangle(cornerRadius: 32)
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 16) {
                headerSection
                
                if isLoading {
                    ProgressView("Loading instructions...")
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 100)
                } else if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                } else {
                    // Ảnh & tiêu đề luôn hiển thị
                    instructionHeader
                    
                    // Tabs
                    tabSelector
                    
                    // Nội dung tab
                    Group {
                        if selectedTab == "Version History" {
                            versionHistorySection
                        } else {
                            documentPlaceholder
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .padding(.horizontal)
        }
        .background(Color.black)
        .task {
            await loadInstructions()
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        HStack(spacing: 16) {
            Button {
                appModel.currentScreen = .projectList
            } label: {
                Label("", systemImage: "chevron.left")
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
        .padding(.top, 24)
    }
    
    // MARK: - Instruction Header
    private var instructionHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let imageURL = appModel.selectedProject?.properties?.media,
               let url = URL(string: imageURL) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 220)
                        .cornerRadius(16)
                } placeholder: {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: 200)
                }
            } else {
                Image(systemName: "photo.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 200)
                    .foregroundColor(.gray)
                    .cornerRadius(16)
            }
            
            Text(instructions.first?.title?["en"] ?? "No title")
                .font(.headline)
                .foregroundColor(.white)
        }
    }
    
    // MARK: - Tab Selector
    private var tabSelector: some View {
        HStack {
            ForEach(["Version History", "Documents"], id: \.self) { tab in
                Button(action: {
                    selectedTab = tab
                }) {
                    VStack {
                        Text(tab)
                            .foregroundColor(selectedTab == tab ? .white : .gray)
                            .fontWeight(selectedTab == tab ? .semibold : .regular)
                        Rectangle()
                            .frame(height: 2)
                            .foregroundColor(selectedTab == tab ? .white : .clear)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.top, 8)
    }
    
    // MARK: - Version History Section
    private var versionHistorySection: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Header row
                HStack {
                    tableHeader("Version")
                    tableHeader("Last edited")
                    tableHeader("Status")
                    Spacer()
                }
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.08))
                .cornerRadius(12)
                
                Divider().background(Color.white.opacity(0.2))
                
                // Table rows
                if let first = instructions.first,
                   let versions = first.versions, !versions.isEmpty {
                    ForEach(Array(versions.enumerated()), id: \.offset) { idx, version in
                        HStack {
                            tableCell("Version \(versions.count - idx)")
                            tableCell(version.lastEditedDate ?? "-")
                            statusBadge(isPublished: version.isPublished)
                            Spacer()
                            
                            // Menu actions
                            Menu {
                                Button("View") {
                                    appModel.currentScreen = .instruction
                                }
                                Button("Duplicate") {
                                    // Thêm logic nếu cần
                                }
                            } label: {
                                Image(systemName: "ellipsis")
                                    .foregroundColor(.white.opacity(0.8))
                                    .padding(.horizontal, 8)
                            }
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 4)
                        .background(idx == 0 ? Color.cyan.opacity(0.25) : Color.white.opacity(0.05))
                        .cornerRadius(10)
                        .padding(.vertical, 2)
                    }
                } else {
                    Text("No version data available.")
                        .foregroundColor(.gray)
                        .padding(.top, 12)
                }
            }
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
    }
    
    // MARK: - Document Placeholder
    private var documentPlaceholder: some View {
        ScrollView {
            VStack {
                Image(systemName: "doc.text.fill")
                    .resizable()
                    .frame(width: 40, height: 50)
                    .foregroundColor(.gray)
                Text("No documents available.")
                    .foregroundColor(.gray)
                    .padding(.top, 8)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.top, 40)
        }
    }
    
    // MARK: - Table Components
    private func tableHeader(_ text: String) -> some View {
        Text(text)
            .font(.caption)
            .foregroundColor(.gray)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func tableCell(_ text: String) -> some View {
        Text(text)
            .font(.subheadline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func statusBadge(isPublished: Bool) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(isPublished ? Color.green : Color.gray)
                .frame(width: 8, height: 8)
            Text(isPublished ? "Published" : "Offline")
                .font(.caption)
                .foregroundColor(isPublished ? .white : .gray)
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isPublished ? Color.green.opacity(0.3) : Color.white.opacity(0.1))
                )
        }
    }
    
    // MARK: - API Loader
    @MainActor
    private func loadInstructions() async {
        guard let projectId = appModel.selectedProject?.id else {
            errorMessage = "No project selected."
            isLoading = false
            return
        }
        
        do {
            let data = try await APIClient.shared.fetchInstructionDetails(for: projectId)
            self.instructions = data
            self.isLoading = false
        } catch {
            self.errorMessage = "Failed to load instructions: \(error.localizedDescription)"
            self.isLoading = false
        }
    }
}

// MARK: - Version Model (extend InstructionDetail)
extension InstructionDetail {
    var versions: [InstructionVersion]? {
        sections?.first?.steps?.enumerated().map { (index, step) in
            InstructionVersion(
                versionNumber: index + 1,
                lastEditedDate: "Jan 14, 2025",
                isPublished: index % 2 == 1 // giả lập
            )
        }
    }
}

struct InstructionVersion: Identifiable {
    let id = UUID()
    let versionNumber: Int
    let lastEditedDate: String?
    let isPublished: Bool
}
