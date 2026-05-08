import SwiftUI
import LocalAuthentication

@MainActor
final class AuthViewModel: ObservableObject {
    enum AuthState: Equatable {
        case loggedOut
        case authenticating
        case authenticated(UserInfo)
        case error(String)
        
        static func == (lhs: AuthState, rhs: AuthState) -> Bool {
            switch (lhs, rhs) {
            case (.loggedOut, .loggedOut): return true
            case (.authenticating, .authenticating): return true
            case (.authenticated(let a), .authenticated(let b)): return a.id == b.id
            case (.error(let a), .error(let b)): return a == b
            default: return false
            }
        }
    }
    
    @Published private(set) var state: AuthState = .loggedOut
    private let authManager: AuthManager
    private let context = LAContext()
    
    var isBiometricAvailable: Bool {
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }
    
    init(authManager: AuthManager = AuthManager()) {
        self.authManager = authManager
    }
    
    func signIn(email: String, password: String) async {
        state = .authenticating
        await authManager.signIn(email: email, password: password)
        if authManager.isAuthenticated, let user = authManager.currentUser {
            state = .authenticated(user)
        } else {
            state = .error(authManager.error ?? "Unknown error")
        }
    }
    
    func authenticateWithBiometrics() async {
        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: "Authenticate to access BuildTrack"
            )
            if success { state = .authenticating }
        } catch {
            state = .error(error.localizedDescription)
        }
    }
}
