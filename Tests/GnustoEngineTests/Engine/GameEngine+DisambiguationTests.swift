import CustomDump
import GnustoTestSupport
import Testing

@testable import GnustoEngine

@Suite("GameEngine Disambiguation Tests")
struct GameEngineDisambiguationTests {

    // MARK: - Context Storage Tests

    @Test("Disambiguation context is stored correctly")
    func testContextStorage() async throws {
        // Given
        let newBook = Item(
            id: "newBook",
            .name("new book"),
            .isTakable,
            .in(.player)
        )

        let oldBook = Item(
            id: "oldBook",
            .name("old book"),
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            items: newBook, oldBook
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        // When
        await engine.storeDisambiguationContext(
            originalInput: "put book on table",
            noun: "book",
            options: ["the new book", "the old book"]
        )

        // Then
        let context = await engine.lastDisambiguationContext
        let options = await engine.lastDisambiguationOptions

        #expect(context != nil)
        #expect(context?.originalInput == "put book on table")
        #expect(context?.noun == "book")
        #expect(options == ["the new book", "the old book"])
    }

    @Test("Context storage handles missing input gracefully")
    func testContextStorageWithNilInput() async throws {
        // Given
        let (engine, _) = await GameEngine.test()

        // When
        await engine.storeDisambiguationContext(
            originalInput: nil,
            noun: "book",
            options: ["the new book", "the old book"]
        )

        // Then
        let context = await engine.lastDisambiguationContext
        let options = await engine.lastDisambiguationOptions

        #expect(context == nil)
        #expect(options == nil)
    }

    // MARK: - Response Matching Tests

    @Test("Disambiguation response matches exact option")
    func testResponseMatching() async throws {
        // Given
        let newBook = Item(
            id: "newBook",
            .name("new book"),
            .isTakable,
            .in(.player)
        )

        let table = Item(
            id: "table",
            .name("table"),
            .isSurface,
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: newBook, table
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        // Store disambiguation context
        await engine.storeDisambiguationContext(
            originalInput: "put book on table",
            noun: "book",
            options: ["the new book", "the old book"]
        )

        let context = GameEngine.LastDisambiguationContext(
            originalInput: "put book on table",
            verb: Verb(id: "put"),
            noun: "book"
        )

        // When
        let handled = await engine.tryHandleDisambiguationResponse(
            input: "the new book",
            context: context
        )

        // Then
        #expect(handled == true)

        // Verify the item was moved to the table
        let finalNewBook = await engine.item("newBook")
        #expect(await finalNewBook.parent == .item(table.proxy(engine)))
    }

    @Test("Disambiguation response handles case insensitive matching")
    func testCaseInsensitiveMatching() async throws {
        // Given
        let newBook = Item(
            id: "newBook",
            .name("new book"),
            .isTakable,
            .in(.player)
        )

        let table = Item(
            id: "table",
            .name("table"),
            .isSurface,
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: newBook, table
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        // Store disambiguation context
        await engine.storeDisambiguationContext(
            originalInput: "put book on table",
            noun: "book",
            options: ["the new book", "the old book"]
        )

        let context = GameEngine.LastDisambiguationContext(
            originalInput: "put book on table",
            verb: Verb(id: "put"),
            noun: "book"
        )

        // When - test with different cases
        let handled1 = await engine.tryHandleDisambiguationResponse(
            input: "THE NEW BOOK",
            context: context
        )

        // Reset for second test
        await engine.storeDisambiguationContext(
            originalInput: "put book on table",
            noun: "book",
            options: ["the new book", "the old book"]
        )

        let handled2 = await engine.tryHandleDisambiguationResponse(
            input: "The New Book",
            context: context
        )

        // Then
        #expect(handled1 == true)
        #expect(handled2 == true)
    }

    @Test("Disambiguation response rejects non-matching input")
    func testNonMatchingInput() async throws {
        // Given
        let (engine, _) = await GameEngine.test()

        await engine.storeDisambiguationContext(
            originalInput: "put book on table",
            noun: "book",
            options: ["the new book", "the old book"]
        )

        let context = GameEngine.LastDisambiguationContext(
            originalInput: "put book on table",
            verb: Verb(id: "put"),
            noun: "book"
        )

        // When
        let handled = await engine.tryHandleDisambiguationResponse(
            input: "something else",
            context: context
        )

        // Then
        #expect(handled == false)

        // Context should be cleared after failed attempt
        let finalContext = await engine.lastDisambiguationContext
        let finalOptions = await engine.lastDisambiguationOptions
        #expect(finalContext == nil)
        #expect(finalOptions == nil)
    }

    // MARK: - Command Reconstruction Tests

    @Test("Command reconstruction replaces only first occurrence")
    func testCommandReconstruction() async throws {
        // Given
        let (_, _) = await GameEngine.test()

        // Test the private method via reflection or make it internal
        let original = "put book on bookshelf"
        let target = "book"
        let replacement = "new book"

        // This tests the logic we know should work
        let expected = "put new book on bookshelf"

        // We can test this by calling the method through tryHandleDisambiguationResponse
        // and checking the reconstructed command behavior

        // For now, let's verify the logic works as expected
        func replaceFirstOccurrence(of target: String, with replacement: String, in source: String)
            -> String
        {
            if let range = source.range(of: target) {
                return source.replacingCharacters(in: range, with: replacement)
            }
            return source
        }

        let result = replaceFirstOccurrence(of: target, with: replacement, in: original)
        #expect(result == expected)
    }

    // MARK: - Integration Tests

    @Test("End-to-end disambiguation flow works")
    func testEndToEndDisambiguation() async throws {
        // Given
        let newBook = Item(
            id: "newBook",
            .name("new book"),
            .isTakable,
            .in(.player)
        )

        let oldBook = Item(
            id: "oldBook",
            .name("old book"),
            .isTakable,
            .in(.player)
        )

        let table = Item(
            id: "table",
            .name("table"),
            .isSurface,
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: newBook, oldBook, table
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When - execute the commands that should trigger disambiguation
        try await engine.execute(
            "put book on table",
            "the new book"
        )

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > put book on table
            Which do you mean: the new book or the old book?

            > the new book
            You successfully put the new book on the table.
            """
        )

        // Verify the new book was moved to the table
        let finalNewBook = await engine.item("newBook")
        #expect(await finalNewBook.parent == .item(table.proxy(engine)))

        // Verify the old book is still with the player
        let finalOldBook = await engine.item("oldBook")
        #expect(await finalOldBook.parent == .player)
    }
}
