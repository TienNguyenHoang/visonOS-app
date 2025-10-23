import SwiftUI

struct ProjectView: View {
    @Environment(AppModel.self) private var appModel
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    @State private var searchText: String = ""

    // MARK: - Computed filtered projects
    private var filteredProjects: [Project] {
        if searchText.isEmpty {
            return appModel.projects
        } else {
            return appModel.projects.filter { project in
                let title = project.properties?.title?["en"] ?? ""
                return title.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    var body: some View {
        ZStack {
            backgroundGradient

            VStack(alignment: .leading, spacing: 24) {
                if isLoading {
                    ProgressView("Loading projects...")
                } else if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                } else {
                    headerSection
                    searchBar
                    projectListSection
                    Spacer()
                    footerSection
                }
            }
            .padding(32)
        }
        .ignoresSafeArea()
        .task {
            await loadProjects()
        }
    }

    // MARK: - UI Sections

    private var backgroundGradient: some View {
        RoundedRectangle(cornerRadius: 24)
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
            .padding()
    }

    private var headerSection: some View {
        VStack(alignment: .center, spacing: 8) {
            Text("Synode")
                .font(.system(size: 40, weight: .bold))
                .foregroundColor(.white)

            Text("3D Immersive Instructions")
                .font(.headline)
                .foregroundColor(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
    }

    // ✅ SearchBar có textfield thực sự
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)

            TextField("Search for your product", text: $searchText)
                .foregroundColor(.white)
                .textFieldStyle(.plain)
                .disableAutocorrection(true)

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }

    private var projectListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Explore Instructions")
                .font(.title2)
                .bold()
                .foregroundColor(.white)

            if filteredProjects.isEmpty {
                Text("No projects found.")
                    .foregroundColor(.gray)
                    .padding(.top, 20)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(filteredProjects) { project in
                            Button {
                                appModel.selectedProject = project
                            } label: {
                                ProductCardView(
                                    imageURL: project.firstImageURL,
                                    title: project.properties?.title?["en"] ?? "Unnamed"
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
        }
    }

    private var footerSection: some View {
        Text("Access the full Synode library of projects on the mobile app.")
            .font(.footnote)
            .foregroundColor(.white.opacity(0.8))
            .frame(maxWidth: .infinity, alignment: .center)
    }

    // MARK: - Load Projects

    func loadProjects() async {
        guard let userID = appModel.userID else {
            errorMessage = "Missing user info"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let projects = try await APIClient.shared.fetchProjects(for: userID)
            await MainActor.run {
                appModel.projects = projects
            }
        } catch let error as APIError {
            await MainActor.run {
                if case .tokenExpired = error {
                    // Token expired, logout user
                    appModel.logout()
                } else {
                    errorMessage = error.localizedDescription
                }
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
            }
        }

        isLoading = false
    }
}


// MARK: - Product Card Component

struct ProductCardView: View {
    let imageURL: String?
    let title: String

    var body: some View {
        VStack(spacing: 12) {
            if let imageURL = imageURL, let url = URL(string: imageURL) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(height: 60)
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                            .frame(height: 60)
                    case .failure:
                        Image(systemName: "cube.box.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 60)
                            .foregroundColor(.gray)
                    @unknown default:
                        EmptyView()
                    }
                }
            } else {
                Image(systemName: "cube.box.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 60)
                    .foregroundColor(.gray)
            }

            Text(title)
                .font(.headline)
                .foregroundColor(.white)
                .lineLimit(1)
                .truncationMode(.tail)
        }
        .frame(width: 200, height: 160)
        .background(Color.white.opacity(0.08))
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
        )
    }
}

#Preview {
    ProjectView()
        .environment(AppModel())
}
