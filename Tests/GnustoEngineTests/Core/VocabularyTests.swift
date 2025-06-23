import Testing
@testable import GnustoEngine

@Suite("Vocabulary Tests")
struct VocabularyTests {

    @Test("Default verbSynonyms mapping is correct")
    func testDefaultVerbSynonyms() throws {
        // Arrange: Get the default vocabulary used by MinimalGame
        // Note: We access defaultVerbs directly as MinimalGame isn't customizable here.
        let defaultActionHandlers = Array(GameEngine.defaultActionHandlers.values)
        let allVerbs = GameEngine.extractVerbDefinitions(from: defaultActionHandlers)
        let defaultGameVocabulary = Vocabulary.build(verbs: allVerbs)
        let synonyms = defaultGameVocabulary.verbSynonyms

        // — Turn Off —
        #expect(synonyms["turn off"] == [.turnOff], "Primary 'turn off' should map to itself")
        #expect(synonyms["extinguish"] == [.turnOff], "'extinguish' should map to 'turn off'")
        #expect(synonyms["douse"] == [.turnOff], "'douse' should map to 'turn off'")
        #expect(synonyms["switch off"] == [.turnOff], "'switch off' should map to 'turn off'")
        #expect(synonyms["blow out"] == [.turnOff], "'blow out' should map to 'turn off'")

        // — Turn On —
        #expect(synonyms["turn on"] == [.turnOn], "Primary 'turn on' should map to itself")
        // "light" should map to multiple verbs since it's a synonym for both burn and turnOn
        let lightMappings = synonyms["light"]
        #expect(lightMappings != nil, "The word 'light' should have verb mappings")
        if let mappings = lightMappings {
            #expect(mappings.contains(.turnOn), "'light' should map to .turnOn verb")
            #expect(mappings.contains(.burn), "'light' should also map to .burn verb as a synonym")
        }
        #expect(synonyms["switch on"] == [.turnOn], "'switch on' should map to 'turn on'")

        // — Other samples —
        // "look" should map to multiple verbs since it's a synonym for lookInside and lookUnder
        let lookMappings = synonyms["look"]
        #expect(lookMappings != nil, "The word 'look' should have verb mappings")
        if let mappings = lookMappings {
            #expect(mappings.contains(.look), "'look' should map to .look verb")
            #expect(mappings.contains(.lookInside), "'look' should also map to .lookInside verb as a synonym")
            #expect(mappings.contains(.lookUnder), "'look' should also map to .lookUnder verb as a synonym")
        }
        #expect(synonyms["l"] == [.look], "'l' should map only to 'look'")
        #expect(synonyms["examine"] == [.examine], "Primary 'examine' should map to itself")
        #expect(synonyms["x"] == [.examine], "'x' should map to 'examine'")
        #expect(synonyms["inspect"] == [.examine], "'inspect' should map to 'examine'")

        // — Check non-existent mapping —
        #expect(synonyms["3733t"] == nil, "'3733t' should not exist in synonyms")
    }

    @Test("Climb verb synonym mapping handles conflicts correctly")
    func testClimbVerbSynonymConflict() throws {
        // This test demonstrates the bug where "climb" should map to both .climb and .climbOn
        // but currently only maps to .climb due to exact ID matching taking precedence

        // Build vocabulary the same way GameEngine does it
        let defaultActionHandlers = Array(GameEngine.defaultActionHandlers.values)
        let allVerbs = GameEngine.extractVerbDefinitions(from: defaultActionHandlers)
        let defaultGameVocabulary = Vocabulary.build(verbs: allVerbs)
        let synonyms = defaultGameVocabulary.verbSynonyms

        // Debug: Print all climb-related mappings
        print("=== Debug: All verb synonyms that contain 'climb' ===")
        for (word, verbSet) in synonyms where word.contains("climb") {
            print("'\(word)' -> \(verbSet)")
        }

        print("=== Debug: Looking for specific mappings ===")
        print("'climb' mapping: \(synonyms["climb"] ?? Set())")
        print("'climbOn' mapping: \(synonyms["climbon"] ?? Set())")
        print("'climb on' mapping: \(synonyms["climb on"] ?? Set())")
        print("'sit' mapping: \(synonyms["sit"] ?? Set())")
        print("'mount' mapping: \(synonyms["mount"] ?? Set())")

        // "climb" should map to both .climb (exact ID match) AND .climbOn (synonym)
        // Currently this fails because exact ID matching excludes synonyms
        let climbMappings = synonyms["climb"]
        #expect(climbMappings != nil, "The word 'climb' should have verb mappings")
        if let mappings = climbMappings {
            #expect(mappings.contains(.climb), "'climb' should map to .climb verb")
            #expect(mappings.contains(.climbOn), "'climb' should also map to .climbOn verb as a synonym")
        }

        // For verification, check that "sit" (synonym for climbOn) works correctly
        // since it doesn't conflict with an exact ID match
        let sitMappings = synonyms["sit"]
        #expect(sitMappings == [.climbOn], "'sit' should map only to .climbOn")
    }

    // TODO: Add tests for item/adjective mapping if needed
}
