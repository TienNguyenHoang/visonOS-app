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

            VStack(spacing: 24) {
                Image("Image")
                    .foregroundColor(.white)
                    .scaleEffect(x: 0.6, y: 0.6)
                    .padding(.bottom, 3)

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
                                .padding(.vertical, 6)
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
                                .frame(width: 14, height: 14)
                                .foregroundColor(.gray.opacity(0.8))
                                .padding(.bottom, 1)
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
                    
                    if showError {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.footnote)
                            .padding(.top, 8)
                    }
                }
                .frame(maxWidth: 320)

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

    @MainActor
    private func performLogin(email: String, password: String) {
        isLoading = true
        showError = false
        errorMessage = ""

        Task {
            do {
                let response = try await APIClient.shared.login(email: email, password: password)
                
                guard
                    let token = response.token,
                    let refreshToken = response.refresh,
                    let payload = decodeJWT(token),
                    let id = payload.id
                else {
                    await MainActor.run {
                        errorMessage = "Login failed: Invalid server response"
                        showError = true
                        isLoading = false
                    }
                    return
                }

                await MainActor.run {
                    appModel.login(jwt_token: token, refresh_token: refreshToken, userID: id)
                    isLoading = false
                }

            } catch {
                await MainActor.run {
                    if error.localizedDescription == "Unauthorized" {
                        errorMessage = "Invalid userName or password"
                    } else {
                        errorMessage = error.localizedDescription
                    }
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
