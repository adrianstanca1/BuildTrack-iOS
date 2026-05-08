import SwiftUI
import OSLog
import Supabase

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
        Task { await restoreSession() }
    }
    
    func signIn(email: String, password: String) async {
        isLoading = true; error = nil
        do {
            let session = try await client.auth.signIn(email: email, password: password)
            isAuthenticated = true
            currentUser = UserInfo(from: session.user)
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
    
    func signUp(email: String, password: String, fullName: String) async {
        isLoading = true; error = nil
        do {
            _ = try await client.auth.signUp(email: email, password: password, data: ["full_name": .string(fullName)])
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
    
    func signOut() async {
        do {
            try await client.auth.signOut()
            isAuthenticated = false
            currentUser = nil
        } catch {
            Logger.auth.error("Sign out failed")
        }
    }
    
    private func restoreSession() async {
        do {
            let session = try await client.auth.session
            isAuthenticated = true
            currentUser = UserInfo(from: session.user)
        } catch {
            isAuthenticated = false
        }
    }
}

struct UserInfo: Identifiable, Equatable, Sendable {
    let id: String
    let email: String
    let fullName: String?
    
    init(from user: Supabase.User) {
        self.id = user.id.uuidString
        self.email = user.email ?? ""
        self.fullName = user.userMetadata["full_name"]?.stringValue
    }
}
