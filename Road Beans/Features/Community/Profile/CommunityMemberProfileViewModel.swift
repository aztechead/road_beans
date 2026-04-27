import Foundation
import Observation

@Observable
@MainActor
final class CommunityMemberProfileViewModel {
    var member: CommunityMemberSnapshot?
    var isFavorite = false
    var state: ScreenState = .idle
    private var currentMemberID: String?

    let memberUserRecordID: String
    private let service: any CommunityService
    private let favorites: any FavoriteMemberRepository

    init(
        memberUserRecordID: String,
        service: any CommunityService,
        favorites: any FavoriteMemberRepository
    ) {
        self.memberUserRecordID = memberUserRecordID
        self.service = service
        self.favorites = favorites
    }

    var isSelf: Bool {
        currentMemberID == memberUserRecordID
    }

    func load() async {
        state = .loading
        do {
            currentMemberID = try await service.currentMember()?.userRecordID
            member = try await service.fetchMember(userRecordID: memberUserRecordID)
            isFavorite = (try? favorites.contains(memberUserRecordID: memberUserRecordID)) ?? false
            state = member == nil ? .empty : .loaded
        } catch {
            state = .failed("Road Beans could not load this member.")
        }
    }

    func toggleFavorite() {
        do {
            if isFavorite {
                try favorites.remove(memberUserRecordID: memberUserRecordID)
                isFavorite = false
            } else {
                try favorites.add(memberUserRecordID: memberUserRecordID)
                isFavorite = true
            }
        } catch {
            state = .failed("Road Beans could not update favorites.")
        }
    }

    func leave() async -> Bool {
        do {
            try await service.leave(deleteRatings: true)
            member = nil
            state = .empty
            return true
        } catch {
            state = .failed("Road Beans could not leave the community.")
            return false
        }
    }
}
