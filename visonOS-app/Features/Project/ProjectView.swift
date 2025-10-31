import SwiftUI

struct Brand: Identifiable {
    let id = UUID()
    let name: String
    let category: String
    let logoURL: String
}

private let fakeBrands: [Brand] = [
    Brand(name: "Bestar", category: "Furniture", logoURL: "https://media.licdn.com/dms/image/v2/C4D0BAQEgYYxBBcVm6w/company-logo_200_200/company-logo_200_200/0/1630560956031/bestar_logo?e=2147483647&v=beta&t=nIy7na_nlSQ0g4G6-nn5O3ywNAI_QddrJZNx3XOxe9c"),
    Brand(name: "BRP", category: "Vehicular", logoURL: "https://upload.wikimedia.org/wikipedia/en/thumb/c/c6/BRP_inc_logo.svg/1200px-BRP_inc_logo.svg.png"),
    Brand(name: "Gale Pacific", category: "Building Materials", logoURL: "https://media.licdn.com/dms/image/v2/C560BAQGa2iR1qt6siw/company-logo_200_200/company-logo_200_200/0/1631364152168?e=2147483647&v=beta&t=n5D5id2nS0Spemy4pgSao3qZZp2HrMSHgDK5sW6ReEU"),
    Brand(name: "Mitsubishi Electric", category: "Industrial", logoURL: "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSe6TFHAotpk__o-ZhW1GMlRXW5bNn54LIR7w&s"),
    Brand(name: "Ford", category: "Automotive", logoURL: "https://yt3.googleusercontent.com/AyCV427GJWM0-na5D6q6_9-Zgn9JzLk62kcpKNWgllq2qjfsN2SwKKXjGfi1xOcBTghZeUhf=s176-c-k-c0x00ffffff-no-rj-mo"),
    Brand(name: "Palliser", category: "Furniture", logoURL: "https://images.squarespace-cdn.com/content/v1/6228f4b688354547aae067ec/08175e0f-022b-4186-bca7-6eb5cf0a2a65/Palliser+Furniture+logo.png")
]

struct ProjectView: View {
    @Environment(AppModel.self) private var appModel
    @State private var selectedCategory: String = "All"
    @State private var searchText: String = ""
    @State private var isLoading = false
    @State private var errorMessage: String? = nil

