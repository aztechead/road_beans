import SwiftUI

struct VisitDetailView: View {
    let visitID: UUID

    var body: some View {
        Text("Visit \(visitID.uuidString)")
            .navigationTitle("Visit")
    }
}
