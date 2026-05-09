import SwiftUI
import AuthenticationServices

// MARK: - Auth View (Redesigned)

struct AuthView: View {
    @Environment(AuthManager.self)
    private var authManager
    @State private var showRegister = false
    @State private var showForgotPassword = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                BuildTrackColors.heroGradient
                    .ignoresSafeArea()
                    .overlay(
                        // Subtle pattern
                        Image(systemName: "building.2.fill")
                            .font(.system(size: 300, weight: .ultraLight))
                            .foregroundStyle(.white.opacity(0.03))
                            .offset(x: 80, y: -100)
                    )
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Hero section
                        VStack(spacing: 16) {
                            Spacer().frame(height: 60)
                            
                            ZStack {
                                Circle()
                                    .fill(Color.white.opacity(0.15))
                                    .frame(width: 100, height: 100)
                                
                                Image(systemName: "building.columns.fill")
                                    .font(.system(size: 44))
                                    .foregroundStyle(.white)
                            }
                            
                            VStack(spacing: 6) {
                                Text("BuildTrack")
                                    .font(.system(size: 34, weight: .bold))
                                    .foregroundStyle(.white)
                                
                                Text("Construction Management")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(.white.opacity(0.8))
                            }
                            
                            Spacer().frame(height: 20)
                        }
                        
                        // Form card
                        VStack(spacing: 24) {
                            if showRegister {
                                RegisterForm()
                                    .transition(.asymmetric(
                                        insertion: .move(edge: .trailing).combined(with: .opacity),
                                        removal: .move(edge: .leading).combined(with: .opacity)
                                    ))
                            } else {
                                LoginForm(showForgotPassword: $showForgotPassword)
                                    .transition(.asymmetric(
                                        insertion: .move(edge: .leading).combined(with: .opacity),
                                        removal: .move(edge: .trailing).combined(with: .opacity)
                                    ))
                            }
                            
                            // Divider
                            HStack(spacing: 16) {
                                Divider()
                                    .background(Color(.separator))
                                Text("or")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Divider()
                                    .background(Color(.separator))
                            }
                            
                            // Social auth buttons
                            VStack(spacing: 12) {
                                SignInWithAppleButton(.signIn) { request in
                                    request.requestedScopes = [.fullName, .email]
                                } onCompletion: { result in
                                    handleAppleSignIn(result)
                                }
                                .signInWithAppleButtonStyle(.whiteOutline)
                                .frame(height: 50)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                
                                Button {
                                    // Google Sign In
                                } label: {
                                    HStack {
                                        Image(systemName: "g.circle.fill")
                                            .font(.title3)
                                        Text("Continue with Google")
                                            .font(.subheadline.weight(.semibold))
                                    }
                                    .foregroundStyle(.primary)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(Color(.systemBackground))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color(.separator), lineWidth: 1)
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                            }
                            
                            // Toggle auth mode
                            HStack(spacing: 4) {
                                Text(showRegister ? "Already have an account?" : "Don't have an account?")
                                    .foregroundStyle(.secondary)
                                Button(showRegister ? "Sign In" : "Sign Up") {
                                    withAnimation(.spring(response: 0.35)) {
                                        showRegister.toggle()
                                    }
                                }
                                .fontWeight(.semibold)
                                .foregroundStyle(BuildTrackColors.primary)
                            }
                            .font(.subheadline)
                            .padding(.top, 8)
                        }
                        .padding(24)
                        .background(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .fill(Color(.systemBackground))
                                .shadow(color: .black.opacity(0.1), radius: 24, x: 0, y: -8)
                        )
                        .padding(.horizontal, 20)
                        
                        Spacer().frame(height: 40)
                    }
                }
            }
            .sheet(isPresented: $showForgotPassword) {
                ForgotPasswordView()
            }
        }
    }
    
    private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let auth):
            if let credential = auth.credential as? ASAuthorizationAppleIDCredential {
                Task {
                    await authManager.signInWithApple(credential: credential)
                }
            }
        case .failure(let error):
            authManager.error = error.localizedDescription
        }
    }
}

// MARK: - Login Form

