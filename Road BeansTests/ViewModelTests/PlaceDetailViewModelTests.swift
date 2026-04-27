import Foundation
import Testing
@testable import Road_Beans

@Suite("PlaceDetailViewModel")
@MainActor
struct PlaceDetailViewModelTests {
    @Test func loadAssignsDetail() async {
        let repository = FakePlaceRepository()
        let id = UUID()
        repository.details[id] = PlaceDetail(
            id: id,
            name: "Loves",
            kind: .truckStop,
            source: .mapKit,
            address: nil,
            streetNumber: nil,
            streetName: nil,
            city: nil,
            region: nil,
            postalCode: nil,
            country: nil,
            phoneNumber: nil,
            websiteURL: nil,
            coordinate: nil,
            averageRating: 4.0,
            visits: []
        )
        let viewModel = PlaceDetailViewModel(placeRepo: repository, visitRepo: FakeVisitRepository())

        await viewModel.load(id: id)

        #expect(viewModel.state == .loaded)
        #expect(viewModel.detail?.name == "Loves")
    }

    @Test func missingDetailSetsDetailNil() async {
        let repository = FakePlaceRepository()
        let viewModel = PlaceDetailViewModel(placeRepo: repository, visitRepo: FakeVisitRepository())

        await viewModel.load(id: UUID())

        #expect(viewModel.state == .empty)
        #expect(viewModel.detail == nil)
    }

    @Test func repositoryFailureSetsFailedState() async {
        let repository = FakePlaceRepository()
        repository.detailError = FakeViewModelError.failed
        let viewModel = PlaceDetailViewModel(placeRepo: repository, visitRepo: FakeVisitRepository())

        await viewModel.load(id: UUID())

        #expect(viewModel.state.errorMessage != nil)
        #expect(viewModel.detail == nil)
    }

    @Test func updatePassesCommandAndReloads() async throws {
        let repository = FakePlaceRepository()
        let id = UUID()
        repository.details[id] = PlaceDetail(
            id: id,
            name: "Old",
            kind: .truckStop,
            source: .custom,
            address: nil,
            streetNumber: nil,
            streetName: nil,
            city: nil,
            region: nil,
            postalCode: nil,
            country: nil,
            phoneNumber: nil,
            websiteURL: nil,
            coordinate: nil,
            averageRating: nil,
            visits: []
        )
        let viewModel = PlaceDetailViewModel(placeRepo: repository, visitRepo: FakeVisitRepository())
        let command = UpdatePlaceCommand(id: id, name: "New", kind: .coffeeShop, address: "Main")

        try await viewModel.update(command)

        #expect(repository.updates == [command])
        #expect(viewModel.state == .loaded)
    }

    @Test func deleteVisitPassesCommandAndReloads() async throws {
        let repository = FakePlaceRepository()
        let visits = FakeVisitRepository()
        let placeID = UUID()
        let visitID = UUID()
        repository.details[placeID] = PlaceDetail(
            id: placeID,
            name: "Loves",
            kind: .truckStop,
            source: .mapKit,
            address: nil,
            streetNumber: nil,
            streetName: nil,
            city: nil,
            region: nil,
            postalCode: nil,
            country: nil,
            phoneNumber: nil,
            websiteURL: nil,
            coordinate: nil,
            averageRating: nil,
            visits: []
        )
        let viewModel = PlaceDetailViewModel(placeRepo: repository, visitRepo: visits)

        try await viewModel.deleteVisit(id: visitID, placeID: placeID)

        #expect(visits.deletedIDs == [visitID])
        #expect(viewModel.state == .loaded)
    }
}
