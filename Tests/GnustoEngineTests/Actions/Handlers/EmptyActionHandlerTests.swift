import CustomDump
import Testing

import GnustoEngine

@Suite("EmptyActionHandler")
struct EmptyActionHandlerTests {
    // MARK: - Test Helpers

    private func createTestEngine() async -> (GameEngine, MockIOHandler) {
        let box = Item(
            id: "box",
            .name("box"),
            .isContainer,
            .isOpen,
            .isTakable,
            .in(.location("testRoom"))
        )

        let coin = Item(
            id: "coin",
            .name("coin"),
            .isTakable,
            .in(.item("box"))
        )

        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .description("A room for testing empty commands."),
            .inherentlyLit
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: box, coin
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        return (engine, mockIO)
    }

    private func createTestEngineWithEmptyBox() async -> (GameEngine, MockIOHandler) {
        let box = Item(
            id: "box",
            .name("box"),
            .isContainer,
            .isOpen,
            .isTakable,
            .in(.location("testRoom"))
        )

        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .description("A room for testing empty commands."),
            .inherentlyLit
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: box
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        return (engine, mockIO)
    }

    private func createTestEngineWithClosedBox() async -> (GameEngine, MockIOHandler) {
        let box = Item(
            id: "box",
            .name("box"),
            .isContainer,
            .isTakable,
            .in(.location("testRoom"))
        )

        let coin = Item(
            id: "coin",
            .name("coin"),
            .isTakable,
            .in(.item("box"))
        )

        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .description("A room for testing empty commands."),
            .inherentlyLit
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: box, coin
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        return (engine, mockIO)
    }

    private func createTestEngineWithNonContainer() async -> (GameEngine, MockIOHandler) {
        let rock = Item(
            id: "rock",
            .name("rock"),
            .isTakable,
            .in(.location("testRoom"))
        )

        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .description("A room for testing empty commands."),
            .inherentlyLit
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: rock
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        return (engine, mockIO)
    }

    // MARK: - Tests

    @Test("EMPTY command without object")
    func testEmptyCommandNoObject() async throws {
        let (engine, mockIO) = await createTestEngine()

        // Act
        try await engine.execute("empty")

        // Check the output
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > empty
            Empty what?
            """)
    }

    @Test("EMPTY command on container with contents")
    func testEmptyCommand() async throws {
        let (engine, mockIO) = await createTestEngine()

        // Act
        try await engine.execute("empty box")

        // Verify box is marked as touched
        let boxAfter = try await engine.item("box")
        #expect(boxAfter.hasFlag(.isTouched))

        // Verify coin is now in the test room
        let coinAfter = try await engine.item("coin")
        #expect(coinAfter.parent == .location("testRoom"))

        // Check the output
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > empty box
            You empty the box, and a coin falls to the ground.
            """)
    }

    @Test("EMPTY command on empty container")
    func testEmptyEmptyContainer() async throws {
        let (engine, mockIO) = await createTestEngineWithEmptyBox()

        // Act
        try await engine.execute("empty box")

        // Verify box is marked as touched
        let boxAfter = try await engine.item("box")
        #expect(boxAfter.hasFlag(.isTouched))

        // Check the output
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > empty box
            The box is already empty.
            """)
    }

    @Test("EMPTY command on closed container")
    func testEmptyClosedContainer() async throws {
        let (engine, mockIO) = await createTestEngineWithClosedBox()

        // Act
        try await engine.execute("empty box")

        // Check that an error message was displayed
        let output = await mockIO.flush()
        #expect(output.contains("closed") || output.contains("can't empty"))
    }

    @Test("EMPTY command on non-container")
    func testEmptyNonContainer() async throws {
        let (engine, mockIO) = await createTestEngineWithNonContainer()

        // Act
        try await engine.execute("empty rock")

        // Check that an error message was displayed
        let output = await mockIO.flush()
        #expect(output.contains("You can") && output.contains("put things in") && output.contains("rock"))
    }
}
