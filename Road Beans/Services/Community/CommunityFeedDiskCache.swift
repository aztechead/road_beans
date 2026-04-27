import Foundation

actor CommunityFeedDiskCache {
    struct Entry: Codable, Sendable {
        var favorites: [CommunityVisitRow]
        var everyone: [CommunityVisitRow]
        var nextCursor: String?
        var savedAt: Date
    }

    private let url: URL

    init(filename: String = "CommunityFeedCache.json") {
        let baseDirectory = (try? FileManager.default.url(
            for: .cachesDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )) ?? URL(fileURLWithPath: NSTemporaryDirectory())
        self.url = baseDirectory.appendingPathComponent(filename)
    }

    func load() -> [String: Entry] {
        guard let data = try? Data(contentsOf: url) else { return [:] }
        return (try? JSONDecoder().decode([String: Entry].self, from: data)) ?? [:]
    }

    func save(_ entries: [String: Entry]) {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        try? data.write(to: url, options: .atomic)
    }

    func clear() {
        try? FileManager.default.removeItem(at: url)
    }
}
