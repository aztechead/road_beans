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

    @Test func parsesRecentVisitsRoute() throws {
        #expect(AppRoute(url: URL(string: "roadbeans://recent")!) == .recentVisits)
        #expect(AppRoute(url: URL(string: "roadbeans://visits")!) == .recentVisits)
    }

    @Test func parsesMapRoute() throws {
        #expect(AppRoute(url: URL(string: "roadbeans://map")!) == .map)
    }

    @Test func rejectsUnknownRoutes() {
        #expect(AppRoute(url: URL(string: "roadbeans://settings")!) == nil)
        #expect(AppRoute(url: URL(string: "https://example.com/add-visit")!) == nil)
    }
}
