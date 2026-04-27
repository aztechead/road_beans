import Foundation

actor CommunityMemberCache {
    private var member: CommunityMemberSnapshot?
    private var didAttemptPreload = false

    func preload(using service: any CommunityService) async {
        guard !didAttemptPreload else { return }
        didAttemptPreload = true
        await refresh(using: service)
    }

    func refresh(using service: any CommunityService) async {
        member = try? await service.currentMember()
    }

    func snapshot() -> CommunityMemberSnapshot? {
        member
    }

    func store(_ member: CommunityMemberSnapshot?) {
        self.member = member
        didAttemptPreload = true
    }
}