struct LoginForm: View {
    @Environment(AuthManager.self)
    private var authManager
    @Binding var showForgotPassword: Bool
    @State private var email = ""
    @State private var password = ""
    @FocusState private var focusedField: Field?
    
    enum Field: Hashable {
        case email, password
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Welcome Back")
                .font(.title3.bold())
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Email field
            AuthTextField(
                icon: "envelope.fill",
                placeholder: "Email",
                text: $email,
                keyboardType: .emailAddress,
                textContentType: .emailAddress
            )
            .focused($focusedField, equals: .email)
            .submitLabel(.next)
            .onSubmit { focusedField = .password }
            
            // Password field
            AuthSecureField(
                icon: "lock.fill",
                placeholder: "Password",
                text: $password
            )
            .focused($focusedField, equals: .password)
            .submitLabel(.go)
            .onSubmit { signIn() }
            
            // Forgot password
            Button("Forgot Password?") {
                showForgotPassword = true
            }
            .font(.subheadline.weight(.medium))
            .foregroundStyle(BuildTrackColors.primary)
            .frame(maxWidth: .infinity, alignment: .trailing)
            
            // Error message
            if let error = authManager.error {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption)
                    Text(error)
                        .font(.caption)
                }
                .foregroundStyle(BuildTrackColors.danger)
                .padding(.horizontal, 4)
            }
            
            // Sign in button
            Button {
                signIn()
            } label: {
                HStack {
                    if authManager.isLoading {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(0.8)
                    }
                    Text("Sign In")
                        .font(.headline.weight(.semibold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [BuildTrackColors.primary, BuildTrackColors.primaryLight],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .opacity(email.isEmpty || password.isEmpty ? 0.6 : 1)
            }
            .disabled(email.isEmpty || password.isEmpty || authManager.isLoading)
        }
    }
    
    private func signIn() {
        Task {
            await authManager.signIn(email: email, password: password)
        }
    }
}

// MARK: - Register Form

struct RegisterForm: View {
    @Environment(AuthManager.self)
    private var authManager
    @State private var fullName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @FocusState private var focusedField: Field?
    
    enum Field: Hashable {
        case fullName, email, password, confirmPassword
    }
    
