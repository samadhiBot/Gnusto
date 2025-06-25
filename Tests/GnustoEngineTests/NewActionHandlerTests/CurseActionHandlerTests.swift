import Testing
import CustomDump
@testable import GnustoEngine

@Suite("CurseActionHandler Tests")
struct CurseActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("CURSE syntax without object works")
    func testCurseSyntaxWithoutObject() async throws {
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
        try await engine.execute("curse")

        // Then
        let output = await mockIO.flush().trimmingCharacters(in: .whitespacesAndNewlines)

        let possibleOutputs = [
            "> curse\nSuch language in a high-class establishment like this!",
            "> curse\nOh, dear! Such language.",
            "> curse\nMy, what a foul mouth you have."
        ].map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

        #expect(
            possibleOutputs.contains(output),
            "Output was not one of the expected random responses: \n\(output)"
        )
    }

    @Test("SWEAR AT syntax with object works")
    func testSwearAtSyntaxWithObject() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let rock = Item(
            id: "rock",
            .name("a stubborn rock"),
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: rock
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("swear at rock")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > swear at rock
            Such language in a high-class establishment like this!
            """)
    }

    @Test("DAMN syntax with object works")
    func testDamnSyntaxWithObject() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let troll = Item(
            id: "troll",
            .name("the troll"),
            .isCharacter,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: troll
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("damn troll")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > damn troll
            Oh, dear! Such language.
            """)
    }

    // MARK: - Validation Testing

    @Test("Cannot curse at item not in scope")
    func testCannotCurseAtItemNotInScope() async throws {
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

        let remoteTroll = Item(
            id: "remoteTroll",
            .name("remote troll"),
            .in(.location("anotherRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom, anotherRoom,
            items: remoteTroll
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("damn troll")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > damn troll
            You can't see any such thing.
            """)
    }

    @Test("Does not require light to curse at items")
    func testDoesNotRequireLight() async throws {
        // Given
        let darkRoom = Location(
            id: "darkRoom",
            .name("Dark Room"),
            .description("A pitch black room.")
        )

        let rock = Item(
            id: "rock",
            .name("a rock"),
            .in(.location("darkRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom,
            items: rock
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("curse rock")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > curse rock
            My, what a foul mouth you have.
            """)
    }

    // MARK: - ActionID Testing

    @Test("Handler exposes correct ActionIDs")
    func testActionIDs() async throws {
        let handler = CurseActionHandler()
        #expect(handler.actions.isEmpty)
    }

    @Test("Handler exposes correct VerbIDs")
    func testVerbIDs() async throws {
        let handler = CurseActionHandler()
        #expect(handler.verbs.contains(.curse))
        #expect(handler.verbs.contains(.swear))
        #expect(handler.verbs.contains(.damn))
        #expect(handler.verbs.count == 3)
    }

    @Test("Handler does not require light")
    func testRequiresLightProperty() async throws {
        let handler = CurseActionHandler()
        #expect(handler.requiresLight == false)
    }
}
