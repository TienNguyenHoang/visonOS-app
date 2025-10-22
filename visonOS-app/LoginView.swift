import SwiftUI

struct LoginView: View {
    @Environment(AppModel.self) private var appModel
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isPasswordVisible: Bool = false
    @State private var showError: Bool = false

    var body: some View {
        ZStack {
            // 🌌 Background gradient
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
                // 🌀 Logo
                Image(systemName: "circle.dashed")
                    .resizable()
                    .frame(width: 60, height: 60)
                    .foregroundColor(.cyan)
                    .padding(.bottom, 4)

                // Tiêu đề
                Text("Log in")
                    .font(.title)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.bottom, 10)

                // Email field
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

                // Password field
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

                // Forgot password
                HStack {
                    Spacer()
                    Button(action: {}) {
                        Text("Forgot your password?")
                            .font(.footnote)
                            .foregroundColor(.gray)
                    }
                }
                .frame(maxWidth: 320)

                // Error text
                if showError {
                    Text("❌ Invalid email or password")
                        .foregroundColor(.red)
                        .font(.footnote)
                }

                // Login button
                Button(action: login) {
                    Text("Login")
                        .fontWeight(.semibold)
                        .frame(maxWidth: 320)
                        .padding()
                        .background(isFormValid ? Color.cyan : Color.gray.opacity(0.4))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .disabled(!isFormValid)

                // Sign up link
                VStack(spacing: 4) {
                    Text("Don’t have an account?")
                        .foregroundColor(.gray)
                        .font(.footnote)
                    Button(action: {
                        appModel.currentAuthState = .signup
                    }) {
                        Text("Sign up")
                            .foregroundColor(.cyan)
                            .font(.footnote)
                            .underline()
                    }
                }

                Spacer()
            }
            .padding(.top, 100)
        }
    }

    // MARK: - Logic
    private var isFormValid: Bool {
        !email.isEmpty && !password.isEmpty
    }

    private func login() {
        if email.lowercased() == "admin@example.com" && password == "123456" {
            appModel.isLoggedIn = true
        } else {
            showError = true
        }
    }
}

#Preview {
    LoginView()
        .environment(AppModel())
}
