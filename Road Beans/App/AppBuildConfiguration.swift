import Foundation

enum AppBuildConfiguration {
    static let forcesLocalPersistence: Bool = {
        #if ROAD_BEANS_LOCAL_DEVICE
        true
        #else
        false
        #endif
    }()
}
