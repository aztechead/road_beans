import Foundation
import Observation

@Observable
@MainActor
final class CommunityVisitDetailViewModel {
    var detail: CommunityVisitDetail?
    var commentText = ""
    var state: ScreenState = .idle

    private let recordName: String
    private let service: any CommunityService

    init(recordName: String, service: any CommunityService) {
        self.recordName = recordName
        self.service = service
    }

    func load() async {
        state = .loading
        do {
            detail = try await service.fetchVisitDetail(recordName: recordName)
            state = detail == nil ? .empty : .loaded
        } catch {
            state = .failed("Road Beans could not load this community visit.")
        }
    }

    func toggleLike() async {
        guard let detail else { return }
        do {
            if detail.likedByCurrentUser {
                try await service.unlike(visitRecordName: detail.row.id)
            } else {
                try await service.like(visitRecordName: detail.row.id)
            }
            await load()
        } catch {
            state = .failed("Road Beans could not update the like.")
        }
    }

    func addComment() async {
        let text = commentText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        do {
            _ = try await service.addComment(toVisitRecordName: recordName, text: text)
            commentText = ""
            await load()
        } catch {
            state = .failed("Road Beans could not post the comment.")
        }
    }

    func deleteComment(id: String) async {
        do {
            try await service.deleteComment(recordName: id)
            await load()
        } catch {
            state = .failed("Road Beans could not delete the comment.")
        }
    }
}
