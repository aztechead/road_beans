import Foundation
import Testing
@testable import Road_Beans

@Suite("VisitDetailViewModel")
@MainActor
struct VisitDetailViewModelTests {
    @Test func loadAssignsDetail() async {
        let visits = FakeVisitRepository()
        let id = UUID()
        visits.details[id] = VisitDetail(
            id: id,
            date: .now,
            placeID: UUID(),
            placeName: "Loves",
            placeKind: .truckStop,
            drinks: [],
            tagNames: [],
            photos: []
        )
        let viewModel = VisitDetailViewModel(visits: visits, visitID: id)

        await viewModel.load()

        #expect(viewModel.detail?.id == id)
    }

    @Test func deleteCallsRepository() async throws {
        let visits = FakeVisitRepository()
        let id = UUID()
        let viewModel = VisitDetailViewModel(visits: visits, visitID: id)

        try await viewModel.delete()

        #expect(visits.deletedIDs == [id])
    }
}
