import Testing
import CustomDump
@testable import GnustoEngine

@Suite("EatActionHandler Tests")
struct EatActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("EAT syntax works")
    func testEatSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let apple = Item(
            id: "apple",
            .name("juicy apple"),
            .description("A delicious-looking juicy apple."),
            .isEdible,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: apple
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("eat apple")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > eat apple
            You eat the juicy apple. Delicious!
            """)

        let finalState = await engine.gameState.items[apple.id]
        #expect(finalState == nil) // The apple should be consumed
    }

    // MARK: - Validation Testing

    @Test("Cannot eat without specifying target")
    func testCannotEatWithoutTarget() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("eat")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > eat
            What do you want to eat?
            """)
    }

    @Test("Cannot eat item not in scope")
    func testCannotEatItemNotInScope() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let anotherRoom = Location(
            id: "anotherRoom",
            .name("Another Room"),
            .inherentlyLit
        )

        let remoteApple = Item(
            id: "remoteApple",
            .name("remote apple"),
            .isEdible,
            .in(.location("anotherRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom, anotherRoom,
            items: remoteApple
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("eat apple")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > eat apple
            You can't see any such thing.
            """)
    }

    @Test("Requires light to eat items")
    func testRequiresLight() async throws {
        // Given
        let darkRoom = Location(
            id: "darkRoom",
            .name("Dark Room")
        )

        let apple = Item(
            id: "apple",
            .name("juicy apple"),
            .isEdible,
            .in(.location("darkRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom,
            items: apple
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("eat apple")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > eat apple
            It is pitch black. You can't see a thing.
            """)
    }

    // MARK: - Processing Testing

    @Test("Cannot eat a non-edible item")
    func testCannotEatNonEdibleItem() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let rock = Item(
            id: "rock",
            .name("heavy rock"),
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: rock
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("eat rock")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > eat rock
            You can't eat that.
            """)
    }

    @Test("Cannot eat a character")
    func testCannotEatCharacter() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let wizard = Item(
            id: "wizard",
            .name("grumpy wizard"),
            .isCharacter,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: wizard
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("eat wizard")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > eat wizard
            I don't think the grumpy wizard would appreciate that.
            """)
    }

    // MARK: - ActionID Testing

    @Test("Handler exposes correct VerbIDs")
    func testVerbIDs() async throws {
        let handler = EatActionHandler()
        #expect(handler.verbs.contains(.eat))
        #expect(handler.verbs.count == 1)
    }

    @Test("Handler requires light")
    func testRequiresLightProperty() async throws {
        let handler = EatActionHandler()
        #expect(handler.requiresLight == true)
    }
}
