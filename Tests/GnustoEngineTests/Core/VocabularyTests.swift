import Testing
@testable import GnustoEngine

@Suite("Vocabulary Tests")
struct VocabularyTests {

    @Test("Default verbSynonyms mapping is correct")
        func testDefaultVerbSynonyms() throws {
        // Arrange: Get the default vocabulary used by MinimalGame
        // Note: We access defaultVerbs directly as MinimalGame isn't customizable here.
        let defaultGameVocabulary = Vocabulary.build(items: [], useDefaultVerbs: true)
        let synonyms = defaultGameVocabulary.verbSynonyms

        // Assert: Check specific canonical IDs and their synonyms
        let turnOffID = VerbID("turn off")
        let turnOnID = VerbID("turn on")
        let lookID = VerbID("look")
        let examineID = VerbID("examine")

        // --- Turn Off ---
        #expect(synonyms["turn off"] == [turnOffID], "Primary 'turn off' should map to itself")
        #expect(synonyms["extinguish"] == [turnOffID], "'extinguish' should map to 'turn off'")
        #expect(synonyms["douse"] == [turnOffID], "'douse' should map to 'turn off'")
        #expect(synonyms["switch off"] == [turnOffID], "'switch off' should map to 'turn off'")
        #expect(synonyms["blow out"] == [turnOffID], "'blow out' should map to 'turn off'")

        // --- Turn On ---
        #expect(synonyms["turn on"] == [turnOnID], "Primary 'turn on' should map to itself")
        #expect(synonyms["light"] == [turnOnID], "'light' should map to 'turn on'")
        #expect(synonyms["switch on"] == [turnOnID], "'switch on' should map to 'turn on'")

        // --- Other samples ---
        #expect(synonyms["look"] == [lookID], "Primary 'look' should map to itself")
        #expect(synonyms["l"] == [lookID], "'l' should map to 'look'")
        #expect(synonyms["examine"] == [examineID], "Primary 'examine' should map to itself")
        #expect(synonyms["x"] == [examineID], "'x' should map to 'examine'")
        #expect(synonyms["inspect"] == [examineID], "'inspect' should map to 'examine'")

        // --- Check non-existent mapping ---
        #expect(synonyms["xyzzy"] == nil, "'xyzzy' should not exist in synonyms")
    }

    // TODO: Add tests for item/adjective mapping if needed
}
