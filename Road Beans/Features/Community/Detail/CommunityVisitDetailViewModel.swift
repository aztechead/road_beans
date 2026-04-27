import Foundation
import Observation

@Observable
@MainActor
final class CommunityVisitDetailViewModel {
    var detail: CommunityVisitDetail?
    var commentText = ""
    var state: ScreenState = .idle
    var isPostingComment = false
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
            comments: current.comments,
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

    func addComment() async {
        let text = commentText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, let current = detail, !isPostingComment else { return }
        isPostingComment = true
        actionMessage = nil
        commentText = ""
        do {
            let comment = try await service.addComment(toVisitRecordName: recordName, text: text)
            var comments = current.comments
            comments.append(comment)
            var row = current.row
            row.commentCount = comments.count
            detail = CommunityVisitDetail(
                row: row,
                comments: comments,
                likedByCurrentUser: current.likedByCurrentUser
            )
        } catch {
            commentText = text
            actionMessage = "Road Beans could not post the comment."
        }
        isPostingComment = false
    }

    func deleteComment(id: String) async {
        do {
            try await service.deleteComment(recordName: id)
            await load()
        } catch {
            actionMessage = "Road Beans could not delete the comment."
        }
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
