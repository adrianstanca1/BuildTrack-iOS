import SwiftUI
import Supabase

@MainActor
@Observable
final class AuthManager {
    var isAuthenticated = false
    var currentUser: UserInfo?
    var isLoading = false
    var error: String?
    var colorScheme: ColorScheme? = nil
    
    private let client: SupabaseClient
    
    init() {
        self.client = SupabaseManager.shared.client
        
        Task {
            await checkSession()
        }
    }
    
    func checkSession() async {
        do {
            let session = try await client.auth.session
            self.currentUser = UserInfo(
                id: session.user.id.uuidString,
                email: session.user.email ?? "",
                fullName: session.user.userMetadata["full_name"]?.stringValue
                    ?? session.user.userMetadata["name"]?.stringValue
            )
            self.isAuthenticated = true
        } catch {
            self.isAuthenticated = false
        }
    }
    
    func signIn(email: String, password: String) async {
        isLoading = true
        error = nil
        do {
            let _ = try await client.auth.signIn(email: email, password: password)
            await checkSession()
        } catch let authError as AuthError {
            self.error = authError.localizedDescription
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
    
    func signUp(email: String, password: String, fullName: String) async {
        isLoading = true
        error = nil
        do {
            let _ = try await client.auth.signUp(
                email: email,
                password: password,
                data: ["full_name": .string(fullName)]
            )
            self.error = "Check your email for a confirmation link."
        } catch let authError as AuthError {
            self.error = authError.localizedDescription
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
    
    func signOut() async {
        do {
            try await client.auth.signOut()
            self.isAuthenticated = false
            self.currentUser = nil
        } catch {
            print("Sign out error: \(error)")
        }
    }
}

struct UserInfo: Sendable {
    let id: String
    let email: String
    let fullName: String?
}
