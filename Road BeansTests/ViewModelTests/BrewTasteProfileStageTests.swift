import Testing
@testable import Road_Beans

@Suite("Brew taste profile stages")
struct BrewTasteProfileStageTests {
    @Test func stageAdvancesThroughBrewSequence() {
        #expect(BrewTasteProfileStage.current(at: 0).title == "Reading visits")
        #expect(BrewTasteProfileStage.current(at: 1.8).title == "Weighing ratings")
        #expect(BrewTasteProfileStage.current(at: 3.4).title == "Dialing in Radar")
    }

    @Test func progressWrapsAcrossFullCycle() {
        #expect(BrewTasteProfileStage.progress(at: 0) == 0)
        #expect(BrewTasteProfileStage.progress(at: BrewTasteProfileStage.cycleDuration) == 0)
        #expect(BrewTasteProfileStage.progress(at: BrewTasteProfileStage.cycleDuration / 2) == 0.5)
    }
}
