import XCTest
@testable import BuildTrack

final class DeepLinkRouterTests: XCTestCase {
    let router = DeepLinkRouter()
    let sampleUUID = UUID(uuidString: "11111111-2222-3333-4444-555555555555")!

    // MARK: - Scheme validation

    func testRejectsNonBuildtrackScheme() {
        XCTAssertNil(router.resolve("https://dashboard"))
        XCTAssertNil(router.resolve("http://projects"))
        XCTAssertNil(router.resolve("ftp://anything"))
    }

    func testRejectsUnknownHost() {
        XCTAssertNil(router.resolve("buildtrack://unknown"))
        XCTAssertNil(router.resolve("buildtrack://"))
        XCTAssertNil(router.resolve("buildtrack://nope/\(sampleUUID)"))
    }

    func testRejectsMalformedURL() {
        XCTAssertNil(router.resolve("not a url at all"))
    }

    // MARK: - Simple list screens (no ID)

    func testDashboard() {
        XCTAssertEqual(router.resolve("buildtrack://dashboard"), .dashboard)
    }

    func testProjectsList() {
        XCTAssertEqual(router.resolve("buildtrack://projects"), .projects)
    }

    func testTasksList() {
        XCTAssertEqual(router.resolve("buildtrack://tasks"), .tasks)
    }

    func testRfisList() {
        XCTAssertEqual(router.resolve("buildtrack://rfis"), .rfis)
    }

    func testDrawingsList() {
        XCTAssertEqual(router.resolve("buildtrack://drawings"), .drawings)
    }

    func testMap() {
        XCTAssertEqual(router.resolve("buildtrack://map"), .map)
    }

    func testTeam() {
        XCTAssertEqual(router.resolve("buildtrack://team"), .team)
    }

    func testNotifications() {
        XCTAssertEqual(router.resolve("buildtrack://notifications"), .notifications)
    }

    // MARK: - Detail screens with path-based ID

    func testProjectDetailViaPath() {
        XCTAssertEqual(
            router.resolve("buildtrack://project/\(sampleUUID)"),
            .projectDetail(sampleUUID)
        )
    }

    func testTaskDetailViaPath() {
        XCTAssertEqual(
            router.resolve("buildtrack://task/\(sampleUUID)"),
            .taskDetail(sampleUUID)
        )
    }

    func testRfiDetailViaPath() {
        XCTAssertEqual(
            router.resolve("buildtrack://rfi/\(sampleUUID)"),
            .rfiDetail(sampleUUID)
        )
    }

    func testDrawingDetailViaPath() {
        XCTAssertEqual(
            router.resolve("buildtrack://drawing/\(sampleUUID)"),
            .drawingDetail(sampleUUID)
        )
    }

    func testPunchItemDetailViaPath() {
        XCTAssertEqual(
            router.resolve("buildtrack://punchitem/\(sampleUUID)"),
            .punchItemDetail(sampleUUID)
        )
    }

    // MARK: - Detail screens with query-based ID

    func testProjectDetailViaQuery() {
        XCTAssertEqual(
            router.resolve("buildtrack://project?id=\(sampleUUID)"),
            .projectDetail(sampleUUID)
        )
    }

    func testTaskDetailViaQuery() {
        XCTAssertEqual(
            router.resolve("buildtrack://task?id=\(sampleUUID)"),
            .taskDetail(sampleUUID)
        )
    }

    func testPunchItemDetailViaQuery() {
        XCTAssertEqual(
            router.resolve("buildtrack://punch?id=\(sampleUUID)"),
            .punchItemDetail(sampleUUID)
        )
    }

    // MARK: - Missing ID falls back to list

    func testProjectWithoutIdReturnsList() {
        XCTAssertEqual(router.resolve("buildtrack://project"), .projects)
    }

    func testTaskWithoutIdReturnsList() {
        XCTAssertEqual(router.resolve("buildtrack://task"), .tasks)
    }

