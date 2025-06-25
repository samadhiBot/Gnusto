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
            You boogie down.
            """)
    }

    // MARK: - Validation Testing

    @Test("Cannot dance with a direct object")
    func testCannotDanceWithDirectObject() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let rock = Item(
            id: "rock",
            .name("rock"),
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: rock
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("dance with rock")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > dance with rock
            You can't do that with "dance".
            """)
    }

    // MARK: - ActionID Testing

    @Test("Handler exposes correct ActionIDs")
    func testActionIDs() async throws {
        let handler = DanceActionHandler()
        #expect(handler.actions.isEmpty)
    }

    @Test("Handler exposes correct VerbIDs")
    func testVerbIDs() async throws {
        let handler = DanceActionHandler()
        #expect(handler.verbs.contains(.dance))
        #expect(handler.verbs.count == 1)
    }

    @Test("Handler does not require light")
    func testRequiresLightProperty() async throws {
        let handler = DanceActionHandler()
        #expect(handler.requiresLight == false)
    }
}
