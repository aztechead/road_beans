import Foundation

enum ScreenState: Equatable, Sendable {
    case idle
    case loading
    case loaded
    case empty
    case failed(String)

    var errorMessage: String? {
        guard case .failed(let message) = self else { return nil }
        return message
    }
}