    func testRfiWithoutIdReturnsList() {
        XCTAssertEqual(router.resolve("buildtrack://rfi"), .rfis)
    }

    func testDrawingWithoutIdReturnsList() {
        XCTAssertEqual(router.resolve("buildtrack://drawing"), .drawings)
    }

    func testPunchitemWithoutIdReturnsList() {
        XCTAssertEqual(router.resolve("buildtrack://punchitem"), .punchItems)
    }

    // MARK: - Punch alias hosts (punch, punchitems, punchitem all collapse to .punchItems / .punchItemDetail)

    func testPunchAliasList() {
        XCTAssertEqual(router.resolve("buildtrack://punch"), .punchItems)
        XCTAssertEqual(router.resolve("buildtrack://punchitems"), .punchItems)
    }

    func testPunchAliasDetailViaPath() {
        XCTAssertEqual(
            router.resolve("buildtrack://punch/\(sampleUUID)"),
            .punchItemDetail(sampleUUID)
        )
        XCTAssertEqual(
            router.resolve("buildtrack://punchitems/\(sampleUUID)"),
            .punchItemDetail(sampleUUID)
        )
    }

    // MARK: - Safety alias hosts (safety/inspection/inspections/incident/incidents → .safety)

    func testSafetyAliases() {
        for host in ["safety", "inspection", "inspections", "incident", "incidents"] {
            XCTAssertEqual(
                router.resolve("buildtrack://\(host)"),
                .safety,
                "host '\(host)' should resolve to .safety"
            )
        }
    }

    // MARK: - resolve(URL) variant

    func testResolveWithURLDirectly() {
        let url = URL(string: "buildtrack://dashboard")!
        XCTAssertEqual(router.resolve(url), .dashboard)
    }

    // MARK: - Invalid UUIDs ignored → falls back to list

    func testInvalidUUIDInPathFallsBackToList() {
        XCTAssertEqual(router.resolve("buildtrack://project/not-a-uuid"), .projects)
    }

    func testInvalidUUIDInQueryFallsBackToList() {
        XCTAssertEqual(router.resolve("buildtrack://project?id=not-a-uuid"), .projects)
    }

    // MARK: - Path ID takes precedence over query ID

    func testPathIdPrecedenceOverQuery() {
        let pathId = UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE")!
        let queryId = UUID(uuidString: "11111111-2222-3333-4444-555555555555")!
        let url = "buildtrack://project/\(pathId)?id=\(queryId)"
        XCTAssertEqual(router.resolve(url), .projectDetail(pathId))
    }

    // MARK: - tabFor mapping

    func testTabForRootScreens() {
        XCTAssertEqual(router.tabFor(.dashboard), 0)
        XCTAssertEqual(router.tabFor(.projects), 1)
        XCTAssertEqual(router.tabFor(.tasks), 2)
        XCTAssertEqual(router.tabFor(.punchItems), 3)
        XCTAssertEqual(router.tabFor(.drawings), 4)
    }

    func testTabForDetailScreens() {
        let id = UUID()
        XCTAssertEqual(router.tabFor(.projectDetail(id)), 1)
        XCTAssertEqual(router.tabFor(.taskDetail(id)), 2)
        XCTAssertEqual(router.tabFor(.punchItemDetail(id)), 3)
        XCTAssertEqual(router.tabFor(.drawingDetail(id)), 4)
    }

    func testTabForUntabbedSurfacesFallToDashboard() {
        XCTAssertEqual(router.tabFor(.rfis), 0)
        XCTAssertEqual(router.tabFor(.rfiDetail(UUID())), 0)
        XCTAssertEqual(router.tabFor(.map), 0)
        XCTAssertEqual(router.tabFor(.safety), 0)
        XCTAssertEqual(router.tabFor(.team), 0)
        XCTAssertEqual(router.tabFor(.notifications), 0)
    }
}
