import Testing
import CustomDump
@testable import GnustoEngine

@Suite("ChompActionHandler Tests")
struct ChompActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("CHOMP syntax works")
    func testChompSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let apple = Item(
            id: "apple",
            .name("red apple"),
            .description("A juicy red apple."),
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
        try await engine.execute("chomp apple")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > chomp apple
            You take a bite of the red apple. Delicious!
            """)
    }

    @Test("BITE syntax works")
    func testBiteSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let cheese = Item(
            id: "cheese",
            .name("wedge of cheese"),
            .description("A tasty wedge of cheese."),
            .isEdible,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: cheese
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("bite cheese")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > bite cheese
            You take a bite of the wedge of cheese. Delicious!
            """)
    }

    @Test("CHEW syntax with object works")
    func testChewWithObjectSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let jerky = Item(
            id: "jerky",
            .name("piece of jerky"),
            .description("Some tough, dried meat."),
            .isEdible,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: jerky
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("chew jerky")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > chew jerky
            You take a bite of the piece of jerky. Delicious!
            """)
    }

    // MARK: - Validation Testing

    @Test("Cannot chomp item not in scope")
    func testCannotChompItemNotInScope() async throws {
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
            .in(.location("anotherRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom, anotherRoom,
            items: remoteApple
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("chomp apple")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > chomp apple
            You can't see any such thing.
            """)
    }

    @Test("Requires light to chomp items")
    func testRequiresLight() async throws {
        // Given
        let darkRoom = Location(
            id: "darkRoom",
            .name("Dark Room"),
            .description("A pitch black room.")
        )

        let apple = Item(
            id: "apple",
            .name("red apple"),
            .in(.location("darkRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom,
            items: apple
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("chomp apple")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > chomp apple
            It is pitch black. You can't see a thing.
            """)
    }

    // MARK: - Processing Testing

    @Test("Chomp without an object gives a random message")
    func testChompWithoutObject() async throws {
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
        try await engine.execute("chew") // "chew" is a synonym that can be used alone

        // Then
        let output = await mockIO.flush().trimmingCharacters(in: .whitespacesAndNewlines)
        let possibleOutputs = [
            "> chew\nChomp, chomp, chomp.",
            "> chew\nYour jaws ache from the effort.",
            "> chew\nThere's nothing to chew on.",
        ].map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

        #expect(
            possibleOutputs.contains(output),
            "Output was not one of the expected random responses: \n\(output)"
        )
    }

    @Test("Chomp an edible item")
    func testChompEdibleItem() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let bread = Item(
            id: "bread",
            .name("loaf of bread"),
            .description("A crusty loaf of bread."),
            .isEdible,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: bread
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("chomp bread")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > chomp bread
            You take a bite of a loaf of bread. Delicious!
            """)
        let finalState = try await engine.item("bread")
        #expect(finalState.hasFlag(.isTouched) == true)
    }

    @Test("Chomp a character")
    func testChompCharacter() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let wizard = Item(
            id: "wizard",
            .name("grumpy wizard"),
            .description("A grumpy-looking wizard."),
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
        try await engine.execute("chomp wizard")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > chomp wizard
            I don't think the grumpy wizard would appreciate that.
            """)
        let finalState = try await engine.item("wizard")
        #expect(finalState.hasFlag(.isTouched) == true)
    }

    @Test("Chomp a generic item")
    func testChompGenericItem() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let rock = Item(
            id: "rock",
            .name("hard rock"),
            .description("A very hard rock."),
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: rock
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("chomp rock")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > chomp rock
            Your teeth would not appreciate that.
            """)
        let finalState = try await engine.item("rock")
        #expect(finalState.hasFlag(.isTouched) == true)
    }

    // MARK: - ActionID Testing

    @Test("Handler exposes correct ActionIDs")
    func testActionIDs() async throws {
        let handler = ChompActionHandler()
        #expect(handler.actions.isEmpty)
    }

    @Test("Handler exposes correct VerbIDs")
    func testVerbIDs() async throws {
        let handler = ChompActionHandler()
        #expect(handler.verbs.contains(.chomp))
        #expect(handler.verbs.contains(.bite))
        #expect(handler.verbs.contains(.chew))
        #expect(handler.verbs.count == 3)
    }

    @Test("Handler requires light")
    func testRequiresLightProperty() async throws {
        let handler = ChompActionHandler()
        #expect(handler.requiresLight == true)
    }
}
