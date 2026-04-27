import SwiftUI

struct OnboardingView: View {
    let complete: () -> Void

    @State private var selectedCard = 0

    private let cards = OnboardingCard.all

    var body: some View {
        VStack(spacing: RoadBeansSpacing.xl) {
            Spacer(minLength: 24)

            TabView(selection: $selectedCard) {
                ForEach(cards.indices, id: \.self) { index in
                    OnboardingCardView(card: cards[index])
                        .tag(index)
                        .padding(.horizontal)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))

            VStack(spacing: 12) {
                Button(primaryButtonTitle) {
                    if selectedCard < cards.count - 1 {
                        selectedCard += 1
                    } else {
                        complete()
                    }
                }
                .buttonStyle(.plain)
                .roadBeansStyle(.labelL)
                .frame(minHeight: 44)
                .frame(maxWidth: .infinity)
                .background(Color.accent(.default), in: Capsule())
                .foregroundStyle(.accent(.on))

                Button("Skip for now") {
                    complete()
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            }
            .padding(.bottom, 32)
        }
        .background(Color.surface(.canvas).ignoresSafeArea())
    }

    private var primaryButtonTitle: String {
        selectedCard == cards.count - 1 ? "Start logging" : "Continue"
    }
}

private struct OnboardingCard: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let systemImage: String

    static let all = [
        OnboardingCard(
            title: "Remember the good stops",
            message: "Log coffee, food, gas, truck stops, and notes while the trip is still fresh.",
            systemImage: "cup.and.saucer.fill"
        ),
        OnboardingCard(
            title: "Use location when you ask",
            message: "Road Beans only requests location when you turn on near-me or search nearby stops.",
            systemImage: "location.fill"
        ),
        OnboardingCard(
            title: "Synced with iCloud",
            message: "Road Beans uses your private iCloud account to keep your places, visits, drinks, and photos available across devices.",
            systemImage: "icloud.fill"
        )
    ]
}

private struct OnboardingCardView: View {
    let card: OnboardingCard

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: card.systemImage)
                .font(.system(size: 56, weight: .semibold))
                .foregroundStyle(Color.accent(.default))

            Text(card.title)
                .roadBeansStyle(.displayL)
                .multilineTextAlignment(.center)

            Text(card.message)
                .roadBeansStyle(.bodyM)
                .foregroundStyle(.ink(.secondary))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(RoadBeansSpacing.xl)
        .surface(.raised, radius: RoadBeansRadius.sheet)
        .padding(.vertical, 48)
    }
}

#Preview {
    OnboardingView {}
}
