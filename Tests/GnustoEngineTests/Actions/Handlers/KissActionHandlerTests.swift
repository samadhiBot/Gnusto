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
        await mockIO.expectOutput(
            """
            > kiss princess
            The moment for kissing the beautiful princess has neither
            arrived nor been invited.
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
        await mockIO.expectOutput(
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
        await mockIO.expectOutput(
            """
            > kiss princess
            You cannot reach any such thing from here.
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
        await mockIO.expectOutput(
            """
            > kiss stranger
            The darkness here is absolute, consuming all light and hope of
            sight.
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
        await mockIO.expectOutput(
            """
            > kiss me
            Your flexibility, while admirable, has limits.
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
        await mockIO.expectOutput(
            """
            > kiss friend
            The moment for kissing the old friend has neither arrived nor
            been invited.
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
        await mockIO.expectOutput(
            """
            > kiss troll
            That's an unusual combat strategy, and the angry troll seems
            unlikely to reciprocate.

            No weapons between you--just the enemy's aggression and your
            desperation! You collide in a tangle of strikes and blocks.
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
        await mockIO.expectOutput(
            """
            > kiss statue
            Your lips and the marble statue are destined never to meet.
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
        await mockIO.expectOutput(
            """
            > kiss cat
            The moment for kissing the fluffy cat has neither arrived nor
            been invited.
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
        await mockIO.expectOutput(
            """
            > kiss knight
            The moment for kissing the brave knight has neither arrived nor
            been invited.

            > kiss rose
            Your lips and the red rose are destined never to meet.
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
        await mockIO.expectOutput(
            """
            > kiss locket
            Your lips and the golden locket are destined never to meet.
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
        await mockIO.expectOutput(
            """
            > kiss merchant
            The moment for kissing the traveling merchant has neither
            arrived nor been invited.

            In a moment of raw violence, the terrible dragon comes at you
            with nothing but fury! You raise your fists, knowing this will
            hurt regardless of who wins.

            > kiss dragon
            That's an unusual combat strategy, and the terrible dragon
            seems unlikely to reciprocate.

            In the tangle, the terrible dragon drives an elbow home--sudden
            pressure that blooms into dull pain. Pain flickers and dies.
            Your body has more important work.

            > kiss fairy
            The moment for kissing the woodland fairy has neither arrived
            nor been invited.

            The terrible dragon's answer is swift and punishing--knuckles
            meet flesh with the sound of meat hitting stone. You grunt from
            the impact but maintain your stance.
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
        await mockIO.expectOutput(
            """
            > kiss mirror
            Your lips and the magic mirror are destined never to meet.

            > kiss painting
            Your lips and the beautiful painting are destined never to
            meet.
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
