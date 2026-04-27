import Foundation
import Observation
import OSLog

@Observable
@MainActor
final class CommunityOnboardingViewModel {
    var displayName: String
    var profile: TasteProfile
    var state: ScreenState = .idle
    var errorMessage: String?

    private let service: any CommunityService
    private let existingVisits: () async -> [CommunityVisitDraft]
    private let logger = Logger(subsystem: "brainmeld.Road-Beans", category: "CommunityOnboarding")

    init(
        service: any CommunityService,
        displayName: String? = nil,
        profile: TasteProfile? = nil,
        existingVisits: @escaping () async -> [CommunityVisitDraft] = { [] }
    ) {
        self.service = service
        self.displayName = displayName ?? "Road Beans Member"
        self.profile = profile ?? .midpoint
        self.existingVisits = existingVisits
    }

    var canJoin: Bool {
        !displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func join() async -> Bool {
        guard canJoin else {
            fail("Add a display name to join.")
            return false
        }

        state = .loading
        errorMessage = nil
        do {
            let visits = await existingVisits()
            try await withTimeout(seconds: 20) {
                try await self.service.join(
                    displayName: self.displayName,
                    profile: self.profile,
                    existingVisits: visits
                )
            }
            state = .loaded
            return true
        } catch {
            logger.error("Join community failed: \(String(describing: error), privacy: .public)")
            fail("Road Beans could not join the community: \(Self.readable(error))")
            return false
        }
    }

    private func fail(_ message: String) {
        errorMessage = message
        state = .failed(message)
    }

    private static func readable(_ error: Error) -> String {
        if case CommunityServiceError.alreadyMember = error {
            return "this iCloud account is already a member."
        }
        if case CommunityServiceError.notAMember = error {
            return "iCloud membership could not be confirmed."
        }
        if case CommunityServiceError.invalidInput = error {
            return "the entered profile is invalid."
        }
        if error is TimeoutError {
            return "CloudKit did not respond within 20 seconds."
        }
        return error.localizedDescription
    }
}

private struct TimeoutError: Error {}

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
            throw TimeoutError()
        }

        guard let result = try await group.next() else {
            throw TimeoutError()
        }
        group.cancelAll()
        return result
    }
}
