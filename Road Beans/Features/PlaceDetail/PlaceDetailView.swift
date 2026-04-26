import SwiftUI

struct PlaceDetailView: View {
    let placeID: UUID

    var body: some View {
        Text("Place Detail \(placeID.uuidString)")
            .navigationTitle("Place")
    }
}
