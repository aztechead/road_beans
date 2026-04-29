import Foundation

enum CommunityRecordType {
    nonisolated static let member = "CommunityMember"
    nonisolated static let visit = "CommunityVisit"
    nonisolated static let like = "CommunityLike"
    nonisolated static let report = "CommunityReport"
}

enum CommunityServiceError: Error, Sendable, Equatable {
    case missing
    case notAMember
    case notAuthor
    case alreadyMember
    case notFound
    case invalidInput
    case schemaNotConfigured
    case underlying(String)
}
