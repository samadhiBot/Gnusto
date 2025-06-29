import Testing
import CustomDump

@testable import GnustoEngine

@Suite("DanceActionHandler Tests")
struct DanceActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("DANCE syntax works")
    func testDanceSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .description("A room for testing."),
            .inherentlyLit
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("dance")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > dance
            Your choreography suggests a deep personal relationship with
            music that may be entirely one-sided.
            """)
    }

    @Test("DANCE WITH (Item) DIRECTOBJECT syntax works")
    func testDanceWithItemDirectObjectSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let statue = Item(
            id: "statue",
            .name("stone statue"),
            .description("A graceful marble statue."),
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: statue
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("dance with statue", times: 3)

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > dance with statue
            Your waltz with the stone statue achieves a level of one-sided
            romance that poets would envy.

            > dance with statue
            The stone statue follows your lead with the graceful compliance
            of something that has no choice in the matter.

            > dance with statue
            The stone statue follows your every move with the devoted
            attention of something that has no other options.
            """)
    }

    @Test("DANCE WITH (Character) DIRECTOBJECT syntax works")
    func testDanceWithCharacterDirectObjectSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let partner = Item(
            id: "partner",
            .name("dance partner"),
            .description("A graceful dance partner."),
            .isCharacter,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: partner
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("dance with partner", times: 3)

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > dance with partner
            The dance partner proves to be a dance partner whose enthusiasm
            is inversely proportional to their preparation.

            > dance with partner
            Your dancing partnership with the dance partner demonstrates
            that rhythm is indeed a highly personal interpretation.

            > dance with partner
            Your dance with the dance partner proves that good intentions
            can indeed triumph over mutual inexperience.
            """)
    }

    @Test("DANCE WITH (Enemy) DIRECTOBJECT syntax works")
    func testDanceWithEnemyDirectObjectSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let troll = Item(
            id: "troll",
            .name("menacing troll"),
            .description("A menacing troll."),
            .isCharacter,
            .isFighting,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: troll
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("dance with troll", times: 3)

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > dance with troll
            You offer the menacing troll a dance, creating the kind of
            social paradox that philosophers write dissertations about.

            > dance with troll
            Your dancing invitation catches the menacing troll off guard,
            suggesting they skipped the ‘social graces during
            warfare’ seminars.

            > dance with troll
            The menacing troll contemplates your choreographic offer with
            the sort of suspicion usually reserved for obvious traps.
            """)
    }

    // MARK: - Processing Testing

    @Test("Dance provides atmospheric responses")
    func testDanceAtmosphericResponse() async throws {
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
        try await engine.execute("dance", times: 3)

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > dance
            Your choreography suggests a deep personal relationship with
            music that may be entirely one-sided.

            > dance
            You execute movements that would be called dancing by someone
            with a very generous definition.
            
            > dance
            You execute a dance that proves the triumph of spirit over the
            basic laws of physics.
            """)
    }

    @Test("Dance works in dark rooms")
    func testDanceWorksInDarkRooms() async throws {
        // Given: Dark room (no light required for dancing)
        let darkRoom = Location(
            id: "darkRoom",
            .name("Dark Room"),
            .description("A pitch black room.")
        )

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("dance")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > dance
            Your choreography suggests a deep personal relationship with
            music that may be entirely one-sided.
            """)
    }

    @Test("Dance with object still works")
    func testDanceWithObject() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let chair = Item(
            id: "chair",
            .name("wooden chair"),
            .description("A simple wooden chair."),
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: chair
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("dance with chair")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > dance with chair
            Your waltz with the wooden chair achieves a level of one-sided
            romance that poets would envy.
            """)
    }

    // MARK: - Intent Testing

    @Test("Handler exposes correct Intents")
    func testIntents() async throws {
        let handler = DanceActionHandler()
        // DanceActionHandler doesn’t specify actions, so it should be empty
        #expect(handler.actions.isEmpty)
    }

    @Test("Handler exposes correct Verbs")
    func testVerbs() async throws {
        let handler = DanceActionHandler()
        #expect(handler.verbs.contains(.dance))
        #expect(handler.verbs.count == 1)
    }

    @Test("Handler does not require light")
    func testDoesNotRequireLight() async throws {
        let handler = DanceActionHandler()
        #expect(handler.requiresLight == false)
    }
}
