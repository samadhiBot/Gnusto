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
            You dance a little jig.
            """)
    }

    @Test("DANCE WITH DIRECTOBJECT syntax works")
    func testDanceWithDirectObjectSyntax() async throws {
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
        try await engine.execute("dance with partner")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > dance with partner
            You dance a little jig.
            """)
    }

    // MARK: - Processing Testing

    @Test("Dance provides atmospheric response")
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
        try await engine.execute("dance")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > dance
            You dance a little jig.
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
            You dance a little jig.
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
            You dance a little jig.
            """)
    }

    // MARK: - ActionID Testing

    @Test("Handler exposes correct ActionIDs")
    func testActionIDs() async throws {
        let handler = DanceActionHandler()
        // DanceActionHandler doesn’t specify actions, so it should be empty
        #expect(handler.actions.isEmpty)
    }

    @Test("Handler exposes correct VerbIDs")
    func testVerbIDs() async throws {
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
