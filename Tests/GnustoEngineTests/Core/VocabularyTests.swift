import Testing
@testable import GnustoEngine

@Suite("Vocabulary Tests")
struct VocabularyTests {
    
    @Test("Default verbSynonyms mapping is correct")
    func testDefaultVerbSynonyms() throws {
        // Arrange: Get the default vocabulary used by MinimalGame
        // Note: We access defaultVerbs directly as MinimalGame isn’t customizable here.
        let defaultGameVocabulary = Vocabulary.build()
        let synonyms = defaultGameVocabulary.verbSynonyms
        
        // — Turn Off —
        #expect(synonyms["turn off"] == [.turnOff], "Primary 'turn off' should map to itself")
        #expect(synonyms["extinguish"] == [.turnOff], "'extinguish' should map to 'turn off'")
        #expect(synonyms["douse"] == [.turnOff], "'douse' should map to 'turn off'")
        #expect(synonyms["switch off"] == [.turnOff], "'switch off' should map to 'turn off'")
        #expect(synonyms["blow out"] == [.turnOff], "'blow out' should map to 'turn off'")
        
        // — Turn On —
        #expect(synonyms["turn on"] == [.turnOn], "Primary 'turn on' should map to itself")
        #expect(synonyms["light"] == [.turnOn], "'light' should map to 'turn on'")
        #expect(synonyms["switch on"] == [.turnOn], "'switch on' should map to 'turn on'")
        
        // — Other samples —
        #expect(synonyms["look"] == [.look], "Primary 'look' should map to itself")
        #expect(synonyms["l"] == [.look], "'l' should map to 'look'")
        #expect(synonyms["examine"] == [.examine], "Primary 'examine' should map to itself")
        #expect(synonyms["x"] == [.examine], "'x' should map to 'examine'")
        #expect(synonyms["inspect"] == [.examine], "'inspect' should map to 'examine'")
        
        // — Check non-existent mapping —
        #expect(synonyms["xyzzy"] == nil, "'xyzzy' should not exist in synonyms")
    }
    
    // TODO: Add tests for item/adjective mapping if needed
}
