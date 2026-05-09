import Foundation
import OSLog
import Supabase

// MARK: - Environment Configuration

enum BuildEnvironment: CustomStringConvertible {
    case debug
    case release
    
    var description: String {
        switch self {
        case .debug: return "debug"
        case .release: return "release"
        }
    }
    
    static var current: BuildEnvironment {
        #if DEBUG
        return .debug
        #else
        return .release
        #endif
    }
    
    var supabaseURL: String {
        switch self {
        case .debug:
            // Development: local Supabase or staging
            return Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String
                ?? "http://localhost:54321"
        case .release:
            // Production: buildtrack.cortexbuildpro.com
            return Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String
                ?? "https://buildtrack.cortexbuildpro.com"
        }
    }
    
    var supabaseAnonKey: String {
        switch self {
        case .debug:
            return Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String
                ?? "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0"
        case .release:
            return Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String
                ?? "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJ1aWxkdHJhY2siLCJyb2xlIjoiYW5vbiIsImlhdCI6MTc0NjcxMzYwMCwiZXhwIjoyMDYyMjg5NjAwfQ.demo-key"
        }
    }
    
    var apiBaseURL: String {
        switch self {
        case .debug:
            return Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String
                ?? "http://localhost:54321/api"
        case .release:
            return Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String
                ?? "https://buildtrack.cortexbuildpro.com/api"
        }
    }
}

// MARK: - Supabase Manager

final class SupabaseManager {
    static let shared = SupabaseManager()
    
    let client: SupabaseClient
    let environment: BuildEnvironment
    
    private init() {
        self.environment = BuildEnvironment.current
        
        let url = environment.supabaseURL
        let anonKey = environment.supabaseAnonKey
        
        guard !url.isEmpty, !anonKey.isEmpty,
              let supabaseURL = URL(string: url) else {
            fatalError("""
            Supabase configuration error.
            Environment: \(BuildEnvironment.current)
            URL: \(url)
            Anon Key: \(anonKey.isEmpty ? "<empty>" : "present")
            
            For production builds, ensure Config-Production.xcconfig is set
            as the Release configuration file in Xcode project settings.
            """)
        }
        
        Logger.network.info("Initialising Supabase client")
        Logger.network.info("Environment: \(BuildEnvironment.current)")
        Logger.network.info("URL: \(supabaseURL.absoluteString)")
        
        self.client = SupabaseClient(
            supabaseURL: supabaseURL,
            supabaseKey: anonKey
        )
    }
}
