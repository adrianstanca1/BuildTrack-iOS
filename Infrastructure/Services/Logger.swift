import Foundation
import OSLog

// MARK: - BuildTrack Logger

extension Logger {
    /// Main app logger
    static let app = Logger(subsystem: "ro.stancainvest.buildtrack", category: "app")
    
    /// Auth-related logging
    static let auth = Logger(subsystem: "ro.stancainvest.buildtrack", category: "auth")
    
    /// Data persistence logging
    static let data = Logger(subsystem: "ro.stancainvest.buildtrack", category: "data")
    
    /// Network/Supabase logging
    static let network = Logger(subsystem: "ro.stancainvest.buildtrack", category: "network")
    
    /// Realtime sync logging
    static let realtime = Logger(subsystem: "ro.stancainvest.buildtrack", category: "realtime")
    
    /// Push notification logging
    static let push = Logger(subsystem: "ro.stancainvest.buildtrack", category: "push")
    
    /// Safety incidents/inspections logging
    static let safety = Logger(subsystem: "ro.stancainvest.buildtrack", category: "safety")
    
    /// Task management logging
    static let tasks = Logger(subsystem: "ro.stancainvest.buildtrack", category: "tasks")
    
    /// Project management logging
    static let projects = Logger(subsystem: "ro.stancainvest.buildtrack", category: "projects")
    
    /// General UI logging
    static let ui = Logger(subsystem: "ro.stancainvest.buildtrack", category: "ui")
}

// MARK: - Log Levels

extension Logger {
    /// Log a debug message (stripped in Release builds)
    func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        #if DEBUG
        let fileName = (file as NSString).lastPathComponent
        self.debug("[\(fileName):\(line)] \(function): \(message)")
        #endif
    }
    
    /// Log an info message
    func info(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        let fileName = (file as NSString).lastPathComponent
        self.info("[\(fileName):\(line)] \(message)")
    }
    
    /// Log a warning
    func warning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        let fileName = (file as NSString).lastPathComponent
        self.warning("[\(fileName):\(line)] \(message)")
    }
    
    /// Log an error
    func error(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        let fileName = (file as NSString).lastPathComponent
        self.error("[\(fileName):\(line)] \(message)")
    }
}
