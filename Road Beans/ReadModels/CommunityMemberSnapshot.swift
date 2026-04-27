import Foundation

struct CommunityMemberSnapshot: Identifiable, Sendable, Equatable {
    var id: String { userRecordID }

    let userRecordID: String
    let displayName: String
    let tasteProfile: TasteProfile
    let joinedAt: Date
}
