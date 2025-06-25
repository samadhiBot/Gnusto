import Testing
import CustomDump
@testable import GnustoEngine

@Suite("BurnActionHandler Tests")
struct BurnActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("BURN syntax works")
    func testBurnSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let paper = Item(
            id: "paper",
            .name("piece of paper"),
            .description("A flammable piece of paper."),
            .isFlammable,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: paper
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("burn paper")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > burn paper
            The piece of paper catches fire and is quickly consumed.
            """)

        let finalState = await engine.gameState.items[paper.id]
        #expect(finalState?.parent == .nowhere)
    }

    @Test("IGNITE syntax works")
    func testIgniteSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let kindling = Item(
            id: "kindling",
            .name("pile of kindling"),
            .description("Some dry kindling."),
            .isFlammable,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: kindling
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("ignite kindling")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > ignite kindling
            The pile of kindling catches fire and is quickly consumed.
            """)

        let finalState = await engine.gameState.items[kindling.id]
        #expect(finalState?.parent == .nowhere)
    }

    @Test("LIGHT syntax works for flammable item")
    func testLightSyntaxForFlammable() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let newspaper = Item(
            id: "newspaper",
            .name("old newspaper"),
            .description("An old, yellowed newspaper."),
            .isFlammable,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: newspaper
        )

        // This test assumes BurnActionHandler is checked before TurnOnActionHandler
        // when an item is flammable but not a device.
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("light newspaper")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > light newspaper
            The old newspaper catches fire and is quickly consumed.
            """)

        let finalState = await engine.gameState.items[newspaper.id]
        #expect(finalState?.parent == .nowhere)
    }


    // MARK: - Validation Testing

    @Test("Cannot burn without specifying target")
    func testCannotBurnWithoutTarget() async throws {
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
        try await engine.execute("burn")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > burn
            What do you want to burn?
            """)
    }

    @Test("Cannot burn item not in scope")
    func testCannotBurnItemNotInScope() async throws {
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

        let remotePaper = Item(
            id: "remotePaper",
            .name("remote paper"),
            .description("Some paper in another room."),
            .isFlammable,
            .in(.location("anotherRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom, anotherRoom,
            items: remotePaper
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("burn paper")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > burn paper
            You can't see any such thing.
            """)
    }

    @Test("Requires light to burn items")
    func testRequiresLight() async throws {
        // Given
        let darkRoom = Location(
            id: "darkRoom",
            .name("Dark Room"),
            .description("A pitch black room.")
        )

        let paper = Item(
            id: "paper",
            .name("piece of paper"),
            .isFlammable,
            .in(.location("darkRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom,
            items: paper
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("burn paper")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > burn paper
            It is pitch black. You can't see a thing.
            """)
    }

    // MARK: - Processing Testing

    @Test("Cannot burn a non-flammable item")
    func testCannotBurnNonFlammableItem() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let rock = Item(
            id: "rock",
            .name("heavy rock"),
            .description("A heavy, non-flammable rock."),
            // Note: No .isFlammable property
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: rock
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("burn rock")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > burn rock
            You can't burn the heavy rock.
            """)

        let finalState = await engine.gameState.items[rock.id]
        #expect(finalState?.parent == .location("testRoom"))
        #expect(finalState?.hasFlag(.isTouched) == true)
    }

    // MARK: - ActionID Testing

    @Test("Handler exposes correct ActionIDs")
    func testActionIDs() async throws {
        let handler = BurnActionHandler()
        #expect(handler.actions.isEmpty)
    }

    @Test("Handler exposes correct VerbIDs")
    func testVerbIDs() async throws {
        let handler = BurnActionHandler()
        #expect(handler.verbs.contains(.burn))
        #expect(handler.verbs.contains(.ignite))
        #expect(handler.verbs.contains(.light))
        #expect(handler.verbs.count == 3)
    }

    @Test("Handler requires light")
    func testRequiresLightProperty() async throws {
        let handler = BurnActionHandler()
        #expect(handler.requiresLight == true)
    }
}
