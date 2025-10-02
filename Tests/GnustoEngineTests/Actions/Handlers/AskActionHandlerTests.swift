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
        let wizard = Item("wizard")
            .name("old wizard")
            .description("A wise old wizard.")
            .characterSheet(.default)
            .in(.startRoom)

        let crystal = Item("crystal")
            .name("magic crystal")
            .description("A glowing crystal.")
            .in(.startRoom)

        let game = MinimalGame(
            items: wizard, crystal
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("ask wizard about crystal")

        // Then
        await mockIO.expectOutput(
            """
            > ask wizard about crystal
            The old wizard meets your inquiry about the magic crystal with
            genuine bewilderment.
            """
        )

        let finalState = await engine.item("wizard")
        #expect(await finalState.hasFlag(.isTouched) == true)
    }

    @Test("QUESTION syntax works")
    func testQuestionSyntax() async throws {
        // Given
        let guardItem = Item("guardItem")
            .name("castle guard")
            .description("A stern castle guard.")
            .characterSheet(.default)
            .in(.startRoom)

        let sword = Item("sword")
            .name("silver sword")
            .description("A gleaming silver sword.")
            .in(.startRoom)

        let game = MinimalGame(
            items: guardItem, sword
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("question guard about sword")

        // Then
        await mockIO.expectOutput(
            """
            > question guard about sword
            The castle guard meets your inquiry about the silver sword with
            genuine bewilderment.
            """
        )
    }

    // MARK: - Validation Testing

    @Test("Cannot ask without specifying who")
    func testCannotAskWithoutWho() async throws {
        // Given
        let crystal = Item("crystal")
            .name("magic crystal")
            .description("A glowing crystal.")
            .in(.startRoom)

        let game = MinimalGame(
            items: crystal
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("inquire about the magic crystal")

        // Then
        await mockIO.expectOutput(
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
        await mockIO.expectOutput(
            """
            > ask about the emerald tablet
            Ask whom?
            """
        )
    }

    @Test("Ask without topic prompts for topic (two-phase asking)")
    func testAskWithoutTopicPromptsForTopic() async throws {
        // Given
        let merchant = Item("merchant")
            .name("traveling merchant")
            .description("A traveling merchant.")
            .characterSheet(.default)
            .in(.startRoom)

        let game = MinimalGame(
            items: merchant
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("ask merchant")

        // Then
        await mockIO.expectOutput(
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
        let rock = Item("rock")
            .name("large rock")
            .description("A large boulder.")
            .in(.startRoom)

        let crystal = Item("crystal")
            .name("magic crystal")
            .description("A glowing crystal.")
            .in(.startRoom)

        let game = MinimalGame(
            items: rock, crystal
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("ask rock about crystal")

        // Then
        await mockIO.expectOutput(
            """
            > ask rock about crystal
            The large rock lacks the capacity for conversation.
            """
        )
    }

    @Test("Cannot ask character not in scope")
    func testCannotAskCharacterNotInScope() async throws {
        // Given
        let anotherRoom = Location("anotherRoom")
            .name("Another Room")
            .inherentlyLit

        let remoteWizard = Item("remoteWizard")
            .name("remote wizard")
            .description("A wizard in another room.")
            .characterSheet(.default)
            .in("anotherRoom")

        let crystal = Item("crystal")
            .name("magic crystal")
            .description("A glowing crystal.")
            .in(.startRoom)

        let game = MinimalGame(
            locations: anotherRoom,
            items: remoteWizard, crystal
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("ask wizard about crystal")

        // Then
        await mockIO.expectOutput(
            """
            > ask wizard about crystal
            Any such thing lurks beyond your reach.
            """
        )
    }

    @Test("Requires light to ask")
    func testRequiresLight() async throws {
        // Given: Dark room with character
        let darkRoom = Location("darkRoom")
            .name("Dark Room")
            .description("A pitch black room.")
            // Note: No .inherentlyLit property

        let wizard = Item("wizard")
            .name("old wizard")
            .description("A wise old wizard.")
            .characterSheet(.default)
            .in("darkRoom")

        let crystal = Item("crystal")
            .name("magic crystal")
            .description("A glowing crystal.")
            .in("darkRoom")

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom,
            items: wizard, crystal
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("ask wizard about crystal")

        // Then
        await mockIO.expectOutput(
            """
            > ask wizard about crystal
            The darkness here is absolute, consuming all light and hope of
            sight.
            """
        )
    }

    // MARK: - Processing Testing

    @Test("Ask character about item")
    func testAskCharacterAboutItem() async throws {
        // Given
        let sage = Item("sage")
            .name("wise sage")
            .description("A knowledgeable sage.")
            .characterSheet(.default)
            .in(.startRoom)

        let scroll = Item("scroll")
            .name("ancient scroll")
            .description("An ancient scroll.")
            .in(.startRoom)

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
        await mockIO.expectOutput(
            """
            > ask sage about scroll
            The wise sage meets your inquiry about the ancient scroll with
            genuine bewilderment.
            """
        )
    }

    @Test("Ask character about player")
    func testAskCharacterAboutPlayer() async throws {
        // Given
        let oracle = Item("oracle")
            .name("mystical oracle")
            .description("A mystical oracle.")
            .characterSheet(.default)
            .in(.startRoom)

        let game = MinimalGame(
            items: oracle
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("ask oracle about me")

        // Then
        await mockIO.expectOutput(
            """
            > ask oracle about me
            The mystical oracle meets your inquiry about yourself with
            genuine bewilderment.
            """
        )
    }

    @Test("Ask character about location")
    func testAskCharacterAboutLocation() async throws {
        // Given
        let anotherRoom = Location("library")
            .name("Ancient Library")
            .inherentlyLit

        let librarian = Item("librarian")
            .name("old librarian")
            .description("An old librarian.")
            .characterSheet(.default)
            .in(.startRoom)

        let game = MinimalGame(
            locations: anotherRoom,
            items: librarian
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("ask librarian about library")

        // Then
        await mockIO.expectOutput(
            """
            > ask librarian about library
            The old librarian meets your inquiry about the Ancient Library
            with genuine bewilderment.
            """
        )
    }

    // MARK: - Two-Phase Integration Testing

    @Test("Two-phase asking completes successfully")
    func testTwoPhaseAskingCompleteFlow() async throws {
        // Given
        let wizard = Item("wizard")
            .name("old wizard")
            .description("A wise old wizard.")
            .characterSheet(.default)
            .in(.startRoom)

        let treasure = Item("treasure")
            .name("golden treasure")
            .synonyms("treasure")
            .description("A chest of gold.")
            .in(.startRoom)

        let game = MinimalGame(
            items: wizard, treasure
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Phase 1: Ask without topic
        try await engine.execute("ask the wizard")
        await mockIO.expectOutput(
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
        await mockIO.expectOutput(
            """
            > the treasure
            The old wizard meets your inquiry about the golden treasure
            with genuine bewilderment.
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
        let oracle = Item("oracle")
            .name("mystical oracle")
            .description("A mystical oracle.")
            .characterSheet(.default)
            .in(.startRoom)

        let crystal = Item("crystal")
            .name("magic crystal")
            .description("A glowing crystal.")
            .in(.startRoom)

        let game = MinimalGame(
            items: oracle, crystal
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Direct ask with both character and topic
        try await engine.execute("ask oracle about crystal")

        // Then: Should work immediately without prompting
        await mockIO.expectOutput(
            """
            > ask oracle about crystal
            The mystical oracle meets your inquiry about the magic crystal
            with genuine bewilderment.
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
