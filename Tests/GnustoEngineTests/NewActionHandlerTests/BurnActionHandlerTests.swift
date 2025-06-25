import Testing
import CustomDump
@testable import GnustoEngine

@Suite("BurnActionHandler Tests")
struct BurnActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("BURN DIRECTOBJECT syntax works")
    func testBurnDirectObjectSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .description("A room for testing."),
            .inherentlyLit
        )

        let paper = Item(
            id: "paper",
            .name("piece of paper"),
            .description("A piece of paper."),
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
            The piece of paper catches fire and is consumed!
            """)

        let finalState = try? await engine.item("paper")
        #expect(finalState == nil) // Item should be destroyed
    }

    @Test("BURN DIRECTOBJECT WITH INDIRECTOBJECT syntax works")
    func testBurnWithSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let paper = Item(
            id: "paper",
            .name("piece of paper"),
            .description("A piece of paper."),
            .isFlammable,
            .in(.location("testRoom"))
        )

        let match = Item(
            id: "match",
            .name("wooden match"),
            .description("A wooden match."),
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: paper, match
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("burn paper with match")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > burn paper with match
            The piece of paper catches fire and is consumed!
            """)
    }

    @Test("IGNITE syntax works")
    func testIgniteSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let wood = Item(
            id: "wood",
            .name("dry wood"),
            .description("Some dry wood."),
            .isFlammable,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: wood
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("ignite wood")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > ignite wood
            The dry wood catches fire and is consumed!
            """)
    }

    @Test("LIGHT syntax works")
    func testLightSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let tinder = Item(
            id: "tinder",
            .name("dry tinder"),
            .description("Some dry tinder."),
            .isFlammable,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: tinder
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("light tinder")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > light tinder
            The dry tinder catches fire and is consumed!
            """)
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
            Burn what?
            """)
    }

    @Test("Cannot burn target not in scope")
    func testCannotBurnTargetNotInScope() async throws {
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
            .description("Paper in another room."),
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

    @Test("Requires light to burn")
    func testRequiresLight() async throws {
        // Given: Dark room with flammable item
        let darkRoom = Location(
            id: "darkRoom",
            .name("Dark Room"),
            .description("A pitch black room.")
        )

        let paper = Item(
            id: "paper",
            .name("piece of paper"),
            .description("A piece of paper."),
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

    @Test("Burn flammable item destroys it")
    func testBurnFlammableItemDestroysIt() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let paper = Item(
            id: "paper",
            .name("piece of paper"),
            .description("A piece of paper."),
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
            The piece of paper catches fire and is consumed!
            """)

        // Verify item was destroyed
        let finalState = try? await engine.item("paper")
        #expect(finalState == nil)
    }

    @Test("Burn non-flammable item gives appropriate message")
    func testBurnNonFlammableItem() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let rock = Item(
            id: "rock",
            .name("large rock"),
            .description("A large boulder."),
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
            You can't burn the large rock.
            """)

        let finalState = try await engine.item("rock")
        #expect(finalState.hasFlag(.isTouched) == true)
    }

    @Test("Burning sets isTouched flag")
    func testBurningSetsTouchedFlag() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let metal = Item(
            id: "metal",
            .name("iron bar"),
            .description("A solid iron bar."),
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: metal
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("burn metal")

        // Then
        let finalState = try await engine.item("metal")
        #expect(finalState.hasFlag(.isTouched) == true)
    }

    // MARK: - ActionID Testing

    @Test("Handler exposes correct ActionIDs")
    func testActionIDs() async throws {
        let handler = BurnActionHandler()
        // BurnActionHandler doesn't specify actions, so it should be empty
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
