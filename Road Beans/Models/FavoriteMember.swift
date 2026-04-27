import Foundation
import SwiftData

@Model
final class FavoriteMember {
    var id: UUID = UUID()
    var memberUserRecordID: String = ""
    var addedAt: Date = Date.now

    init() {}
}
