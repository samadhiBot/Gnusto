import CustomDump
import Foundation
import GnustoTestSupport
import Testing

@testable import GnustoEngine

@Suite("Vocabulary Tests")
struct VocabularyTests {

    // MARK: - Architecture Tests

    @Test("Vocabulary is accessible from GameEngine")
    func testVocabularyAccessibleFromEngine() async throws {
        // Given: A game with items and locations
        let item = Item(
            id: "lamp",
            .name("brass lamp"),
            .isTakable,
            .in(.startRoom)
        )

        let location = Location(
            id: .startRoom,
            .name("Test Room"),
            .inherentlyLit
        )

        let game = MinimalGame(
            locations: location,
            items: item
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        // When: We access vocabulary from engine
        let vocabulary = await engine.vocabulary

        // Then: Vocabulary should be properly populated
        #expect(vocabulary.items["lamp"]?.contains("lamp") == true)
        #expect(vocabulary.items["brass lamp"]?.contains("lamp") == true)
        #expect(vocabulary.adjectives["brass"]?.contains("lamp") == true)
        #expect(!vocabulary.verbs.isEmpty)
    }

    @Test("GameState no longer contains vocabulary")
    func testGameStateWithoutVocabulary() async throws {
        // Given: A game engine
        let (engine, _) = await GameEngine.test()

        // When: We access the game state
        let gameState = await engine.gameState

        // Then: GameState should not have vocabulary property
        // This test verifies the architectural change at compile time
        let mirror = Mirror(reflecting: gameState)
        let vocabularyProperty = mirror.children.first { $0.label == "vocabulary" }
        #expect(vocabularyProperty == nil)
    }

    @Test("Save files no longer contain vocabulary data")
    func testSaveFilesWithoutVocabulary() async throws {
        // Given: A game with complex vocabulary
        let complexItem = Item(
            id: "ornateGoldenChalice",
            .name("ornate golden chalice"),
            .description("A beautifully crafted golden chalice with intricate engravings."),
            .adjectives("ornate", "golden", "beautiful", "crafted", "intricate"),
            .synonyms("cup", "goblet", "vessel"),
            .isTakable,
            .in(.startRoom)
        )

        let location = Location(
            id: .startRoom,
            .name("Grand Hall"),
            .description("A magnificent hall with soaring ceilings."),
            .inherentlyLit
        )

        let game = MinimalGame(
            locations: location,
            items: complexItem
        )

        let testHandler = TestFilesystemHandler()
        let (engine, _) = await GameEngine.test(
            blueprint: game,
            filesystemHandler: testHandler
        )

        // When: We save the game
        let saveURL = try await engine.saveGame(saveName: "vocabulary_test")

        // Then: The save file should exist and be reasonably small
        #expect(FileManager.default.fileExists(atPath: saveURL.path))

        let saveData = try Data(contentsOf: saveURL)
        let saveDataString = String(data: saveData, encoding: .utf8) ?? ""

        // Verify that vocabulary-specific data is NOT in the save file
        #expect(!saveDataString.contains("\"adverbs\""))
        #expect(!saveDataString.contains("\"locationNames\""))
        #expect(!saveDataString.contains("\"noiseWords\""))
        #expect(!saveDataString.contains("\"universals\""))
        #expect(!saveDataString.contains("\"verbToSyntax\""))
        #expect(!saveDataString.contains("\"verbs\""))
        #expect(!saveDataString.contains("\"vocabulary\""))

        // But regular game state should still be there
        #expect(saveDataString.contains("\"items\""))
        #expect(saveDataString.contains("\"locations\""))
        #expect(saveDataString.contains("\"player\""))
    }

    @Test("Parser integration works with refactored vocabulary")
    func testParserIntegrationWithRefactoredVocabulary() async throws {
        // Given: A game with items that have vocabulary words
        let lamp = Item(
            id: "lamp",
            .name("brass lamp"),
            .isTakable,
            .in(.startRoom)
        )

        let room = Location(
            id: .startRoom,
            .name("Test Room"),
            .inherentlyLit
        )

        let game = MinimalGame(
            locations: room,
            items: lamp
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: We execute commands that use the vocabulary
        try await engine.execute("take brass lamp")
        try await engine.execute("examine lamp")

        // Then: Commands should work correctly
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > take brass lamp
            Taken.

            > examine lamp
            The brass lamp stubbornly remains ordinary despite your
            thorough examination.
            """
        )
    }

    @Test("Vocabulary contains enhanced adjectives after refactor")
    func testVocabularyEnhancementStillWorks() async throws {
        // Given: An item with a multi-word name that should generate adjectives
        let item = Item(
            id: "silverRing",
            .name("ancient silver ring"),
            .isTakable,
            .in(.startRoom)
        )

        let room = Location(
            id: .startRoom,
            .name("Test Room"),
            .inherentlyLit
        )

        let game = MinimalGame(
            locations: room,
            items: item
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        // When: We check the vocabulary
        let vocabulary = await engine.vocabulary

        // Then: Auto-extracted adjectives should be present
        #expect(vocabulary.adjectives["ancient"]?.contains("silverRing") == true)
        #expect(vocabulary.adjectives["silver"]?.contains("silverRing") == true)

        // And the item should be findable by various names
        #expect(vocabulary.items["ring"]?.contains("silverRing") == true)
        #expect(vocabulary.items["ancient silver ring"]?.contains("silverRing") == true)
    }
}
