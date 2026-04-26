import Testing
@testable import Road_Beans

@Suite("TagTokenField helpers")
struct TagTokenSuggestionTests {
    @Test func addNormalizesAndDedups() {
        var tags = ["smooth"]

        TagTokenLogic.add("  Smooth ", to: &tags)
        TagTokenLogic.add("BURNT", to: &tags)

        #expect(tags == ["smooth", "burnt"])
    }

    @Test func addRejectsEmpty() {
        var tags: [String] = []

        TagTokenLogic.add("   ", to: &tags)

        #expect(tags.isEmpty)
    }
}
