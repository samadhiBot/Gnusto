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
        // Given: Dark room without light source
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

        let item = Item(
            id: "item",
            .name("test item"),
            .description("A test item."),
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: item
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

        let (engine, _) = await GameEngine.test(blueprint: game)

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

    // MARK: - Intent Testing

    @Test("Handler exposes correct Intents")
    func testCorrectIntents() async throws {
        // Given
        let handler = WaitActionHandler()

        // When & Then
        // WaitActionHandler doesn’t specify actions, so it should be empty
        #expect(handler.actions.isEmpty)
    }

    @Test("Handler exposes correct Verbs")
    func testCorrectVerbs() async throws {
        // Given
        let handler = WaitActionHandler()

        // When
        let verbIDs = handler.verbs

        // Then
        #expect(verbIDs.contains(.wait))
        #expect(verbIDs.contains("z"))
    }

    @Test("Handler does not require light")
    func testHandlerDoesNotRequireLight() async throws {
        // Given
        let handler = WaitActionHandler()

        // When & Then
        #expect(handler.requiresLight == false)
    }
}
