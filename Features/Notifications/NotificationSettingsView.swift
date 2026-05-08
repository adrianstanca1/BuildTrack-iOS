import SwiftUI
import SwiftData

struct NotificationSettingsView: View {
    @AppStorage("notifyTaskReminders") private var taskReminders = true
    @AppStorage("notifyIncidentAlerts") private var incidentAlerts = true
    @AppStorage("notifyInspectionDue") private var inspectionDue = true
    @AppStorage("notifyProjectUpdates") private var projectUpdates = true
    @AppStorage("notifyQuietHoursEnabled") private var quietHoursEnabled = false
    @AppStorage("notifyQuietHoursStart") private var quietHoursStart = 22
    @AppStorage("notifyQuietHoursEnd") private var quietHoursEnd = 7
    @AppStorage("notifySoundEnabled") private var soundEnabled = true
    @AppStorage("notifyVibrationEnabled") private var vibrationEnabled = true
    @AppStorage("notifyShowBadge") private var showBadge = true
    
    var body: some View {
        List {
            Section {
                Toggle("Task Reminders", systemImage: "checklist", isOn: $taskReminders)
                Toggle("Incident Alerts", systemImage: "exclamationmark.shield.fill", isOn: $incidentAlerts)
                Toggle("Inspection Due", systemImage: "checkmark.shield.fill", isOn: $inspectionDue)
                Toggle("Project Updates", systemImage: "building.2.fill", isOn: $projectUpdates)
            } header: {
                Text("Notification Types")
            }
            
            Section {
                Toggle("Quiet Hours", systemImage: "moon.zzz.fill", isOn: $quietHoursEnabled)
                if quietHoursEnabled {
                    Stepper("From: \(quietHoursStart):00", value: $quietHoursStart, in: 0...23)
                    Stepper("To: \(quietHoursEnd):00", value: $quietHoursEnd, in: 0...23)
                }
            } header: {
                Text("Schedule")
            }
            
            Section {
                Toggle("Sound", systemImage: "speaker.wave.2.fill", isOn: $soundEnabled)
                Toggle("Vibration", systemImage: "waveform", isOn: $vibrationEnabled)
                Toggle("Badge Count", systemImage: "app.badge", isOn: $showBadge)
            } header: {
                Text("Behaviour")
            }
        }
        .navigationTitle("Notification Settings")
        .tint(BuildTrackColors.primary)
    }
}

#Preview {
    NavigationStack { NotificationSettingsView() }
}
