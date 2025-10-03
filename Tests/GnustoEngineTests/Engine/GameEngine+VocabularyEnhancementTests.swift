import CustomDump
import GnustoEngine
import GnustoTestSupport
import Testing

@Suite("GameEngine Vocabulary Enhancement Tests")
struct GameEngineVocabularyEnhancementTests {

    @Test("GameEngine has VocabularyEnhancer integrated")
    func testGameEngineHasVocabularyEnhancerIntegrated() async throws {
        // Given: A game with an item
        let testItem = Item("item")
            .name("test item")
            .description("A simple test item.")
            .isTakable
            .in(.startRoom)

        let game = MinimalGame(items: testItem)
        let (engine, _) = await GameEngine.test(blueprint: game)

        // When: We access the vocabulary
        let vocabulary = await engine.vocabulary

        // Then: The vocabulary should have an enhancer configured
        #expect(vocabulary.enhancer != nil)
        #expect(vocabulary.enhancer?.configuration.isEnabled == true)

        // And the basic vocabulary building should work
        #expect(vocabulary.items["item"]?.contains("item") == true)
        #expect(vocabulary.items["test item"]?.contains("item") == true)  // full name

        // The "test" adjective should be extracted from the multi-word name
        #expect(vocabulary.adjectives["test"]?.contains("item") == true)
    }

    @Test("Enhanced vocabulary processes items during game initialization")
    func testEnhancedVocabularyProcessesItems() async throws {
        // Given: An item with adjectives that should be available for the enhancer
        let testSword = Item("sword")
            .name("rusty sword")
            .description("A rusty old sword with ancient runes.")
            .isTakable
            .in(.startRoom)

        let game = MinimalGame(
            items: testSword
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        // When: We check the built vocabulary
        let vocabulary = await engine.vocabulary

        // Then: The vocabulary should contain the basic extracted adjectives from the name
        #expect(vocabulary.adjectives["rusty"]?.contains("sword") == true)

        // And the enhancer should have been applied (even if it didn't find additional adjectives)
        #expect(vocabulary.enhancer != nil)

        // The vocabulary should contain the item by its name and noun
        #expect(vocabulary.items["sword"]?.contains("sword") == true)
        #expect(vocabulary.items["rusty sword"]?.contains("sword") == true)
    }

    @Test("Enhancement optimization skips items with sufficient existing terms")
    func testEnhancementOptimizationSkipsWellDefinedItems() async throws {
        // Given: One item with sufficient adjectives (2+) and one without
        let wellDefinedItem = Item("wellDefined")
            .name("crystal orb")
            .description("A magical crystal orb that glows with inner light.")
            .adjectives("magical", "glowing")  // 2 adjectives - should skip enhancement
            .isTakable
            .in(.startRoom)

        let underDefinedItem = Item("underDefined")
            .name("old book")
            .description("An ancient tome filled with mysterious text.")
            .adjectives("old")  // Only 1 adjective - should get enhanced
            .isTakable
            .in(.startRoom)

        let game = MinimalGame(
            items: wellDefinedItem, underDefinedItem
        )

        // When: We build the game (which runs the enhancement logic)
        let (engine, _) = await GameEngine.test(blueprint: game)

        // Then: Both items should be accessible, but enhancement behavior should differ
        let vocabulary = await engine.vocabulary

        // Well-defined item should have its original adjectives
        #expect(vocabulary.adjectives["magical"]?.contains("wellDefined") == true)
        #expect(vocabulary.adjectives["glowing"]?.contains("wellDefined") == true)

        // Under-defined item should have its original adjective plus multi-word name extraction
        #expect(vocabulary.adjectives["old"]?.contains("underDefined") == true)

        // Both items should be findable by their names
        #expect(vocabulary.items["crystal orb"]?.contains("wellDefined") == true)
        #expect(vocabulary.items["old book"]?.contains("underDefined") == true)
    }
}
