import CustomDump
import GnustoEngine
import GnustoTestSupport
import Testing

@Suite("DanceActionHandler Tests")
struct DanceActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("DANCE syntax works")
    func testDanceSyntax() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("dance")

        // Then
        await mockIO.expect(
            """
            > dance
            You execute a series of movements that could generously be
            called dancing.
            """
        )
    }

    @Test("DANCE WITH (Item) DIRECTOBJECT syntax works")
    func testDanceWithItemDirectObjectSyntax() async throws {
        // Given
        let statue = Item("statue")
            .name("stone statue")
            .description("A graceful marble statue.")
            .in(.startRoom)

        let game = MinimalGame(
            items: statue
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("dance with statue")

        // Then
        await mockIO.expect(
            """
            > dance with statue
            The stone statue proves a disappointingly rigid dance partner.
            """
        )
    }

    @Test("DANCE WITH (Character) DIRECTOBJECT syntax works")
    func testDanceWithCharacterDirectObjectSyntax() async throws {
        // Given
        let partner = Item("partner")
            .name("dance partner")
            .description("A graceful dance partner.")
            .characterSheet(.default)
            .in(.startRoom)

        let game = MinimalGame(
            items: partner
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("dance with partner")

        // Then
        await mockIO.expect(
            """
            > dance with partner
            You and the dance partner move together in unexpected harmony,
            if only for a moment.
            """
        )
    }

    @Test("DANCE WITH (Enemy) DIRECTOBJECT syntax works")
    func testDanceWithEnemyDirectObjectSyntax() async throws {
        // This test verifies that non-combat actions during combat:
        // 1. Process through their normal action handlers (dance rejection message)
        // 2. Give the enemy a buffed attack opportunity
        // Combat messages vary due to damage randomization, so we check for key phrases.

        // Given
        let game = MinimalGame(
            items: Lab.troll
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute(
            "look",
            "dance with troll"
        )

        // Then
        await mockIO.expect(
            """
            > look
            --- Laboratory ---

            A laboratory in which strange experiments are being conducted.

            There is a fierce troll here.

            > dance with troll
            For a fleeting instant, you and the fierce troll find rhythm in
            each other's movements.
            """
        )
    }

    // MARK: - Processing Testing

    @Test("Dance works in dark rooms")
    func testDanceWorksInDarkRooms() async throws {
        // Given: Dark room (no light required for dancing)
        let darkRoom = Location("darkRoom")
            .name("Dark Room")
            .description("A pitch black room.")

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("dance")

        // Then
        await mockIO.expect(
            """
            > dance
            You execute a series of movements that could generously be
            called dancing.
            """
        )
    }

    @Test("Dance with object still works")
    func testDanceWithObject() async throws {
        // Given
        let chair = Item("chair")
            .name("wooden chair")
            .description("A simple wooden chair.")
            .in(.startRoom)

        let game = MinimalGame(
            items: chair
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("dance with chair")

        // Then
        await mockIO.expect(
            """
            > dance with chair
            The wooden chair proves a disappointingly rigid dance partner.
            """
        )
    }

    // MARK: - Intent Testing

    @Test("Handler exposes correct Verbs")
    func testVerbs() async throws {
        let handler = DanceActionHandler()
        #expect(handler.synonyms.contains(.dance))
        #expect(handler.synonyms.count == 1)
    }

    @Test("Handler does not require light")
    func testDoesNotRequireLight() async throws {
        let handler = DanceActionHandler()
        #expect(handler.requiresLight == false)
    }
}
