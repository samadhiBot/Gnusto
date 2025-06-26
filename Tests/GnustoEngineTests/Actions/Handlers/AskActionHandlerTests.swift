import Testing
import CustomDump
@testable import GnustoEngine

@Suite("AskActionHandler Tests")
struct AskActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("ASK VERB DIRECT-OBJECT syntax works")
    func testAskDirectObjectSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .description("A room for testing."),
            .inherentlyLit
        )

        let wizard = Item(
            id: "wizard",
            .name("old wizard"),
            .description("A wise old wizard."),
            .isCharacter,
            .in(.location("testRoom"))
        )

        let crystal = Item(
            id: "crystal",
            .name("magic crystal"),
            .description("A glowing crystal."),
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: wizard, crystal
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("ask wizard about crystal")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > ask wizard about crystal
            The old wizard doesn’t seem to know anything about a
            magic crystal.
            """)

        let finalState = try await engine.item("wizard")
        #expect(finalState.hasFlag(.isTouched) == true)
    }

    @Test("QUESTION syntax works")
    func testQuestionSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let guardItem = Item(
            id: "guardItem",
            .name("castle guard"),
            .description("A stern castle guard."),
            .isCharacter,
            .in(.location("testRoom"))
        )

        let sword = Item(
            id: "sword",
            .name("silver sword"),
            .description("A gleaming silver sword."),
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: guardItem, sword
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("question guard about sword")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > question guard about sword
            The castle guard doesn’t seem to know anything about a
            silver sword.
            """)
    }

    // MARK: - Validation Testing

    @Test("Cannot ask without specifying who")
    func testCannotAskWithoutWho() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("ask about treasure")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > ask about treasure
            Ask whom?
            """)
    }

    @Test("Cannot ask without specifying what about")
    func testCannotAskWithoutWhatAbout() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let merchant = Item(
            id: "merchant",
            .name("traveling merchant"),
            .description("A traveling merchant."),
            .isCharacter,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: merchant
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("ask merchant")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > ask merchant
            Ask what?
            """)
    }

    @Test("Cannot ask non-character")
    func testCannotAskNonCharacter() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let rock = Item(
            id: "rock",
            .name("large rock"),
            .description("A large boulder."),
            .in(.location("testRoom"))
        )

        let crystal = Item(
            id: "crystal",
            .name("magic crystal"),
            .description("A glowing crystal."),
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: rock, crystal
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("ask rock about crystal")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > ask rock about crystal
            You can’t ask the large rock about that.
            """)
    }

    @Test("Cannot ask character not in scope")
    func testCannotAskCharacterNotInScope() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let anotherRoom = Location(
            id: "anotherRoom",
            .name("Another Room"),
            .inherentlyLit
        )

        let remoteWizard = Item(
            id: "remoteWizard",
            .name("remote wizard"),
            .description("A wizard in another room."),
            .isCharacter,
            .in(.location("anotherRoom"))
        )

        let crystal = Item(
            id: "crystal",
            .name("magic crystal"),
            .description("A glowing crystal."),
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom, anotherRoom,
            items: remoteWizard, crystal
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("ask wizard about crystal")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > ask wizard about crystal
            You can’t see any such thing.
            """)
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
            .isCharacter,
            .in(.location("darkRoom"))
        )

        let crystal = Item(
            id: "crystal",
            .name("magic crystal"),
            .description("A glowing crystal."),
            .in(.location("darkRoom"))
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
        expectNoDifference(output, """
            > ask wizard about crystal
            It is pitch black. You can’t see a thing.
            """)
    }

    // MARK: - Processing Testing

    @Test("Ask character about item")
    func testAskCharacterAboutItem() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let sage = Item(
            id: "sage",
            .name("wise sage"),
            .description("A knowledgeable sage."),
            .isCharacter,
            .in(.location("testRoom"))
        )

        let scroll = Item(
            id: "scroll",
            .name("ancient scroll"),
            .description("An ancient scroll."),
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: sage, scroll
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("ask sage about scroll")

        // Then: Verify state change
        let finalState = try await engine.item("sage")
        #expect(finalState.hasFlag(.isTouched) == true)

        // Verify message
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > ask sage about scroll
            The wise sage doesn’t seem to know anything about an
            ancient scroll.
            """)
    }

    @Test("Ask character about player")
    func testAskCharacterAboutPlayer() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let oracle = Item(
            id: "oracle",
            .name("mystical oracle"),
            .description("A mystical oracle."),
            .isCharacter,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: oracle
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("ask oracle about me")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > ask oracle about me
            The mystical oracle doesn’t seem to know anything about you.
            """)
    }

    @Test("Ask character about location")
    func testAskCharacterAboutLocation() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let anotherRoom = Location(
            id: "library",
            .name("Ancient Library"),
            .inherentlyLit
        )

        let librarian = Item(
            id: "librarian",
            .name("old librarian"),
            .description("An old librarian."),
            .isCharacter,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom, anotherRoom,
            items: librarian
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("ask librarian about library")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > ask librarian about library
            The old librarian doesn’t seem to know anything about any
            Ancient Library.
            """)
    }

    // MARK: - Intent Testing

    @Test("Handler exposes correct Intents")
    func testIntents() async throws {
        let handler = AskActionHandler()
        // AskActionHandler doesn’t specify actions, so it should be empty
        #expect(handler.actions.isEmpty)
    }

    @Test("Handler exposes correct Verbs")
    func testVerbs() async throws {
        let handler = AskActionHandler()
        #expect(handler.verbs.contains(.ask))
        #expect(handler.verbs.contains(.question))
        #expect(handler.verbs.count == 2)
    }

    @Test("Handler requires light")
    func testRequiresLightProperty() async throws {
        let handler = AskActionHandler()
        #expect(handler.requiresLight == true)
    }
}
