import Foundation

struct CommunityVisitDetail: Sendable, Equatable {
    let row: CommunityVisitRow
    let comments: [CommunityCommentRow]
    let likedByCurrentUser: Bool
}
