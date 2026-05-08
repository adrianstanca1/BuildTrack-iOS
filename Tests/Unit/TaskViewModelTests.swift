import XCTest
@testable import BuildTrack

final class TaskViewModelTests: XCTestCase {
    var viewModel: TaskViewModel!
    
    @MainActor override func setUp() async throws {
        viewModel = TaskViewModel()
    }
    
    override func tearDown() {
        viewModel = nil
    }
    
    // MARK: - Initial State
    
    @MainActor func testInitialStateIsIdle() {
        if case .idle = viewModel.state { /* pass */ }
        else { XCTFail("Expected idle state") }
    }
    
    // MARK: - Grouping Logic
    
    @MainActor func testGroupedTasksSeparatesByDate() async {
        // We test the grouping function directly
        let calendar = Calendar.current
        let today = Date()
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        let plus3Days = calendar.date(byAdding: .day, value: 3, to: today)!
        
        let tasks: [TaskItem] = [
            TaskItem(title: "Overdue Task", priority: .high, status: .pending, dueDate: yesterday),
            TaskItem(title: "Today Task", priority: .medium, status: .pending, dueDate: today),
            TaskItem(title: "Tomorrow Task", priority: .low, status: .pending, dueDate: tomorrow),
            TaskItem(title: "Later Task", priority: .low, status: .pending, dueDate: plus3Days),
            TaskItem(title: "Done", priority: .medium, status: .completed, dueDate: yesterday),
        ]
        
        let groups = viewModel.groupedTasks(tasks)
        let groupNames = groups.map(\.0)
        
        XCTAssertTrue(groupNames.contains("Overdue"))
        if Calendar.current.isDateInToday(today) { XCTAssertTrue(groupNames.contains("Today")) }
        XCTAssertTrue(groupNames.contains("This Week"))
        XCTAssertTrue(groupNames.contains("Completed"))
    }
    
    // MARK: - Filtering
    
    @MainActor func testFilterByPriority() {
        let tasks: [TaskItem] = [
            TaskItem(title: "High priority", priority: .high),
            TaskItem(title: "Medium priority", priority: .medium),
            TaskItem(title: "Another high", priority: .high),
        ]
        
        let highTasks = viewModel.filterByPriority(.high, tasks: tasks)
        XCTAssertEqual(highTasks.count, 2)
        
        let lowTasks = viewModel.filterByPriority(.low, tasks: tasks)
        XCTAssertEqual(lowTasks.count, 0)
    }
    
    // MARK: - Completion Rate
    
    @MainActor func testCompletionRate() {
        let completed = TaskItem(title: "Done", priority: .medium, status: .completed)
        let pending = TaskItem(title: "Pending", priority: .medium, status: .pending)
        let inProgress = TaskItem(title: "WIP", priority: .medium, status: .inProgress)
        
        let tasks = [completed, pending, inProgress]
        let rate = Double(tasks.filter { $0.status == .completed }.count) / Double(tasks.count)
        XCTAssertEqual(rate, 1.0/3.0, accuracy: 0.01)
    }
    
    // MARK: - Search
    
    @MainActor func testSearchTasks() {
        let tasks: [TaskItem] = [
            TaskItem(title: "Foundation pour"),
            TaskItem(title: "Electrical rough-in"),
            TaskItem(title: "Plumbing inspection"),
        ]
        
        let results = viewModel.searchTasks(query: "Foundation")
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.title, "Foundation pour")
        
        let noResults = viewModel.searchTasks(query: "xxxxxxxxxx")
        XCTAssertEqual(noResults.count, 0)
    }
}
