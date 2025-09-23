import CustomDump
import GnustoEngine
import GnustoTestSupport
import Testing

@Suite("ExtinguishActionHandler Tests")
struct ExtinguishActionHandlerTests {

    // MARK: - Syntax Tests

    @Test("BLOW OUT syntax works")
    func testBlowOutSyntax() async throws {
        // Given
        let candle = Item(
            id: "candle",
            .name("small candle"),
            .description("A small wax candle."),
            .isTakable,
            .isLightSource,
            .isBurning,
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: candle
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("blow out candle")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > blow out candle
            You blow out the small candle.
            """
        )

        let finalCandle = await engine.item("candle")
        #expect(await finalCandle.hasFlag(.isBurning) == false)
        #expect(await finalCandle.isTouched)
    }

    @Test("EXTINGUISH syntax works")
    func testExtinguishSyntax() async throws {
        // Given
        let torch = Item(
            id: "torch",
            .name("wooden torch"),
            .description("A wooden torch with a burning tip."),
            .isTakable,
            .isLightSource,
            .isBurning,
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: torch
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("extinguish torch")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > extinguish torch
            You extinguish the wooden torch.
            """
        )

        let finalTorch = await engine.item("torch")
        #expect(await finalTorch.hasFlag(.isBurning) == false)
        #expect(await finalTorch.isTouched)
    }

    @Test("DOUSE synonym works")
    func testDouseSyntax() async throws {
        // Given
        let fire = Item(
            id: "fire",
            .name("small fire"),
            .description("A small crackling fire."),
            .isBurning,
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: fire
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("douse fire")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > douse fire
            You douse the small fire.
            """
        )

        let finalFire = await engine.item("fire")
        #expect(await finalFire.hasFlag(.isBurning) == false)
        #expect(await finalFire.isTouched)
    }

    // MARK: - Validation Tests

    @Test("Cannot extinguish without target")
    func testCannotExtinguishWithoutTarget() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("extinguish")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > extinguish
            Extinguish what?
            """
        )
    }

    @Test("Cannot extinguish target not in scope")
    func testCannotExtinguishTargetNotInScope() async throws {
        // Given
        let otherRoom = Location(
            id: "otherRoom",
            .name("Other Room"),
            .inherentlyLit
        )

        let candle = Item(
            id: "candle",
            .name("small candle"),
            .description("A small wax candle."),
            .isBurning,
            .in("otherRoom")
        )

        let game = MinimalGame(
            locations: otherRoom,
            items: candle
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("extinguish candle")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > extinguish candle
            Any such thing lurks beyond your reach.
            """
        )
    }

    @Test("Requires light to extinguish")
    func testRequiresLight() async throws {
        // Given
        let darkRoom = Location(
            id: "darkRoom",
            .name("Dark Room"),
            .description("A room that is pitch black.")
        )

        let candle = Item(
            id: "candle",
            .name("small candle"),
            .description("A small wax candle."),
            .isBurning,
            .in("darkRoom")
        )

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom,
            items: candle
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("extinguish candle")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > extinguish candle
            You extinguish the small candle.

            Darkness rushes in like a living thing.

            This is the kind of dark that swallows shapes and edges,
            leaving only breath and heartbeat to prove you exist.
            """
        )
    }

    // MARK: - Light Source Tests

    @Test("Extinguish lit light source clears isOn and isBurning")
    func testExtinguishLitLightSource() async throws {
        // Given
        let lamp = Item(
            id: "lamp",
            .name("oil lamp"),
            .description("A brass oil lamp."),
            .isTakable,
            .isLightSource,
            .isBurning,
            .isOn,
            .in(.player)
        )

        let game = MinimalGame(
            items: lamp
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("extinguish lamp")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > extinguish lamp
            You extinguish the oil lamp.
            """
        )

        let finalLamp = await engine.item("lamp")
        #expect(await finalLamp.hasFlag(.isBurning) == false)
        #expect(await finalLamp.hasFlag(.isOn) == false)
        #expect(await finalLamp.isTouched)
    }

    @Test("Extinguish light source that is not lit")
    func testExtinguishUnlitLightSource() async throws {
        // Given
        let torch = Item(
            id: "torch",
            .name("wooden torch"),
            .description("A wooden torch with an unlit tip."),
            .isTakable,
            .isLightSource,
            .in(.player)
        )

        let game = MinimalGame(
            items: torch
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("extinguish torch")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > extinguish torch
            The wooden torch refuses to be extinguished.
            """
        )

        let finalTorch = await engine.item("torch")
        #expect(await finalTorch.hasFlag(.isBurning) == false)
        #expect(await finalTorch.hasFlag(.isOn) == false)
        #expect(await finalTorch.hasFlag(.isTouched) == false)
    }

    // MARK: - Regular Flammable Item Tests

    @Test("Extinguish burning regular item")
    func testExtinguishBurningRegularItem() async throws {
        // Given
        let paper = Item(
            id: "paper",
            .name("piece of paper"),
            .description("A sheet of paper."),
            .isTakable,
            .isBurning,
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: paper
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("extinguish paper")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > extinguish paper
            You extinguish the piece of paper.
            """
        )

        let finalPaper = await engine.item("paper")
        #expect(await finalPaper.hasFlag(.isBurning) == false)
        #expect(await finalPaper.isTouched)
    }

    @Test("Extinguish non-burning regular item")
    func testExtinguishNonBurningRegularItem() async throws {
        // Given
        let book = Item(
            id: "book",
            .name("leather book"),
            .description("A worn leather-bound book."),
            .isTakable,
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: book
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("extinguish book")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > extinguish book
            The leather book refuses to be extinguished.
            """
        )

        let finalBook = await engine.item("book")
        #expect(await finalBook.hasFlag(.isBurning) == false)
        #expect(await finalBook.hasFlag(.isTouched) == false)
    }

