import Foundation
import Observation
import SwiftData

@Observable
@MainActor
final class PersistenceController {
    private(set) var mode: PersistenceMode
    let container: ModelContainer

    private var cloudKitIdentityToken: AnyHashable?

    init(
        icloud: iCloudAvailabilityServiceProtocol,
        useInMemoryStores: Bool = false
    ) {
        let initialICloudToken = icloud.currentToken()
        cloudKitIdentityToken = initialICloudToken
        let resolvedMode: PersistenceMode = initialICloudToken == nil ? .iCloudUnavailable : .cloudKitBacked
        mode = resolvedMode

        do {
            container = try Self.makeContainer(inMemory: useInMemoryStores)
        } catch {
            fatalError("ModelContainer init failed: \(error)")
        }

        Task { [weak self] in
            for await _ in icloud.identityChanges {
                let latestToken = icloud.currentToken()
                await MainActor.run {
                    guard let self else { return }
                    guard latestToken != self.cloudKitIdentityToken else { return }
                    self.cloudKitIdentityToken = latestToken
                    if latestToken == nil {
                        self.mode = .iCloudUnavailable
                    } else if self.mode == .iCloudUnavailable {
                        self.mode = .cloudKitBacked
                    } else {
                        self.mode = .pendingRelaunch
                    }
                }
            }
        }
    }

    private static func makeContainer(inMemory: Bool) throws -> ModelContainer {
        if inMemory {
            return try ModelContainer(
                for: AppSchema.all,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
        }

        let configuration = ModelConfiguration(
            "CloudKitStore",
            schema: AppSchema.all,
            cloudKitDatabase: .private("iCloud.brainmeld.Road-Beans")
        )
        return try ModelContainer(for: AppSchema.all, configurations: [configuration])
    }
}
