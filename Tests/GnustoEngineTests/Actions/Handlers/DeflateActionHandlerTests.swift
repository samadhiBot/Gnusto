import CustomDump
import Foundation
import GnustoEngine
import Testing

@Suite("DeflateActionHandler")
struct DeflateActionHandlerTests {
    // MARK: - Test Helpers

    private func createTestEngine() async -> (GameEngine, MockIOHandler) {
        let balloon = Item(
            id: "balloon",
            .name("balloon"),
            .isInflatable,
            .isTakable,
            .in(.player)
        )

        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .description("A room for testing deflate commands."),
            .inherentlyLit
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: balloon
        )


        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        return (engine, mockIO)
    }

    private func createTestEngineWithInflatedBalloon() async -> (GameEngine, MockIOHandler) {
        let balloon = Item(
            id: "balloon",
            .name("balloon"),
            .isInflatable,
            .isInflated,
            .isTakable,
            .in(.player)
        )

        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .description("A room for testing deflate commands."),
            .inherentlyLit
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: balloon
        )


        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        return (engine, mockIO)
    }

    private func createTestEngineWithDistantItem() async -> (GameEngine, MockIOHandler) {
        let balloon = Item(
            id: "balloon",
            .name("balloon"),
            .isInflatable,
            .isTakable,
            .in(.player)
        )

        let distantBalloon = Item(
            id: "distantBalloon",
            .name("distant balloon"),
            .isInflatable,
            .isTakable,
            .in(.location("anotherRoom"))
        )

        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .description("A room for testing deflate commands."),
            .inherentlyLit
        )

        let anotherRoom = Location(
            id: "anotherRoom",
            .name("Another Room"),
            .description("A distant room."),
            .inherentlyLit
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom, anotherRoom,
            items: balloon, distantBalloon
        )


        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        return (engine, mockIO)
    }

    // MARK: - Tests

    @Test("DEFLATE command without object")
    func testDeflateCommandNoObject() async throws {
        let balloon = Item(
            id: "balloon",
            .name("balloon"),
            .isInflatable,
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(items: balloon)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Execute the command through the full pipeline
        try await engine.execute("deflate")

        // Check the output
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > deflate
            Deflate what?
            """)
    }

    @Test("DEFLATE command on inflated object")
    func testDeflateInflatedObject() async throws {
        let balloon = Item(
            id: "balloon",
            .name("balloon"),
            .isInflatable,
            .isInflated,
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(items: balloon)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Execute the command through the full pipeline
        try await engine.execute("deflate balloon")

        // Verify balloon is no longer inflated and is marked as touched
        let balloonAfter = try await engine.item("balloon")
        #expect(!balloonAfter.hasFlag(.isInflated))
        #expect(balloonAfter.hasFlag(.isTouched))

        // Check the output
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > deflate balloon
            You deflate the balloon.
            """)
    }

    @Test("DEFLATE command on non-inflated object")
    func testDeflateNonInflatedObject() async throws {
        let balloon = Item(
            id: "balloon",
            .name("balloon"),
            .isInflatable,
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(items: balloon)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Execute the command through the full pipeline
        try await engine.execute("deflate balloon")

        // Verify balloon is marked as touched
        let balloonAfter = try await engine.item("balloon")
        #expect(balloonAfter.hasFlag(.isTouched))

        // Check the output
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > deflate balloon
            The balloon is not inflated.
            """)
    }

    @Test("DEFLATE command on inaccessible item")
    func testDeflateInaccessibleItem() async throws {
        let balloon = Item(
            id: "balloon",
            .name("balloon"),
            .isInflatable,
            .isTakable,
            .in(.player)
        )

        let distantBalloon = Item(
            id: "distantBalloon",
            .name("distant balloon"),
            .isInflatable,
            .isTakable,
            .in(.location("anotherRoom"))
        )

        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .description("A room for testing deflate commands."),
            .inherentlyLit
        )

        let anotherRoom = Location(
            id: "anotherRoom",
            .name("Another Room"),
            .description("A distant room."),
            .inherentlyLit
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom, anotherRoom,
            items: balloon, distantBalloon
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Execute the command through the full pipeline
        try await engine.execute("deflate distant balloon")

        // Check that an error message was displayed
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > deflate distant balloon
            You can’t see any such thing.
            """)
    }
}
