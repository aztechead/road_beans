import Foundation
import Testing
@testable import Road_Beans

@Suite("AppRoute")
struct AppRouteTests {
    @Test func parsesAddVisitRoute() throws {
        let route = try #require(AppRoute(url: URL(string: "roadbeans://add-visit")!))

        #expect(route == .addVisit)
        #expect(route.url == URL(string: "roadbeans://add-visit")!)
    }

    @Test func parsesQuickLogRoute() throws {
        let route = try #require(AppRoute(url: URL(string: "roadbeans://quick-log")!))

        #expect(route == .quickLog)
        #expect(route.url == URL(string: "roadbeans://quick-log")!)
    }

    @Test func parsesRecentVisitsRoute() throws {
        #expect(AppRoute(url: URL(string: "roadbeans://recent")!) == .recentVisits)
        #expect(AppRoute(url: URL(string: "roadbeans://visits")!) == .recentVisits)
    }

    @Test func parsesRadarRoute() throws {
        #expect(AppRoute(url: URL(string: "roadbeans://radar")!) == .radar)
        #expect(AppRoute(url: URL(string: "roadbeans://nearby")!) == .radar)
        #expect(AppRoute.radar.url == URL(string: "roadbeans://radar")!)
    }

    @Test func parsesTasteRoute() throws {
        #expect(AppRoute(url: URL(string: "roadbeans://taste")!) == .tasteProfile)
        #expect(AppRoute(url: URL(string: "roadbeans://taste-profile")!) == .tasteProfile)
        #expect(AppRoute.tasteProfile.url == URL(string: "roadbeans://taste-profile")!)
    }

    @Test func parsesMapRoute() throws {
        #expect(AppRoute(url: URL(string: "roadbeans://map")!) == .map)
    }

    @Test func rejectsUnknownRoutes() {
        #expect(AppRoute(url: URL(string: "roadbeans://settings")!) == nil)
        #expect(AppRoute(url: URL(string: "https://example.com/add-visit")!) == nil)
    }
}
