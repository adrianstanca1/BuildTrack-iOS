import SwiftUI

struct AuthView: View {
    @Environment(AuthManager.self) private var authManager
    @State private var showRegister = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()
                
                VStack(spacing: 32) {
                    Spacer()
                    
                    VStack(spacing: 12) {
                        Image(systemName: "building.columns.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(BuildTrackColors.primary)
                        Text("BuildTrack")
                            .font(.largeTitle.bold())
                        Text("Construction Management")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    if showRegister {
                        RegisterForm()
                    } else {
                        LoginForm()
                    }
                    
                    HStack {
                        Text(showRegister ? "Already have an account?" : "Don't have an account?")
                            .foregroundStyle(.secondary)
                        Button(showRegister ? "Sign In" : "Sign Up") {
                            withAnimation { showRegister.toggle() }
                        }
                        .fontWeight(.semibold)
                        .foregroundStyle(BuildTrackColors.primary)
                    }
                    .font(.subheadline)
                    
                    if let error = authManager.error {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    
                    Spacer()
                }
                .padding()
            }
        }
    }
}

struct LoginForm: View {
    @Environment(AuthManager.self) private var authManager
    @State private var email = ""
    @State private var password = ""
    
    var body: some View {
        VStack(spacing: 16) {
            TextField("Email", text: $email)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding()
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            
            SecureField("Password", text: $password)
                .textContentType(.password)
                .padding()
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            
            Button {
                Task { await authManager.signIn(email: email, password: password) }
            } label: {
                HStack {
                    if authManager.isLoading {
                        ProgressView().tint(.white)
                    }
                    Text("Sign In")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    email.isEmpty || password.isEmpty
                    ? BuildTrackColors.primary.opacity(0.4)
                    : BuildTrackColors.primary
                )
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(email.isEmpty || password.isEmpty || authManager.isLoading)
        }
    }
}

struct RegisterForm: View {
    @Environment(AuthManager.self) private var authManager
    @State private var fullName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    
    var passwordsMatch: Bool { password == confirmPassword }
    var isValid: Bool { !fullName.isEmpty && !email.isEmpty && password.count >= 6 && passwordsMatch }
    
    var body: some View {
        VStack(spacing: 16) {
            TextField("Full Name", text: $fullName)
                .textContentType(.name)
                .padding()
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            
            TextField("Email", text: $email)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding()
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            
            SecureField("Password (min 6 chars)", text: $password)
                .textContentType(.newPassword)
                .padding()
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            
            SecureField("Confirm Password", text: $confirmPassword)
                .textContentType(.newPassword)
                .padding()
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            
            if !password.isEmpty && !confirmPassword.isEmpty && !passwordsMatch {
                Text("Passwords do not match")
                    .font(.caption)
                    .foregroundStyle(.red)
            }
            
            Button {
                Task { await authManager.signUp(email: email, password: password, fullName: fullName) }
            } label: {
                HStack {
                    if authManager.isLoading {
                        ProgressView().tint(.white)
                    }
                    Text("Create Account")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(isValid ? BuildTrackColors.primary : BuildTrackColors.primary.opacity(0.4))
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(!isValid || authManager.isLoading)
        }
    }
}
