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

        #expect(viewModel.state == .loaded)
        #expect(viewModel.detail?.id == id)
    }

    @Test func missingVisitSetsEmptyState() async {
        let visits = FakeVisitRepository()
        let viewModel = VisitDetailViewModel(visits: visits, visitID: UUID())

        await viewModel.load()

        #expect(viewModel.state == .empty)
        #expect(viewModel.detail == nil)
    }

    @Test func repositoryFailureSetsFailedState() async {
        let visits = FakeVisitRepository()
        visits.detailError = FakeViewModelError.failed
        let viewModel = VisitDetailViewModel(visits: visits, visitID: UUID())

        await viewModel.load()

        #expect(viewModel.state.errorMessage != nil)
        #expect(viewModel.detail == nil)
    }

    @Test func deleteCallsRepository() async throws {
        let visits = FakeVisitRepository()
        let id = UUID()
        let viewModel = VisitDetailViewModel(visits: visits, visitID: id)

        try await viewModel.delete()

        #expect(visits.deletedIDs == [id])
    }
}
