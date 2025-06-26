import Testing
import CustomDump
@testable import GnustoEngine

@Suite("ThinkActionHandler Tests")
struct ThinkActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("THINK syntax works")
    func testThinkSyntax() async throws {
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
        try await engine.execute("think")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > think
            You think deeply.
            """)
    }

    @Test("THINK ABOUT DIRECTOBJECT syntax works")
    func testThinkAboutDirectObjectSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let puzzle = Item(
            id: "puzzle",
            .name("ancient puzzle"),
            .description("A mysterious ancient puzzle."),
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: puzzle
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("think about puzzle")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > think about puzzle
            You ponder the ancient puzzle but gain no new insights.
            """)

        let finalState = try await engine.item("puzzle")
        #expect(finalState.hasFlag(.isTouched) == true)
    }

    // MARK: - Validation Testing

    @Test("Cannot think about item not in scope")
    func testCannotThinkAboutItemNotInScope() async throws {
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

        let remotePuzzle = Item(
            id: "remotePuzzle",
            .name("remote puzzle"),
            .description("A puzzle in another room."),
            .in(.location("anotherRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom, anotherRoom,
            items: remotePuzzle
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("think about puzzle")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > think about puzzle
            You can’t see any such thing.
            """)
    }

    @Test("Requires light to think about specific items")
    func testRequiresLightToThinkAboutItems() async throws {
        // Given: Dark room with an item
        let darkRoom = Location(
            id: "darkRoom",
            .name("Dark Room"),
            .description("A pitch black room.")
        )

        let riddle = Item(
            id: "riddle",
            .name("complex riddle"),
            .description("A complex riddle."),
            .in(.location("darkRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom,
            items: riddle
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("think about riddle")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > think about riddle
            It is pitch black. You can’t see a thing.
            """)
    }

    // MARK: - Processing Testing

    @Test("Think without object gives general response")
    func testThinkWithoutObject() async throws {
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
        try await engine.execute("think")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > think
            You think deeply.
            """)
    }

    @Test("Think works in dark rooms when no object specified")
    func testThinkWorksInDarkRoomsNoObject() async throws {
        // Given: Dark room (light not required for general thinking)
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
        try await engine.execute("think")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > think
            You think deeply.
            """)
    }

    @Test("Think about item sets isTouched flag")
    func testThinkAboutItemSetsTouchedFlag() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let problem = Item(
            id: "problem",
            .name("mathematical problem"),
            .description("A challenging mathematical problem."),
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: problem
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("think about problem")

        // Then
        let finalState = try await engine.item("problem")
        #expect(finalState.hasFlag(.isTouched) == true)
    }

    // MARK: - Intent Testing

    @Test("Handler exposes correct Intents")
    func testIntents() async throws {
        let handler = ThinkActionHandler()
        // ThinkActionHandler doesn’t specify actions, so it should be empty
        #expect(handler.actions.isEmpty)
    }

    @Test("Handler exposes correct Verbs")
    func testVerbs() async throws {
        let handler = ThinkActionHandler()
        #expect(handler.verbs.contains(.think))
        #expect(handler.verbs.count == 1)
    }

    @Test("Handler requires light for object-specific thinking")
    func testRequiresLightProperty() async throws {
        let handler = ThinkActionHandler()
        #expect(handler.requiresLight == true)
    }
}
