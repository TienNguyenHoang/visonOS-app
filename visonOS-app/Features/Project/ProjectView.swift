import SwiftUI

struct ProjectView: View {
    @Environment(AppModel.self) private var appModel
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    @State private var searchText: String = ""

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

            VStack(spacing: 40) {
                headerSection
                
                searchBar
                    .padding(.horizontal, 80)

                Group {
                    if isLoading {
                        Spacer()
                        ProgressView("Loading projects...")
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .center)
                        Spacer()
                    } else if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    } else {
                        projectListSection
                    }
                }
                .padding(.horizontal, 50)

                Spacer(minLength: 20)
                footerSection
            }
            .padding(.vertical, 50)
        }
        .task {
            if appModel.projects.isEmpty {
                await loadProjects()
            }
        }
    }

    private var headerSection: some View {
        HStack {
            Spacer()
            Button {
                appModel.logout()
            } label: {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.title3)
                    .foregroundColor(.red)
                    .padding(8)
                    .clipShape(Circle())
            }
        }
        .overlay(
            VStack(spacing: 4) {
                Text("Synode")
                    .font(.system(size: 42, weight: .bold))
                    .foregroundColor(.white)
                Text("3D Immersive Instructions")
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.7))
            }
        )
        .padding(.horizontal)
        .frame(maxWidth: .infinity)

    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.white.opacity(0.7))

            TextField("Search for your product", text: $searchText)
                .foregroundColor(.white)
                .textFieldStyle(.plain)
                .disableAutocorrection(true)
                .autocapitalization(.none)

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white.opacity(0.7))
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.08))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 4)
    }

    private var projectListSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Explore Instructions")
                .font(.title2.bold())
                .foregroundColor(.white)
                .padding(.leading, 10)

            if filteredProjects.isEmpty {
                VStack {
                    Spacer(minLength: 40)
                    Text("No projects found.")
                        .foregroundColor(.gray)
                        .padding(.top, 20)
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 180)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 24) {
                        ForEach(filteredProjects) { project in
                            Button {
                                appModel.selectProject(project)
                            } label: {
                                ProjectCardView(
                                    imageURL: project.firstImageURL,
                                    title: project.properties?.title?["en"] ?? "Unnamed"
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, 10)
                }
            }
        }
    }

    private var footerSection: some View {
        Text("Access the full Synode library of projects on the mobile app.")
            .font(.footnote)
            .foregroundColor(.white.opacity(0.7))
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.bottom, 20)
    }

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

struct ProjectCardView: View {
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
                            .shadow(radius: 6)
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
        }
        .frame(width: 200, height: 160)
        .background(Color.white.opacity(0.07))
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.4), radius: 12, x: 0, y: 6)
        .hoverEffect(.lift)
    }
}

#Preview {
    ProjectView()
        .environment(AppModel())
}
