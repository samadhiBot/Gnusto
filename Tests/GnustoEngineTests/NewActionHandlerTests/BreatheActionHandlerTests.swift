import Testing
import CustomDump
@testable import GnustoEngine

@Suite("BreatheActionHandler Tests")
struct BreatheActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("BREATHE syntax works")
    func testBreatheSyntax() async throws {
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
        try await engine.execute("breathe")

        // Then
        let output = await mockIO.flush().trimmingCharacters(in: .whitespacesAndNewlines)

        // The response is random, so check against the possible options.
        let possibleOutputs = [
            """
            > breathe
            You take a deep breath.
            """,
            """
            > breathe
            The air here is fresh and clear.
            """,
            """
            > breathe
            You breathe in the musty air.
            """,
        ]

        #expect(
            possibleOutputs.contains(output),
            "Output was not one of the expected random responses: \n\(output)"
        )
    }

    // MARK: - Validation Testing

    @Test("Cannot breathe on a direct object")
    func testCannotBreatheOnDirectObject() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let rock = Item(
            id: "rock",
            .name("a rock"),
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: rock
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        // The syntax rule allows this to be parsed, but validate() rejects it.
        try await engine.execute("breathe on rock")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > breathe on rock
            You can’t do that with “breathe”.
            """)
    }

    // MARK: - ActionID Testing

    @Test("Handler exposes correct ActionIDs")
    func testActionIDs() async throws {
        let handler = BreatheActionHandler()
        #expect(handler.actions.isEmpty)
    }

    @Test("Handler exposes correct VerbIDs")
    func testVerbIDs() async throws {
        let handler = BreatheActionHandler()
        #expect(handler.verbs.contains(.breathe))
        #expect(handler.verbs.count == 1)
    }

    @Test("Handler does not require light")
    func testRequiresLightProperty() async throws {
        let handler = BreatheActionHandler()
        #expect(handler.requiresLight == false)
    }
}
