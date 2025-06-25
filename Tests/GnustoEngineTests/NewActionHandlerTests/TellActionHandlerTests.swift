import CustomDump
import Testing

@testable import GnustoEngine

@Suite("TellActionHandler Tests")
struct TellActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("TELL DIRECTOBJECT syntax works")
    func testTellDirectObjectSyntax() async throws {
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

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
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
            Tell the old wizard about what?
            """)
    }

    @Test("TELL DIRECTOBJECT ABOUT INDIRECTOBJECT syntax works")
    func testTellAboutSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .description("A room for testing."),
            .inherentlyLit
        )

        let sage = Item(
            id: "sage",
            .name("wise sage"),
            .description("A knowledgeable sage."),
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
            The wise sage listens to what you tell them about the magic crystal.
            """)

        let finalState = try await engine.item("sage")
        #expect(finalState.hasFlag(.isTouched) == true)
    }

    @Test("INFORM syntax works")
    func testInformSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let guardItem = Item(
            id: "guard",
            .name("castle guard"),
            .description("A stern castle guard."),
            .isCharacter,
            .in(.location("testRoom"))
        )

        let threat = Item(
            id: "threat",
            .name("approaching danger"),
            .description("Imminent danger approaches."),
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: guardItem, threat
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("inform guard about danger")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > inform guard about danger
            The castle guard listens to what you tell them about the approaching danger.
            """)
    }

    // MARK: - Validation Testing

    @Test("Cannot tell without specifying who")
    func testCannotTellWithoutWho() async throws {
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
        try await engine.execute("tell about treasure")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > tell about treasure
            Tell whom?
            """)
    }

    @Test("Cannot tell without specifying what about")
    func testCannotTellWithoutWhatAbout() async throws {
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
        try await engine.execute("tell merchant")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > tell merchant
            Tell the traveling merchant about what?
            """)
    }

    @Test("Cannot tell non-character")
    func testCannotTellNonCharacter() async throws {
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

        let secret = Item(
            id: "secret",
            .name("hidden secret"),
            .description("A hidden secret."),
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: rock, secret
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("tell rock about secret")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > tell rock about secret
            You can’t tell the large rock about that.
            """)
    }

    @Test("Cannot tell character not in scope")
    func testCannotTellCharacterNotInScope() async throws {
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

        let news = Item(
            id: "news",
            .name("important news"),
            .description("Important news to share."),
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom, anotherRoom,
            items: remoteWizard, news
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("tell wizard about news")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > tell wizard about news
            You can’t see any such thing.
            """)
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
            .isCharacter,
            .in(.location("darkRoom"))
        )

        let secret = Item(
            id: "secret",
            .name("important secret"),
            .description("An important secret."),
            .in(.location("darkRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom,
            items: wizard, secret
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("tell wizard about secret")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > tell wizard about secret
            It is pitch black. You can’t see a thing.
            """)
    }

    // MARK: - Processing Testing

    @Test("Tell character about item")
    func testTellCharacterAboutItem() async throws {
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

        let prophecy = Item(
            id: "prophecy",
            .name("ancient prophecy"),
            .description("An ancient prophecy."),
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: oracle, prophecy
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("tell oracle about prophecy")

        // Then: Verify state change
        let finalState = try await engine.item("oracle")
        #expect(finalState.hasFlag(.isTouched) == true)

        // Verify message
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > tell oracle about prophecy
            The mystical oracle listens to what you tell them about the ancient prophecy.
            """)
    }

    @Test("Tell character about player")
    func testTellCharacterAboutPlayer() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let counselor = Item(
            id: "counselor",
            .name("wise counselor"),
            .description("A wise counselor."),
            .isCharacter,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: counselor
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("tell counselor about me")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > tell counselor about me
            The wise counselor listens to what you tell them about yourself.
            """)
    }

    @Test("Tell character about location")
    func testTellCharacterAboutLocation() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let castle = Location(
            id: "castle",
            .name("Ancient Castle"),
            .inherentlyLit
        )

        let historian = Item(
            id: "historian",
            .name("local historian"),
            .description("A local historian."),
            .isCharacter,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom, castle,
            items: historian
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("tell historian about castle")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > tell historian about castle
            The local historian listens to what you tell them about Ancient Castle.
            """)
    }

    @Test("Tell multiple characters")
    func testTellMultipleCharacters() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let priest = Item(
            id: "priest",
            .name("village priest"),
            .description("A village priest."),
            .isCharacter,
            .in(.location("testRoom"))
        )

        let mayor = Item(
            id: "mayor",
            .name("town mayor"),
            .description("The town mayor."),
            .isCharacter,
            .in(.location("testRoom"))
        )

        let treasure = Item(
            id: "treasure",
            .name("hidden treasure"),
            .description("Hidden treasure."),
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: priest, mayor, treasure
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Tell first character
        try await engine.execute("tell priest about treasure")

        // Then
        let output1 = await mockIO.flush()
        expectNoDifference(
            output1,
            """
            > tell priest about treasure
            The village priest listens to what you tell them about the hidden treasure.
            """)

        // When: Tell second character
        try await engine.execute("tell mayor about treasure")

        // Then
        let output2 = await mockIO.flush()
        expectNoDifference(
            output2,
            """
            > tell mayor about treasure
            The town mayor listens to what you tell them about the hidden treasure.
            """)

        // Verify both characters were touched
        let finalPriest = try await engine.item("priest")
        let finalMayor = try await engine.item("mayor")
        #expect(finalPriest.hasFlag(.isTouched) == true)
        #expect(finalMayor.hasFlag(.isTouched) == true)
    }

    // MARK: - ActionID Testing

    @Test("Handler exposes correct ActionIDs")
    func testActionIDs() async throws {
        let handler = TellActionHandler()
        // TellActionHandler doesn’t specify actions, so it should be empty
        #expect(handler.actions.isEmpty)
    }

    @Test("Handler exposes correct VerbIDs")
    func testVerbIDs() async throws {
        let handler = TellActionHandler()
        #expect(handler.verbs.contains(.tell))
        #expect(handler.verbs.contains(.inform))
        #expect(handler.verbs.count == 2)
    }

    @Test("Handler requires light")
    func testRequiresLightProperty() async throws {
        let handler = TellActionHandler()
        #expect(handler.requiresLight == true)
    }
}
