import Foundation
import OSLog

actor CommunityPublishCoordinator {
    private let community: any CommunityService
    private let visitsLoader: @Sendable (UUID) async throws -> CommunityVisitDraft?
    private let logger = Logger(subsystem: "brainmeld.Road-Beans", category: "CommunityPublish")

    init(
        community: any CommunityService,
        visitsLoader: @escaping @Sendable (UUID) async throws -> CommunityVisitDraft?
    ) {
        self.community = community
        self.visitsLoader = visitsLoader
    }

    func publishIfMember(visitID: UUID) async {
        await retry("publish visit \(visitID.uuidString)") {
            guard try await community.currentMember() != nil else { return }
            guard let draft = try await visitsLoader(visitID) else { return }
            _ = try await community.publish(draft)
        }
    }

    func republishIfMember(visitID: UUID) async {
        await retry("republish visit \(visitID.uuidString)") {
            guard try await community.currentMember() != nil else { return }
            guard let draft = try await visitsLoader(visitID) else { return }
            try await community.updatePublishedVisit(draft)
        }
    }

    func unpublishIfPossible(visitID: UUID) async {
        await retry("unpublish visit \(visitID.uuidString)") {
            try await community.deletePublishedVisit(localVisitID: visitID)
        }
    }

    private func retry(_ label: String, _ operation: () async throws -> Void) async {
        var delay: UInt64 = 250_000_000
        for attempt in 0..<3 {
            do {
                try await operation()
                logger.info("Community \(label, privacy: .public) succeeded")
                return
            } catch {
                logger.error("Community \(label, privacy: .public) failed attempt \(attempt + 1): \(String(describing: error), privacy: .public)")
                guard attempt < 2 else { return }
                try? await Task.sleep(nanoseconds: delay)
                delay *= 2
            }
        }
    }
}
