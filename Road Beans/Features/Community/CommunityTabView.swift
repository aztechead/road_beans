import SwiftUI

struct CommunityTabView: View {
    @Environment(\.communityService) private var community
    @Environment(\.communityMemberCache) private var communityMemberCache
    @Environment(\.favoriteMemberRepository) private var favorites
    @Environment(\.visitRepository) private var visits
    @State private var feedViewModel: CommunityFeedViewModel?
    @State private var isShowingOnboarding = false
    @State private var isShowingSettings = false

    var body: some View {
        NavigationStack {
            Group {
                if let feedViewModel {
                    CommunityFeedView(viewModel: feedViewModel) {
                        isShowingOnboarding = true
                    }
                } else {
                    RoadBeansLoadingState(title: "Loading community...")
                }
            }
            .navigationTitle("Community")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        if let currentMember = feedViewModel?.currentMember {
                            Task { await communityMemberCache.store(currentMember) }
                        }
                        isShowingSettings = true
                    } label: {
                        Label("Settings", systemImage: "gearshape")
                    }
                }
            }
            .background(Color.surface(.canvas).ignoresSafeArea())
        }
        .background(Color.surface(.canvas).ignoresSafeArea())
        .task {
            if feedViewModel == nil {
                feedViewModel = CommunityFeedViewModel(
                    service: community,
                    favorites: favorites,
                    memberCache: communityMemberCache
                )
            }
        }
        .sheet(isPresented: $isShowingOnboarding) {
            CommunityOnboardingView(
                viewModel: CommunityOnboardingViewModel(
                    service: community,
                    existingVisits: existingCommunityVisitDrafts
                )
            ) {
                Task { await feedViewModel?.refresh() }
            }
        }
        .sheet(isPresented: $isShowingSettings) {
            CommunitySettingsView(
                viewModel: CommunitySettingsViewModel(
                    service: community,
                    memberCache: communityMemberCache,
                    initialMember: feedViewModel?.currentMember
                )
            ) {
                Task { await feedViewModel?.refresh() }
            }
        }
    }

    private func existingCommunityVisitDrafts() async -> [CommunityVisitDraft] {
        do {
            let recent = try await visits.recentRows(limit: 500)
            var drafts: [CommunityVisitDraft] = []
            for row in recent {
                if let draft = try await visits.communityDraft(for: row.visit.id) {
                    drafts.append(draft)
                }
            }
            return drafts
        } catch {
            return []
        }
    }
}
