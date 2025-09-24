import CustomDump
import GnustoEngine
import GnustoTestSupport
import Testing

@Suite("AskActionHandler Tests")
struct AskActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("ASK VERB DIRECT-OBJECT syntax works")
    func testAskDirectObjectSyntax() async throws {
        // Given
        let wizard = Item(
            id: "wizard",
            .name("old wizard"),
            .description("A wise old wizard."),
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
            items: wizard, crystal
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("ask wizard about crystal")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > ask wizard about crystal
            The mention of the magic crystal draws only a blank stare from
            the old wizard.
            """
        )

        let finalState = await engine.item("wizard")
        #expect(await finalState.hasFlag(.isTouched) == true)
    }

    @Test("QUESTION syntax works")
    func testQuestionSyntax() async throws {
        // Given
        let guardItem = Item(
            id: "guardItem",
            .name("castle guard"),
            .description("A stern castle guard."),
            .characterSheet(.default),
            .in(.startRoom)
        )

        let sword = Item(
            id: "sword",
            .name("silver sword"),
            .description("A gleaming silver sword."),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: guardItem, sword
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("question guard about sword")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > question guard about sword
            The mention of the silver sword draws only a blank stare from
            the castle guard.
            """
        )
    }

    // MARK: - Validation Testing

    @Test("Cannot ask without specifying who")
    func testCannotAskWithoutWho() async throws {
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
        try await engine.execute("inquire about the magic crystal")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > inquire about the magic crystal
            Ask whom?
            """
        )
    }

    @Test("Cannot ask about nonexistent items")
    func testCannotAskAboutNonexistent() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("ask about the emerald tablet")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > ask about the emerald tablet
            Ask whom?
            """
        )
    }

    @Test("Ask without topic prompts for topic (two-phase asking)")
    func testAskWithoutTopicPromptsForTopic() async throws {
        // Given
        let merchant = Item(
            id: "merchant",
            .name("traveling merchant"),
            .description("A traveling merchant."),
            .characterSheet(.default),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: merchant
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("ask merchant")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > ask merchant
            What do you want to ask the traveling merchant about?
            """
        )

        // Verify that a question is now pending
        let hasPendingQuestion = await engine.conversationManager.hasPendingQuestion
        #expect(hasPendingQuestion == true)

        let currentPrompt = await engine.conversationManager.currentQuestionPrompt
        #expect(currentPrompt?.contains("What do you want to ask") == true)
    }

    @Test("Cannot ask non-character")
    func testCannotAskNonCharacter() async throws {
        // Given
        let rock = Item(
            id: "rock",
            .name("large rock"),
            .description("A large boulder."),
            .in(.startRoom)
        )

        let crystal = Item(
            id: "crystal",
            .name("magic crystal"),
            .description("A glowing crystal."),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: rock, crystal
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("ask rock about crystal")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > ask rock about crystal
            Questions require someone who can answer--the large rock
            cannot.
            """
        )
    }

    @Test("Cannot ask character not in scope")
    func testCannotAskCharacterNotInScope() async throws {
        // Given
        let anotherRoom = Location(
            id: "anotherRoom",
            .name("Another Room"),
            .inherentlyLit
        )

        let remoteWizard = Item(
            id: "remoteWizard",
            .name("remote wizard"),
            .description("A wizard in another room."),
            .characterSheet(.default),
            .in("anotherRoom")
        )

        let crystal = Item(
            id: "crystal",
            .name("magic crystal"),
            .description("A glowing crystal."),
            .in(.startRoom)
        )

        let game = MinimalGame(
            locations: anotherRoom,
            items: remoteWizard, crystal
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("ask wizard about crystal")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > ask wizard about crystal
            Any such thing remains frustratingly inaccessible.
            """
        )
    }

    @Test("Requires light to ask")
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

        let crystal = Item(
            id: "crystal",
            .name("magic crystal"),
            .description("A glowing crystal."),
            .in("darkRoom")
        )

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom,
            items: wizard, crystal
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("ask wizard about crystal")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > ask wizard about crystal
            You stand in a depthless black where even your thoughts seem to
            whisper, careful not to make a sound.
            """
        )
    }

    // MARK: - Processing Testing

    @Test("Ask character about item")
    func testAskCharacterAboutItem() async throws {
        // Given
        let sage = Item(
            id: "sage",
            .name("wise sage"),
            .description("A knowledgeable sage."),
            .characterSheet(.default),
            .in(.startRoom)
        )

        let scroll = Item(
            id: "scroll",
            .name("ancient scroll"),
            .description("An ancient scroll."),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: sage, scroll
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("ask sage about scroll")

        // Then: Verify state change
        let finalState = await engine.item("sage")
        #expect(await finalState.hasFlag(.isTouched) == true)

        // Verify message
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > ask sage about scroll
            The mention of the ancient scroll draws only a blank stare from
            the wise sage.
            """
        )
    }

    @Test("Ask character about player")
    func testAskCharacterAboutPlayer() async throws {
        // Given
        let oracle = Item(
            id: "oracle",
            .name("mystical oracle"),
            .description("A mystical oracle."),
            .characterSheet(.default),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: oracle
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("ask oracle about me")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > ask oracle about me
            The mention of yourself draws only a blank stare from the
            mystical oracle.
            """
        )
    }

    @Test("Ask character about location")
    func testAskCharacterAboutLocation() async throws {
        // Given
        let anotherRoom = Location(
            id: "library",
            .name("Ancient Library"),
            .inherentlyLit
        )

        let librarian = Item(
            id: "librarian",
            .name("old librarian"),
            .description("An old librarian."),
            .characterSheet(.default),
            .in(.startRoom)
        )

        let game = MinimalGame(
            locations: anotherRoom,
            items: librarian
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("ask librarian about library")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > ask librarian about library
            The mention of the Ancient Library draws only a blank stare
            from the old librarian.
            """
        )
    }

    // MARK: - Two-Phase Integration Testing

    @Test("Two-phase asking completes successfully")
    func testTwoPhaseAskingCompleteFlow() async throws {
        // Given
        let wizard = Item(
            id: "wizard",
            .name("old wizard"),
            .description("A wise old wizard."),
            .characterSheet(.default),
            .in(.startRoom)
        )

        let treasure = Item(
            id: "treasure",
            .name("golden treasure"),
            .synonyms("treasure"),
            .description("A chest of gold."),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: wizard, treasure
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Phase 1: Ask without topic
        try await engine.execute("ask the wizard")
        let phase1Output = await mockIO.flush()
        expectNoDifference(
            phase1Output,
            """
            > ask the wizard
            What do you want to ask the old wizard about?
            """
        )

        // Verify question is pending
        let hasPending = await engine.conversationManager.hasPendingQuestion
        #expect(hasPending == true)

        // Phase 2: Provide topic
        try await engine.execute("the treasure")
        let phase2Output = await mockIO.flush()
        expectNoDifference(
            phase2Output,
            """
            > the treasure
            The mention of the golden treasure draws only a blank stare
            from the old wizard.
            """
        )

        // Verify question is no longer pending
        let stillPending = await engine.conversationManager.hasPendingQuestion
        #expect(stillPending == false)

        // Verify wizard was touched and pronouns updated
        let finalWizard = await engine.item("wizard")
        #expect(await finalWizard.hasFlag(.isTouched) == true)
    }

    @Test("Direct ask still works with both character and topic")
    func testDirectAskStillWorks() async throws {
        // Given
        let oracle = Item(
            id: "oracle",
            .name("mystical oracle"),
            .description("A mystical oracle."),
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
            items: oracle, crystal
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Direct ask with both character and topic
        try await engine.execute("ask oracle about crystal")

        // Then: Should work immediately without prompting
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > ask oracle about crystal
            The mention of the magic crystal draws only a blank stare from
            the mystical oracle.
            """
        )

        // Verify no question is pending (direct ask doesn't create questions)
        let hasPending = await engine.conversationManager.hasPendingQuestion
        #expect(hasPending == false)

        // Verify oracle was touched
        let finalOracle = await engine.item("oracle")
        #expect(await finalOracle.hasFlag(.isTouched) == true)
    }

    // MARK: - Intent Testing

    @Test("Handler exposes correct Verbs")
    func testVerbs() async throws {
        let handler = AskActionHandler()
        #expect(handler.synonyms.contains(.ask))
        #expect(handler.synonyms.contains(.question))
        #expect(handler.synonyms.count == 2)
    }

    @Test("Handler requires light")
    func testRequiresLightProperty() async throws {
        let handler = AskActionHandler()
        #expect(handler.requiresLight == true)
    }
}
