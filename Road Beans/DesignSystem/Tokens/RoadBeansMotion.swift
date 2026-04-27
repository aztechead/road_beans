import SwiftUI

enum RoadBeansMotion {
    enum Duration {
        static let micro = 0.12
        static let short = 0.20
        static let medium = 0.30
        static let long = 0.50
    }

    static let `default` = Animation.spring(response: 0.40, dampingFraction: 0.85)
    static let soft = Animation.spring(response: 0.55, dampingFraction: 0.78)
    static let snap = Animation.spring(response: 0.30, dampingFraction: 0.90)

    enum Signature {
        case beanCommit
        case publishToCommunity
        case pullToRefreshTopo
    }

    static func signature(_ kind: Signature, reduceMotion: Bool) -> Animation {
        if reduceMotion {
            return .easeInOut(duration: Duration.short)
        }

        switch kind {
        case .beanCommit:
            return `default`
        case .publishToCommunity:
            return .easeOut(duration: Duration.long + 0.2)
        case .pullToRefreshTopo:
            return .easeOut(duration: Duration.medium)
        }
    }
}
