import Foundation
import Testing
@testable import Road_Beans

@Suite("CloudKitCommunityService")
struct CloudKitCommunityServiceTests {
    @Test func doubleValueAcceptsNSNumberAndDouble() {
        #expect(CloudKitCommunityService.doubleValue(NSNumber(value: 35.4364)) == 35.4364)
        #expect(CloudKitCommunityService.doubleValue(35.4364 as Double) == 35.4364)
        #expect(CloudKitCommunityService.doubleValue(nil) == nil)
    }
}
