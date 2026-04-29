import NaturalLanguage
import SwiftUI

#if canImport(FoundationModels)
import FoundationModels
#endif

struct AppleIntelligenceInfoView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var sparkleSpin = false
    @State private var showingResetConfirmation = false
    @State private var resetCompletedAt: Date?

    private let capabilities = AppleIntelligenceCapabilities.current
    private let onReset: (() async -> Void)?

    init(onReset: (() async -> Void)? = nil) {
        self.onReset = onReset
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: RoadBeansSpacing.lg) {
                    header

                    VStack(spacing: RoadBeansSpacing.md) {
                        capabilityRow(capabilities.foundationModels)
                        capabilityRow(capabilities.nlEmbedding)
                        capabilityRow(capabilities.nlTokenizer)
                        capabilityRow(capabilities.onDeviceOnly)
                    }

                    privacyCallout

                    if onReset != nil {
                        resetCard
                    }
                }
                .padding(RoadBeansSpacing.lg)
            }
            .confirmationDialog(
                "Reset Apple Intelligence?",
                isPresented: $showingResetConfirmation,
                titleVisibility: .visible
            ) {
                Button("Reset and Relearn", role: .destructive) {
                    Task {
                        await onReset?()
                        resetCompletedAt = Date()
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Road Beans Radar will turn off and discard the current taste profile. Your saved visits stay. Re-enable Radar to relearn from scratch.")
            }
            .background(Color.surface(.canvas).ignoresSafeArea())
            .navigationTitle("Apple Intelligence")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: RoadBeansSpacing.sm) {
            HStack(spacing: RoadBeansSpacing.sm) {
                Image(systemName: "sparkles")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(LinearGradient(
                        colors: [.accent(.default), .purple, .blue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .rotationEffect(.degrees(sparkleSpin ? 18 : -18))
                    .animation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true), value: sparkleSpin)

                VStack(alignment: .leading, spacing: 2) {
                    Text("How we use Apple Intelligence")
                        .roadBeansStyle(.titleL)
                    Text("Everything runs on your iPhone. No servers, no API keys, no third-party data sharing.")
                        .roadBeansStyle(.bodyS)
                        .foregroundStyle(.ink(.secondary))
                }
            }
            .onAppear { sparkleSpin = true }
        }
    }

    private func capabilityRow(_ capability: CapabilityCard) -> some View {
        RoadBeansCard(tint: capability.tint) {
            VStack(alignment: .leading, spacing: RoadBeansSpacing.sm) {
                HStack(alignment: .top, spacing: RoadBeansSpacing.md) {
                    ZStack {
                        RoundedRectangle(cornerRadius: RoadBeansRadius.md, style: .continuous)
                            .fill(capability.tint.opacity(0.18))
                        Image(systemName: capability.systemImage)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(capability.tint)
                    }
                    .frame(width: 44, height: 44)

                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text(capability.name)
                                .roadBeansStyle(.titleM)
                            statusBadge(capability.status)
                        }
                        Text(capability.frameworkName)
                            .roadBeansStyle(.caption)
                            .foregroundStyle(.ink(.secondary))
                    }
                    Spacer(minLength: 0)
                }

                Text(capability.summary)
                    .roadBeansStyle(.bodyS)
                    .foregroundStyle(.ink(.primary))

                Label(capability.usage, systemImage: "arrow.right.circle.fill")
                    .roadBeansStyle(.bodyS)
                    .foregroundStyle(.ink(.secondary))
                    .labelStyle(.titleAndIcon)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func statusBadge(_ status: CapabilityStatus) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(status.color)
                .frame(width: 7, height: 7)
            Text(status.label)
                .roadBeansStyle(.caption)
                .foregroundStyle(status.color)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(status.color.opacity(0.12), in: Capsule())
    }

    private var resetCard: some View {
        RoadBeansCard(tint: .orange) {
            VStack(alignment: .leading, spacing: RoadBeansSpacing.sm) {
                Label("Reset Apple Intelligence", systemImage: "arrow.counterclockwise")
                    .roadBeansStyle(.titleM)
                    .foregroundStyle(.orange)

                Text("Turn off Road Beans Radar and discard the current on-device taste profile. The model will relearn from your visits the next time you turn Radar back on. Your saved stops, drinks, and ratings are kept.")
                    .roadBeansStyle(.bodyS)
                    .foregroundStyle(.ink(.primary))

                if let resetCompletedAt {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(.green)
                        Text("Reset \(resetCompletedAt.formatted(date: .omitted, time: .shortened)). Re-enable Radar from the Stops screen.")
                            .roadBeansStyle(.caption)
                            .foregroundStyle(.ink(.secondary))
                    }
                } else {
                    Button(role: .destructive) {
                        showingResetConfirmation = true
                    } label: {
                        Label("Reset and Relearn", systemImage: "arrow.counterclockwise.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var privacyCallout: some View {
        RoadBeansCard(tint: .accent(.default)) {
            VStack(alignment: .leading, spacing: RoadBeansSpacing.sm) {
                Label("Stays on your device", systemImage: "lock.shield.fill")
                    .roadBeansStyle(.titleM)
                    .foregroundStyle(.accent(.default))

                Text("Road Beans Radar reads your saved visits, your tags, and your location. Apple Intelligence then ranks public Apple Maps places. None of this is sent to a server, uploaded to a third party, or used to train a remote model.")
                    .roadBeansStyle(.bodyS)
                    .foregroundStyle(.ink(.primary))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct CapabilityCard {
    let name: String
    let frameworkName: String
    let systemImage: String
    let summary: String
    let usage: String
    let status: CapabilityStatus
    let tint: Color
}

private enum CapabilityStatus: Equatable {
    case active
    case fallback(reason: String)
    case unavailable(reason: String)

    var label: String {
        switch self {
        case .active: "Active"
        case .fallback: "Fallback"
        case .unavailable: "Unavailable"
        }
    }

    var color: Color {
        switch self {
        case .active: .green
        case .fallback: .orange
        case .unavailable: .secondary
        }
    }
}

private struct AppleIntelligenceCapabilities {
    let foundationModels: CapabilityCard
    let nlEmbedding: CapabilityCard
    let nlTokenizer: CapabilityCard
    let onDeviceOnly: CapabilityCard

    static var current: AppleIntelligenceCapabilities {
        AppleIntelligenceCapabilities(
            foundationModels: CapabilityCard(
                name: "On-Device Language Model",
                frameworkName: "FoundationModels · Apple Intelligence",
                systemImage: "brain.head.profile.fill",
                summary: "An on-device LLM ranks nearby candidates against your taste profile. It picks the best matches and writes the short reasons you see on each card.",
                usage: "Used to rank, summarize, and explain picks.",
                status: foundationModelsStatus(),
                tint: .accent(.default)
            ),
            nlEmbedding: CapabilityCard(
                name: "Semantic Word Embeddings",
                frameworkName: "NaturalLanguage · NLEmbedding",
                systemImage: "point.3.connected.trianglepath.dotted",
                summary: "Apple's on-device word vectors connect related ideas. \"Espresso\" pulls in \"ristretto\". \"Patio\" pulls in \"outdoor\". You don't have to spell every preference.",
                usage: "Used to broaden tag and drink matching.",
                status: nlEmbeddingStatus(),
                tint: .blue
            ),
            nlTokenizer: CapabilityCard(
                name: "Linguistic Tokenizer",
                frameworkName: "NaturalLanguage · NLTokenizer",
                systemImage: "textformat.abc",
                summary: "Splits place names, addresses, and metadata into clean words so the matcher can compare meanings instead of raw strings.",
                usage: "Used before semantic matching.",
                status: .active,
                tint: .purple
            ),
            onDeviceOnly: CapabilityCard(
                name: "Local-Only Pipeline",
                frameworkName: "Privacy by design",
                systemImage: "lock.shield",
                summary: "Your taste profile, location, and visit history never leave the device. Apple Maps place lookups are public-place data only — they carry no personal context.",
                usage: "Used to keep your data yours.",
                status: .active,
                tint: .green
            )
        )
    }

    private static func foundationModelsStatus() -> CapabilityStatus {
        #if canImport(FoundationModels)
        switch SystemLanguageModel.default.availability {
        case .available:
            return .active
        case .unavailable(let reason):
            return .fallback(reason: "\(reason)")
        }
        #else
        return .unavailable(reason: "Apple Intelligence not available on this device.")
        #endif
    }

    private static func nlEmbeddingStatus() -> CapabilityStatus {
        NLEmbedding.wordEmbedding(for: .english) != nil
            ? .active
            : .fallback(reason: "English embedding not loaded.")
    }
}
