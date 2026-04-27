import SwiftUI

struct CommunityVisitRowView: View {
    let row: CommunityVisitRow
    var isFavorite: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: RoadBeansTheme.Spacing.sm) {
            HStack(alignment: .firstTextBaseline) {
                Text(row.authorDisplayName)
                    .font(.roadBeansHeadline)
                if isFavorite {
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundStyle(.yellow)
                }
                Spacer()
                BeanRating(value: row.beanRating, pixelSize: 2)
            }

            TasteProfileChips(profile: row.authorTasteProfile)

            HStack {
                Image(systemName: PlaceKind(rawValue: row.placeKindRawValue)?.sfSymbol ?? PlaceKind.other.sfSymbol)
                    .foregroundStyle((PlaceKind(rawValue: row.placeKindRawValue) ?? .other).accentColor)
                Text(row.placeName)
                    .font(.roadBeansBody)
            }

            if !row.drinkSummary.isEmpty {
                Text(row.drinkSummary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if !row.tagSummary.isEmpty {
                Text(row.tagSummary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 16) {
                Label("\(row.likeCount)", systemImage: "heart")
                Label("\(row.commentCount)", systemImage: "bubble.right")
                Spacer()
                Text(row.visitDate.formatted(date: .abbreviated, time: .omitted))
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 6)
    }
}
