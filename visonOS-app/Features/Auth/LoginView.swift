import SwiftUI

struct LoginView: View {
    @Environment(AppModel.self) private var appModel
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isPasswordVisible: Bool = false
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    @State private var isLoading: Bool = false

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black,
                    Color(red: 0.0, green: 0.15, blue: 0.18)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                HStack(spacing: 12) {
                    Image("Image")
                        .foregroundColor(.white)
                        .scaleEffect(x: 0.8, y: 0.8)
                    
                    Text("Synode")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                .padding(.bottom, 4)

                Text("Log in")
                    .font(.title)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.bottom, 10)

                // EMAIL FIELD
                VStack(alignment: .leading, spacing: 6) {
                    Text("Email")
                        .font(.footnote)
                        .foregroundColor(.gray)

                    TextField("", text: $email)
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 10)
                        .background(Color.white.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                        .foregroundColor(.white)
                }
                .frame(maxWidth: 320)

                // PASSWORD FIELD (đã chỉnh lại)
                VStack(alignment: .leading, spacing: 6) {
                    Text("Password")
                        .font(.footnote)
                        .foregroundColor(.gray)

                    HStack(spacing: 8) {
                        if isPasswordVisible {
                            TextField("", text: $password)
                                .textContentType(.password)
                                .foregroundColor(.white)
                                .font(.body)
                                .padding(.vertical, 6) // 👈 thấp hơn
                        } else {
                            SecureField("", text: $password)
                                .textContentType(.password)
                                .foregroundColor(.white)
                                .font(.body)
                                .padding(.vertical, 6)
                        }

                        Button(action: {
                            isPasswordVisible.toggle()
                        }) {
                            Image(systemName: isPasswordVisible ? "eye" : "eye.slash")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 14, height: 14) // 👈 nhỏ hơn
                                .foregroundColor(.gray.opacity(0.8))
                                .padding(.bottom, 1) // 👈 hạ thấp icon chút
                        }
                        .buttonStyle(.plain)
                        .padding(.trailing, 6)
                    }
                    .padding(.horizontal, 8)
                    .background(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                }
                .frame(maxWidth: 320)

                // ERROR TEXT
                if showError {
                    Text("\(errorMessage)")
                        .foregroundColor(.red)
                        .font(.footnote)
                }

            // Custom rounded button
            HStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                }
                Text(isLoading ? "Logging in..." : "Login")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: 320)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isFormValid && !isLoading ? Color.cyan : Color.gray.opacity(0.5))
            )
            .foregroundColor(.white)
            .shadow(color: Color.cyan.opacity(isFormValid ? 0.3 : 0), radius: 5, x: 0, y: 3)
            .onTapGesture {
                if isFormValid && !isLoading {
                    login()
                }
            }

                Spacer()
            }
            .padding(.top, 100)
        }
    }

    private var isFormValid: Bool {
        !email.isEmpty && !password.isEmpty
    }

    private func login() {
        performLogin(email: email, password: password)
    }

    private func performLogin(email: String, password: String) {
        isLoading = true
        showError = false

        Task {
            do {
                let response = try await APIClient.shared.login(email: email, password: password)
                await MainActor.run {
                    if response.success {
                        if let token = response.token {
                            UserDefaults.standard.set(token, forKey: "auth_token")
                            if let payload = decodeJWT(token),
                               let id = payload.id {
                                appModel.login(token: token, userID: id)
                                print("User ID decoded from token: \(id)")
                            } else {
                                print("Could not decode user ID from JWT")
                            }
                        }

                        if let refreshToken = response.refresh {
                            UserDefaults.standard.set(refreshToken, forKey: "refresh_token")
                            appModel.refreshToken = refreshToken
                            print("Refresh token saved")
                        }

                    } else {
                        errorMessage = "Login failed"
                        showError = true
                    }
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                    isLoading = false
                }
            }
        }
    }
}

#Preview {
    LoginView()
        .environment(AppModel())
}
