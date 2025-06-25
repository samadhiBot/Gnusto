import Testing
import CustomDump
@testable import GnustoEngine

@Suite("DigActionHandler Tests")
struct DigActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("DIG syntax works")
    func testDigSyntax() async throws {
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
        try await engine.execute("dig")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > dig
            You can't dig here.
            """)
    }

    // MARK: - Validation Testing

    @Test("Cannot dig with a direct object")
    func testCannotDigWithDirectObject() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let ground = Item(
            id: "ground",
            .name("ground"),
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: ground
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("dig ground")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > dig ground
            You can't do that with "dig".
            """)
    }

    // MARK: - ActionID Testing

    @Test("Handler exposes correct VerbIDs")
    func testVerbIDs() async throws {
        let handler = DigActionHandler()
        #expect(handler.verbs.contains(.dig))
        #expect(handler.verbs.count == 1)
    }

    @Test("Handler does not require light")
    func testRequiresLightProperty() async throws {
        let handler = DigActionHandler()
        #expect(handler.requiresLight == false)
    }
}
