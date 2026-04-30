import Foundation

enum AppRoute: Equatable {
    nonisolated static let scheme = "roadbeans"

    case addVisit
    case quickLog
    case recentVisits
    case radar
    case tasteProfile
    case map

    nonisolated init?(url: URL) {
        guard url.scheme == Self.scheme else { return nil }

        let route = [url.host, url.pathComponents.dropFirst().joined(separator: "/")]
            .compactMap { $0 }
            .first { !$0.isEmpty }

        switch route {
        case "add-visit":
            self = .addVisit
        case "quick-log", "log-here":
            self = .quickLog
        case "recent", "visits":
            self = .recentVisits
        case "radar", "nearby":
            self = .radar
        case "taste", "taste-profile":
            self = .tasteProfile
        case "map":
            self = .map
        default:
            return nil
        }
    }

    nonisolated var url: URL {
        switch self {
        case .addVisit:
            URL(string: "\(Self.scheme)://add-visit")!
        case .quickLog:
            URL(string: "\(Self.scheme)://quick-log")!
        case .recentVisits:
            URL(string: "\(Self.scheme)://recent")!
        case .radar:
            URL(string: "\(Self.scheme)://radar")!
        case .tasteProfile:
            URL(string: "\(Self.scheme)://taste-profile")!
        case .map:
            URL(string: "\(Self.scheme)://map")!
        }
    }
}
