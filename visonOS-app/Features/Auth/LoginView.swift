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
                Image(systemName: "circle.dashed")
                    .resizable()
                    .frame(width: 60, height: 60)
                    .foregroundColor(.cyan)
                    .padding(.bottom, 4)

                Text("Log in")
                    .font(.title)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.bottom, 10)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Email")
                        .font(.footnote)
                        .foregroundColor(.gray)

                    TextField("", text: $email)
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                        .padding(10)
                        .background(Color.white.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                        .foregroundColor(.white)
                }
                .frame(maxWidth: 320)


                VStack(alignment: .leading, spacing: 6) {
                    Text("Password")
                        .font(.footnote)
                        .foregroundColor(.gray)

                    HStack {
                        if isPasswordVisible {
                            TextField("", text: $password)
                                .textContentType(.password)
                                .foregroundColor(.white)
                        } else {
                            SecureField("", text: $password)
                                .textContentType(.password)
                                .foregroundColor(.white)
                        }

                        Button(action: {
                            isPasswordVisible.toggle()
                        }) {
                            Image(systemName: isPasswordVisible ? "eye" : "eye.slash")
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(10)
                    .background(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                }
                .frame(maxWidth: 320)

                // Error text
                if showError {
                    Text("\(errorMessage)")
                        .foregroundColor(.red)
                        .font(.footnote)
                }

                // Login button
                Button(action: login) {
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
                    .background(isFormValid && !isLoading ? Color.cyan : Color.gray.opacity(0.4))
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .disabled(!isFormValid || isLoading)

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
                        appModel.isLoggedIn = true
                        if let token = response.token {
                            UserDefaults.standard.set(token, forKey: "auth_token")
                            appModel.jwtToken = token
                            if let payload = decodeJWT(token),
                               let id = payload.id {
                                appModel.userID = id
                                print("userID \(id)")
                                print("User ID decoded from token: \(id)")
                            } else {
                                print("Could not decode user ID from JWT")
                            }
                        }
                    } else {
                        print("test2")
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
