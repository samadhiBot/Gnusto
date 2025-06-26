import CustomDump
import Testing

@testable import GnustoEngine

@Suite("DeflateActionHandler Tests")
struct DeflateActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("DEFLATE DIRECTOBJECT syntax works")
    func testDeflateDirectObjectSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .description("A room for testing."),
            .inherentlyLit
        )

        let balloon = Item(
            id: "balloon",
            .name("red balloon"),
            .description("A red balloon."),
            .isInflatable,
            .isInflated,
            .isTakable,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: balloon
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("deflate balloon")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > deflate balloon
            You deflate the red balloon.
            """)

        let finalState = try await engine.item("balloon")
        #expect(finalState.hasFlag(.isTouched) == true)
        #expect(finalState.hasFlag(.isInflated) == false)
    }

    // MARK: - Validation Testing

    @Test("Cannot deflate without specifying target")
    func testCannotDeflateWithoutTarget() async throws {
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
        try await engine.execute("deflate")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > deflate
            Deflate what?
            """)
    }

    @Test("Cannot deflate target not in scope")
    func testCannotDeflateTargetNotInScope() async throws {
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

        let remoteBalloon = Item(
            id: "remoteBalloon",
            .name("remote balloon"),
            .description("A balloon in another room."),
            .isInflatable,
            .isInflated,
            .in(.location("anotherRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom, anotherRoom,
            items: remoteBalloon
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("deflate balloon")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > deflate balloon
            You can’t see any such thing.
            """)
    }

    @Test("Cannot deflate non-inflatable item")
    func testCannotDeflateNonInflatableItem() async throws {
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
        try await engine.execute("deflate rock")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > deflate rock
            You can’t deflate the large rock.
            """)
    }

    @Test("Requires light to deflate")
    func testRequiresLight() async throws {
        // Given: Dark room with inflatable item
        let darkRoom = Location(
            id: "darkRoom",
            .name("Dark Room"),
            .description("A pitch black room.")
            // Note: No .inherentlyLit property
        )

        let balloon = Item(
            id: "balloon",
            .name("red balloon"),
            .description("A red balloon."),
            .isInflatable,
            .isInflated,
            .in(.location("darkRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom,
            items: balloon
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("deflate balloon")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > deflate balloon
            It is pitch black. You can’t see a thing.
            """)
    }

    // MARK: - Processing Testing

    @Test("Deflate inflated item succeeds")
    func testDeflateInflatedItemSucceeds() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let raft = Item(
            id: "raft",
            .name("rubber raft"),
            .description("A rubber raft."),
            .isInflatable,
            .isInflated,
            .isTakable,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: raft
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("deflate raft")

        // Then: Verify state changes
        let finalState = try await engine.item("raft")
        #expect(finalState.hasFlag(.isTouched) == true)
        #expect(finalState.hasFlag(.isInflated) == false)
        #expect(finalState.hasFlag(.isInflatable) == true)  // Still inflatable

        // Verify message
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > deflate raft
            You deflate the rubber raft.
            """)
    }

    @Test("Deflate already deflated item gives appropriate message")
    func testDeflateAlreadyDeflatedItem() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let balloon = Item(
            id: "balloon",
            .name("blue balloon"),
            .description("A blue balloon."),
            .isInflatable,
            .isTakable,
            .in(.location("testRoom"))
            // Note: No .isInflated flag - it’s already deflated
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: balloon
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("deflate balloon")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > deflate balloon
            The blue balloon is not inflated.
            """)

        // Should still touch the item
        let finalState = try await engine.item("balloon")
        #expect(finalState.hasFlag(.isTouched) == true)
        #expect(finalState.hasFlag(.isInflated) == false)
    }

    @Test("Deflate item held by player")
    func testDeflateItemHeldByPlayer() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let balloon = Item(
            id: "balloon",
            .name("green balloon"),
            .description("A green balloon."),
            .isInflatable,
            .isInflated,
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: balloon
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("deflate balloon")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > deflate balloon
            You deflate the green balloon.
            """)

        let finalState = try await engine.item("balloon")
        #expect(finalState.hasFlag(.isInflated) == false)
        #expect(finalState.parent == .player)  // Still held by player
    }

    @Test("Deflate multiple different items")
    func testDeflateMultipleDifferentItems() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let balloon = Item(
            id: "balloon",
            .name("yellow balloon"),
            .description("A yellow balloon."),
            .isInflatable,
            .isInflated,
            .in(.location("testRoom"))
        )

        let mattress = Item(
            id: "mattress",
            .name("air mattress"),
            .description("An inflatable air mattress."),
            .isInflatable,
            .isInflated,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: balloon, mattress
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Deflate balloon
        try await engine.execute("deflate balloon")

        // Then
        let output1 = await mockIO.flush()
        expectNoDifference(
            output1,
            """
            > deflate balloon
            You deflate the yellow balloon.
            """)

        // When: Deflate mattress
        try await engine.execute("deflate mattress")

        // Then
        let output2 = await mockIO.flush()
        expectNoDifference(
            output2,
            """
            > deflate mattress
            You deflate the air mattress.
            """)

        // Verify both items are deflated
        let balloonState = try await engine.item("balloon")
        let mattressState = try await engine.item("mattress")
        #expect(balloonState.hasFlag(.isInflated) == false)
        #expect(mattressState.hasFlag(.isInflated) == false)
    }

    // MARK: - Intent Testing

    @Test("Handler exposes correct Intents")
    func testIntents() async throws {
        let handler = DeflateActionHandler()
        // DeflateActionHandler doesn’t specify actions, so it should be empty
        #expect(handler.actions.isEmpty)
    }

    @Test("Handler exposes correct Verbs")
    func testVerbs() async throws {
        let handler = DeflateActionHandler()
        #expect(handler.verbs.contains(.deflate))
        #expect(handler.verbs.count == 1)
    }

    @Test("Handler requires light")
    func testRequiresLightProperty() async throws {
        let handler = DeflateActionHandler()
        #expect(handler.requiresLight == true)
    }
}