    let categories = ["All", "Builder", "Visualizer", "Localizer", "Private"]

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
            RoundedRectangle(cornerRadius: 40)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.3, green: 0.32, blue: 0.35).opacity(0.45),
                            Color(red: 0.18, green: 0.19, blue: 0.22).opacity(0.55)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .black.opacity(0.25), radius: 20, x: 0, y: 8)


            VStack(alignment: .leading, spacing: 30) {
                topBar
                
                categoryTabs
                    .padding(.horizontal, 30)
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 40) {
                        brandSection
                        instructionSection
                    }
                    .padding(.horizontal, 100)
                    .padding(.bottom, 40)
                }
            }
            .padding(.top, 20)
        }
        .frame(maxWidth: 1200, maxHeight: 800)
        .task {
            if appModel.projects.isEmpty {
                await loadProjects()
            }
        }
    }

    private var topBar: some View {
        HStack(spacing: 18) {
            HStack(alignment: .center, spacing: 12) {
                Image("Image")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 28, height: 28)
                    .foregroundColor(.white)

                Text("synode")
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.bottom, 8)
            }

            Spacer()

            HStack(spacing: 12) {
                HStack(spacing: 10) {
                    
                    TextField("Search", text: $searchText)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .textFieldStyle(.plain)
                        .disableAutocorrection(true)
                        .autocapitalization(.none)
                    
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.white.opacity(0.7))
                    
                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .frame(height: 44)
                .frame(maxWidth: 560)
                .background(
                    RoundedRectangle(cornerRadius: 22)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.black.opacity(0.45),
                                    Color.black.opacity(0.25)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .padding(.horizontal, 16)


            Spacer()

            HStack(spacing: 12) {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Good morning,")
                        .foregroundColor(.white.opacity(0.7))
                        .font(.subheadline)
                    Text("John")
                        .foregroundColor(.blue)
                        .fontWeight(.semibold)
                        .font(.subheadline)
                }

                Menu {
                    Button {
                        
                    } label: {
                        Label("Profile", systemImage: "person.circle")
                    }

                    Button {
                        appModel.logout()
                    } label: {
                        Label("Logout", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                } label: {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .frame(width: 36, height: 36)
                        .foregroundColor(.white.opacity(0.9))
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.15), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                }
                .menuIndicator(.hidden)
                .buttonStyle(.plain)
            }

        }
        .padding(.horizontal, 30)
    }

    private var categoryTabs: some View {
        HStack(spacing: 0) {
            ForEach(categories, id: \.self) { category in
                Button {
                    selectedCategory = category
                } label: {
                    Text(category)
                        .font(.system(size: 16, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .foregroundColor(selectedCategory == category ? .white : .white.opacity(0.6))
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(
                                    selectedCategory == category
                                    ? Color.white.opacity(0.15)
                                    : Color.clear
                                )
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(6)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.black.opacity(0.65),
                            Color.black.opacity(0.45)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .shadow(color: .black.opacity(0.35), radius: 10, x: 0, y: 4)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 30)
    }

    private var brandSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Brands")
                .font(.title2)
                .foregroundColor(.white)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 40) {
                    ForEach(fakeBrands) { brand in
                        VStack(spacing: 10) {
                            AsyncImage(url: URL(string: brand.logoURL)) { phase in
                                switch phase {
                                case .empty:
                                    ProgressView()
                                        .frame(width: 80, height: 80)
                                case .success(let image):
                                    image.resizable()
                                        .scaledToFit()
                                        .frame(width: 120, height: 120)
                                        .clipShape(Circle())
                                case .failure:
                                    Circle()
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(width: 120, height: 120)
                                @unknown default:
                                    EmptyView()
                                }
                            }
                            Text(brand.name)
                                .foregroundColor(.white)
                                .font(.headline)
                            Text(brand.category)
                                .foregroundColor(.white.opacity(0.6))
                                .font(.caption)
                        }
                    }
                }
                .padding(.horizontal, 10)
            }
        }
    }

    private var instructionSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack {
                Text("Instructions")
                    .font(.title2)
                    .foregroundColor(.white)
                Spacer()
                Button("Show all") {}
                    .foregroundColor(.white.opacity(0.6))
                    .font(.subheadline)
            }

            if isLoading {
                ProgressView("Loading projects...")
                    .foregroundColor(.white)
            } else if let errorMessage = errorMessage {
                Text(errorMessage).foregroundColor(.red)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 24) {
                        ForEach(filteredProjects) { project in
                            ProjectCardView(
                                imageURL: project.firstImageURL,
                                title: project.properties?.title?["en"] ?? "Unnamed",
                                subtitle:  ""
                            )
                            .onTapGesture {
                                appModel.selectProject(project)
                            }
                        }
                    }
                }
            }
        }
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
    let subtitle: String

    var body: some View {
        VStack(spacing: 8) {
            AsyncImage(url: URL(string: imageURL ?? "")) { phase in
                switch phase {
                case .empty:
                    ProgressView().frame(height: 100)
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFit()
                        .frame(height: 100)
                case .failure:
                    Image(systemName: "cube.box.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 100)
                        .foregroundColor(.gray)
                @unknown default:
                    EmptyView()
                }
            }

            Text(title)
                .font(.headline)
                .foregroundColor(.white)

            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(width: 180, height: 200)
//        .background(
//            Color.white.opacity(0.06)
//        )
//        .cornerRadius(24)
        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
        .hoverEffect(.lift)
    }
}


#Preview {
    ProjectView()
        .environment(AppModel())
}
