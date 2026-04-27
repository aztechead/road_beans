import Foundation

struct CommunityCommentRow: Identifiable, Sendable, Equatable {
    let id: String
    let authorUserRecordID: String
    let authorDisplayName: String
    let text: String
    let timestamp: Date
}
