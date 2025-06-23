import CustomDump
import GnustoEngine
import Testing

@Suite("BlowActionHandler")
struct BlowActionHandlerTests {
    @Test("BLOW command without object")
    func testBlowCommandNoObject() async throws {
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
            .in(.location(.startRoom))
        )

        let game = MinimalGame(
            items: balloon, candle
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Execute the command through the full pipeline
        try await engine.execute("blow")

        // Check the output
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > blow
            You blow the air around, but nothing interesting happens.
            """)
    }

    @Test("BLOW command (on) object")
    func testBlowCommandObject() async throws {
        let balloon = Item(
            id: "balloon",
            .name("balloon"),
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(items: balloon)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Execute the command through the full pipeline
        try await engine.execute("blow balloon")

        // Verify balloon is marked as touched
        let balloonAfter = try await engine.item("balloon")
        #expect(balloonAfter.hasFlag(.isTouched))

        // Check the output
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > blow balloon
            You blow on the balloon, but nothing interesting happens.
            """)
    }

    @Test("BLOW command on object")
    func testBlowCommandOnObject() async throws {
        let balloon = Item(
            id: "balloon",
            .name("balloon"),
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(items: balloon)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Execute the command through the full pipeline
        try await engine.execute("blow on the balloon")

        // Verify balloon is marked as touched
        let balloonAfter = try await engine.item("balloon")
        #expect(balloonAfter.hasFlag(.isTouched))

        // Check the output
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > blow on the balloon
            You blow on the balloon, but nothing interesting happens.
            """)
    }

    @Test("BLOW command up object")
    func testBlowCommandUpObject() async throws {
        let tire = Item(
            id: "tire",
            .name("tire"),
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(items: tire)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Execute the command through the full pipeline
        try await engine.execute("blow up the tire")

        // Attempt fails, so tire is not marked as touched
        let tireAfter = try await engine.item("tire")
        #expect(!tireAfter.hasFlag(.isTouched))

        // Check the output
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > blow up the tire
            You can’t inflate the tire.
            """)
    }

    @Test("BLOW command on lit light source")
    func testBlowOnLitLightSource() async throws {
        let candle = Item(
            id: "candle",
            .name("candle"),
            .isLightSource,
            .isFlammable,
            .isLit,
            .isTakable,
            .in(.location(.startRoom))
        )

        let game = MinimalGame(items: candle)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Execute the command through the full pipeline
        try await engine.execute("blow candle")

        // Verify candle is marked as touched
        let candleAfter = try await engine.item("candle")
        #expect(candleAfter.hasFlag(.isTouched))

        // Check the output:
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > blow candle
            You blow on the candle, but it doesn’t go out.
            """)
    }

    @Test("BLOW command on flammable object")
    func testBlowOnFlammableObject() async throws {
        let paper = Item(
            id: "paper",
            .name("paper"),
            .isFlammable,
            .isTakable,
            .in(.location(.startRoom))
        )

        let game = MinimalGame(items: paper)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Execute the command through the full pipeline
        try await engine.execute("blow paper")

        // Verify paper is marked as touched
        let paperAfter = try await engine.item("paper")
        #expect(paperAfter.hasFlag(.isTouched))

        // Check the output
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > blow paper
            Blowing on the paper has no effect.
            """)
    }

    @Test("BLOW command on inaccessible item")
    func testBlowInaccessibleItem() async throws {
        let balloon = Item(
            id: "balloon",
            .name("held balloon"),
            .synonyms("held", "balloon"),
            .isTakable,
            .in(.player)
        )

        let distantBalloon = Item(
            id: "distantBalloon",
            .name("distant balloon"),
            .synonyms("distant", "balloon"),
            .isTakable,
            .in(.location("anotherRoom")),
            .isTouched
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
            locations: testRoom, anotherRoom,
            items: balloon, distantBalloon
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Execute the command through the full pipeline
        try await engine.execute("blow on the distant balloon")

        // Check that an error message was displayed
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > blow on the distant balloon
            You can’t see the distant balloon.
            """)
    }
}
