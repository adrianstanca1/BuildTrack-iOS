
// MARK: - Enum Labels/Colors
extension BudgetStatus {
    var label: String { rawValue.capitalized }
    var color: String {
        switch self { case .draft: return "gray"; case .approved: return "green"; case .inProgress: return "orange"; case .overBudget: return "red"; case .completed: return "blue"; case .cancelled: return "gray" }
    }
}
extension MaterialStatus {
    var label: String { rawValue.capitalized }
    var color: String {
        switch self { case .ordered: return "orange"; case .delivered: return "blue"; case .inStock: return "green"; case .used: return "gray" }
    }
}
extension MeetingType {
    var label: String { rawValue.capitalized }
    var color: String {
        switch self { case .site: return "blue"; case .progress: return "green"; case .safety: return "orange"; case .design: return "purple"; case .other: return "gray" }
    }
}
extension TimesheetStatus {
    var label: String { rawValue.capitalized }
    var color: String {
        switch self { case .draft: return "gray"; case .submitted: return "blue"; case .approved: return "green"; case .rejected: return "red" }
    }
}
extension PermitStatus {
    var label: String { rawValue.capitalized }
    var color: String {
        switch self { case .applied: return "gray"; case .underReview: return "orange"; case .approved: return "green"; case .rejected: return "red"; case .expired: return "red" }
    }
}
extension DailyReportStatus {
    var label: String { rawValue.capitalized }
    var color: String {
        switch self { case .draft: return "gray"; case .submitted: return "blue"; case .approved: return "green" }
    }
}
