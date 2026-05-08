import SwiftUI
import LocalAuthentication

@MainActor
@Observable
final class AuthViewModel {
    enum AuthState: Equatable {
        case loggedOut
        case authenticating
        case authenticated(UserInfo)
        case error(String)
    }
    
    private(set) var state: AuthState = .loggedOut
    private let authManager: AuthManager
    private let context = LAContext()
    
    var isBiometricAvailable: Bool {
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }
    
    var biometricType: String {
        switch context.biometryType {
        case .faceID: "Face ID"
        case .touchID: "Touch ID"
        case .opticID: "Optic ID"
        default: "Biometrics"
        }
    }
    
    init(authManager: AuthManager) {
        self.authManager = authManager
    }
    
    // MARK: - Password Validation
    
    func validatePassword(_ password: String) -> [String] {
        var issues: [String] = []
        if password.count < 8 { issues.append("At least 8 characters") }
        if !password.contains(where: \.isUppercase) { issues.append("One uppercase letter") }
        if !password.contains(where: \.isNumber) { issues.append("One number") }
        if !password.contains(where: { "!@#$%^&*()_+-=[]{}|;':\",./<>?".contains($0) }) {
            issues.append("One special character")
        }
        return issues
    }
    
    var passwordIsValid: Bool {
        // Used by the form view for visual feedback
        true
    }
    
    // MARK: - Auth Actions
    
    func signIn(email: String, password: String) async {
        guard !email.isEmpty, !password.isEmpty else {
            state = .error("Email and password are required")
            return
        }
        
        state = .authenticating
        await authManager.signIn(email: email, password: password)
        
        if authManager.isAuthenticated, let user = authManager.currentUser {
            state = .authenticated(user)
        } else if let error = authManager.error {
            state = .error(error)
        } else {
            state = .loggedOut
        }
    }
    
    func signUp(email: String, password: String, fullName: String) async {
        let issues = validatePassword(password)
        guard issues.isEmpty else {
            state = .error("Password requirements not met: \(issues.joined(separator: ", "))")
            return
        }
        
        state = .authenticating
        await authManager.signUp(email: email, password: password, fullName: fullName)
        
        if let error = authManager.error {
            state = .error(error)
        }
    }
    
    func signOut() async {
        await authManager.signOut()
        state = .loggedOut
    }
    
    // MARK: - Biometric
    
    func authenticateWithBiometrics() async {
        guard isBiometricAvailable else {
            state = .error("\(biometricType) is not available")
            return
        }
        
        do {
            let _ = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: "Unlock BuildTrack to access your projects"
            )
            
            // Biometric success — attempt Supabase session refresh
            await authManager.checkSession()
            if let user = authManager.currentUser {
                state = .authenticated(user)
            }
        } catch {
            switch error {
            case LAError.userCancel:
                break // User cancelled — stay on current state
            case LAError.biometryLockout:
                state = .error("\(biometricType) is locked. Use password instead.")
            default:
                state = .error("Authentication failed")
            }
        }
    }
    
    func clearError() {
        if case .error = state { state = .loggedOut }
    }
}
