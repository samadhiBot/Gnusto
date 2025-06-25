import CustomDump
import Testing

@testable import GnustoEngine

@Suite("InflateActionHandler Tests")
struct InflateActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("INFLATE DIRECTOBJECT syntax works")
    func testInflateDirectObjectSyntax() async throws {
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
        try await engine.execute("inflate balloon")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > inflate balloon
            The red balloon inflates.
            """)

        let finalState = try await engine.item("balloon")
        #expect(finalState.hasFlag(.isTouched))
        #expect(finalState.hasFlag(.isInflated))
    }

    @Test("INFLATE DIRECTOBJECT WITH INDIRECTOBJECT syntax works")
    func testInflateWithObjectSyntax() async throws {
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
            .isTakable,
            .in(.location("testRoom"))
        )

        let pump = Item(
            id: "pump",
            .name("air pump"),
            .description("An air pump."),
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: raft, pump
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("inflate raft with pump")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > inflate raft with pump
            The rubber raft inflates.
            """)
    }

    @Test("BLOW UP DIRECTOBJECT syntax works")
    func testBlowUpDirectObjectSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let mattress = Item(
            id: "mattress",
            .name("air mattress"),
            .description("An inflatable air mattress."),
            .isInflatable,
            .isTakable,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: mattress
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("blow up mattress")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > blow up mattress
            The air mattress inflates.
            """)
    }

    @Test("BLOW UP DIRECTOBJECT WITH INDIRECTOBJECT syntax works")
    func testBlowUpWithObjectSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let tire = Item(
            id: "tire",
            .name("bicycle tire"),
            .description("A bicycle tire."),
            .isInflatable,
            .isTakable,
            .in(.location("testRoom"))
        )

        let compressor = Item(
            id: "compressor",
            .name("air compressor"),
            .description("An air compressor."),
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: tire, compressor
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("blow up tire with compressor")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > blow up tire with compressor
            The bicycle tire inflates.
            """)
    }

    // MARK: - Validation Testing

    @Test("Cannot inflate without specifying target")
    func testCannotInflateWithoutTarget() async throws {
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
        try await engine.execute("inflate")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > inflate
            Inflate what?
            """)
    }

    @Test("Cannot inflate target not in scope")
    func testCannotInflateTargetNotInScope() async throws {
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
            .in(.location("anotherRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom, anotherRoom,
            items: remoteBalloon
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("inflate balloon")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > inflate balloon
            You can't see any such thing.
            """)
    }

    @Test("Cannot inflate non-inflatable item")
    func testCannotInflateNonInflatableItem() async throws {
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
        try await engine.execute("inflate rock")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > inflate rock
            You can't inflate the large rock.
            """)
    }

    @Test("Requires light to inflate")
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
            .in(.location("darkRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom,
            items: balloon
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("inflate balloon")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > inflate balloon
            It is pitch black. You can't see a thing.
            """)
    }

    // MARK: - Processing Testing

    @Test("Inflate deflated item succeeds")
    func testInflateDeflatedItemSucceeds() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let lifeVest = Item(
            id: "lifeVest",
            .name("life vest"),
            .description("An inflatable life vest."),
            .isInflatable,
            .isTakable,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: lifeVest
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("inflate vest")

        // Then: Verify state changes
        let finalState = try await engine.item("lifeVest")
        #expect(finalState.hasFlag(.isTouched))
        #expect(finalState.hasFlag(.isInflated))
        #expect(finalState.hasFlag(.isInflatable))  // Still inflatable

        // Verify message
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > inflate vest
            The life vest inflates.
            """)
    }

    @Test("Inflate already inflated item gives appropriate message")
    func testInflateAlreadyInflatedItem() async throws {
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
        try await engine.execute("inflate balloon")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > inflate balloon
            The blue balloon is already inflated.
            """)

        // Should still touch the item
        let finalState = try await engine.item("balloon")
        #expect(finalState.hasFlag(.isTouched))
        #expect(finalState.hasFlag(.isInflated))
    }

    @Test("Inflate item held by player")
    func testInflateItemHeldByPlayer() async throws {
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
        try await engine.execute("inflate balloon")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > inflate balloon
            The green balloon inflates.
            """)

        let finalState = try await engine.item("balloon")
        #expect(finalState.hasFlag(.isInflated))
        #expect(finalState.parent == .player)  // Still held by player
    }

    @Test("Inflate multiple different items")
    func testInflateMultipleDifferentItems() async throws {
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
            .in(.location("testRoom"))
        )

        let raft = Item(
            id: "raft",
            .name("life raft"),
            .description("An inflatable life raft."),
            .isInflatable,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: balloon, raft
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Inflate balloon
        try await engine.execute("inflate balloon")

        // Then
        let output1 = await mockIO.flush()
        expectNoDifference(
            output1,
            """
            > inflate balloon
            The yellow balloon inflates.
            """)

        // When: Inflate raft
        try await engine.execute("blow up raft")

        // Then
        let output2 = await mockIO.flush()
        expectNoDifference(
            output2,
            """
            > blow up raft
            The life raft inflates.
            """)

        // Verify both items are inflated
        let balloonState = try await engine.item("balloon")
        let raftState = try await engine.item("raft")
        #expect(balloonState.hasFlag(.isInflated))
        #expect(raftState.hasFlag(.isInflated))
    }

    @Test("Inflate sets touched flag on item")
    func testInflateSetsTouchedFlag() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let tube = Item(
            id: "tube",
            .name("inner tube"),
            .description("An inflatable inner tube."),
            .isInflatable,
            .isTakable,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: tube
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("inflate tube")

        // Then: Verify state changes
        let finalState = try await engine.item("tube")
        #expect(finalState.hasFlag(.isTouched))
        #expect(finalState.hasFlag(.isInflated))

        // Verify message
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > inflate tube
            The inner tube inflates.
            """)
    }

    @Test("Inflate with different syntax variations")
    func testInflateWithDifferentSyntaxVariations() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let balloon1 = Item(
            id: "balloon1",
            .name("red balloon"),
            .description("A red balloon."),
            .isInflatable,
            .in(.location("testRoom"))
        )

        let balloon2 = Item(
            id: "balloon2",
            .name("blue balloon"),
            .description("A blue balloon."),
            .isInflatable,
            .in(.location("testRoom"))
        )

        let pump = Item(
            id: "pump",
            .name("hand pump"),
            .description("A hand pump."),
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: balloon1, balloon2, pump
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Use "inflate" syntax
        try await engine.execute("inflate red balloon")

        // Then
        let output1 = await mockIO.flush()
        expectNoDifference(
            output1,
            """
            > inflate red balloon
            The red balloon inflates.
            """)

        // When: Use "blow up" syntax with tool
        try await engine.execute("blow up blue balloon with pump")

        // Then
        let output2 = await mockIO.flush()
        expectNoDifference(
            output2,
            """
            > blow up blue balloon with pump
            The blue balloon inflates.
            """)

        // Verify both balloons are inflated
        let balloon1State = try await engine.item("balloon1")
        let balloon2State = try await engine.item("balloon2")
        #expect(balloon1State.hasFlag(.isInflated))
        #expect(balloon2State.hasFlag(.isInflated))
    }

    @Test("Inflate twice shows already inflated message")
    func testInflateTwiceShowsAlreadyInflatedMessage() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let cushion = Item(
            id: "cushion",
            .name("air cushion"),
            .description("An inflatable air cushion."),
            .isInflatable,
            .isTakable,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: cushion
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: First inflation
        try await engine.execute("inflate cushion")

        // Then
        let output1 = await mockIO.flush()
        expectNoDifference(
            output1,
            """
            > inflate cushion
            The air cushion inflates.
            """)

        // When: Second inflation attempt
        try await engine.execute("inflate cushion")

        // Then
        let output2 = await mockIO.flush()
        expectNoDifference(
            output2,
            """
            > inflate cushion
            The air cushion is already inflated.
            """)
    }

    // MARK: - ActionID Testing

    @Test("Handler exposes correct ActionIDs")
    func testActionIDs() async throws {
        let handler = InflateActionHandler()
        // InflateActionHandler doesn't specify actions, so it should be empty
        #expect(handler.actions.isEmpty)
    }

    @Test("Handler exposes correct VerbIDs")
    func testVerbIDs() async throws {
        let handler = InflateActionHandler()
        #expect(handler.verbs.contains(.inflate))
        #expect(handler.verbs.count == 1)
    }

    @Test("Handler requires light")
    func testRequiresLightProperty() async throws {
        let handler = InflateActionHandler()
        #expect(handler.requiresLight == true)
    }
}
