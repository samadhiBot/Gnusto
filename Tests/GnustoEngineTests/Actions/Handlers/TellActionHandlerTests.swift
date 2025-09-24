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
            Your voice trails off, leaving the old wizard waiting
            expectantly.
            """
        )

        let finalState = await engine.item("wizard")
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
            Your explanation of the magic crystal finds an attentive
            audience in the wise sage.
            """
        )

        let finalState = await engine.item("sage")
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
            Your explanation of the silver key finds an attentive audience
            in the palace guard.
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
            Your explanation of the ancient treasure finds an attentive
            audience in the traveling merchant.
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
            Your explanation of the prayer blessing finds an attentive
            audience in the village priest.
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
            Your explanation of the ancient book finds an attentive
            audience in the learned scholar.
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
            Who should receive this wisdom you're eager to share?
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
            You cannot reach any such thing from here.
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
            You cannot reach any such thing from here.
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
            Your monologue on the magic crystal echoes in the silence.
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
            You stand in a depthless black where even your thoughts seem to
            whisper, careful not to make a sound.
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
            Your voice trails off, leaving the old wizard waiting
            expectantly.
            """
        )

        let finalState = await engine.item("wizard")
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
            Your explanation of the magic crystal finds an attentive
            audience in the wise sage.
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
            Your voice trails off, leaving the fierce troll waiting
            expectantly.
            """
        )

        let finalState = await engine.item("troll")
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
            The subject of the steel sword cannot bridge the chasm between
            you and the fierce orc.

            The warrior attacks with pure murderous intent! You brace
            yourself for the impact, guard up, ready for the worst kind of
            fight.

            > tell the orc about my sword
            The subject of the steel sword cannot bridge the chasm between
            you and the fierce orc.

            The warrior shatters your defense with bare hands, leaving you
            wide open and unable to protect yourself.
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
            Communication requires a listener, which the marble statue
            decidedly is not.
            """
        )

        let finalState = await engine.item("statue")
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
            The silver mirror remains unmoved by your knowledge of the dark
            secret, being unmovable by words in general.
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
            Your explanation of the dragons finds an attentive audience in
            the old wizard.
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
