import Testing
import CustomDump
@testable import GnustoEngine

@Suite("TakeActionHandler Tests")
struct TakeActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("TAKE syntax works")
    func testTakeSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .description("A room for testing."),
            .inherentlyLit
        )

        let key = Item(
            id: "key",
            .name("brass key"),
            .description("A small brass key."),
            .isTakable,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: key
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("take key")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > take key
            Taken.
            """)

        let finalState = try await engine.item("key")
        #expect(finalState.parent == .player)
    }

    @Test("GET syntax works")
    func testGetSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let coin = Item(
            id: "coin",
            .name("gold coin"),
            .description("A shiny gold coin."),
            .isTakable,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: coin
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("get coin")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > get coin
            Taken.
            """)

        let finalState = try await engine.item("coin")
        #expect(finalState.parent == .player)
    }

    @Test("GRAB syntax works")
    func testGrabSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let rope = Item(
            id: "rope",
            .name("coiled rope"),
            .description("A length of coiled rope."),
            .isTakable,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: rope
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("grab rope")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > grab rope
            Taken.
            """)

        let finalState = try await engine.item("rope")
        #expect(finalState.parent == .player)
    }

    @Test("STEAL syntax works")
    func testStealSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let gem = Item(
            id: "gem",
            .name("sparkling gem"),
            .description("A beautiful sparkling gem."),
            .isTakable,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: gem
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("steal gem")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > steal gem
            Taken.
            """)

        let finalState = try await engine.item("gem")
        #expect(finalState.parent == .player)
    }

    // MARK: - Validation Testing

    @Test("Cannot take item that is not takable")
    func testCannotTakeNonTakableItem() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let statue = Item(
            id: "statue",
            .name("stone statue"),
            .description("A heavy stone statue."),
            .in(.location("testRoom"))
            // Note: No .isTakable property
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: statue
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("take statue")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > take statue
            You can’t take the stone statue.
            """)

        let finalState = try await engine.item("statue")
        #expect(finalState.parent == .location("testRoom"))
    }

    @Test("Cannot take item already held")
    func testCannotTakeAlreadyHeldItem() async throws {
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
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: book
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("take book")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > take book
            You already have that.
            """)

        let finalState = try await engine.item("book")
        #expect(finalState.parent == .player)
    }

    @Test("Cannot take item not in scope")
    func testCannotTakeItemNotInScope() async throws {
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

        let remoteItem = Item(
            id: "remote",
            .name("remote item"),
            .description("An item in another room."),
            .isTakable,
            .in(.location("anotherRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom, anotherRoom,
            items: remoteItem
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("take remote")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > take remote
            You can’t see any such thing.
            """)

        let finalState = try await engine.item("remote")
        #expect(finalState.parent == .location("anotherRoom"))
    }

    @Test("Requires light to take items")
    func testRequiresLight() async throws {
        // Given: Dark room with no light sources
        let darkRoom = Location(
            id: "darkRoom",
            .name("Dark Room"),
            .description("A pitch black room.")
            // Note: No .inherentlyLit property
        )

        let key = Item(
            id: "key",
            .name("brass key"),
            .description("A small brass key."),
            .isTakable,
            .in(.location("darkRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom,
            items: key
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("take key")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > take key
            It is pitch black. You can’t see a thing.
            """)

        let finalState = try await engine.item("key")
        #expect(finalState.parent == .location("darkRoom"))
    }

    // MARK: - Processing Testing

    @Test("Successful take moves item to player")
    func testSuccessfulTakeMovesItem() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let scroll = Item(
            id: "scroll",
            .name("ancient scroll"),
            .description("An ancient papyrus scroll."),
            .isTakable,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: scroll
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("take scroll")

        // Then: Verify state change
        let finalState = try await engine.item("scroll")
        #expect(finalState.parent == .player)

        // Verify message
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > take scroll
            Taken.
            """)
    }

    @Test("Taking item sets touched property")
    func testTakingItemSetsTouchedProperty() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let crystal = Item(
            id: "crystal",
            .name("blue crystal"),
            .description("A translucent blue crystal."),
            .isTakable,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: crystal
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("take crystal")

        // Then
        let finalState = try await engine.item("crystal")
        #expect(finalState.hasFlag(.isTouched) == true)

        let output = await mockIO.flush()
        expectNoDifference(output, """
            > take crystal
            Taken.
            """)
    }

    // MARK: - ActionID Testing

    @Test("Handler exposes correct ActionIDs")
    func testActionIDs() async throws {
        let handler = TakeActionHandler()
        #expect(handler.actions.contains(.take))
        #expect(handler.actions.count == 1)
    }

    @Test("Handler exposes correct VerbIDs")
    func testVerbIDs() async throws {
        let handler = TakeActionHandler()
        #expect(handler.verbs.contains(.take))
        #expect(handler.verbs.contains(.get))
        #expect(handler.verbs.contains(.grab))
        #expect(handler.verbs.contains(.steal))
        #expect(handler.verbs.count == 4)
    }

    @Test("Handler requires light")
    func testRequiresLightProperty() async throws {
        let handler = TakeActionHandler()
        #expect(handler.requiresLight == true)
    }
}
