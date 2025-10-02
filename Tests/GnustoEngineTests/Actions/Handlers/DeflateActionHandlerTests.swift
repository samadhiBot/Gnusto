import CustomDump
import GnustoEngine
import GnustoTestSupport
import Testing

@Suite("DeflateActionHandler Tests")
struct DeflateActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("DEFLATE DIRECTOBJECT syntax works")
    func testDeflateDirectObjectSyntax() async throws {
        // Given
        let balloon = Item("balloon")
            .name("red balloon")
            .description("A red balloon.")
            .isInflatable
            .isInflated
            .isTakable
            .in(.startRoom)

        let game = MinimalGame(
            items: balloon
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("deflate balloon")

        // Then
        await mockIO.expectOutput(
            """
            > deflate balloon
            You deflate the red balloon.
            """
        )

        let finalState = await engine.item("balloon")
        #expect(await finalState.hasFlag(.isTouched) == true)
        #expect(await finalState.hasFlag(.isInflated) == false)
    }

    // MARK: - Validation Testing

    @Test("Cannot deflate without specifying target")
    func testCannotDeflateWithoutTarget() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("deflate")

        // Then
        await mockIO.expectOutput(
            """
            > deflate
            Deflate what?
            """
        )
    }

    @Test("Cannot deflate target not in scope")
    func testCannotDeflateTargetNotInScope() async throws {
        // Given
        let anotherRoom = Location("anotherRoom")
            .name("Another Room")
            .inherentlyLit

        let remoteBalloon = Item("remoteBalloon")
            .name("remote balloon")
            .description("A balloon in another room.")
            .isInflatable
            .isInflated
            .in("anotherRoom")

        let game = MinimalGame(
            locations: anotherRoom,
            items: remoteBalloon
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("deflate balloon")

        // Then
        await mockIO.expectOutput(
            """
            > deflate balloon
            Any such thing lurks beyond your reach.
            """
        )
    }

    @Test("Cannot deflate non-inflatable item")
    func testCannotDeflateNonInflatableItem() async throws {
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
        try await engine.execute("deflate rock")

        // Then
        await mockIO.expectOutput(
            """
            > deflate rock
            The large rock stubbornly resists your attempts to deflate it.
            """
        )
    }

    @Test("Requires light to deflate")
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
            .isInflated
            .in("darkRoom")

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom,
            items: balloon
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("deflate balloon")

        // Then
        await mockIO.expectOutput(
            """
            > deflate balloon
            The darkness here is absolute, consuming all light and hope of
            sight.
            """
        )
    }

    // MARK: - Processing Testing

    @Test("Deflate inflated item succeeds")
    func testDeflateInflatedItemSucceeds() async throws {
        // Given
        let raft = Item("raft")
            .name("rubber raft")
            .description("A rubber raft.")
            .isInflatable
            .isInflated
            .isTakable
            .in(.startRoom)

        let game = MinimalGame(
            items: raft
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("deflate raft")

        // Then: Verify state changes
        let finalState = await engine.item("raft")
        #expect(await finalState.hasFlag(.isTouched) == true)
        #expect(await finalState.hasFlag(.isInflated) == false)
        #expect(await finalState.hasFlag(.isInflatable) == true)  // Still inflatable

        // Verify message
        await mockIO.expectOutput(
            """
            > deflate raft
            You deflate the rubber raft.
            """
        )
    }

    @Test("Deflate already deflated item gives appropriate message")
    func testDeflateAlreadyDeflatedItem() async throws {
        // Given
        let balloon = Item("balloon")
            .name("blue balloon")
            .description("A blue balloon.")
            .isInflatable
            .isTakable
            .in(.startRoom)
            // Note: No .isInflated flag - it's already deflated

        let game = MinimalGame(
            items: balloon
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("deflate balloon")

        // Then
        await mockIO.expectOutput(
            """
            > deflate balloon
            The blue balloon is not inflated.
            """
        )

        // Should still touch the item
        let finalState = await engine.item("balloon")
        #expect(await finalState.hasFlag(.isTouched) == true)
        #expect(await finalState.hasFlag(.isInflated) == false)
    }

    @Test("Deflate item held by player")
    func testDeflateItemHeldByPlayer() async throws {
        // Given
        let balloon = Item("balloon")
            .name("green balloon")
            .description("A green balloon.")
            .isInflatable
            .isInflated
            .isTakable
            .in(.player)

        let game = MinimalGame(
            items: balloon
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("deflate balloon")

        // Then
        await mockIO.expectOutput(
            """
            > deflate balloon
            You deflate the green balloon.
            """
        )

        let finalState = await engine.item("balloon")
        #expect(await finalState.hasFlag(.isInflated) == false)
        #expect(await finalState.playerIsHolding)  // Still held by player
    }

    @Test("Deflate multiple different items")
    func testDeflateMultipleDifferentItems() async throws {
        // Given
        let balloon = Item("balloon")
            .name("yellow balloon")
            .description("A yellow balloon.")
            .isInflatable
            .isInflated
            .in(.startRoom)

        let mattress = Item("mattress")
            .name("air mattress")
            .description("An inflatable air mattress.")
            .isInflatable
            .isInflated
            .in(.startRoom)

        let game = MinimalGame(
            items: balloon, mattress
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Deflate balloon
        try await engine.execute("deflate balloon")

        // Then
        await mockIO.expectOutput(
            """
            > deflate balloon
            You deflate the yellow balloon.
            """
        )

        // When: Deflate mattress
        try await engine.execute("deflate mattress")

        // Then
        await mockIO.expectOutput(
            """
            > deflate mattress
            You deflate the air mattress.
            """
        )

        // Verify both items are deflated
        let balloonState = await engine.item("balloon")
        let mattressState = await engine.item("mattress")
        #expect(await balloonState.hasFlag(.isInflated) == false)
        #expect(await mattressState.hasFlag(.isInflated) == false)
    }

    // MARK: - Intent Testing

    @Test("Handler exposes correct Verbs")
    func testVerbs() async throws {
        let handler = DeflateActionHandler()
        #expect(handler.synonyms.contains(.deflate))
        #expect(handler.synonyms.count == 1)
    }

    @Test("Handler requires light")
    func testRequiresLightProperty() async throws {
        let handler = DeflateActionHandler()
        #expect(handler.requiresLight == true)
    }
}
