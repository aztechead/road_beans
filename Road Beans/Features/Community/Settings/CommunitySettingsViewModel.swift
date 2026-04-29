import Foundation
import Observation
import OSLog

@Observable
@MainActor
final class CommunitySettingsViewModel {
    var displayName = ""
    var profile: TasteProfile = .midpoint
    var deleteRatingsWhenLeaving = false
    var state: ScreenState = .idle
    var errorMessage: String?
    var actionMessage: String?

    private var originalDisplayName = ""
    private var originalProfile: TasteProfile = .midpoint
    private let service: any CommunityService
    private let memberCache: CommunityMemberCache
    private let logger = Logger(subsystem: "brainmeld.Road-Beans", category: "CommunitySettings")

    init(
        service: any CommunityService,
        memberCache: CommunityMemberCache,
        initialMember: CommunityMemberSnapshot? = nil
    ) {
        self.service = service
        self.memberCache = memberCache
        if let initialMember {
            apply(initialMember)
            state = .loaded
        }
    }

    var isMember: Bool {
        !originalDisplayName.isEmpty
    }

    var canSave: Bool {
        let trimmedName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmedName.isEmpty
            && !CommunityContentFilter.containsBlockedContent(trimmedName)
            && (trimmedName != originalDisplayName || profile != originalProfile)
    }

    var shouldShowUsernameWarning: Bool {
        isMember && displayName.trimmingCharacters(in: .whitespacesAndNewlines) != originalDisplayName
    }

    func load() async {
        if let cached = await memberCache.snapshot() {
            apply(cached)
            state = .loaded
        } else {
            state = .loading
        }
        errorMessage = nil
        do {
            guard let member = try await withTimeout(seconds: 5, operation: {
                try await self.service.currentMember()
            }) else {
                await memberCache.store(nil)
                originalDisplayName = ""
                displayName = ""
                state = .empty
                return
            }
            await memberCache.store(member)
            apply(member)
            state = .loaded
        } catch {
            logger.error("Community settings load failed: \(String(describing: error), privacy: .public)")
            if !isMember {
                fail("Road Beans could not load community settings. Try again in a moment.")
            } else {
                actionMessage = "Road Beans could not refresh community settings."
                state = .loaded
            }
        }
    }

    func save() async -> Bool {
        let trimmedName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            fail("Enter a username before saving.")
            return false
        }
        guard !CommunityContentFilter.containsBlockedContent(trimmedName) else {
            fail("Choose a different username.")
            return false
        }

        state = .loading
        errorMessage = nil
        actionMessage = nil
        do {
            try await service.updateProfile(displayName: trimmedName, profile: profile)
            originalDisplayName = trimmedName
            originalProfile = profile
            displayName = trimmedName
            await memberCache.refresh(using: service)
            actionMessage = "Community settings saved."
            state = .loaded
            return true
        } catch {
            logger.error("Community settings save failed: \(String(describing: error), privacy: .public)")
            fail("Road Beans could not save community settings.")
            return false
        }
    }

    func leave() async -> Bool {
        state = .loading
        errorMessage = nil
        actionMessage = nil
        do {
            try await service.leave(deleteRatings: deleteRatingsWhenLeaving)
            await memberCache.store(nil)
            originalDisplayName = ""
            displayName = ""
            state = .empty
            return true
        } catch {
            logger.error("Community leave failed: \(String(describing: error), privacy: .public)")
            fail("Road Beans could not leave the community.")
            return false
        }
    }

    private func fail(_ message: String) {
        errorMessage = message
        state = .failed(message)
    }

    private func apply(_ member: CommunityMemberSnapshot) {
        originalDisplayName = member.displayName
        originalProfile = member.tasteProfile
        displayName = member.displayName
        profile = member.tasteProfile
    }
}

private struct SettingsTimeoutError: Error {}

private func withTimeout<T: Sendable>(
    seconds: UInt64,
    operation: @escaping @Sendable () async throws -> T
) async throws -> T {
    try await withThrowingTaskGroup(of: T.self) { group in
        group.addTask {
            try await operation()
        }
        group.addTask {
            try await Task.sleep(nanoseconds: seconds * 1_000_000_000)
            throw SettingsTimeoutError()
        }

        guard let result = try await group.next() else {
            throw SettingsTimeoutError()
        }
        group.cancelAll()
        return result
    }
}
