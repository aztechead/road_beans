import CoreLocation
import MapKit
import SwiftUI

struct RecommendationDeckView: View {
    @Bindable var viewModel: RecommendationDeckViewModel
    @State private var showingAppleIntelligenceInfo = false
    @State private var isBrewingTasteProfile = false
    @AppStorage("recommendationsCollapsed") private var isCollapsed = true

    var body: some View {
        Group {
            switch viewModel.availability {
            case .optedOut:
                optInCard
            case .learning(let progress):
                learningCard(progress: progress)
            case .locationUnavailable:
                statusCard(
                    title: "Location is off",
                    message: "Nearby picks need your location to look within 5 miles.",
                    systemImage: "location.slash"
                )
            case .unavailable(let message):
                statusCard(title: "Radar is quiet", message: message, systemImage: "antenna.radiowaves.left.and.right.slash")
            case .ready:
                if viewModel.isLoading && viewModel.recommendations.isEmpty {
                    statusCard(title: "Scanning nearby stops", message: "Checking Apple Maps places against your Road Beans history.", systemImage: "dot.radiowaves.left.and.right")
                } else if !viewModel.recommendations.isEmpty {
                    deck
                } else {
                    statusCard(title: "Radar is quiet", message: "No nearby coffee or road stops matched your taste profile.", systemImage: "antenna.radiowaves.left.and.right.slash")
                }
            }
        }
        .sheet(isPresented: $showingAppleIntelligenceInfo) {
            AppleIntelligenceInfoView(onReset: { await viewModel.reset() })
        }
    }

