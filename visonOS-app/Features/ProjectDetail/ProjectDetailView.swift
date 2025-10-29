import SwiftUI
import RealityKit

struct ProjectDetailView: View {
    @Environment(AppModel.self) private var appModel
    
    @State private var instructions: [InstructionDetail] = []
    @State private var selectedTab: String = "Version History"
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 36)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.black,
                            Color(red: 0.0, green: 0.15, blue: 0.18)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(radius: 20)
            
            VStack(alignment: .leading, spacing: 16) {
                headerSection
                
                if isLoading {
                    VStack {
                        Spacer()
                        ProgressView("Loading instructions...")
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                } else {
                    instructionHeader
                    tabSelector
                    
                    Group {
                        if selectedTab == "Version History" {
                            versionHistoryList
                        } else {
                            documentPlaceholder
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .padding(.horizontal)
        }
        .task {
            await loadInstructions()
        }
    }
    
    private var headerSection: some View {
        HStack(spacing: 16) {
            Button {
                appModel.currentScreen = .projectList
            } label: {
                Label("", systemImage: "chevron.left")
                    .foregroundColor(.white)
                    .padding(8)
                    .cornerRadius(8)
            }
            
            Text(appModel.selectedProject?.properties?.title?["en"] ?? "Project Detail")
                .font(.title2)
                .bold()
                .foregroundColor(.white)
            
            Spacer()
        }
        .padding(.top, 24)
    }
    
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
        }
    }
    
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

    
    private var versionHistoryList: some View {
        List {
            Section(header: Text("Version History")
                .font(.headline)
                .foregroundColor(.white)
            ) {
                if !instructions.isEmpty {
                    ForEach(Array(instructions.reversed().enumerated()), id: \.offset)
                    { idx, instruction in
                        VersionRow(
                            index: idx,
                            total: instructions.count,
                            instruction: instruction,
                            onSelect: { appModel.selectVersion(instruction.id) }
                        )
                    }
                } else {
                    Text("No version data available.")
                        .foregroundColor(.gray)
                        .padding(.vertical, 8)
                        .listRowBackground(Color.clear)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.clear)
    }
    
    private struct VersionRow: View {
        let index: Int
        let total: Int
        let instruction: InstructionDetail
        let onSelect: () -> Void
        
        var body: some View {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Version \(total - index)")
                        .font(.headline)
                        .foregroundColor(.white)

                    Text(formattedDate(from: instruction.updatedAt ?? instruction.createdAt))
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                Spacer()

                statusBadge(isPublished: instruction.status == "published" ? true : false)

                Menu {
                    Button("View", action: onSelect)
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .padding(.vertical, 8)
            .listRowBackground(Color.white.opacity(0.08))
            .cornerRadius(12)
        }
    }
    
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

private func formattedDate(from isoString: String?) -> String {
    guard let isoString = isoString else { return "-" }

    let isoFormatter = ISO8601DateFormatter()
    isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

    guard let date = isoFormatter.date(from: isoString)
       ?? ISO8601DateFormatter().date(from: isoString) else { return "-" }

    let displayFormatter = DateFormatter()
    displayFormatter.dateStyle = .long
    displayFormatter.timeStyle = .none
    displayFormatter.locale = Locale(identifier: "en_US_POSIX")

    return displayFormatter.string(from: date)
}

private func statusBadge(isPublished: Bool) -> some View {
    HStack(spacing: 6) {
        Circle()
            .fill(isPublished ? Color.green : Color.gray)
            .frame(width: 8, height: 8)
        Text(isPublished ? "Published" : "Offline")
            .font(.caption)
            .foregroundColor(.white)
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isPublished ? Color.green.opacity(0.3) : Color.white.opacity(0.1))
            )
    }
}

#Preview {
    ProjectDetailView()
        .environment(AppModel())
}
