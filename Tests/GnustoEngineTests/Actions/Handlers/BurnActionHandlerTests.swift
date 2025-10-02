import CustomDump
import GnustoEngine
import GnustoTestSupport
import Testing

@Suite("BurnActionHandler Tests")
struct BurnActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("BURN DIRECTOBJECT syntax works")
    func testBurnDirectObjectSyntax() async throws {
        // Given
        let paper = Item("paper")
            .name("piece of paper")
            .description("A piece of paper.")
            .isTakable
            .in(.startRoom)

        let game = MinimalGame(
            items: paper
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("burn paper")

        // Then
        await mockIO.expect(
            """
            > burn paper
            The piece of paper stubbornly resists your attempts to burn it.
            """
        )
    }

    @Test("BURN DIRECTOBJECT WITH INDIRECTOBJECT syntax works")
    func testBurnWithSyntax() async throws {
        // Given
        let paper = Item("paper")
            .name("piece of paper")
            .description("A piece of paper.")
            .isTakable
            .in(.startRoom)

        let match = Item("match")
            .name("wooden match")
            .description("A wooden match.")
            .isTakable
            .in(.player)

        let game = MinimalGame(
            items: paper, match
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("burn paper with match")

        // Then
        await mockIO.expect(
            """
            > burn paper with match
            You can't burn the piece of paper with the wooden match.
            """
        )
    }

    @Test("IGNITE syntax works")
    func testIgniteSyntax() async throws {
        // Given
        let wood = Item("wood")
            .name("dry wood")
            .description("Some dry wood.")
            .isTakable
            .in(.startRoom)

        let game = MinimalGame(
            items: wood
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("ignite wood")

        // Then
        await mockIO.expect(
            """
            > ignite wood
            The dry wood stubbornly resists your attempts to ignite it.
            """
        )
    }

    @Test("LIGHT syntax works")
    func testLightSyntax() async throws {
        // Given
        let tinder = Item("tinder")
            .name("dry tinder")
            .description("Some dry tinder.")
            .isTakable
            .in(.startRoom)

        let game = MinimalGame(
            items: tinder
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("light tinder")

        // Then
        await mockIO.expect(
            """
            > light tinder
            The dry tinder stubbornly resists your attempts to light it.
            """
        )
    }

    // MARK: - Validation Testing

    @Test("Cannot burn without specifying target")
    func testCannotBurnWithoutTarget() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("burn")

        // Then
        await mockIO.expect(
            """
            > burn
            Burn what?
            """
        )
    }

    @Test("Cannot burn target not in scope")
    func testCannotBurnTargetNotInScope() async throws {
        // Given
        let anotherRoom = Location("anotherRoom")
            .name("Another Room")
            .inherentlyLit

        let remotePaper = Item("remotePaper")
            .name("remote paper")
            .description("Paper in another room.")
            .isTakable
            .in("anotherRoom")

        let game = MinimalGame(
            locations: anotherRoom,
            items: remotePaper
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("burn paper")

        // Then
        await mockIO.expect(
            """
            > burn paper
            Any such thing lurks beyond your reach.
            """
        )
    }

    @Test("Can burn in dark room since requiresLight is false")
    func testCanBurnInDarkRoom() async throws {
        // Given: Dark room with item held by player
        let darkRoom = Location("darkRoom")
            .name("Dark Room")
            .description("A pitch black room.")

        let paper = Item("paper")
            .name("piece of paper")
            .description("A piece of paper.")
            .isTakable
            .in(.player)

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom,
            items: paper
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("burn paper")

        // Then
        await mockIO.expect(
            """
            > burn paper
            The piece of paper stubbornly resists your attempts to burn it.
            """
        )
    }

    @Test("Indirect object must be held by player")
    func testIndirectObjectMustBeHeld() async throws {
        // Given
        let paper = Item("paper")
            .name("piece of paper")
            .description("A piece of paper.")
            .isTakable
            .in(.player)

        let match = Item("match")
            .name("wooden match")
            .description("A wooden match.")
            .isTakable
            .in(.startRoom)  // Not held by player

        let game = MinimalGame(
            items: paper, match
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("burn paper with match")

        // Then
        await mockIO.expect(
            """
            > burn paper with match
            You aren't holding the wooden match.
            """
        )
    }

    // MARK: - Light Source Processing

    @Test("Light source that is not flammable falls through to regular burn")
    func testNonFlammableLightSource() async throws {
        // Given
        let flashlight = Item("flashlight")
            .name("electric flashlight")
            .description("A battery-powered flashlight.")
            .isLightSource  // Light source but NOT flammable
            .isDevice
            .isTakable
            .in(.player)

        let game = MinimalGame(
            items: flashlight
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("light flashlight")

        // Then
        await mockIO.expect(
            """
            > light flashlight
            You light the electric flashlight.
            """
        )

        let finalFlashlight = await engine.item("flashlight")
        #expect(await finalFlashlight.hasFlag(.isTouched) == true)
        #expect(await finalFlashlight.hasFlag(.isBurning) == false)
    }

    @Test("Already lit light source gives appropriate message")
    func testAlreadyLitLightSource() async throws {
        // Given
        let torch = Item("torch")
            .name("wooden torch")
            .description("A wooden torch.")
            .isLightSource
            .isFlammable
            .isTakable
            .in(.player)

        let game = MinimalGame(
            items: torch
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Set torch to already be lit
        try await engine.apply(
            torch.proxy(engine).setFlag(.isBurning)
        )

        // When
        try await engine.execute("light torch")

        // Then
        await mockIO.expect(
            """
            > light torch
            The wooden torch already dances with flame.
            """
        )
    }

    @Test("Self-ignitable light source can be lit directly")
    func testSelfIgnitableLightSource() async throws {
        // Given
        let candle = Item("candle")
            .name("white candle")
            .description("A white wax candle.")
            .isLightSource
            .isFlammable
            .isSelfIgnitable
            .isTakable
            .in(.player)

        let game = MinimalGame(
            items: candle
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("light candle")

        // Then
        await mockIO.expect(
            """
            > light candle
            You light the white candle. You can see your surroundings now.
            """
        )

        let finalCandle = await engine.item("candle")
        #expect(await finalCandle.hasFlag(.isBurning) == true)
        #expect(await finalCandle.hasFlag(.isTouched) == true)
    }

    @Test("Flammable light source requires igniter when not self-ignitable")
    func testFlammableLightSourceRequiresIgniter() async throws {
        // Given
        let torch = Item("torch")
            .name("wooden torch")
            .description("A wooden torch.")
            .isLightSource
            .isFlammable
            // Note: NOT self-ignitable
            .isTakable
            .in(.player)

        let game = MinimalGame(
            items: torch
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("light torch")

        // Then
        await mockIO.expect(
            """
            > light torch
            You need something to light the wooden torch with.
            """
        )
    }

    @Test("Light source can be ignited with burning item")
    func testLightSourceWithBurningIgniter() async throws {
        // Given
        let torch = Item("torch")
            .name("wooden torch")
            .description("A wooden torch.")
            .isLightSource
            .isFlammable
            .isTakable
            .in(.player)

        let match = Item("match")
            .name("lit match")
            .description("A burning match.")
            .isTakable
            .in(.player)

        let game = MinimalGame(
            items: torch, match
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Set match to be burning
        try await engine.apply(
            match.proxy(engine).setFlag(.isBurning)
        )

        // When
        try await engine.execute("light torch with match")

        // Then
        await mockIO.expect(
            """
            > light torch with match
            You light the wooden torch. You can see your surroundings now.
            """
        )

        let finalTorch = await engine.item("torch")
        let finalMatch = await engine.item("match")
        #expect(await finalTorch.hasFlag(.isBurning) == true)
        #expect(await finalTorch.hasFlag(.isTouched) == true)
        #expect(await finalMatch.hasFlag(.isTouched) == true)
    }

    @Test("Light source can be ignited with self-ignitable item")
    func testLightSourceWithSelfIgnitableIgniter() async throws {
        // Given
        let torch = Item("torch")
            .name("wooden torch")
            .description("A wooden torch.")
            .isLightSource
            .isFlammable
            .isTakable
            .in(.player)

        let lighter = Item("lighter")
            .name("cigarette lighter")
            .description("A disposable lighter.")
            .isSelfIgnitable
            .isTakable
            .in(.player)

        let game = MinimalGame(
            items: torch, lighter
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("light torch with lighter")

        // Then
        await mockIO.expect(
            """
            > light torch with lighter
            You light the wooden torch. You can see your surroundings now.
            """
        )

        let finalTorch = await engine.item("torch")
        let finalLighter = await engine.item("lighter")
        #expect(await finalTorch.hasFlag(.isBurning) == true)
        #expect(await finalTorch.hasFlag(.isTouched) == true)
        #expect(await finalLighter.hasFlag(.isTouched) == true)
    }

    @Test("Invalid igniter cannot light source")
    func testInvalidIgniter() async throws {
        // Given
        let torch = Item("torch")
            .name("wooden torch")
            .description("A wooden torch.")
            .isLightSource
            .isFlammable
            .isTakable
            .in(.player)

        let rock = Item("rock")
            .name("granite rock")
            .description("A hard granite rock.")
            .isTakable
            .in(.player)

        let game = MinimalGame(
            items: torch, rock
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("light torch with rock")

        // Then
        await mockIO.expect(
            """
            > light torch with rock
            You can't light the wooden torch with the granite rock.
            """
        )
    }

    // MARK: - Regular Item Processing

    @Test("Regular item gives generic burn message")
    func testRegularItemBurn() async throws {
        // Given
        let book = Item("book")
            .name("leather book")
            .description("A worn leather book.")
            .isTakable
            .in(.player)

        let game = MinimalGame(
            items: book
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("burn book")

        // Then
        await mockIO.expect(
            """
            > burn book
            The leather book stubbornly resists your attempts to burn it.
            """
        )
    }

    @Test("Regular item with held tool gives tool message")
    func testRegularItemWithHeldTool() async throws {
        // Given
        let paper = Item("paper")
            .name("piece of paper")
            .description("A piece of paper.")
            .isTakable
            .in(.player)

        let match = Item("match")
            .name("wooden match")
            .description("A wooden match.")
            .isSelfIgnitable
            .isTakable
            .in(.player)

        let game = MinimalGame(
            items: paper, match
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("burn paper with match")

        // Then
        await mockIO.expect(
            """
            > burn paper with match
            The wooden match proves woefully inadequate as an implement of
            combustion for the piece of paper.
            """
        )
    }

    // MARK: - Character and Enemy Processing

    @Test("Burning character gives character-specific message")
    func testBurnCharacter() async throws {
        // Given
        let wizard = Item("wizard")
            .name("wise wizard")
            .description("A wise old wizard.")
            .characterSheet(.wise)
            .in(.startRoom)

        let game = MinimalGame(
            items: wizard
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("burn wizard")

        // Then
        await mockIO.expect(
            """
            > burn wizard
            That would be needlessly cruel.
            """
        )
    }

    @Test("Burning enemy gives enemy-specific message")
    func testBurnEnemy() async throws {
        // Given
        let torch = Item("torch")
            .name("flaming torch")
            .isFlammable
            .isBurning
            .isLightSource
            .in(.player)

        let game = MinimalGame(
            items: Lab.troll, torch
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute(
            "look",
            "burn the troll",
            "attack the troll",
            "burn the troll",
        )

        // Then
        await mockIO.expect(
            """
            > look
            --- Laboratory ---

            A laboratory in which strange experiments are being conducted.

            There is a fierce troll here.

            > burn the troll
            That would be needlessly cruel.

            > attack the troll
            You drive forward with your flaming torch seeking its purpose
            as the fearsome beast meets you barehanded, flesh against steel
            in the oldest gamble.

            Your flaming torch swings wide, and the fearsome creature
            avoids your poorly aimed strike with ease.

            The angry beast counters with a force that shatters your guard,
            leaving you exposed to whatever violence comes next.

            > burn the troll
            Your flaming torch inflicts a light wound on the creature, more
            sting than damage. He registers the wound with annoyance.

            The monster's answer is swift and punishing -- knuckles meet
            flesh with the sound of meat hitting stone. The blow lands
            solidly, drawing blood. You feel the sting but remain strong.
            """
        )

        let finalTroll = await engine.item("troll")
        #expect(await finalTroll.hasFlag(.isTouched) == true)
    }

    @Test("Burning character with tool gives tool message")
    func testBurnCharacterWithTool() async throws {
        // Given
        let palaceGuard = Item("guard")
            .name("palace guard")
            .description("A stern palace guard.")
            .characterSheet(.strong)
            .in(.startRoom)

        let torch = Item("torch")
            .name("burning torch")
            .description("A lit torch.")
            .isBurning
            .isTakable
            .in(.player)

        let game = MinimalGame(
            items: palaceGuard, torch
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("burn guard with torch")

        // Then
        await mockIO.expect(
            """
            > burn guard with torch
            The burning torch proves woefully inadequate as an implement of
            combustion for the palace guard.
            """
        )

        let finalGuard = await engine.item("guard")
        #expect(await finalGuard.hasFlag(.isTouched) == true)
    }

    // MARK: - Properties and Configuration Testing

    @Test("Handler has correct properties")
    func testHandlerProperties() async throws {
        let handler = BurnActionHandler()

        #expect(handler.requiresLight == false)
        #expect(handler.synonyms.contains(.burn))
        #expect(handler.synonyms.contains(.ignite))
        #expect(handler.synonyms.contains(.light))
        #expect(handler.synonyms.count == 3)
    }

    @Test("Handler syntax rules")
    func testSyntaxRules() async throws {
        let handler = BurnActionHandler()

        expectNoDifference(
            handler.syntax,
            [
                .match(.verb, .directObject),
                .match(.verb, .directObject, .with, .indirectObject),
            ])
    }

    @Test("Handler is registered in engine")
    func testHandlerRegistration() async throws {
        let handlers = GameEngine.defaultActionHandlers
        let burnHandlers = handlers.compactMap { $0 as? BurnActionHandler }

        #expect(burnHandlers.count == 1)
    }

    // MARK: - Integration Testing

    @Test("All synonyms work correctly")
    func testAllSynonyms() async throws {
        // Given
        let paper = Item("paper")
            .name("piece of paper")
            .description("A piece of paper.")
            .isTakable
            .in(.player)

        let game = MinimalGame(
            items: paper
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When - Test all synonyms
        try await engine.execute("burn paper")
        try await engine.execute("ignite paper")
        try await engine.execute("light paper")

        // Then
        await mockIO.expect(
            """
            > burn paper
            The piece of paper stubbornly resists your attempts to burn it.

            > ignite paper
            You cannot ignite the piece of paper, much as you might wish
            otherwise.

            > light paper
            The universe denies your request to light the piece of paper.
            """
        )
    }

    @Test("Cannot burn with nonexistent tool")
    func testCannotBurnWithNonexistentTool() async throws {
        // Given
        let paper = Item("paper")
            .name("piece of paper")
            .description("A piece of paper.")
            .isTakable
            .in(.player)

        let game = MinimalGame(
            items: paper
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("burn paper with unicorn")

        // Then
        await mockIO.expect(
            """
            > burn paper with unicorn
            Any such thing lurks beyond your reach.
            """
        )
    }

    @Test("Light source igniting in dark room shows room description")
    func testLightSourceInDarkRoom() async throws {
        // Given - Dark room
        let darkRoom = Location("darkRoom")
            .name("Dark Room")
            .description("A room shrouded in darkness.")
        // Note: No .inherentlyLit flag

        let candle = Item("candle")
            .name("white candle")
            .description("A white wax candle.")
            .isLightSource
            .isFlammable
            .isSelfIgnitable
            .isTakable
            .in(.player)

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom,
            items: candle
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("light candle")

        // Then
        await mockIO.expect(
            """
            > light candle
            You light the white candle. You can see your surroundings now.

            --- Dark Room ---

            A room shrouded in darkness.
            """
        )

        let finalCandle = await engine.item("candle")
        #expect(await finalCandle.hasFlag(.isBurning) == true)
    }
}
