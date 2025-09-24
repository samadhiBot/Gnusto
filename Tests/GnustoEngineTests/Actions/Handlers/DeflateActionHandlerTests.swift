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
        let balloon = Item(
            id: "balloon",
            .name("red balloon"),
            .description("A red balloon."),
            .isInflatable,
            .isInflated,
            .isTakable,
            .in(.startRoom)
        )

        let game = MinimalGame(
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
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > deflate
            Deflate what?
            """
        )
    }

    @Test("Cannot deflate target not in scope")
    func testCannotDeflateTargetNotInScope() async throws {
        // Given
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
            .in("anotherRoom")
        )

        let game = MinimalGame(
            locations: anotherRoom,
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
            Any such thing remains frustratingly inaccessible.
            """
        )
    }

    @Test("Cannot deflate non-inflatable item")
    func testCannotDeflateNonInflatableItem() async throws {
        // Given
        let rock = Item(
            id: "rock",
            .name("large rock"),
            .description("A large boulder."),
            .in(.startRoom)
        )

        let game = MinimalGame(
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
            The universe denies your request to deflate the large rock.
            """
        )
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
            .in("darkRoom")
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
            You stand in a depthless black where even your thoughts seem to
            whisper, careful not to make a sound.
            """
        )
    }

    // MARK: - Processing Testing

    @Test("Deflate inflated item succeeds")
    func testDeflateInflatedItemSucceeds() async throws {
        // Given
        let raft = Item(
            id: "raft",
            .name("rubber raft"),
            .description("A rubber raft."),
            .isInflatable,
            .isInflated,
            .isTakable,
            .in(.startRoom)
        )

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
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > deflate raft
            You deflate the rubber raft.
            """
        )
    }

    @Test("Deflate already deflated item gives appropriate message")
    func testDeflateAlreadyDeflatedItem() async throws {
        // Given
        let balloon = Item(
            id: "balloon",
            .name("blue balloon"),
            .description("A blue balloon."),
            .isInflatable,
            .isTakable,
            .in(.startRoom)
            // Note: No .isInflated flag - it's already deflated
        )

        let game = MinimalGame(
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
            """
        )

        let finalState = await engine.item("balloon")
        #expect(await finalState.hasFlag(.isInflated) == false)
        #expect(await finalState.playerIsHolding)  // Still held by player
    }

    @Test("Deflate multiple different items")
    func testDeflateMultipleDifferentItems() async throws {
        // Given
        let balloon = Item(
            id: "balloon",
            .name("yellow balloon"),
            .description("A yellow balloon."),
            .isInflatable,
            .isInflated,
            .in(.startRoom)
        )

        let mattress = Item(
            id: "mattress",
            .name("air mattress"),
            .description("An inflatable air mattress."),
            .isInflatable,
            .isInflated,
            .in(.startRoom)
        )

        let game = MinimalGame(
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
            """
        )

        // When: Deflate mattress
        try await engine.execute("deflate mattress")

        // Then
        let output2 = await mockIO.flush()
        expectNoDifference(
            output2,
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
