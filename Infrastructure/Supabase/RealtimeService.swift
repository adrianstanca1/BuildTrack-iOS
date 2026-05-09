import Foundation
import OSLog
import Supabase

actor RealtimeService {
    private static let log = Logger(subsystem: "com.cortexbuild.track", category: "RealtimeService")
    
    private let client: SupabaseClient
    private var pollingTimer: Timer?
    
    init(client: SupabaseClient) {
        self.client = client
    }
    
    func startListening(for table: String, onChange: @escaping () -> Void) {
        Task { @MainActor in
            self.pollingTimer?.invalidate()
            self.pollingTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
                onChange()
            }
        }
        Self.log.info("Started polling for: \(table)")
    }
    
    func stopListening() {
        Task { @MainActor in
            pollingTimer?.invalidate()
            pollingTimer = nil
        }
        Self.log.info("Stopped polling")
    }
}
