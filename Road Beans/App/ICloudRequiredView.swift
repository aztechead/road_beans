import SwiftUI

struct ICloudRequiredView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "icloud.slash")
                .font(.largeTitle)

            Text("iCloud Required")
                .font(.roadBeansHeadline)

            Text("Sign in to iCloud and relaunch Road Beans to keep your places, visits, drinks, and photos synced.")
                .font(.roadBeansBody)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .roadBeansScreenBackground()
    }
}

#Preview {
    ICloudRequiredView()
}
