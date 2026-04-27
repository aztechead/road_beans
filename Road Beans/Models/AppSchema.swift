import SwiftData

enum AppSchema {
    static let all: Schema = Schema([
        Place.self,
        Visit.self,
        Drink.self,
        Tag.self,
        VisitPhoto.self,
        Tombstone.self,
        FavoriteMember.self,
    ])
}
