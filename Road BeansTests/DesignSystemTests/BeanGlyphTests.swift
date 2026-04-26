import Testing
@testable import Road_Beans

@Suite("BeanGlyph")
struct BeanGlyphTests {
    @Test func valueToCountMapping() {
        #expect(BeanGlyph.beanCount(for: 0.0) == 0)
        #expect(BeanGlyph.beanCount(for: 0.99) == 0)
        #expect(BeanGlyph.beanCount(for: 1.0) == 1)
        #expect(BeanGlyph.beanCount(for: 1.5) == 1)
        #expect(BeanGlyph.beanCount(for: 4.99) == 4)
        #expect(BeanGlyph.beanCount(for: 5.0) == 5)
        #expect(BeanGlyph.beanCount(for: -1.0) == 0)
        #expect(BeanGlyph.beanCount(for: 7.0) == 5)
    }
}
