import Foundation
import Observation

@Observable
@MainActor
final class CommunityVisitDetailViewModel {
    var detail: CommunityVisitDetail?
    var state: ScreenState = .idle
    var isUpdatingLike = false
    var isDeletingVisit = false
    var actionMessage: String?
    var deleteSucceeded = false

    private let recordName: String
    private let service: any CommunityService
    private var currentMember: CommunityMemberSnapshot?

    init(recordName: String, service: any CommunityService) {
        self.recordName = recordName
        self.service = service
    }

    func load() async {
        state = .loading
        do {
            async let loadedMember = service.currentMember()
            async let loadedDetail = service.fetchVisitDetail(recordName: recordName)
            currentMember = try await loadedMember
            detail = try await loadedDetail
            state = detail == nil ? .empty : .loaded
        } catch {
            state = .failed("Road Beans could not load this community visit.")
        }
    }

    var canDeleteVisit: Bool {
        guard let currentMember, let detail else { return false }
        return detail.row.authorUserRecordID == currentMember.userRecordID
    }

    func toggleLike() async {
        guard let current = detail, !isUpdatingLike else { return }
        isUpdatingLike = true
        actionMessage = nil
        let wasLiked = current.likedByCurrentUser
        var row = current.row
        row.likeCount = max(0, row.likeCount + (wasLiked ? -1 : 1))
        detail = CommunityVisitDetail(
            row: row,
            likedByCurrentUser: !wasLiked
        )
        do {
            if wasLiked {
                try await service.unlike(visitRecordName: current.row.id)
            } else {
                try await service.like(visitRecordName: current.row.id)
            }
        } catch {
            detail = current
            actionMessage = "Road Beans could not update the like."
        }
        isUpdatingLike = false
    }

    func deleteVisit() async {
        guard canDeleteVisit, !isDeletingVisit else { return }
        isDeletingVisit = true
        actionMessage = nil
        do {
            try await service.deleteVisit(recordName: recordName)
            deleteSucceeded = true
        } catch CommunityServiceError.notAuthor {
            actionMessage = "Only the author can delete this community review."
        } catch {
            actionMessage = "Road Beans could not delete this community review."
        }
        isDeletingVisit = false
    }
}
