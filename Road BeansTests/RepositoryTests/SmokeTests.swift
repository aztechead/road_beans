import Testing

@Suite("Smoke")
struct SmokeTests {
    @Test func testTargetIsWiredUp() {
        #expect(1 + 1 == 2)
    }
}
