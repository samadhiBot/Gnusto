import Testing
import CustomDump
@testable import GnustoEngine

@Suite("TurnOnActionHandler Tests")
struct TurnOnActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("TURN ON syntax works")
    func testTurnOnSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .description("A room for testing."),
            .inherentlyLit
        )

        let lamp = Item(
            id: "lamp",
            .name("brass lamp"),
            .description("A brass oil lamp."),
            .isLightSource,
            .isDevice,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: lamp
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("turn on lamp")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > turn on lamp
            The brass lamp is now on.
            """)

        let finalState = try await engine.item("lamp")
        #expect(finalState.hasFlag(.isOn) == true)
    }

    @Test("LIGHT syntax works")
    func testLightSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let lantern = Item(
            id: "lantern",
            .name("glass lantern"),
            .description("A glass lantern."),
            .isLightSource,
            .isDevice,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: lantern
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("light lantern")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > light lantern
            The glass lantern is now on.
            """)

        let finalState = try await engine.item("lantern")
        #expect(finalState.hasFlag(.isOn) == true)
    }

    // MARK: - Validation Testing

    @Test("Cannot turn on non-light source")
    func testCannotTurnOnNonLightSource() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let book = Item(
            id: "book",
            .name("leather book"),
            .description("A worn leather-bound book."),
            .in(.location("testRoom"))
            // Note: No .isLightSource property
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: book
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("turn on book")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > turn on book
            You can’t turn that on.
            """)
    }

    @Test("Cannot turn on already lit item")
    func testCannotTurnOnAlreadyLitItem() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let torch = Item(
            id: "torch",
            .name("wooden torch"),
            .description("A wooden torch."),
            .isLightSource,
            .isDevice,
            .isLit,
            .isOn,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: torch
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("turn on torch")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > turn on torch
            It’s already on.
            """)
    }

    @Test("Cannot turn on item not in scope")
    func testCannotTurnOnItemNotInScope() async throws {
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

        let remoteLamp = Item(
            id: "remoteLamp",
            .name("remote lamp"),
            .description("A lamp in another room."),
            .isLightSource,
            .isDevice,
            .in(.location("anotherRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom, anotherRoom,
            items: remoteLamp
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("turn on lamp")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > turn on lamp
            You can’t see any such thing.
            """)
    }

    @Test("Requires light to turn on items")
    func testRequiresLight() async throws {
        // Given: Dark room with an unlit lamp
        let darkRoom = Location(
            id: "darkRoom",
            .name("Dark Room"),
            .description("A room that is pitch black if you aren't carrying a light.")
            // Note: No .inherentlyLit property
        )

        let lamp = Item(
            id: "lamp",
            .name("brass lamp"),
            .description("A brass oil lamp."),
            .isLightSource,
            .isDevice,
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom,
            items: lamp
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("turn on lamp")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > turn on lamp
            The brass lamp is now on. You can see your surroundings now.

            — Dark Room —

            A room that is pitch black if you aren’t carrying a light.
            """)
    }

    // MARK: - Processing Testing

    @Test("Successful turn on sets lit flag")
    func testSuccessfulTurnOnSetsLitFlag() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let candle = Item(
            id: "candle",
            .name("white candle"),
            .description("A white wax candle."),
            .isLightSource,
            .isDevice,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: candle
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("turn on candle")

        // Then: Verify state change
        let finalState = try await engine.item("candle")
        #expect(finalState.hasFlag(.isOn) == true)

        // Verify message
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > turn on candle
            The white candle is now on.
            """)
    }

    // MARK: - ActionID Testing

    @Test("Handler exposes correct ActionIDs")
    func testActionIDs() async throws {
        let handler = TurnOnActionHandler()
        #expect(handler.actions.contains(.lightSource))
        #expect(handler.actions.contains(.burn))
    }

    @Test("Handler exposes correct VerbIDs")
    func testVerbIDs() async throws {
        let handler = TurnOnActionHandler()
        // Note: TurnOnActionHandler is syntax-based and should have empty verbs
        #expect(handler.verbs.isEmpty)
    }

    @Test("Handler requires light")
    func testRequiresLightProperty() async throws {
        let handler = TurnOnActionHandler()
        #expect(handler.requiresLight == true)
    }
}
