import Foundation

struct DrinkDraft: Hashable, Sendable {
    var name: String
    var category: DrinkCategory
    var rating: Double
    var tags: [String]
}

struct PhotoDraft: Hashable, Sendable {
    let rawImageData: Data
    var caption: String?
}