    var passwordsMatch: Bool { password == confirmPassword }
    var isValid: Bool {
        !fullName.isEmpty && !email.isEmpty && password.count >= 8 && passwordsMatch
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Create Account")
                .font(.title3.bold())
                .frame(maxWidth: .infinity, alignment: .leading)
            
            AuthTextField(
                icon: "person.fill",
                placeholder: "Full Name",
                text: $fullName,
                textContentType: .name
            )
            .focused($focusedField, equals: .fullName)
            .submitLabel(.next)
            .onSubmit { focusedField = .email }
            
            AuthTextField(
                icon: "envelope.fill",
                placeholder: "Email",
                text: $email,
                keyboardType: .emailAddress,
                textContentType: .emailAddress
            )
            .focused($focusedField, equals: .email)
            .submitLabel(.next)
            .onSubmit { focusedField = .password }
            
            AuthSecureField(
                icon: "lock.fill",
                placeholder: "Password (min 8 chars)",
                text: $password
            )
            .focused($focusedField, equals: .password)
            .submitLabel(.next)
            .onSubmit { focusedField = .confirmPassword }
            
            AuthSecureField(
                icon: "lock.shield.fill",
                placeholder: "Confirm Password",
                text: $confirmPassword
            )
            .focused($focusedField, equals: .confirmPassword)
            .submitLabel(.go)
            .onSubmit { signUp() }
            
            // Password strength indicator
            if !password.isEmpty {
                PasswordStrengthBar(password: password)
            }
            
            if !password.isEmpty && !confirmPassword.isEmpty && !passwordsMatch {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.caption)
                    Text("Passwords do not match")
                        .font(.caption)
                }
                .foregroundStyle(BuildTrackColors.danger)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 4)
            }
            
            if let error = authManager.error {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption)
                    Text(error)
                        .font(.caption)
                }
                .foregroundStyle(BuildTrackColors.danger)
                .padding(.horizontal, 4)
            }
            
            Button {
                signUp()
            } label: {
                HStack {
                    if authManager.isLoading {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(0.8)
                    }
                    Text("Create Account")
                        .font(.headline.weight(.semibold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: isValid
                            ? [BuildTrackColors.primary, BuildTrackColors.primaryLight]
                            : [BuildTrackColors.primary.opacity(0.4), BuildTrackColors.primaryLight.opacity(0.4)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(!isValid || authManager.isLoading)
        }
    }
    
    private func signUp() {
        Task {
            await authManager.signUp(email: email, password: password, fullName: fullName)
        }
    }
}

// MARK: - Password Strength Bar

struct PasswordStrengthBar: View {
    let password: String
    
    var strength: PasswordStrength {
        var score = 0
        if password.count >= 8 { score += 1 }
        if password.rangeOfCharacter(from: .uppercaseLetters) != nil { score += 1 }
        if password.rangeOfCharacter(from: .lowercaseLetters) != nil { score += 1 }
        if password.rangeOfCharacter(from: .decimalDigits) != nil { score += 1 }
        if password.rangeOfCharacter(from: .symbols) != nil { score += 1 }
        
        switch score {
        case 0...1: return .weak
        case 2...3: return .fair
        case 4: return .good
        default: return .strong
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                ForEach(0..<4) { index in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(barColor(for: index))
                        .frame(height: 4)
                }
            }
            
            Text(strength.label)
                .font(.caption2.weight(.medium))
                .foregroundStyle(strength.color)
        }
    }
    
    private func barColor(for index: Int) -> Color {
        let filledBars: Int = {
            switch strength {
            case .weak: return 1
            case .fair: return 2
            case .good: return 3
            case .strong: return 4
            }
        }()
        return index < filledBars ? strength.color : Color(.systemGray5)
    }
}

enum PasswordStrength {
    case weak, fair, good, strong
    
    var label: String {
        switch self {
        case .weak: return "Weak"
        case .fair: return "Fair"
        case .good: return "Good"
        case .strong: return "Strong"
        }
    }
    
    var color: Color {
        switch self {
        case .weak: return BuildTrackColors.danger
        case .fair: return BuildTrackColors.warning
        case .good: return BuildTrackColors.info
        case .strong: return BuildTrackColors.success
        }
    }
}

// MARK: - Auth Text Field

struct AuthTextField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var textContentType: UITextContentType?
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(BuildTrackColors.primary)
                .frame(width: 24)
            
            TextField(placeholder, text: $text)
                .textContentType(textContentType)
                .keyboardType(keyboardType)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Auth Secure Field

struct AuthSecureField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    @State private var isVisible = false
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(BuildTrackColors.primary)
                .frame(width: 24)
            
            if isVisible {
                TextField(placeholder, text: $text)
                    .textContentType(.password)
            } else {
                SecureField(placeholder, text: $text)
                    .textContentType(.password)
            }
            
            Button {
                isVisible.toggle()
            } label: {
                Image(systemName: isVisible ? "eye.slash.fill" : "eye.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Forgot Password View

struct ForgotPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var isSent = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer().frame(height: 40)
                
                Image(systemName: "envelope.badge.shield.half.filled")
                    .font(.system(size: 64))
                    .foregroundStyle(BuildTrackColors.primary)
                
                VStack(spacing: 8) {
                    Text("Reset Password")
                        .font(.title2.bold())
                    Text("Enter your email and we'll send you a link to reset your password.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                
                if !isSent {
                    AuthTextField(
                        icon: "envelope.fill",
                        placeholder: "Email",
                        text: $email,
                        keyboardType: .emailAddress,
                        textContentType: .emailAddress
                    )
                    .padding(.horizontal, 24)
                    
                    Button {
                        // Send reset email
                        isSent = true
                    } label: {
                        Text("Send Reset Link")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(BuildTrackColors.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal, 24)
                    .disabled(email.isEmpty)
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(BuildTrackColors.success)
                        
                        Text("Check your email")
                            .font(.headline)
                        
                        Text("We've sent a password reset link to \(email)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 32)
                }
                
                Spacer()
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    AuthView()
        .environment(AuthManager())
}
