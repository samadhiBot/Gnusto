import Testing
import CustomDump
@testable import GnustoEngine

@Suite("CryActionHandler Tests")
struct CryActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("CRY syntax works")
    func testCrySyntax() async throws {
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
        try await engine.execute("cry")

        // Then
        let output = await mockIO.flush().trimmingCharacters(in: .whitespacesAndNewlines)

        let possibleOutputs = [
            "> cry\nBoo hoo.",
            "> cry\nIt does no good to cry.",
            "> cry\nThere, there. It will be all right."
        ].map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

        #expect(
            possibleOutputs.contains(output),
            "Output was not one of the expected random responses: \n\(output)"
        )
    }

    @Test("WEEP syntax works")
    func testWeepSyntax() async throws {
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
        try await engine.execute("weep")

        // Then
        let output = await mockIO.flush().trimmingCharacters(in: .whitespacesAndNewlines)

        let possibleOutputs = [
            "> weep\nBoo hoo.",
            "> weep\nIt does no good to cry.",
            "> weep\nThere, there. It will be all right."
        ].map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

        #expect(
            possibleOutputs.contains(output),
            "Output was not one of the expected random responses: \n\(output)"
        )
    }

    // MARK: - Validation Testing

    @Test("Cannot cry with a direct object")
    func testCannotCryWithDirectObject() async throws {
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
        try await engine.execute("cry rock")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > cry rock
            You can't do that with "cry".
            """)
    }


    // MARK: - ActionID Testing

    @Test("Handler exposes correct ActionIDs")
    func testActionIDs() async throws {
        let handler = CryActionHandler()
        #expect(handler.actions.isEmpty)
    }

    @Test("Handler exposes correct VerbIDs")
    func testVerbIDs() async throws {
        let handler = CryActionHandler()
        #expect(handler.verbs.contains(.cry))
        #expect(handler.verbs.contains(.weep))
        #expect(handler.verbs.count == 2)
    }

    @Test("Handler does not require light")
    func testRequiresLightProperty() async throws {
        let handler = CryActionHandler()
        #expect(handler.requiresLight == false)
    }
}