    private var optInCard: some View {
        RoadBeansCard(tint: .accent(.default)) {
            VStack(alignment: .leading, spacing: RoadBeansSpacing.md) {
                HStack {
                    Label("Road Beans Radar", systemImage: "sparkles")
                        .roadBeansStyle(.label)
                        .foregroundStyle(.accent(.default))
                    Spacer()
                    appleIntelligenceInfoButton
                }

                Text("Find coffee and stops your way.")
                    .roadBeansStyle(.titleL)

                Text("Your saved visits stay on this device. Road Beans uses Apple Maps to find nearby public places, then ranks them on-device when Apple Intelligence is available.")
                    .roadBeansStyle(.bodyS)
                    .foregroundStyle(.ink(.secondary))

                optInDataGuide

                BrewTasteProfileButton(isBrewing: isBrewingTasteProfile || viewModel.isEnabling) {
                    isBrewingTasteProfile = true
                    Task {
                        await viewModel.enable()
                        try? await Task.sleep(for: .milliseconds(750))
                        isBrewingTasteProfile = false
                    }
                }

                if !viewModel.optInProgress.isComplete {
                    Text("\(viewModel.optInProgress.ratedVisits) of \(viewModel.optInProgress.required) ratings logged. Tap to review what Radar still needs.")
                        .roadBeansStyle(.caption)
                        .foregroundStyle(.ink(.secondary))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var optInDataGuide: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Good data in, good picks out", systemImage: "lightbulb.fill")
                .roadBeansStyle(.label)
                .foregroundStyle(.accent(.default))

            optInTip(
                icon: "star.fill",
                title: "Rate a few stops",
                detail: "Three honest ratings unlock picks. High ratings teach the model what to seek, and low ratings teach it what to skip."
            )

            optInTip(
                icon: "tag.fill",
                title: "Tag what stood out",
                detail: "Tags like \"patio\", \"oat milk\", or \"fast Wi-Fi\" become the words the matcher looks for in nearby places."
            )

            optInTip(
                icon: "cup.and.saucer.fill",
                title: "Log the drink",
                detail: "Naming what you ordered helps the model connect drinks to ratings and weigh signals like \"espresso\" or \"cold brew\"."
            )
        }
        .padding(RoadBeansSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.accent(.default).opacity(0.08), in: RoundedRectangle(cornerRadius: RoadBeansRadius.md, style: .continuous))
    }

    private func optInTip(icon: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: RoadBeansSpacing.sm) {
            Image(systemName: icon)
                .font(.footnote.weight(.bold))
                .foregroundStyle(.accent(.default))
                .frame(width: 18, alignment: .center)
                .padding(.top, 2)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .roadBeansStyle(.label)
                    .foregroundStyle(.ink(.primary))
                Text(detail)
                    .roadBeansStyle(.caption)
                    .foregroundStyle(.ink(.secondary))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var appleIntelligenceInfoButton: some View {
        Button {
            showingAppleIntelligenceInfo = true
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "sparkles")
                Text("How AI is used")
                Image(systemName: "info.circle.fill")
            }
            .font(.footnote.weight(.semibold))
            .foregroundStyle(.accent(.default))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.accent(.default).opacity(0.14), in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("How Apple Intelligence is used")
    }

    private var deck: some View {
        VStack(alignment: .leading, spacing: RoadBeansSpacing.sm) {
            Button {
                withAnimation(.easeInOut(duration: 0.22)) { isCollapsed.toggle() }
            } label: {
                HStack {
                    Image(systemName: "sparkles")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.accent(.default))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Road Beans Radar")
                            .roadBeansStyle(.titleM)
                        Text(isCollapsed
                             ? "\(viewModel.recommendations.count) pick\(viewModel.recommendations.count == 1 ? "" : "s") within 5 miles"
                             : "Apple-native picks within 5 miles")
                            .roadBeansStyle(.bodyS)
                            .foregroundStyle(.ink(.secondary))
                    }
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.footnote.weight(.bold))
                        .foregroundStyle(.ink(.secondary))
                        .rotationEffect(.degrees(isCollapsed ? 0 : 180))
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isCollapsed ? "Expand Road Beans Radar" : "Collapse Road Beans Radar")

            if !isCollapsed {
                HStack(spacing: RoadBeansSpacing.sm) {
                    appleIntelligenceInfoButton
                    Spacer()
                    if viewModel.isLoading {
                        ProgressView()
                    } else {
                        Button {
                            Task { await viewModel.reload() }
                        } label: {
                            Image(systemName: "arrow.clockwise")
                        }
                        .buttonStyle(.bordered)
                        .accessibilityLabel("Refresh nearby picks")
                    }
                }

                if let message = viewModel.rankingStatusMessage {
                    Label(message, systemImage: "exclamationmark.triangle.fill")
                        .roadBeansStyle(.caption)
                        .foregroundStyle(.orange)
                        .fixedSize(horizontal: false, vertical: true)
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: RoadBeansSpacing.md) {
                        ForEach(viewModel.recommendations) { recommendation in
                            RecommendationCard(
                                recommendation: recommendation,
                                onSave: { try await viewModel.saveRecommendationAsPlace(recommendation) },
                                onDismiss: {
                                viewModel.dismiss(recommendation)
                            })
                        }
                    }
                    .padding(.bottom, 6)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func statusCard(title: String, message: String, systemImage: String) -> some View {
        RoadBeansCard {
            VStack(alignment: .leading, spacing: RoadBeansSpacing.sm) {
                HStack(alignment: .center, spacing: RoadBeansSpacing.sm) {
                    Image(systemName: systemImage)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.accent(.default))
                        .frame(width: 28)
                    Text(title)
                        .roadBeansStyle(.titleM)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: RoadBeansSpacing.sm)
                    compactInfoButton
                }
                Text(message)
                    .roadBeansStyle(.bodyS)
                    .foregroundStyle(.ink(.secondary))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func learningCard(progress: LearningProgress) -> some View {
        RoadBeansCard(tint: .accent(.default)) {
            VStack(alignment: .leading, spacing: RoadBeansSpacing.md) {
                HStack(alignment: .center, spacing: RoadBeansSpacing.sm) {
                    Image(systemName: "sparkles")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.accent(.default))
                        .frame(width: 28)
                    Text("Road Beans Radar is learning")
                        .roadBeansStyle(.titleM)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: RoadBeansSpacing.sm)
                    compactInfoButton
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .firstTextBaseline) {
                        Text("\(progress.ratedVisits) of \(progress.required) rated visits")
                            .roadBeansStyle(.titleM)
                            .foregroundStyle(.ink(.primary))
                        Spacer()
                        Text("\(Int(progress.fraction * 100))%")
                            .roadBeansStyle(.caption)
                            .foregroundStyle(.ink(.secondary))
                            .monospacedDigit()
                    }

                    ProgressView(value: progress.fraction)
                        .progressViewStyle(.linear)
                        .tint(.accent(.default))

                    learningSteps(progress: progress)
                }

                Text(progress.remaining == 0
                     ? "Ready. Pull to refresh to see picks."
                     : "Rate \(progress.remaining) more visit\(progress.remaining == 1 ? "" : "s") so on-device matching has enough taste signal. High ratings shape what to seek. Low ratings shape what to skip — at that place, not everywhere.")
                    .roadBeansStyle(.bodyS)
                    .foregroundStyle(.ink(.secondary))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func learningSteps(progress: LearningProgress) -> some View {
        HStack(spacing: 6) {
            ForEach(0..<progress.required, id: \.self) { index in
                Capsule()
                    .fill(index < progress.ratedVisits ? Color.accent(.default) : Color.surface(.sunken))
                    .frame(height: 6)
                    .overlay(
                        Capsule()
                            .stroke(Color.accent(.default).opacity(0.35), lineWidth: index < progress.ratedVisits ? 0 : 1)
                    )
            }
        }
    }

    private var compactInfoButton: some View {
        Button {
            showingAppleIntelligenceInfo = true
        } label: {
            Image(systemName: "sparkles")
                .font(.footnote.weight(.bold))
                .foregroundStyle(.accent(.default))
                .padding(8)
                .background(Color.accent(.default).opacity(0.14), in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("How Apple Intelligence is used")
    }
}

private struct BrewTasteProfileButton: View {
    let isBrewing: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Capsule()
                    .fill(buttonFill)
                    .overlay {
                        Capsule()
                            .stroke(Color.accent(.on).opacity(isBrewing ? 0.45 : 0), lineWidth: 1)
                    }

                if isBrewing {
                    RadarBrewAnimation()
                        .clipShape(Capsule())
                        .transition(.opacity)
                }

                HStack(spacing: RoadBeansSpacing.sm) {
                    ZStack {
                        Image(systemName: "location.magnifyingglass")
                            .opacity(isBrewing ? 0 : 1)

                        if isBrewing {
                            BeanMark(state: .full, size: 18)
                                .foregroundStyle(Color.accent(.on))
                                .rotationEffect(.degrees(-16))
                        }
                    }
                    .frame(width: 24, height: 24)

                    Text(isBrewing ? "Brewing Taste Profile" : "Brew your Taste Profile")
                        .roadBeansStyle(.label)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)

                    if isBrewing {
                        Image(systemName: "sparkles")
                            .font(.footnote.weight(.bold))
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .foregroundStyle(Color.accent(.on))
                .frame(maxWidth: .infinity)
                .padding(.horizontal, RoadBeansSpacing.lg)
            }
            .frame(minHeight: 48)
            .contentShape(Capsule())
            .animation(.easeInOut(duration: 0.22), value: isBrewing)
        }
        .buttonStyle(BrewButtonStyle())
        .disabled(isBrewing)
        .accessibilityLabel(isBrewing ? "Brewing taste profile" : "Brew your Taste Profile")
    }

    private var buttonFill: some ShapeStyle {
        LinearGradient(
            colors: [
                Color.accent(.pressed),
                Color.accent(.default),
                Color.state(.success).opacity(0.9)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

private struct BrewButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(RoadBeansMotion.snap, value: configuration.isPressed)
    }
}

private struct RadarBrewAnimation: View {
    var body: some View {
        TimelineView(.animation) { timeline in
            let phase = timeline.date.timeIntervalSinceReferenceDate

            ZStack {
                ForEach(0..<3, id: \.self) { index in
                    let progress = (phase * 0.9 + Double(index) / 3).truncatingRemainder(dividingBy: 1)
                    Capsule()
                        .stroke(Color.accent(.on).opacity(0.26 * (1 - progress)), lineWidth: 1.4)
                        .scaleEffect(x: 0.12 + progress * 1.5, y: 0.42 + progress * 0.9)
                }

                ForEach(0..<5, id: \.self) { index in
                    BeanMark(state: .full, size: 8 + CGFloat(index % 2) * 2)
                        .opacity(0.2 + 0.35 * abs(sin(phase * 2 + Double(index))))
                        .rotationEffect(.degrees(Double(index) * 34 + phase * 28))
                        .offset(
                            x: CGFloat(cos(phase * 1.4 + Double(index))) * CGFloat(32 + index * 18),
                            y: CGFloat(sin(phase * 1.9 + Double(index))) * 9
                        )
                }
            }
        }
        .allowsHitTesting(false)
    }
}

private struct RecommendationCard: View {
    let recommendation: PlaceRecommendation
    var onSave: () async throws -> UUID
    var onDismiss: () -> Void
    @State private var savedPlaceID: UUID?
    @State private var isSaving = false

    private static let cardWidth: CGFloat = 330
    private static let cardHeight: CGFloat = 360

    var body: some View {
        VStack(alignment: .leading, spacing: RoadBeansSpacing.md) {
            HStack(alignment: .top) {
                ZStack {
                    RoundedRectangle(cornerRadius: RoadBeansRadius.md, style: .continuous)
                        .fill(recommendation.kind.accentColor.opacity(0.15))
                    Icon(.place(recommendation.kind), size: 24)
                }
                .frame(width: 44, height: 44)

                VStack(alignment: .leading, spacing: 3) {
                    Text(recommendation.placeName)
                        .roadBeansStyle(.titleM)
                        .lineLimit(2)
                    Text(subtitle)
                        .roadBeansStyle(.bodyS)
                        .foregroundStyle(.ink(.secondary))
                        .lineLimit(1)
                }

                Spacer(minLength: 8)

                VStack(alignment: .trailing, spacing: 2) {
                    Text(recommendation.confidence.displayName)
                        .roadBeansStyle(.label)
                        .foregroundStyle(recommendation.kind.accentColor)
                        .multilineTextAlignment(.trailing)
                    Text("\(recommendation.score)% fit")
                        .roadBeansStyle(.caption)
                        .foregroundStyle(.ink(.secondary))
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Label("Why it fits", systemImage: "checkmark.seal.fill")
                    .roadBeansStyle(.caption)
                    .foregroundStyle(recommendation.kind.accentColor)

                ForEach(recommendation.reasons.prefix(2), id: \.self) { reason in
                    Text(reason)
                        .roadBeansStyle(.bodyS)
                        .foregroundStyle(.ink(.primary))
                        .lineLimit(2)
                        .truncationMode(.tail)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if !recommendation.matchedSignals.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(recommendation.matchedSignals.prefix(4), id: \.self) { signal in
                            RoadBeansChip(title: signal)
                        }
                    }
                }
                .frame(height: 28)
            }

            if let caution = recommendation.cautions.first {
                Text(caution)
                    .roadBeansStyle(.caption)
                    .foregroundStyle(.ink(.secondary))
                    .lineLimit(1)
                    .truncationMode(.tail)
            }

            Spacer(minLength: 0)

            HStack(spacing: RoadBeansSpacing.sm) {
                if let placeID = savedPlaceID ?? recommendation.placeID {
                    NavigationLink(value: placeID) {
                        Label("View", systemImage: "chevron.right.circle.fill")
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(recommendation.kind.accentColor)
                } else if recommendation.source == .mapKit || recommendation.source == .external {
                    Button {
                        Task {
                            isSaving = true
                            defer { isSaving = false }
                            savedPlaceID = try? await onSave()
                        }
                    } label: {
                        Label(isSaving ? "Saving" : "Save", systemImage: isSaving ? "hourglass" : "plus.circle.fill")
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(recommendation.kind.accentColor)
                    .disabled(isSaving)
                }

                Button {
                    openInMaps()
                } label: {
                    Image(systemName: "map.fill")
                        .frame(width: 24, height: 24)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(recommendation.coordinate == nil)
                .accessibilityLabel("Open in Maps")
                .accessibilityHint("Opens Apple Maps for navigation")

                Button {
                    onDismiss()
                } label: {
                    Image(systemName: "xmark")
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.bordered)
                .accessibilityLabel("Dismiss recommendation")
            }
        }
        .padding(RoadBeansSpacing.lg)
        .frame(width: Self.cardWidth, height: Self.cardHeight, alignment: .topLeading)
        .background(cardBackground, in: RoundedRectangle(cornerRadius: RoadBeansRadius.sheet, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: RoadBeansRadius.sheet, style: .continuous)
                .stroke(recommendation.kind.accentColor.opacity(0.28), lineWidth: 1)
        }
    }

    private var subtitle: String {
        let distance = recommendation.distanceMeters.map { distanceString($0) }
        return [distance, recommendation.kind.displayName].compactMap { $0 }.joined(separator: " • ")
    }

    private var cardBackground: some ShapeStyle {
        LinearGradient(
            colors: [
                recommendation.kind.accentColor.opacity(0.18),
                Color.surface(.raised).opacity(0.95),
                Color.surface(.canvas).opacity(0.9)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private func distanceString(_ meters: Double) -> String {
        RecommendationRanking.formattedDistance(meters)
    }

    private func openInMaps() {
        guard let coordinate = recommendation.coordinate else { return }
        let item = MKMapItem(
            location: CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude),
            address: nil
        )
        item.name = recommendation.placeName
        item.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
    }
}
