import SwiftUI

struct ICloudRequiredView: View {
    var body: some View {
        VStack(spacing: RoadBeansSpacing.lg) {
            Image(systemName: "icloud.slash")
                .font(.largeTitle)

            Text("iCloud Required")
                .roadBeansStyle(.titleL)

            Text("Sign in to iCloud and relaunch Road Beans to keep your places, visits, drinks, and photos synced.")
                .roadBeansStyle(.bodyM)
                .foregroundStyle(.ink(.secondary))
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color.surface(.canvas).ignoresSafeArea())
    }
}

#Preview {
    ICloudRequiredView()
}
