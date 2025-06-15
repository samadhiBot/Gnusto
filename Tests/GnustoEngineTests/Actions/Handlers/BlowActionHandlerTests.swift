import CustomDump
import GnustoEngine
import Testing

@Suite("BlowActionHandler")
struct BlowActionHandlerTests {
    // MARK: - Test Helpers

    private func createTestEngine() async -> (GameEngine, MockIOHandler) {
        let balloon = Item(
            id: "balloon",
            .name("balloon"),
            .isTakable,
            .in(.player)
        )

        let candle = Item(
            id: "candle",
            .name("candle"),
            .isLightSource,
            .isLit,
            .isTakable,
            .in(.location("testRoom"))
        )

        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .description("A room for testing blow commands."),
            .inherentlyLit
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: [testRoom],
            items: [balloon, candle]
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

    private func createTestEngineWithFlammableItem() async -> (GameEngine, MockIOHandler) {
        let balloon = Item(
            id: "balloon",
            .name("balloon"),
            .isTakable,
            .in(.player)
        )

        let candle = Item(
            id: "candle",
            .name("candle"),
            .isLightSource,
            .isLit,
            .isTakable,
            .in(.location("testRoom"))
        )

        let paper = Item(
            id: "paper",
            .name("paper"),
            .isFlammable,
            .isTakable,
            .in(.location("testRoom"))
        )

        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .description("A room for testing blow commands."),
            .inherentlyLit
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: [testRoom],
            items: [balloon, candle, paper]
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
            .isTakable,
            .in(.player)
        )

        let distantBalloon = Item(
            id: "distantBalloon",
            .name("distant balloon"),
            .isTakable,
            .in(.location("anotherRoom"))
        )

        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .description("A room for testing blow commands."),
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

    @Test("BLOW command without object")
    func testBlowCommandNoObject() async throws {
        let (engine, mockIO) = await createTestEngine()
        let command = Command(verb: .blow, rawInput: "blow")

        // Execute the command through the full pipeline
        await engine.execute(command: command)

        // Check the output
        let output = await mockIO.flush()
        expectNoDifference(output, "You blow air around. Nothing happens.")
    }

    @Test("BLOW command on object")
    func testBlowCommandOnObject() async throws {
        let (engine, mockIO) = await createTestEngine()
        let command = Command(verb: .blow, directObject: .item("balloon"), rawInput: "blow balloon")

        // Execute the command through the full pipeline
        await engine.execute(command: command)

        // Verify balloon is marked as touched
        let balloonAfter = try await engine.item("balloon")
        #expect(balloonAfter.hasFlag(.isTouched))

        // Check the output
        let output = await mockIO.flush()
        #expect(output.contains("You blow on the balloon"))
    }

    @Test("BLOW command on lit light source")
    func testBlowOnLitLightSource() async throws {
        let (engine, mockIO) = await createTestEngine()
        let command = Command(verb: .blow, directObject: .item("candle"), rawInput: "blow candle")

        // Execute the command through the full pipeline
        await engine.execute(command: command)

        // Verify candle is marked as touched
        let candleAfter = try await engine.item("candle")
        #expect(candleAfter.hasFlag(.isTouched))

        // Check the output
        let output = await mockIO.flush()
        #expect(output.contains("You blow on the candle") && output.contains("go out"))
    }

    @Test("BLOW command on flammable object")
    func testBlowOnFlammableObject() async throws {
        let (engine, mockIO) = await createTestEngineWithFlammableItem()
        let command = Command(verb: .blow, directObject: .item("paper"), rawInput: "blow paper")

        // Execute the command through the full pipeline
        await engine.execute(command: command)

        // Verify paper is marked as touched
        let paperAfter = try await engine.item("paper")
        #expect(paperAfter.hasFlag(.isTouched))

        // Check the output
        let output = await mockIO.flush()
        #expect(output.contains("Blowing on the paper has no effect"))
    }

    @Test("BLOW command on inaccessible item")
    func testBlowInaccessibleItem() async throws {
        let (engine, mockIO) = await createTestEngineWithDistantItem()
        let command = Command(verb: .blow, directObject: .item("distantBalloon"), rawInput: "blow distant balloon")

        // Execute the command through the full pipeline
        await engine.execute(command: command)

        // Check that an error message was displayed
        let output = await mockIO.flush()
        #expect(output.contains("any such thing") || output.contains("not accessible") || output.contains("can't see"))
    }
}
