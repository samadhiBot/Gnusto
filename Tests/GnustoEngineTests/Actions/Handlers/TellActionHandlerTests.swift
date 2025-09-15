import CustomDump
import GnustoEngine
import GnustoTestSupport
import Testing

@Suite("TellActionHandler Tests")
struct TellActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("TELL DIRECTOBJECT syntax works")
    func testTellDirectObjectSyntax() async throws {
        // Given
        let wizard = Item(
            id: "wizard",
            .name("old wizard"),
            .description("A wise old wizard."),
            .characterSheet(.wise),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: wizard
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("tell wizard")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > tell wizard
            The old wizard awaits the subject of your discourse.
            """
        )

        let finalState = try await engine.item("wizard")
        #expect(await finalState.hasFlag(.isTouched) == true)
    }

    @Test("TELL DIRECTOBJECT ABOUT INDIRECTOBJECT syntax works")
    func testTellAboutSyntax() async throws {
        // Given
        let sage = Item(
            id: "sage",
            .name("wise sage"),
            .description("A knowledgeable sage."),
            .characterSheet(.default),
            .in(.startRoom)
        )

        let crystal = Item(
            id: "crystal",
            .name("magic crystal"),
            .description("A glowing crystal."),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: sage, crystal
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("tell sage about crystal")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > tell sage about crystal
            The wise sage absorbs your words about the magic crystal with
            thoughtful consideration.
            """
        )

        let finalState = try await engine.item("sage")
        #expect(await finalState.hasFlag(.isTouched) == true)
    }

    @Test("SPEAK TO DIRECTOBJECT ABOUT INDIRECTOBJECT syntax works")
    func testSpeakToAboutSyntax() async throws {
        // Given
        let palaceGuard = Item(
            id: "guard",
            .name("palace guard"),
            .description("A stern palace guard."),
            .characterSheet(.default),
            .in(.startRoom)
        )

        let key = Item(
            id: "key",
            .name("silver key"),
            .description("A small silver key."),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: palaceGuard, key
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("speak to guard about key")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > speak to guard about key
            The palace guard absorbs your words about the silver key with
            thoughtful consideration.
            """
        )
    }

    @Test("TALK TO DIRECTOBJECT ABOUT INDIRECTOBJECT syntax works")
    func testTalkToAboutSyntax() async throws {
        // Given
        let merchant = Item(
            id: "merchant",
            .name("traveling merchant"),
            .description("A traveling merchant."),
            .characterSheet(.default),
            .in(.startRoom)
        )

        let treasure = Item(
            id: "treasure",
            .name("ancient treasure"),
            .description("A chest of ancient treasure."),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: merchant, treasure
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("talk to merchant about treasure")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > talk to merchant about treasure
            The traveling merchant absorbs your words about the ancient
            treasure with thoughtful consideration.
            """
        )
    }

    @Test("SAY INDIRECTOBJECT TO DIRECTOBJECT syntax works")
    func testSaySyntax() async throws {
        // Given
        let priest = Item(
            id: "priest",
            .name("village priest"),
            .description("A kindly village priest."),
            .characterSheet(.default),
            .in(.startRoom)
        )

        let blessing = Item(
            id: "blessing",
            .name("prayer blessing"),
            .description("A sacred blessing."),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: priest, blessing
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("say blessing to priest")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > say blessing to priest
            The village priest absorbs your words about the prayer blessing
            with thoughtful consideration.
            """
        )
    }

    @Test("INFORM syntax works")
    func testInformSyntax() async throws {
        // Given
        let scholar = Item(
            id: "scholar",
            .name("learned scholar"),
            .description("A learned scholar."),
            .characterSheet(.default),
            .in(.startRoom)
        )

        let book = Item(
            id: "book",
            .name("ancient book"),
            .description("An ancient tome."),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: scholar, book
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("inform scholar about book")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > inform scholar about book
            The learned scholar absorbs your words about the ancient book
            with thoughtful consideration.
            """
        )
    }

    // MARK: - Validation Testing

    @Test("Cannot tell without specifying who")
    func testCannotTellWithoutWho() async throws {
        // Given
        let treasure = Item(
            id: "treasure",
            .name("gold treasure"),
            .description("A pile of gold."),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: treasure
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("tell about treasure")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > tell about treasure
            Your voice trails off, seeking an audience.
            """
        )
    }

    @Test("Cannot tell non-existent character")
    func testCannotTellNonExistentCharacter() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("tell wizard about magic")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > tell wizard about magic
            Any such thing remains frustratingly inaccessible.
            """
        )
    }

    @Test("Cannot tell character not in scope")
    func testCannotTellCharacterNotInScope() async throws {
        // Given
        let anotherRoom = Location(
            id: "anotherRoom",
            .name("Another Room"),
            .inherentlyLit
        )

        let distantWizard = Item(
            id: "wizard",
            .name("distant wizard"),
            .description("A wizard in another room."),
            .characterSheet(.default),
            .in("anotherRoom")
        )

        let game = MinimalGame(
            locations: anotherRoom,
            items: distantWizard
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("tell wizard about magic")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > tell wizard about magic
            Any such thing remains frustratingly inaccessible.
            """
        )
    }

    @Test("Cannot tell self about something")
    func testCannotTellSelf() async throws {
        // Given
        let crystal = Item(
            id: "crystal",
            .name("magic crystal"),
            .description("A glowing crystal."),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: crystal
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("tell me about crystal")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > tell me about crystal
            You engage in a spirited internal dialogue about the magic
            crystal.
            """
        )
    }

    @Test("Requires light to tell")
    func testRequiresLight() async throws {
        // Given: Dark room with character
        let darkRoom = Location(
            id: "darkRoom",
            .name("Dark Room"),
            .description("A pitch black room.")
            // Note: No .inherentlyLit property
        )

        let wizard = Item(
            id: "wizard",
            .name("old wizard"),
            .description("A wise old wizard."),
            .characterSheet(.default),
            .in("darkRoom")
        )

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom,
            items: wizard
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("tell wizard about magic")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > tell wizard about magic
            The darkness here is absolute, consuming all light and hope of
            sight.
            """
        )
    }

    // MARK: - Processing Testing

    @Test("Tell character gives variety of responses")
    func testTellCharacterVariety() async throws {
        // Given
        let wizard = Item(
            id: "wizard",
            .name("old wizard"),
            .description("A wise old wizard."),
            .characterSheet(.default),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: wizard
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("tell wizard")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > tell wizard
            The old wizard awaits the subject of your discourse.
            """
        )

        let finalState = try await engine.item("wizard")
        #expect(await finalState.hasFlag(.isTouched) == true)
    }

    @Test("Tell character about topic gives variety of responses")
    func testTellCharacterAboutTopicVariety() async throws {
        // Given
        let sage = Item(
            id: "sage",
            .name("wise sage"),
            .description("A knowledgeable sage."),
            .characterSheet(.default),
            .in(.startRoom)
        )

        let crystal = Item(
            id: "crystal",
            .name("magic crystal"),
            .description("A glowing crystal."),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: sage, crystal
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("tell sage about crystal")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > tell sage about crystal
            The wise sage absorbs your words about the magic crystal with
            thoughtful consideration.
            """
        )
    }

    @Test("Tell enemy gives appropriate responses")
    func testTellEnemy() async throws {
        // Given
        let game = MinimalGame(
            items: Lab.troll
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("tell troll")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > tell troll
            The fierce troll awaits the subject of your discourse.
            """
        )

        let finalState = try await engine.item("troll")
        #expect(await finalState.hasFlag(.isTouched) == true)
    }

    @Test("Tell enemy about topic gives appropriate responses")
    func testTellEnemyAboutTopic() async throws {
        // Given
        let orc = Item(
            id: "orc",
            .name("fierce orc"),
            .description("A fierce orc warrior."),
            .characterSheet(.init(isFighting: true)),
            .in(.startRoom)
        )

        let sword = Item(
            id: "sword",
            .name("steel sword"),
            .description("A sharp steel sword."),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: orc, sword
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("tell the orc about my sword", times: 2)

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > tell the orc about my sword
            The fierce orc dismisses your words about the steel sword with
            contemptuous silence.

            In a moment of raw violence, the warrior comes at you with
            nothing but fury! You raise your fists, knowing this will hurt
            regardless of who wins.

            > tell the orc about my sword
            The subject of the steel sword cannot bridge the chasm between
            you and the fierce orc.

            The fierce warrior's brutal retaliation breaks through your
            defenses completely, rendering you vulnerable as an opened
            shell.
            """
        )
    }

    @Test("Tell non-character object")
    func testTellObject() async throws {
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
        try await engine.execute("tell statue")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > tell statue
            Your words bounce off the marble statue without effect or
            acknowledgment.
            """
        )

        let finalState = try await engine.item("statue")
        #expect(await finalState.hasFlag(.isTouched) == true)
    }

    @Test("Tell object about topic")
    func testTellObjectAboutTopic() async throws {
        // Given
        let mirror = Item(
            id: "mirror",
            .name("silver mirror"),
            .description("A polished silver mirror."),
            .in(.startRoom)
        )

        let secret = Item(
            id: "secret",
            .name("dark secret"),
            .description("A mysterious secret."),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: mirror, secret
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("tell mirror about secret")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > tell mirror about secret
            Your eloquent exposition on the dark secret is wasted on the
            silver mirror's inanimate indifference.
            """
        )
    }

    @Test("Tell about non-existent topic")
    func testTellAboutNonExistentTopic() async throws {
        // Given
        let wizard = Item(
            id: "wizard",
            .name("old wizard"),
            .description("A wise old wizard."),
            .characterSheet(.default),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: wizard
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("tell wizard about dragons")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > tell wizard about dragons
            The old wizard absorbs your words about the dragons with
            thoughtful consideration.
            """
        )
    }

    // MARK: - Intent Testing

    @Test("Handler exposes correct Verbs")
    func testVerbs() async throws {
        let handler = TellActionHandler()
        #expect(handler.synonyms.contains(.tell))
        #expect(handler.synonyms.contains(.inform))
        #expect(handler.synonyms.count == 2)
    }

    @Test("Handler requires light")
    func testRequiresLightProperty() async throws {
        let handler = TellActionHandler()
        #expect(handler.requiresLight == true)
    }
}
