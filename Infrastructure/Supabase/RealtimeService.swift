import Foundation
import OSLog
import Supabase

@MainActor
final class RealtimeService: ObservableObject {
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
        
        let _ = channel.on(.insert) { _ in
            self.debouncer.debounce(key: "insert-\(projectId)") { onUpdate() }
        }
        let _ = channel.on(.update) { _ in
            self.debouncer.debounce(key: "update-\(projectId)") { onUpdate() }
        }
        let _ = channel.on(.delete) { _ in
            self.debouncer.debounce(key: "delete-\(projectId)") { onUpdate() }
        }
        
        Task { try? await channel.subscribe() }
        channels[channelName] = channel
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
    
    init(delay: TimeInterval) { self.delay = delay }
    
    func debounce(key: String, action: @escaping () -> Void) {
        queue.async {
            self.timers[key]?.invalidate()
            let timer = Timer.scheduledTimer(withTimeInterval: self.delay, repeats: false) { _ in
                DispatchQueue.main.async { action() }
            }
            self.timers[key] = timer
        }
    }
}
