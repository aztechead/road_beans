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
        let viewModel = PlaceDetailViewModel(placeRepo: repository)

        await viewModel.load(id: id)

        #expect(viewModel.detail?.name == "Loves")
    }

    @Test func missingDetailSetsDetailNil() async {
        let repository = FakePlaceRepository()
        let viewModel = PlaceDetailViewModel(placeRepo: repository)

        await viewModel.load(id: UUID())

        #expect(viewModel.detail == nil)
    }
}
