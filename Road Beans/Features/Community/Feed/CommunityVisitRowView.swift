import SwiftUI

struct CommunityVisitRowView: View {
    let row: CommunityVisitRow
    var isFavorite: Bool
    var isLiked = false
    var onRowTapped: (() -> Void)?
    var onLikeTapped: (() -> Void)?

    var body: some View {
        let placeKind = PlaceKind(rawValue: row.placeKindRawValue) ?? .other

        VStack(alignment: .leading, spacing: RoadBeansSpacing.md) {
            VStack(alignment: .leading, spacing: RoadBeansSpacing.md) {
                HStack(alignment: .top, spacing: RoadBeansSpacing.md) {
                    Icon(.place(placeKind), size: 22)
                        .frame(width: 40, height: 40)
                        .background(placeKind.accentColor.opacity(0.12), in: Circle())

                    VStack(alignment: .leading, spacing: RoadBeansSpacing.xxs) {
                        HStack(alignment: .firstTextBaseline, spacing: RoadBeansSpacing.xs) {
                            Text(row.authorDisplayName)
                                .roadBeansStyle(.titleM)
                            if isFavorite {
                                Image(systemName: "star.fill")
                                    .font(.caption)
                                    .foregroundStyle(Color.accent(.default))
                            }
                        }

                        Text(row.placeName)
                            .roadBeansStyle(.bodyM)
                            .foregroundStyle(.ink(.primary))
                            .lineLimit(1)
                    }

                    Spacer(minLength: RoadBeansSpacing.md)

                    BeanRatingView(value: .constant(row.beanRating), size: 16, editable: false)
                }

                TasteProfileChips(profile: row.authorTasteProfile)

                if !row.drinkSummary.isEmpty {
                    Text(row.drinkSummary)
                        .roadBeansStyle(.bodyS)
                        .foregroundStyle(.ink(.secondary))
                        .lineLimit(2)
                }

                if !row.tagSummary.isEmpty {
                    Text(row.tagSummary)
                        .roadBeansStyle(.caption)
                        .foregroundStyle(.ink(.secondary))
                        .lineLimit(2)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                onRowTapped?()
            }

            Divider()

            HStack(spacing: RoadBeansSpacing.lg) {
                actionLabel(
                    count: row.likeCount,
                    systemImage: isLiked ? "heart.fill" : "heart",
                    activeColor: .state(.danger),
                    isActive: isLiked,
                    action: onLikeTapped,
                    accessibilityLabel: isLiked ? "Unlike" : "Like"
                )

                Spacer()

                Text(row.visitDate.formatted(date: .abbreviated, time: .omitted))
                    .roadBeansStyle(.caption)
                    .foregroundStyle(.ink(.secondary))
            }
        }
        .padding(RoadBeansSpacing.lg)
        .roadBeansSurface(.base, tint: placeKind.accentColor)
    }

    private func actionLabel(
        count: Int,
        systemImage: String,
        activeColor: Color,
        isActive: Bool,
        action: (() -> Void)?,
        accessibilityLabel: String
    ) -> some View {
        Group {
            if let action {
                Button(action: action) {
                    actionLabelContent(count: count, systemImage: systemImage, activeColor: activeColor, isActive: isActive)
                }
                .buttonStyle(.plain)
            } else {
                actionLabelContent(count: count, systemImage: systemImage, activeColor: activeColor, isActive: isActive)
            }
        }
        .accessibilityLabel(accessibilityLabel)
        .accessibilityValue("\(count)")
    }

    private func actionLabelContent(
        count: Int,
        systemImage: String,
        activeColor: Color,
        isActive: Bool
    ) -> some View {
        Label("\(count)", systemImage: systemImage)
            .roadBeansStyle(.caption)
            .foregroundStyle(isActive ? activeColor : Color.ink(.secondary))
            .frame(minWidth: 44, minHeight: 32, alignment: .leading)
            .contentShape(Rectangle())
    }
}
