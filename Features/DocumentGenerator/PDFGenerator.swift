import UIKit
import SwiftData

enum PDFGenerator {

    static func generateDailyReport(project: Project, reports: [DailyReport]) -> Data {
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 612, height: 792))
        return renderer.pdfData { context in
            context.beginPage()
            drawHeader(title: "Daily Report", subtitle: project.name, in: context)
            var cursor: CGFloat = 100
            for report in reports {
                if cursor > 720 { context.beginPage(); cursor = 60; drawHeader(title: "Daily Report (cont.)", subtitle: project.name, in: context); cursor = 100 }
                let dateStr = report.date.formatted(date: .abbreviated, time: .omitted)
                drawRow(label: dateStr, value: report.status.label, y: &cursor, context: context)
                if report.weather.rawValue != "clear" { drawRow(label: "Weather", value: report.weather.rawValue, y: &cursor, context: context) }
                if !report.notes.isEmpty { drawWrappedText(text: report.notes, y: &cursor, context: context) }
                cursor += 10
            }
            if reports.isEmpty { drawWrappedText(text: "No daily reports found for this period.", y: &cursor, context: context) }
        }
    }

    static func generateTimesheetSummary(workerName: String, entries: [TimesheetEntry]) -> Data {
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 612, height: 792))
        return renderer.pdfData { context in
            context.beginPage()
            drawHeader(title: "Timesheet Summary", subtitle: workerName, in: context)
            var cursor: CGFloat = 100
            let totalHours = entries.reduce(0) { $0 + $1.hoursWorked }
            drawRow(label: "Total Hours", value: String(format: "%.1f", totalHours), y: &cursor, context: context)
            drawRow(label: "Entries", value: "\(entries.count)", y: &cursor, context: context)
            cursor += 16
            for entry in entries {
                if cursor > 720 { context.beginPage(); cursor = 60 }
                let dateStr = entry.date.formatted(date: .abbreviated, time: .omitted)
                drawRow(label: dateStr, value: "\(String(format: "%.1f", entry.hoursWorked))h - \(entry.task)", y: &cursor, context: context)
            }
            if entries.isEmpty { drawWrappedText(text: "No timesheet entries found for this worker.", y: &cursor, context: context) }
        }
    }

    static func generateSafetyReport(incidents: [Incident]) -> Data {
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 612, height: 792))
        return renderer.pdfData { context in
            context.beginPage()
            drawHeader(title: "Safety Incident Report", subtitle: "", in: context)
            var cursor: CGFloat = 100
            for incident in incidents {
                if cursor > 720 { context.beginPage(); cursor = 60 }
                drawRow(label: incident.title, value: incident.severity.label, y: &cursor, context: context)
                drawWrappedText(text: incident.descriptionText, y: &cursor, context: context)
                cursor += 8
            }
            if incidents.isEmpty { drawWrappedText(text: "No incidents recorded.", y: &cursor, context: context) }
        }
    }

    static func generateProjectStatus(project: Project, tasks: [TaskItem], budget: Budget?) -> Data {
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 612, height: 792))
        return renderer.pdfData { context in
            context.beginPage()
            drawHeader(title: "Project Status Report", subtitle: project.name, in: context)
            var cursor: CGFloat = 100
            drawRow(label: "Status", value: project.status.label, y: &cursor, context: context)
            drawRow(label: "Progress", value: "\(Int(project.progress))%", y: &cursor, context: context)
            drawRow(label: "Budget", value: Formatter.currency(project.budget), y: &cursor, context: context)
            drawRow(label: "Spent", value: Formatter.currency(project.spentToDate), y: &cursor, context: context)
            cursor += 16
            drawRow(label: "Tasks", value: "Total: \(tasks.count)", y: &cursor, context: context)
            let completed = tasks.filter { $0.status == .completed }.count
            drawRow(label: "Completed", value: "\(completed)", y: &cursor, context: context)
            let overdue = tasks.filter { if let d = $0.dueDate { return d < Date() && $0.status != .completed } else { return false } }.count
            drawRow(label: "Overdue", value: "\(overdue)", y: &cursor, context: context)
            if let budget {
                cursor += 16
                drawRow(label: "Budget Name", value: budget.name, y: &cursor, context: context)
                drawRow(label: "Total Budget", value: Formatter.currency(budget.totalBudget), y: &cursor, context: context)
                drawRow(label: "Total Spent", value: Formatter.currency(budget.totalSpent), y: &cursor, context: context)
            }
        }
    }

    static func generateBudgetOverview(project: Project, budget: Budget, items: [Material]) -> Data {
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 612, height: 792))
        return renderer.pdfData { context in
            context.beginPage()
            drawHeader(title: "Budget Overview", subtitle: project.name, in: context)
            var cursor: CGFloat = 100
            drawRow(label: "Total Budget", value: Formatter.currency(budget.totalBudget), y: &cursor, context: context)
            drawRow(label: "Spent to Date", value: Formatter.currency(budget.totalSpent), y: &cursor, context: context)
            drawRow(label: "Remaining", value: Formatter.currency(budget.totalBudget - budget.totalSpent), y: &cursor, context: context)
            drawRow(label: "Progress", value: "\(Int(budget.progress * 100))%", y: &cursor, context: context)
            cursor += 16
            for item in items {
                if cursor > 720 { context.beginPage(); cursor = 60 }
                drawRow(label: item.name, value: "\(String(format: "%.1f", item.quantity)) \(item.unit)", y: &cursor, context: context)
            }
        }
    }

    static func generatePunchList(project: Project, items: [PunchItem]) -> Data {
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 612, height: 792))
        return renderer.pdfData { context in
            context.beginPage()
            drawHeader(title: "Punch List", subtitle: project.name, in: context)
            var cursor: CGFloat = 100
            let openItems = items.filter { $0.status != .closed && $0.status != .resolved }
            let closedItems = items.filter { $0.status == .closed || $0.status == .resolved }
            drawRow(label: "Open Items", value: "\(openItems.count)", y: &cursor, context: context)
            drawRow(label: "Closed Items", value: "\(closedItems.count)", y: &cursor, context: context)
            cursor += 16
            for item in items {
                if cursor > 720 { context.beginPage(); cursor = 60 }
                drawRow(label: item.title, value: item.status.label, y: &cursor, context: context)
                drawRow(label: "Location", value: item.location, y: &cursor, context: context)
                drawRow(label: "Severity", value: item.severity.label, y: &cursor, context: context)
                cursor += 8
            }
            if items.isEmpty { drawWrappedText(text: "No punch items for this project.", y: &cursor, context: context) }
        }
    }

    // MARK: - Drawing Helpers

    private static func drawHeader(title: String, subtitle: String, in context: UIGraphicsPDFRendererContext) {
        let titleAttr: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 24, weight: .bold),
            .foregroundColor: UIColor.label
        ]
        let titleRect = CGRect(x: 36, y: 36, width: 540, height: 32)
        title.draw(in: titleRect, withAttributes: titleAttr)

        if !subtitle.isEmpty {
            let subAttr: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 14, weight: .medium),
                .foregroundColor: UIColor.secondaryLabel
            ]
            let subRect = CGRect(x: 36, y: 70, width: 540, height: 20)
            subtitle.draw(in: subRect, withAttributes: subAttr)
        }

        let line = UIBezierPath()
        line.move(to: CGPoint(x: 36, y: subtitle.isEmpty ? 74 : 94))
        line.addLine(to: CGPoint(x: 576, y: subtitle.isEmpty ? 74 : 94))
        UIColor.separator.setStroke()
        line.lineWidth = 0.5
        line.stroke()
    }

    private static func drawRow(label: String, value: String, y: inout CGFloat, context: UIGraphicsPDFRendererContext) {
        let labelAttr: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 12, weight: .medium), .foregroundColor: UIColor.label]
        let valueAttr: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 12, weight: .regular), .foregroundColor: UIColor.secondaryLabel]
        label.draw(in: CGRect(x: 36, y: y, width: 250, height: 16), withAttributes: labelAttr)
        value.draw(in: CGRect(x: 290, y: y, width: 286, height: 16), withAttributes: valueAttr)
        y += 20
    }

    private static func drawWrappedText(text: String, y: inout CGFloat, context: UIGraphicsPDFRendererContext) {
        let attr: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 11), .foregroundColor: UIColor.secondaryLabel]
        let size = CGSize(width: 540, height: 400)
        let rect = text.boundingRect(with: size, options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: attr, context: nil)
        text.draw(in: CGRect(x: 36, y: y, width: 540, height: rect.height + 4), withAttributes: attr)
        y += rect.height + 8
    }
}

enum Formatter {
    static func currency(_ value: Double) -> String {
        let nf = NumberFormatter()
        nf.numberStyle = .currency
        nf.currencyCode = "GBP"
        nf.maximumFractionDigits = 0
        return nf.string(from: NSNumber(value: value)) ?? "£0"
    }
}
