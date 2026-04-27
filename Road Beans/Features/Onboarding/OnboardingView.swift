import SwiftUI

struct OnboardingView: View {
    let complete: () -> Void

    @State private var selectedCard = 0

    private let cards = OnboardingCard.all

    var body: some View {
        VStack(spacing: 24) {
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
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Button("Skip for now") {
                    complete()
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            }
            .padding(.bottom, 32)
        }
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.98, green: 0.90, blue: 0.76),
                    Color(red: 0.33, green: 0.18, blue: 0.09)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
    }

    private var primaryButtonTitle: String {
        selectedCard == cards.count - 1 ? "Start Logging" : "Continue"
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
                .foregroundStyle(Color(red: 0.31, green: 0.16, blue: 0.07))

            Text(card.title)
                .font(.largeTitle.weight(.bold))
                .multilineTextAlignment(.center)

            Text(card.message)
                .font(.roadBeansBody)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(28)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 32, style: .continuous))
        .padding(.vertical, 48)
    }
}

#Preview {
    OnboardingView {}
}
