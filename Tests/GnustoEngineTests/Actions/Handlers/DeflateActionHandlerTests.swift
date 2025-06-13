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
            locations: [testRoom],
            items: [balloon]
        )

        let mockIO = await MockIOHandler()
        let mockParser = MockParser()

        let engine = await GameEngine(
            blueprint: game,
            parser: mockParser,
            ioHandler: mockIO
        )

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
            locations: [testRoom],
            items: [balloon]
        )

        let mockIO = await MockIOHandler()
        let mockParser = MockParser()

        let engine = await GameEngine(
            blueprint: game,
            parser: mockParser,
            ioHandler: mockIO
        )

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
            locations: [testRoom, anotherRoom],
            items: [balloon, distantBalloon]
        )

        let mockIO = await MockIOHandler()
        let mockParser = MockParser()

        let engine = await GameEngine(
            blueprint: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        return (engine, mockIO)
    }

    // MARK: - Tests

    @Test("DEFLATE command without object")
    func testDeflateCommandNoObject() async throws {
        let (engine, mockIO) = await createTestEngine()
        let command = Command(verb: .deflate, rawInput: "deflate")

        // Execute the command through the full pipeline
        await engine.execute(command: command)

        // Check the output
        let output = await mockIO.flush()
        #expect(output.contains("deflate what") || output.contains("What do you want to deflate"))
    }

    @Test("DEFLATE command on inflated object")
    func testDeflateInflatedObject() async throws {
        let (engine, mockIO) = await createTestEngineWithInflatedBalloon()
        let command = Command(verb: .deflate, directObject: .item("balloon"), rawInput: "deflate balloon")

        // Execute the command through the full pipeline
        await engine.execute(command: command)

        // Verify balloon is no longer inflated and is marked as touched
        let balloonAfter = try await engine.item("balloon")
        #expect(!balloonAfter.hasFlag(.isInflated))
        #expect(balloonAfter.hasFlag(.isTouched))

        // Check the output
        let output = await mockIO.flush()
        #expect(output.contains("deflate") && output.contains("balloon"))
    }

    @Test("DEFLATE command on non-inflated object")
    func testDeflateNonInflatedObject() async throws {
        let (engine, mockIO) = await createTestEngine()
        let command = Command(verb: .deflate, directObject: .item("balloon"), rawInput: "deflate balloon")

        // Execute the command through the full pipeline
        await engine.execute(command: command)

        // Verify balloon is marked as touched
        let balloonAfter = try await engine.item("balloon")
        #expect(balloonAfter.hasFlag(.isTouched))

        // Check the output
        let output = await mockIO.flush()
        #expect(output.contains("already deflated") || output.contains("not inflated"))
    }

    @Test("DEFLATE command on inaccessible item")
    func testDeflateInaccessibleItem() async throws {
        let (engine, mockIO) = await createTestEngineWithDistantItem()
        let command = Command(verb: .deflate, directObject: .item("distantBalloon"), rawInput: "deflate distant balloon")

        // Execute the command through the full pipeline
        await engine.execute(command: command)

        // Check that an error message was displayed
        let output = await mockIO.flush()
        #expect(output.contains("any such thing") || output.contains("not accessible") || output.contains("can't see"))
    }
}
