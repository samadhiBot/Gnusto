import Testing
import CustomDump
@testable import GnustoEngine

@Suite("ClimbOnActionHandler Tests")
struct ClimbOnActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("CLIMB ON syntax works")
    func testClimbOnSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let stump = Item(
            id: "stump",
            .name("wide stump"),
            .description("A wide, flat tree stump."),
            .isClimbable,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: stump
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("climb on stump")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > climb on stump
            You are now on the wide stump.
            """)
    }

    @Test("GET ON syntax works")
    func testGetOnSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let platform = Item(
            id: "platform",
            .name("wooden platform"),
            .description("A sturdy wooden platform."),
            .isClimbable,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: platform
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("get on platform")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > get on platform
            You are now on the wooden platform.
            """)
    }

    // MARK: - Validation Testing

    @Test("Cannot climb on without specifying target")
    func testCannotClimbOnWithoutTarget() async throws {
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
        try await engine.execute("climb on")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > climb on
            What do you want to climb on?
            """)
    }

    @Test("Cannot climb on item not in scope")
    func testCannotClimbOnItemNotInScope() async throws {
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

        let remoteStump = Item(
            id: "remoteStump",
            .name("remote stump"),
            .in(.location("anotherRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom, anotherRoom,
            items: remoteStump
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("climb on stump")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > climb on stump
            You can't see any such thing.
            """)
    }

    @Test("Requires light to climb on items")
    func testRequiresLight() async throws {
        // Given
        let darkRoom = Location(
            id: "darkRoom",
            .name("Dark Room"),
            .description("A pitch black room.")
        )

        let stump = Item(
            id: "stump",
            .name("wide stump"),
            .in(.location("darkRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom,
            items: stump
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("climb on stump")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > climb on stump
            It is pitch black. You can't see a thing.
            """)
    }

    // MARK: - Processing Testing

    @Test("Cannot climb on a non-climbable item")
    func testClimbOnNonClimbableItem() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let ball = Item(
            id: "ball",
            .name("slippery ball"),
            .description("A large, slippery ball."),
            // Note: Not .isClimbable
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: ball
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("climb on ball")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > climb on ball
            You can't climb on that.
            """)
        let finalState = try await engine.item("ball")
        #expect(finalState.hasFlag(.isTouched) == true)
    }

    // MARK: - ActionID Testing

    @Test("Handler exposes correct ActionIDs")
    func testActionIDs() async throws {
        let handler = ClimbOnActionHandler()
        #expect(handler.actions.isEmpty)
    }

    @Test("Handler exposes correct VerbIDs")
    func testVerbIDs() async throws {
        let handler = ClimbOnActionHandler()
        #expect(handler.verbs.contains(.climb))
        #expect(handler.verbs.contains(.sit))
        #expect(handler.verbs.count == 2)
    }

    @Test("Handler requires light")
    func testRequiresLightProperty() async throws {
        let handler = ClimbOnActionHandler()
        #expect(handler.requiresLight == true)
    }
}
