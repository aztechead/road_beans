import Foundation

enum AppRoute: Equatable {
    nonisolated static let scheme = "roadbeans"

    case addVisit
    case recentVisits
    case map

    nonisolated init?(url: URL) {
        guard url.scheme == Self.scheme else { return nil }

        let route = [url.host, url.pathComponents.dropFirst().joined(separator: "/")]
            .compactMap { $0 }
            .first { !$0.isEmpty }

        switch route {
        case "add-visit":
            self = .addVisit
        case "recent", "visits":
            self = .recentVisits
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
        case .recentVisits:
            URL(string: "\(Self.scheme)://recent")!
        case .map:
            URL(string: "\(Self.scheme)://map")!
        }
    }
}
