import CustomDump
import GnustoEngine
import GnustoTestSupport
import Testing

@Suite("KissActionHandler Tests")
struct KissActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("KISS DIRECTOBJECT syntax works")
    func testKissDirectObjectSyntax() async throws {
        // Given
        let princess = Item(
            id: "princess",
            .name("beautiful princess"),
            .description("A beautiful princess."),
            .characterSheet(.default),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: princess
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("kiss princess")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > kiss princess
            Your romantic impulses toward the beautiful princess must
            remain unexpressed.
            """
        )

        let finalState = await engine.item("princess")
        #expect(await finalState.hasFlag(.isTouched))
    }

    // MARK: - Validation Testing

    @Test("Cannot kiss without specifying target")
    func testCannotKissWithoutTarget() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("kiss")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > kiss
            Kiss what?
            """
        )
    }

    @Test("Cannot kiss target not in scope")
    func testCannotKissTargetNotInScope() async throws {
        // Given
        let anotherRoom = Location(
            id: "anotherRoom",
            .name("Another Room"),
            .inherentlyLit
        )

        let remotePrincess = Item(
            id: "remotePrincess",
            .name("distant princess"),
            .description("A princess in another room."),
            .characterSheet(.default),
            .in("anotherRoom")
        )

        let game = MinimalGame(
            locations: anotherRoom,
            items: remotePrincess
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("kiss princess")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > kiss princess
            Any such thing lurks beyond your reach.
            """
        )
    }

    @Test("Requires light to kiss")
    func testRequiresLight() async throws {
        // Given: Dark room with character
        let darkRoom = Location(
            id: "darkRoom",
            .name("Dark Room"),
            .description("A pitch black room.")
            // Note: No .inherentlyLit property
        )

        let stranger = Item(
            id: "stranger",
            .name("mysterious stranger"),
            .description("A mysterious stranger."),
            .characterSheet(.default),
            .in("darkRoom")
        )

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom,
            items: stranger
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("kiss stranger")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > kiss stranger
            You stand in a depthless black where even your thoughts seem to
            whisper, careful not to make a sound.
            """
        )
    }

    // MARK: - Processing Testing

    @Test("Kiss self gives appropriate message")
    func testKissSelfGivesAppropriateMessage() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("kiss me")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > kiss me
            Self-affection requires a level of contortion beyond your
            abilities.
            """
        )
    }

    @Test("Kiss friendly character")
    func testKissFriendlyCharacter() async throws {
        // Given
        let friend = Item(
            id: "friend",
            .name("old friend"),
            .description("A dear old friend."),
            .characterSheet(.default),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: friend
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("kiss friend")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > kiss friend
            Your romantic impulses toward the old friend must remain
            unexpressed.
            """
        )

        let finalState = await engine.item("friend")
        #expect(await finalState.hasFlag(.isTouched))
    }

    @Test("Kiss hostile character")
    func testKissHostileCharacter() async throws {
        // Given
        let enemy = Item(
            id: "enemy",
            .name("angry troll"),
            .description("An angry troll."),
            .characterSheet(.init(isFighting: true)),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: enemy
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("kiss troll")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > kiss troll
            Romance and warfare make poor bedfellows, especially with the
            angry troll.

            The enemy attacks with pure murderous intent! You brace
            yourself for the impact, guard up, ready for the worst kind of
            fight.
            """
        )

        let finalState = await engine.item("enemy")
        #expect(await finalState.hasFlag(.isTouched))
    }

    @Test("Kiss inanimate object")
    func testKissInanimateObject() async throws {
        // Given
        let statue = Item(
            id: "statue",
            .name("marble statue"),
            .description("A beautiful marble statue."),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: statue
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("kiss statue")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > kiss statue
            You and the marble statue lack the necessary chemistry.
            """
        )

        let finalState = await engine.item("statue")
        #expect(await finalState.hasFlag(.isTouched))
    }

    @Test("Kiss sets touched flag on target")
    func testKissSetsTouchedFlagOnTarget() async throws {
        // Given
        let cat = Item(
            id: "cat",
            .name("fluffy cat"),
            .description("A fluffy cat."),
            .characterSheet(.default),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: cat
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("kiss cat")

        // Then: Verify state changes
        let finalState = await engine.item("cat")
        #expect(await finalState.hasFlag(.isTouched))

        // Verify message
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > kiss cat
            Your romantic impulses toward the fluffy cat must remain
            unexpressed.
            """
        )
    }

    @Test("Kiss multiple different targets")
    func testKissMultipleDifferentTargets() async throws {
        // Given
        let knight = Item(
            id: "knight",
            .name("brave knight"),
            .description("A brave knight."),
            .characterSheet(.default),
            .in(.startRoom)
        )

        let flower = Item(
            id: "flower",
            .name("red rose"),
            .description("A beautiful red rose."),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: knight, flower
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Kiss character
        try await engine.execute(
            "kiss knight",
            "kiss rose"
        )

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > kiss knight
            Your romantic impulses toward the brave knight must remain
            unexpressed.

            > kiss rose
            The red rose remains unmoved by your romantic overtures.
            """
        )

        // Verify both items were touched
        let knightState = await engine.item("knight")
        let flowerState = await engine.item("flower")
        #expect(await knightState.hasFlag(.isTouched))
        #expect(await flowerState.hasFlag(.isTouched))
    }

    @Test("Kiss item held by player")
    func testKissItemHeldByPlayer() async throws {
        // Given
        let locket = Item(
            id: "locket",
            .name("golden locket"),
            .description("A golden locket."),
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            items: locket
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("kiss locket")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > kiss locket
            You and the golden locket lack the necessary chemistry.
            """
        )

        let finalState = await engine.item("locket")
        #expect(await finalState.playerIsHolding)  // Still held by player
        #expect(await finalState.hasFlag(.isTouched))
    }

    @Test("Kiss different character types")
    func testKissDifferentCharacterTypes() async throws {
        // Given
        let game = MinimalGame(
            items: Lab.merchant, Lab.dragon.fighting, Lab.fairy
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Kiss friendly character
        try await engine.execute(
            "kiss merchant",
            "kiss dragon",
            "kiss fairy"
        )

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > kiss merchant
            Your romantic impulses toward the traveling merchant must
            remain unexpressed.

            The terrible dragon attacks with pure murderous intent! You
            brace yourself for the impact, guard up, ready for the worst
            kind of fight.

            > kiss dragon
            Your lips approaching the terrible dragon would likely meet
            steel rather than flesh.

            The counterstrike comes heavy. The terrible dragon's fist finds
            ribs, and pain blooms like fire through your chest. First blood
            to them. The wound is real but manageable.

            > kiss fairy
            The moment for kissing the woodland fairy has neither arrived
            nor been invited.

            The terrible dragon's brutal retaliation stops you short, the
            raw violence of it shaking your confidence to its core.
            """
        )

        // Verify all characters were touched
        let merchantState = await engine.item("merchant")
        let dragonState = await engine.item("dragon")
        let fairyState = await engine.item("fairy")
        #expect(await merchantState.hasFlag(.isTouched))
        #expect(await dragonState.hasFlag(.isTouched))
        #expect(await fairyState.hasFlag(.isTouched))
    }

    @Test("Kiss various objects gives romantic message")
    func testKissVariousObjectsGivesRomanticMessage() async throws {
        // Given
        let mirror = Item(
            id: "mirror",
            .name("magic mirror"),
            .description("A magic mirror."),
            .in(.startRoom)
        )

        let painting = Item(
            id: "painting",
            .name("beautiful painting"),
            .description("A beautiful painting."),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: mirror, painting
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Kiss mirror
        try await engine.execute(
            "kiss mirror",
            "kiss painting"
        )

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > kiss mirror
            You and the magic mirror lack the necessary chemistry.

            > kiss painting
            The beautiful painting remains unmoved by your romantic
            overtures.
            """
        )
    }

    // MARK: - Intent Testing

    @Test("Handler exposes correct Verbs")
    func testVerbs() async throws {
        let handler = KissActionHandler()
        #expect(handler.synonyms.contains(.kiss))
        #expect(handler.synonyms.count == 1)
    }

    @Test("Handler requires light")
    func testRequiresLightProperty() async throws {
        let handler = KissActionHandler()
        #expect(handler.requiresLight == true)
    }
}
