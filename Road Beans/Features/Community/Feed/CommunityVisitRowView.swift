import SwiftUI

struct CommunityVisitRowView: View {
    let row: CommunityVisitRow
    var isFavorite: Bool
    var isLiked = false
    var onRowTapped: (() -> Void)?
    var onLikeTapped: (() -> Void)?
    var onCommentTapped: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: RoadBeansTheme.Spacing.sm) {
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
            }
            .contentShape(Rectangle())
            .onTapGesture {
                onRowTapped?()
            }

            HStack(spacing: 16) {
                if let onLikeTapped {
                    Label("\(row.likeCount)", systemImage: isLiked ? "heart.fill" : "heart")
                        .contentShape(Rectangle())
                        .onTapGesture(perform: onLikeTapped)
                        .accessibilityAddTraits(.isButton)
                        .accessibilityLabel(isLiked ? "Unlike" : "Like")
                        .accessibilityValue("\(row.likeCount)")
                        .foregroundStyle(isLiked ? .red : .secondary)
                } else {
                    Label("\(row.likeCount)", systemImage: isLiked ? "heart.fill" : "heart")
                        .foregroundStyle(isLiked ? .red : .secondary)
                }

                if let onCommentTapped {
                    Label("\(row.commentCount)", systemImage: "bubble.right")
                        .contentShape(Rectangle())
                        .onTapGesture(perform: onCommentTapped)
                        .accessibilityAddTraits(.isButton)
                        .accessibilityLabel("Comments")
                        .accessibilityValue("\(row.commentCount)")
                        .foregroundStyle(.secondary)
                } else {
                    Label("\(row.commentCount)", systemImage: "bubble.right")
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(row.visitDate.formatted(date: .abbreviated, time: .omitted))
            }
            .font(.caption)
        }
        .padding(.vertical, 6)
    }
}
