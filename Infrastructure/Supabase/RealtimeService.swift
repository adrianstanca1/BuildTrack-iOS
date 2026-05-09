import Foundation
import OSLog
import Supabase

final class RealtimeService {
    static let shared = RealtimeService()
    
    private let client: SupabaseClient
    private var channels: [String: RealtimeChannel] = [:]
    private let debouncer = Debouncer(delay: 0.3)
    
    init() {
        self.client = SupabaseManager.shared.client
    }
    
    func subscribeToProjectChanges(projectId: String, onUpdate: @escaping () -> Void) {
        let channelName = "project-\(projectId)"
        guard channels[channelName] == nil else { return }
        
        let channel = client.realtime.channel(channelName)
        
        // Supabase Swift V2 API: use postgresChange for database events
        // The V2 API uses channel.onPostgresChange with a filter parameter
        Task {
            do {
                await channel.onPostgresChange(
                    filter: PostgresChangeFilter(
                        event: "*",
                        schema: "public",
                        table: "*",
                        filter: "project_id=eq.\(projectId)"
                    )
                ) { _ in
                    self.debouncer.debounce(key: "change-\(projectId)") { onUpdate() }
                }
                try await channel.subscribe()
                channels[channelName] = channel
            } catch {
                Logger.realtime.error("Failed to subscribe: \(error.localizedDescription)")
            }
        }
    }
    
    func unsubscribe(projectId: String) {
        let channelName = "project-\(projectId)"
        guard let channel = channels[channelName] else { return }
        Task { try? await channel.unsubscribe() }
        channels.removeValue(forKey: channelName)
    }
}

private final class Debouncer {
    private let delay: TimeInterval
    private var timers: [String: Timer] = [:]
    private let queue = DispatchQueue(label: "debouncer")
    
    init(delay: TimeInterval) {
        self.delay = delay
    }
    
    func debounce(key: String, action: @escaping () -> Void) {
        queue.sync {
            timers[key]?.invalidate()
            timers[key] = Timer(timeInterval: delay, repeats: false, block: { _ in
                DispatchQueue.main.async { action() }
            })
            RunLoop.main.add(timers[key]!, forMode: .common)
        }
    }
}

@available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *)
extension Logger {
    static let realtime = Logger(subsystem: "com.cortexbuild.BuildTrack", category: "realtime")
}