    // MARK: - Touched Flag Tests

    @Test("Touched flag always set on successful extinguish")
    func testTouchedFlagAlwaysSet() async throws {
        // Given
        let candle = Item(
            id: "candle",
            .name("wax candle"),
            .description("A simple wax candle."),
            .isTakable,
            .isBurning,
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: candle
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        // Verify item starts without touched flag
        let initialCandle = await engine.item("candle")
        #expect(await initialCandle.hasFlag(.isTouched) == false)

        // When
        try await engine.execute("extinguish candle")

        // Then
        let finalCandle = await engine.item("candle")
        #expect(await finalCandle.isTouched)
    }

    // MARK: - Multiple Item Tests

    @Test("Extinguish specific item when multiple burning items present")
    func testExtinguishSpecificItem() async throws {
        // Given
        let candle = Item(
            id: "candle",
            .name("small candle"),
            .description("A small wax candle."),
            .isBurning,
            .in(.startRoom)
        )

        let torch = Item(
            id: "torch",
            .name("wooden torch"),
            .description("A wooden torch."),
            .isBurning,
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: candle, torch
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("extinguish candle")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > extinguish candle
            You extinguish the small candle.
            """
        )

        let finalCandle = await engine.item("candle")
        let finalTorch = await engine.item("torch")
        #expect(await finalCandle.hasFlag(.isBurning) == false)
        #expect(await finalTorch.hasFlag(.isBurning) == true)
    }

    // MARK: - Dark Room Tests

    @Test("Can extinguish in dark room while holding lit light source")
    func testCanExtinguishInDarkRoomWithOtherLight() async throws {
        // Given
        let darkRoom = Location(
            id: "darkRoom",
            .name("Dark Room"),
            .description("A room that is pitch black.")
        )

        let heldLamp = Item(
            id: "heldLamp",
            .name("oil lamp"),
            .description("A brass oil lamp."),
            .isLightSource,
            .isOn,
            .in(.player)
        )

        let candle = Item(
            id: "candle",
            .name("small candle"),
            .description("A small wax candle."),
            .isBurning,
            .in("darkRoom")
        )

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom,
            items: heldLamp, candle
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("extinguish candle")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > extinguish candle
            You extinguish the small candle.
            """
        )

        let finalCandle = await engine.item("candle")
        #expect(await finalCandle.hasFlag(.isBurning) == false)
    }

    @Test("Can extinguish in dark room without other light source")
    func testCanExtinguishInDarkRoom() async throws {
        // Given
        let darkRoom = Location(
            id: "darkRoom",
            .name("Dark Room"),
            .description("A room that is pitch black.")
        )

        let candle = Item(
            id: "candle",
            .name("small candle"),
            .description("A small wax candle."),
            .isBurning,
            .in("darkRoom")
        )

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom,
            items: candle
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("extinguish candle")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > extinguish candle
            You extinguish the small candle.

            Darkness rushes in like a living thing.

            This is the kind of dark that swallows shapes and edges,
            leaving only breath and heartbeat to prove you exist.
            """
        )

        let finalCandle = await engine.item("candle")
        #expect(await finalCandle.hasFlag(.isBurning) == false)
    }

    // MARK: - Handler Property Tests

    @Test("Handler properties are correct")
    func testHandlerProperties() async throws {
        let handler = ExtinguishActionHandler()
        #expect(handler.requiresLight == true)
        #expect(handler.synonyms == [.extinguish, .douse])
    }

    @Test("Syntax rules are correct")
    func testSyntaxRules() async throws {
        let handler = ExtinguishActionHandler()
        let expectedSyntax: [SyntaxRule] = [
            .match(.blow, .out, .directObject),
            .match(.verb, .directObject),
        ]
        #expect(handler.syntax == expectedSyntax)
    }

    @Test("Handler registration in default handlers")
    func testHandlerRegistration() async throws {
        let defaultHandlers = GameEngine.defaultActionHandlers
        #expect(defaultHandlers.contains { $0 is ExtinguishActionHandler })
    }

    @Test("All synonyms work")
    func testAllSynonyms() async throws {
        // Given
        let candle = Item(
            id: "candle",
            .name("small candle"),
            .description("A small wax candle."),
            .isBurning,
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: candle
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Test each synonym
        for verb in ["extinguish", "douse"] {
            let candleProxy = await candle.proxy(engine)

            // Reset candle state
            try await engine.apply(
                candleProxy.setFlag(.isBurning),
                candleProxy.clearFlag(.isTouched)
            )

            // When
            try await engine.execute("\(verb) candle")
        }

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > extinguish candle
            You extinguish the small candle.

            > douse candle
            You douse the small candle.
            """
        )

        let finalCandle = await engine.item("candle")
        #expect(await finalCandle.hasFlag(.isBurning) == false)
    }
}
