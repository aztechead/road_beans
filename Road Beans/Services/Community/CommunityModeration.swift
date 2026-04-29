import Foundation

struct CommunityReportDraft: Sendable, Equatable {
    let visitRecordName: String
    let reportedAuthorUserRecordID: String
    let reason: String
}

enum CommunityContentFilter {
    nonisolated private static let blockedTerms: Set<String> = [
        "fuck", "shit", "bitch", "cunt", "nigger", "faggot", "retard",
        "kys", "kill yourself", "rape", "nazi"
    ]

    nonisolated static func containsBlockedContent(_ values: [String]) -> Bool {
        values.contains { containsBlockedContent($0) }
    }

    nonisolated static func containsBlockedContent(_ value: String) -> Bool {
        let normalized = value
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .lowercased()
        return blockedTerms.contains { term in
            normalized.contains(term)
        }
    }
}

enum CommunityModerationStore {
    private static let blockedAuthorsKey = "communityBlockedAuthorIDs"
    private static let acceptedTermsKey = "communityAcceptedTerms"

    static var hasAcceptedTerms: Bool {
        get { UserDefaults.standard.bool(forKey: acceptedTermsKey) }
        set { UserDefaults.standard.set(newValue, forKey: acceptedTermsKey) }
    }

    static var blockedAuthorIDs: Set<String> {
        get {
            Set(UserDefaults.standard.stringArray(forKey: blockedAuthorsKey) ?? [])
        }
        set {
            UserDefaults.standard.set(Array(newValue).sorted(), forKey: blockedAuthorsKey)
        }
    }

    static func block(authorUserRecordID: String) {
        var blocked = blockedAuthorIDs
        blocked.insert(authorUserRecordID)
        blockedAuthorIDs = blocked
    }

    static func unblock(authorUserRecordID: String) {
        var blocked = blockedAuthorIDs
        blocked.remove(authorUserRecordID)
        blockedAuthorIDs = blocked
    }
}
