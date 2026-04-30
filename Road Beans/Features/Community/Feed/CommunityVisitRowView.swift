import SwiftUI

struct CommunityVisitRowView: View {
    let row: CommunityVisitRow
    var isFavorite: Bool
    var isLiked = false
    var reviewContextSummary: String?
    var onRowTapped: (() -> Void)?
    var onLikeTapped: (() -> Void)?

    var body: some View {
        let placeKind = PlaceKind(rawValue: row.placeKindRawValue) ?? .other
        let contextFacts = CommunityReviewContextSummary.facts(for: row)

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

                if contextFacts.hasContext {
                    CommunityReviewContextBlock(
                        summary: reviewContextSummary,
                        options: contextFacts.options,
                        tags: contextFacts.tags
                    )
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

private struct CommunityReviewContextBlock: View {
    let summary: String?
    let options: [String]
    let tags: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: RoadBeansSpacing.sm) {
            if let summary, !summary.isEmpty {
                Text(summary)
                    .roadBeansStyle(.bodyS)
                    .foregroundStyle(.ink(.secondary))
                    .lineLimit(2)
            }

            if !options.isEmpty {
                chipGroup(title: "Reviewed", chips: options, systemImage: "cup.and.saucer.fill")
            }

            if !tags.isEmpty {
                chipGroup(title: "Tags", chips: tags, systemImage: "tag.fill")
            }
        }
        .padding(RoadBeansSpacing.md)
        .surface(.sunken, radius: RoadBeansRadius.md)
        .transaction { transaction in
            transaction.animation = nil
        }
    }

    private func chipGroup(title: String, chips: [String], systemImage: String) -> some View {
        VStack(alignment: .leading, spacing: RoadBeansSpacing.xs) {
            Label(title, systemImage: systemImage)
                .roadBeansStyle(.caption)
                .foregroundStyle(.ink(.tertiary))

            FlowLayout(spacing: RoadBeansSpacing.xs, rowSpacing: RoadBeansSpacing.xs) {
                ForEach(chips, id: \.self) { chip in
                    Text(chip)
                        .roadBeansStyle(.caption)
                        .padding(.horizontal, RoadBeansSpacing.sm)
                        .padding(.vertical, 5)
                        .background(Color.surface(.raised), in: Capsule())
                        .foregroundStyle(.ink(.secondary))
                }
            }
        }
    }
}

private struct FlowLayout: Layout {
    var spacing: CGFloat
    var rowSpacing: CGFloat

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Void
    ) -> CGSize {
        layout(in: proposal.replacingUnspecifiedDimensions().width, subviews: subviews).size
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Void
    ) {
        let rows = layout(in: bounds.width, subviews: subviews)
        for item in rows.items {
            subviews[item.index].place(
                at: CGPoint(x: bounds.minX + item.origin.x, y: bounds.minY + item.origin.y),
                proposal: ProposedViewSize(item.size)
            )
        }
    }

    private func layout(in width: CGFloat, subviews: Subviews) -> (items: [PositionedItem], size: CGSize) {
        var items: [PositionedItem] = []
        var origin = CGPoint.zero
        var rowHeight: CGFloat = 0
        var maxWidth: CGFloat = 0
        let availableWidth = max(width, 1)

        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            if origin.x > 0, origin.x + size.width > availableWidth {
                origin.x = 0
                origin.y += rowHeight + rowSpacing
                rowHeight = 0
            }

            items.append(PositionedItem(index: index, origin: origin, size: size))
            origin.x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
            maxWidth = max(maxWidth, origin.x - spacing)
        }

        return (items, CGSize(width: min(maxWidth, availableWidth), height: origin.y + rowHeight))
    }

    private struct PositionedItem {
        let index: Int
        let origin: CGPoint
        let size: CGSize
    }
}
