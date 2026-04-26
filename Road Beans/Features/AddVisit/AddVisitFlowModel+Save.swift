import Foundation

extension AddVisitFlowModel {
    func save() async throws -> String {
        guard let placeRef else { throw VisitValidationError.missingPlace }
        guard !drinks.isEmpty else { throw VisitValidationError.missingDrinks }

        let command = CreateVisitCommand(
            placeRef: placeRef,
            date: date,
            drinks: drinks,
            tags: visitTags,
            photos: photos
        )

        _ = try await visits.save(command)
        return "Added to \(placeName(for: placeRef))."
    }

    private func placeName(for reference: PlaceReference) -> String {
        switch reference {
        case .existing:
            "place"
        case .newMapKit(let draft):
            draft.name
        case .newCustom(let draft):
            draft.name
        }
    }
}
