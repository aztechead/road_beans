import CoreSpotlight
import Foundation
import UniformTypeIdentifiers

struct SpotlightIndexingService: Sendable {
    static let shared = SpotlightIndexingService()

    private let placeDomain = "brainmeld.Road-Beans.places"
    private let visitDomain = "brainmeld.Road-Beans.visits"

    func reindex(places: [PlaceSummary], visits: [RecentVisitRow]) {
        guard CSSearchableIndex.isIndexingAvailable() else { return }

        let items = placeItems(from: places) + visitItems(from: visits)
        CSSearchableIndex.default().deleteSearchableItems(withDomainIdentifiers: [placeDomain, visitDomain]) { _ in
            CSSearchableIndex.default().indexSearchableItems(items)
        }
    }

    private func placeItems(from places: [PlaceSummary]) -> [CSSearchableItem] {
        places.map { place in
            let attributes = CSSearchableItemAttributeSet(contentType: .item)
            attributes.title = place.name
            attributes.displayName = place.name
            attributes.contentDescription = [
                place.kind.displayName,
                place.address,
                place.averageRating.map { String(format: "%.1f beans", $0) },
                place.visitCount > 0 ? "\(place.visitCount) saved visit\(place.visitCount == 1 ? "" : "s")" : nil
            ]
            .compactMap { $0 }
            .joined(separator: " · ")
            attributes.keywords = [
                place.name,
                place.kind.displayName,
                place.address
            ].compactMap { $0 }

            return CSSearchableItem(
                uniqueIdentifier: "place.\(place.id.uuidString)",
                domainIdentifier: placeDomain,
                attributeSet: attributes
            )
        }
    }

    private func visitItems(from visits: [RecentVisitRow]) -> [CSSearchableItem] {
        visits.map { row in
            let attributes = CSSearchableItemAttributeSet(contentType: .item)
            attributes.title = row.placeName
            attributes.displayName = row.placeName
            attributes.contentDescription = [
                row.drinkNames.isEmpty ? nil : row.drinkNames.joined(separator: ", "),
                row.visit.averageRating.map { String(format: "%.1f beans", $0) },
                row.visit.tagNames.isEmpty ? nil : row.visit.tagNames.joined(separator: ", "),
                Optional(row.visit.date.formatted(date: .abbreviated, time: .omitted))
            ]
            .compactMap { $0 }
            .joined(separator: " · ")
            attributes.keywords = [
                row.placeName,
                row.placeKind.displayName
            ] + row.drinkNames + row.visit.tagNames

            return CSSearchableItem(
                uniqueIdentifier: "visit.\(row.visit.id.uuidString)",
                domainIdentifier: visitDomain,
                attributeSet: attributes
            )
        }
    }
}
