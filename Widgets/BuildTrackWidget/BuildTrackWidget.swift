import WidgetKit
import SwiftUI
import SwiftData

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), activeProjects: 5, todayTasks: 3, overdueTasks: 1)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), activeProjects: 5, todayTasks: 3, overdueTasks: 1)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [SimpleEntry] = []
        let currentDate = Date()
        for hourOffset in 0 ..< 5 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let entry = SimpleEntry(date: entryDate, activeProjects: 5, todayTasks: 3, overdueTasks: 1)
            entries.append(entry)
        }
        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let activeProjects: Int
    let todayTasks: Int
    let overdueTasks: Int
}

struct BuildTrackWidgetEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .systemLarge, .systemExtraLarge:
            LargeWidgetView(entry: entry)
        @unknown default:
            SmallWidgetView(entry: entry)
        }
    }
}

struct SmallWidgetView: View {
    let entry: SimpleEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "hammer.fill")
                    .foregroundStyle(BuildTrackColors.primary)
                Text("BuildTrack")
                    .font(.caption.bold())
            }
            Spacer()
            Text("\(entry.activeProjects)")
                .font(.system(size: 32, weight: .bold))
            Text("Active Projects")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

struct MediumWidgetView: View {
    let entry: SimpleEntry
    
    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading) {
                HStack {
                    Image(systemName: "hammer.fill")
                        .foregroundStyle(BuildTrackColors.primary)
                    Text("BuildTrack")
                        .font(.caption.bold())
                }
                Spacer()
                Text("\(entry.activeProjects)")
                    .font(.title.bold())
                Text("Active Projects")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "checklist")
                        .foregroundStyle(.blue)
                    Text("\(entry.todayTasks)")
                        .font(.title3.bold())
                    Text("Today")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundStyle(.red)
                    Text("\(entry.overdueTasks)")
                        .font(.title3.bold())
                    Text("Overdue")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
    }
}

struct LargeWidgetView: View {
    let entry: SimpleEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "hammer.fill")
                    .foregroundStyle(BuildTrackColors.primary)
                Text("BuildTrack")
                    .font(.headline.bold())
                Spacer()
                Text(entry.date, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            HStack(spacing: 20) {
                StatBlock(icon: "building.2", label: "Projects", value: entry.activeProjects, color: .blue)
                StatBlock(icon: "checklist", label: "Today", value: entry.todayTasks, color: .green)
                StatBlock(icon: "exclamationmark.triangle", label: "Overdue", value: entry.overdueTasks, color: .red)
                StatBlock(icon: "shield", label: "Incidents", value: 0, color: .orange)
            }
            
            Spacer()
            
            Button(intent: OpenAppIntent()) {
                Label("Open BuildTrack", systemImage: "arrow.up.right.square")
                    .font(.caption)
            }
            .buttonStyle(.plain)
        }
        .padding()
    }
}

struct StatBlock: View {
    let icon: String
    let label: String
    let value: Int
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .font(.title3)
            Text("\(value)")
                .font(.title2.bold())
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct BuildTrackWidget: Widget {
    let kind: String = "BuildTrackWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(iOS 17.0, *) {
                BuildTrackWidgetEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                BuildTrackWidgetEntryView(entry: entry)
                    .padding()
                    .background()
            }
        }
        .configurationDisplayName("BuildTrack Stats")
        .description("View your active projects and today's tasks.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct OpenAppIntent: AppIntent {
    static var title: LocalizedStringResource = "Open BuildTrack"
    static var description = IntentDescription("Opens the BuildTrack app")
    static var openAppWhenRun: Bool = true
    
    @MainActor
    func perform() async throws -> some IntentResult {
        return .result()
    }
}

#Preview(as: .systemSmall) {
    BuildTrackWidget()
} timeline: {
    SimpleEntry(date: .now, activeProjects: 5, todayTasks: 3, overdueTasks: 1)
    SimpleEntry(date: .now.addingTimeInterval(3600), activeProjects: 6, todayTasks: 4, overdueTasks: 0)
}

#Preview(as: .systemMedium) {
    BuildTrackWidget()
} timeline: {
    SimpleEntry(date: .now, activeProjects: 5, todayTasks: 3, overdueTasks: 1)
}

#Preview(as: .systemLarge) {
    BuildTrackWidget()
} timeline: {
    SimpleEntry(date: .now, activeProjects: 5, todayTasks: 3, overdueTasks: 1)
}
