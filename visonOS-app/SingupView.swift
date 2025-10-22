
import SwiftUI

struct SignUpView: View {
    @Environment(AppModel.self) private var appModel
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isPasswordVisible = false
    @State private var isConfirmVisible = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        ZStack {
            // Nền gradient xanh đen giống ảnh
            LinearGradient(gradient: Gradient(colors: [Color.black, Color.teal.opacity(0.8)]),
                           startPoint: .top,
                           endPoint: .bottom)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                HStack {
                    Button(action: {
                        appModel.currentAuthState = .login
                    }) {
                        Label("Back to Login", systemImage: "arrow.left")
                            .padding(8)
                            .background(Color.black.opacity(0.2))
                            .cornerRadius(8)
                    }
                    .foregroundColor(.white)
                    .padding(.leading)
                    Spacer()
                }
                
                Spacer()
                
                Image(systemName: "atom")
                    .font(.system(size: 50))
                    .foregroundColor(.teal)
                    .padding(.bottom, 10)
                Text("Create Account")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Group {
                    TextField("First Name", text: $firstName)
                        .textFieldStyle(.roundedBorder)
                    TextField("Last Name", text: $lastName)
                        .textFieldStyle(.roundedBorder)
                    TextField("Email", text: $email)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.emailAddress)
                    
                    HStack {
                        if isPasswordVisible {
                            TextField("Password", text: $password)
                        } else {
                            SecureField("Password", text: $password)
                        }
                        Button(action: { isPasswordVisible.toggle() }) {
                            Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                                .foregroundColor(.gray)
                        }
                    }
                    .textFieldStyle(.roundedBorder)
                    
                    HStack {
                        if isConfirmVisible {
                            TextField("Confirm Password", text: $confirmPassword)
                        } else {
                            SecureField("Confirm Password", text: $confirmPassword)
                        }
                        Button(action: { isConfirmVisible.toggle() }) {
                            Image(systemName: isConfirmVisible ? "eye.slash" : "eye")
                                .foregroundColor(.gray)
                        }
                    }
                    .textFieldStyle(.roundedBorder)
                }
                .frame(maxWidth: 400)
                
                if showError {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.footnote)
                }
                
                Button(action: signUp) {
                    Text("Create Account")
                        .frame(maxWidth: 400)
                        .padding()
                        .background(Color.teal.opacity(0.6))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .disabled(!isFormValid)
                .opacity(isFormValid ? 1 : 0.5)
                
                Spacer()
            }
            .padding()
        }
    }
    
    // MARK: - Validation
    var isFormValid: Bool {
        !firstName.isEmpty &&
        !lastName.isEmpty &&
        !email.isEmpty &&
        !password.isEmpty &&
        password == confirmPassword
    }
    
    // MARK: - Sign up logic
    func signUp() {
        guard isFormValid else {
            showError = true
            errorMessage = "Please fill all fields correctly."
            return
        }
        
        // Giả lập xử lý đăng ký
        print("✅ Account created for \(email)")
        showError = false
        
        // Tự động đăng nhập sau khi đăng ký thành công
        appModel.userEmail = email
        appModel.isLoggedIn = true
    }
}

#Preview {
    SignUpView()
        .environment(AppModel())
}
