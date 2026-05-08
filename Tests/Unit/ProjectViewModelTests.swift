import XCTest
@testable import BuildTrack
import SwiftData

final class ProjectViewModelTests: XCTestCase {
    var viewModel: ProjectViewModel!
    var mockContainer: ModelContainer!
    
    @MainActor override func setUp() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        mockContainer = try ModelContainer(for: Project.self, TaskItem.self, configurations: config)
        viewModel = ProjectViewModel()
    }
    
    override func tearDown() {
        viewModel = nil
        mockContainer = nil
    }
    
    // MARK: - Initial State
    
    @MainActor func testInitialStateIsIdle() {
        XCTAssertEqual(viewModel.state, .idle)
    }
    
    // MARK: - State Transitions
    
    @MainActor func testStateTransitionsToLoadedAfterFetch() async {
        // Insert mock projects
        let context = mockContainer.mainContext
        let project = Project(name: "Test Project", status: .active, budget: 100_000)
        context.insert(project)
        try? context.save()
        
        await viewModel.loadProjects()
        
        if case .loaded(let projects) = viewModel.state {
            XCTAssertGreaterThanOrEqual(projects.count, 1)
            XCTAssertTrue(projects.contains { $0.name == "Test Project" })
        } else {
            XCTFail("Expected loaded state, got \(viewModel.state)")
        }
    }
    
    @MainActor func testStateTransitionsToErrorOnFailure() async {
        let failingVM = ProjectViewModel(repository: .failing)
        await failingVM.loadProjects()
        
        if case .error(let message) = failingVM.state {
            XCTAssertFalse(message.isEmpty)
        } else {
            XCTFail("Expected error state")
        }
    }
    
    // MARK: - Filtering
    
    @MainActor func testFilterByStatus() async {
        let context = mockContainer.mainContext
        context.insert(Project(name: "A", status: .active, budget: 100))
        context.insert(Project(name: "B", status: .completed, budget: 200))
        context.insert(Project(name: "C", status: .planning, budget: 300))
        try? context.save()
        
        await viewModel.loadProjects()
        
        let activeProjects = viewModel.filteredProjects(status: .active)
        XCTAssertEqual(activeProjects.count, 1)
        XCTAssertEqual(activeProjects.first?.name, "A")
        
        let allProjects = viewModel.filteredProjects(status: nil)
        XCTAssertEqual(allProjects.count, 3)
    }
    
    @MainActor func testSearchProjects() async {
        let context = mockContainer.mainContext
        context.insert(Project(name: "Alpha Tower", status: .active, budget: 100))
        context.insert(Project(name: "Beta Complex", status: .planning, budget: 200))
        try? context.save()
        
        await viewModel.loadProjects()
        
        let results = viewModel.searchProjects(query: "Alpha")
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.name, "Alpha Tower")
    }
    
    // MARK: - Computed Properties
    
    @MainActor func testActiveProjectsCount() async {
        let context = mockContainer.mainContext
        context.insert(Project(name: "Active 1", status: .active, budget: 100))
        context.insert(Project(name: "Active 2", status: .active, budget: 200))
        context.insert(Project(name: "Done", status: .completed, budget: 300))
        try? context.save()
        
        await viewModel.loadProjects()
        XCTAssertEqual(viewModel.activeProjects, 2)
    }
    
    // MARK: - Optimistic Updates
    
    @MainActor func testOptimisticDeleteRemovesProjectLocally() async {
        let context = mockContainer.mainContext
        let project = Project(name: "To Delete", status: .active, budget: 100)
        context.insert(project)
        try? context.save()
        
        await viewModel.loadProjects()
        XCTAssertEqual(viewModel.totalCount, 1)
        
        await viewModel.deleteProject(project)
        XCTAssertEqual(viewModel.totalCount, 0)
    }
}

// MARK: - Mock Repository

extension ProjectRepository {
    static var failing: ProjectRepository {
        ProjectRepository(
            fetchAll: { throw NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Simulated failure"]) },
            fetchById: { _ in throw NSError(domain: "test", code: 1) },
            create: { _ in throw NSError(domain: "test", code: 1) },
            update: { _ in },
            delete: { _ in }
        )
    }
}

extension ProjectViewModel.State: @retroactive Equatable {
    public static func == (lhs: ProjectViewModel.State, rhs: ProjectViewModel.State) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle): true
        case (.loading, .loading): true
        case (.loaded(let l), .loaded(let r)): l.map(\.id) == r.map(\.id)
        case (.error(let l), .error(let r)): l == r
        default: false
        }
    }
}
