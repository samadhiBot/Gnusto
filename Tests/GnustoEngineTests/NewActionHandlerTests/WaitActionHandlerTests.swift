import Testing
import CustomDump
@testable import GnustoEngine

@Suite("WaitActionHandler Tests")
struct WaitActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("WAIT syntax works")
    func testWaitSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .description("A room for testing."),
            .inherentlyLit
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("wait")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > wait
            Time passes.
            """)
    }

    @Test("Z syntax works")
    func testZSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .description("A room for testing."),
            .inherentlyLit
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("z")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > z
            Time passes.
            """)
    }

    // MARK: - Validation Testing

    @Test("Does not require light to wait")
    func testDoesNotRequireLight() async throws {
        // Given: Dark room
        let darkRoom = Location(
            id: "darkRoom",
            .name("Dark Room"),
            .description("A pitch black room.")
        )

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("wait")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > wait
            Time passes.
            """)
    }

    // MARK: - Processing Testing

    @Test("Wait in lit room")
    func testWaitInLitRoom() async throws {
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
        try await engine.execute("wait")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > wait
            Time passes.
            """)
    }

    @Test("Wait in dark room")
    func testWaitInDarkRoom() async throws {
        // Given
        let darkRoom = Location(
            id: "darkRoom",
            .name("Dark Room"),
            .description("A pitch black room.")
        )

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("wait")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > wait
            Time passes.
            """)
    }

    @Test("Wait with objects in room")
    func testWaitWithObjectsInRoom() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let chest = Item(
            id: "chest",
            .name("wooden chest"),
            .description("A large wooden chest."),
            .in(.location("testRoom"))
        )

        let gem = Item(
            id: "gem",
            .name("sparkling gem"),
            .description("A beautiful gem."),
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: chest, gem
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("wait")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > wait
            Time passes.
            """)
    }

    @Test("Wait multiple times")
    func testWaitMultipleTimes() async throws {
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
        try await engine.execute("wait")
        try await engine.execute("z")
        try await engine.execute("wait")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > wait
            Time passes.
            > z
            Time passes.
            > wait
            Time passes.
            """)
    }

    @Test("Wait does not change game state")
    func testWaitDoesNotChangeGameState() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let book = Item(
            id: "book",
            .name("leather book"),
            .description("A thick leather-bound book."),
            .isTakable,
            .in(.location("testRoom"))
        )

        let coin = Item(
            id: "coin",
            .name("gold coin"),
            .description("A shiny gold coin."),
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: book, coin
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Capture initial state
        let initialBookState = try await engine.item("book")
        let initialCoinState = try await engine.item("coin")
        let initialPlayerLocation = await engine.playerLocationID

        // When
        try await engine.execute("wait")

        // Then
        let finalBookState = try await engine.item("book")
        let finalCoinState = try await engine.item("coin")
        let finalPlayerLocation = await engine.playerLocationID

        #expect(initialBookState.parent == finalBookState.parent)
        #expect(initialCoinState.parent == finalCoinState.parent)
        #expect(initialPlayerLocation == finalPlayerLocation)
    }

    // MARK: - ActionID Testing

    @Test("Handler exposes correct ActionIDs")
    func testActionIDs() async throws {
        let handler = WaitActionHandler()
        // WaitActionHandler doesn't specify actions, so it should be empty
        #expect(handler.actions.isEmpty)
    }

    @Test("Handler exposes correct VerbIDs")
    func testVerbIDs() async throws {
        let handler = WaitActionHandler()
        #expect(handler.verbs.contains(.wait))
        #expect(handler.verbs.contains(VerbID("z")))
        #expect(handler.verbs.count == 2)
    }

    @Test("Handler does not require light")
    func testRequiresLightProperty() async throws {
        let handler = WaitActionHandler()
        #expect(handler.requiresLight == false)
    }
}
