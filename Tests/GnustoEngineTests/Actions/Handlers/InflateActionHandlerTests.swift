import CustomDump
import GnustoEngine
import GnustoTestSupport
import Testing

@Suite("InflateActionHandler Tests")
struct InflateActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("INFLATE DIRECTOBJECT syntax works")
    func testInflateDirectObjectSyntax() async throws {
        // Given
        let balloon = Item("balloon")
            .name("red balloon")
            .description("A red balloon.")
            .isInflatable
            .isTakable
            .in(.startRoom)

        let game = MinimalGame(
            items: balloon
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("inflate balloon")

        // Then
        await mockIO.expectOutput(
            """
            > inflate balloon
            You inflate the red balloon.
            """
        )

        let finalState = await engine.item("balloon")
        #expect(await finalState.hasFlag(.isTouched))
        #expect(await finalState.hasFlag(.isInflated))
    }

    @Test("INFLATE DIRECTOBJECT WITH INDIRECTOBJECT syntax works")
    func testInflateWithObjectSyntax() async throws {
        // Given
        let raft = Item("raft")
            .name("rubber raft")
            .description("A rubber raft.")
            .isInflatable
            .isTakable
            .in(.startRoom)

        let pump = Item("pump")
            .name("air pump")
            .description("An air pump.")
            .isTakable
            .in(.player)

        let game = MinimalGame(
            items: raft, pump
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("inflate raft with pump")

        // Then
        await mockIO.expectOutput(
            """
            > inflate raft with pump
            You inflate the rubber raft.
            """
        )
    }

    @Test("BLOW UP DIRECTOBJECT syntax works")
    func testBlowUpDirectObjectSyntax() async throws {
        // Given
        let mattress = Item("mattress")
            .name("air mattress")
            .description("An inflatable air mattress.")
            .isInflatable
            .isTakable
            .in(.startRoom)

        let game = MinimalGame(
            items: mattress
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("blow up mattress")

        // Then
        await mockIO.expectOutput(
            """
            > blow up mattress
            You inflate the air mattress.
            """
        )
    }

    @Test("BLOW UP DIRECTOBJECT WITH INDIRECTOBJECT syntax works")
    func testBlowUpWithObjectSyntax() async throws {
        // Given
        let tire = Item("tire")
            .name("bicycle tire")
            .description("A bicycle tire.")
            .isInflatable
            .isTakable
            .in(.startRoom)

        let compressor = Item("compressor")
            .name("air compressor")
            .description("An air compressor.")
            .isTakable
            .in(.player)

        let game = MinimalGame(
            items: tire, compressor
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("blow up tire with compressor")

        // Then
        await mockIO.expectOutput(
            """
            > blow up tire with compressor
            You inflate the bicycle tire.
            """
        )
    }

    // MARK: - Validation Testing

    @Test("Cannot inflate without specifying target")
    func testCannotInflateWithoutTarget() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("inflate")

        // Then
        await mockIO.expectOutput(
            """
            > inflate
            Inflate what?
            """
        )
    }

    @Test("Cannot inflate target not in scope")
    func testCannotInflateTargetNotInScope() async throws {
        // Given
        let anotherRoom = Location("anotherRoom")
            .name("Another Room")
            .inherentlyLit

        let remoteBalloon = Item("remoteBalloon")
            .name("remote balloon")
            .description("A balloon in another room.")
            .isInflatable
            .in("anotherRoom")

        let game = MinimalGame(
            locations: anotherRoom,
            items: remoteBalloon
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("inflate balloon")

        // Then
        await mockIO.expectOutput(
            """
            > inflate balloon
            Any such thing lurks beyond your reach.
            """
        )
    }

    @Test("Cannot inflate non-inflatable item")
    func testCannotInflateNonInflatableItem() async throws {
        // Given
        let rock = Item("rock")
            .name("large rock")
            .description("A large boulder.")
            .in(.startRoom)

        let game = MinimalGame(
            items: rock
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("inflate rock")

        // Then
        await mockIO.expectOutput(
            """
            > inflate rock
            The large rock stubbornly resists your attempts to inflate it.
            """
        )
    }

    @Test("Requires light to inflate")
    func testRequiresLight() async throws {
        // Given: Dark room with inflatable item
        let darkRoom = Location("darkRoom")
            .name("Dark Room")
            .description("A pitch black room.")
            // Note: No .inherentlyLit property

        let balloon = Item("balloon")
            .name("red balloon")
            .description("A red balloon.")
            .isInflatable
            .in("darkRoom")

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom,
            items: balloon
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("inflate balloon")

        // Then
        await mockIO.expectOutput(
            """
            > inflate balloon
            The darkness here is absolute, consuming all light and hope of
            sight.
            """
        )
    }

    // MARK: - Processing Testing

    @Test("Inflate deflated item succeeds")
    func testInflateDeflatedItemSucceeds() async throws {
        // Given
        let lifeVest = Item("lifeVest")
            .name("life vest")
            .description("An inflatable life vest.")
            .isInflatable
            .isTakable
            .in(.startRoom)

        let game = MinimalGame(
            items: lifeVest
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("inflate vest")

        // Then: Verify state changes
        let finalState = await engine.item("lifeVest")
        #expect(await finalState.hasFlag(.isTouched))
        #expect(await finalState.hasFlag(.isInflated))
        #expect(await finalState.hasFlag(.isInflatable))  // Still inflatable

        // Verify message
        await mockIO.expectOutput(
            """
            > inflate vest
            You inflate the life vest.
            """
        )
    }

    @Test("Inflate already inflated item gives appropriate message")
    func testInflateAlreadyInflatedItem() async throws {
        // Given
        let balloon = Item("balloon")
            .name("blue balloon")
            .description("A blue balloon.")
            .isInflatable
            .isInflated
            .isTakable
            .in(.startRoom)

        let game = MinimalGame(
            items: balloon
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("inflate balloon")

        // Then
        await mockIO.expectOutput(
            """
            > inflate balloon
            The blue balloon is already inflated.
            """
        )

        // Should still touch the item
        let finalState = await engine.item("balloon")
        #expect(await finalState.hasFlag(.isTouched))
        #expect(await finalState.hasFlag(.isInflated))
    }

    @Test("Inflate item held by player")
    func testInflateItemHeldByPlayer() async throws {
        // Given
        let balloon = Item("balloon")
            .name("green balloon")
            .description("A green balloon.")
            .isInflatable
            .isTakable
            .in(.player)

        let game = MinimalGame(
            items: balloon
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("inflate balloon")

        // Then
        await mockIO.expectOutput(
            """
            > inflate balloon
            You inflate the green balloon.
            """
        )

        let finalState = await engine.item("balloon")
        #expect(await finalState.hasFlag(.isInflated))
        #expect(await finalState.playerIsHolding)  // Still held by player
    }

    @Test("Inflate multiple different items")
    func testInflateMultipleDifferentItems() async throws {
        // Given
        let balloon = Item("balloon")
            .name("yellow balloon")
            .description("A yellow balloon.")
            .isInflatable
            .in(.startRoom)

        let raft = Item("raft")
            .name("life raft")
            .description("An inflatable life raft.")
            .isInflatable
            .in(.startRoom)

        let game = MinimalGame(
            items: balloon, raft
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Inflate balloon
        try await engine.execute("inflate balloon")

        // Then
        await mockIO.expectOutput(
            """
            > inflate balloon
            You inflate the yellow balloon.
            """
        )

        // When: Inflate raft
        try await engine.execute("blow up raft")

        // Then
        await mockIO.expectOutput(
            """
            > blow up raft
            You inflate the life raft.
            """
        )

        // Verify both items are inflated
        let balloonState = await engine.item("balloon")
        let raftState = await engine.item("raft")
        #expect(await balloonState.hasFlag(.isInflated))
        #expect(await raftState.hasFlag(.isInflated))
    }

    @Test("Inflate sets touched flag on item")
    func testInflateSetsTouchedFlag() async throws {
        // Given
        let tube = Item("tube")
            .name("inner tube")
            .description("An inflatable inner tube.")
            .isInflatable
            .isTakable
            .in(.startRoom)

        let game = MinimalGame(
            items: tube
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("inflate tube")

        // Then: Verify state changes
        let finalState = await engine.item("tube")
        #expect(await finalState.hasFlag(.isTouched))
        #expect(await finalState.hasFlag(.isInflated))

        // Verify message
        await mockIO.expectOutput(
            """
            > inflate tube
            You inflate the inner tube.
            """
        )
    }

    @Test("Inflate with different syntax variations")
    func testInflateWithDifferentSyntaxVariations() async throws {
        // Given
        let balloon1 = Item("balloon1")
            .name("red balloon")
            .description("A red balloon.")
            .isInflatable
            .in(.startRoom)

        let balloon2 = Item("balloon2")
            .name("blue balloon")
            .description("A blue balloon.")
            .isInflatable
            .in(.startRoom)

        let pump = Item("pump")
            .name("hand pump")
            .description("A hand pump.")
            .isTakable
            .in(.player)

        let game = MinimalGame(
            items: balloon1, balloon2, pump
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Use "inflate" syntax
        try await engine.execute("inflate red balloon")

        // Then
        await mockIO.expectOutput(
            """
            > inflate red balloon
            You inflate the red balloon.
            """
        )

        // When: Use "blow up" syntax with tool
        try await engine.execute("blow up blue balloon with pump")

        // Then
        await mockIO.expectOutput(
            """
            > blow up blue balloon with pump
            You inflate the blue balloon.
            """
        )

        // Verify both balloons are inflated
        let balloon1State = await engine.item("balloon1")
        let balloon2State = await engine.item("balloon2")
        #expect(await balloon1State.hasFlag(.isInflated))
        #expect(await balloon2State.hasFlag(.isInflated))
    }

    @Test("Inflate twice shows already inflated message")
    func testInflateTwiceShowsAlreadyInflatedMessage() async throws {
        // Given
        let cushion = Item("cushion")
            .name("air cushion")
            .description("An inflatable air cushion.")
            .isInflatable
            .isTakable
            .in(.startRoom)

        let game = MinimalGame(
            items: cushion
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: First inflation
        try await engine.execute("inflate cushion")

        // Then
        await mockIO.expectOutput(
            """
            > inflate cushion
            You inflate the air cushion.
            """
        )

        // When: Second inflation attempt
        try await engine.execute("inflate cushion")

        // Then
        await mockIO.expectOutput(
            """
            > inflate cushion
            The air cushion is already inflated.
            """
        )
    }

    // MARK: - Intent Testing

    @Test("Handler exposes correct Verbs")
    func testVerbs() async throws {
        let handler = InflateActionHandler()
        #expect(handler.synonyms.contains(.inflate))
        #expect(handler.synonyms.count == 1)
    }

    @Test("Handler requires light")
    func testRequiresLightProperty() async throws {
        let handler = InflateActionHandler()
        #expect(handler.requiresLight == true)
    }
}
