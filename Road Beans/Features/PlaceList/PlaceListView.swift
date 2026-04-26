import SwiftUI

struct PlaceListView: View {
    var body: some View {
        NavigationStack {
            Text("List")
                .navigationTitle("Stops")
        }
    }
}

#Preview {
    PlaceListView()
}
