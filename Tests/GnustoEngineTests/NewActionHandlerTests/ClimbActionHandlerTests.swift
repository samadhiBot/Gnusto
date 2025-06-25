import Testing
import CustomDump
@testable import GnustoEngine

@Suite("ClimbActionHandler Tests")
struct ClimbActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("CLIMB syntax without object works")
    func testClimbSyntaxWithoutObject() async throws {
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
        try await engine.execute("climb")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > climb
            You can't climb here.
            """)
    }

    @Test("CLIMB UP syntax works")
    func testClimbUpSyntax() async throws {
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
        try await engine.execute("climb up")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > climb up
            You can't go that way.
            """)
    }

    @Test("SCALE syntax works")
    func testScaleSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let tree = Item(
            id: "tree",
            .name("tall tree"),
            .description("A tall, sturdy tree."),
            .isClimbable,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: tree
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("scale tree")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > scale tree
            (We'll pretend you're climbing the tall tree for now.)
            """)
    }

    // MARK: - Validation Testing

    @Test("Cannot climb item not in scope")
    func testCannotClimbItemNotInScope() async throws {
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

        let remoteTree = Item(
            id: "remoteTree",
            .name("remote tree"),
            .in(.location("anotherRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom, anotherRoom,
            items: remoteTree
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("climb tree")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > climb tree
            You can't see any such thing.
            """)
    }

    @Test("Requires light to climb items")
    func testRequiresLight() async throws {
        // Given
        let darkRoom = Location(
            id: "darkRoom",
            .name("Dark Room"),
            .description("A pitch black room.")
        )

        let tree = Item(
            id: "tree",
            .name("tall tree"),
            .in(.location("darkRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom,
            items: tree
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("climb tree")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > climb tree
            It is pitch black. You can't see a thing.
            """)
    }


    // MARK: - Processing Testing

    @Test("Climb a non-climbable item")
    func testClimbNonClimbableItem() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let rock = Item(
            id: "rock",
            .name("slippery rock"),
            .description("A large, slippery rock."),
            // Note: Not .isClimbable
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: rock
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("climb rock")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > climb rock
            You can't climb that.
            """)
    }

    @Test("Climb a climbable item")
    func testClimbClimbableItem() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let ladder = Item(
            id: "ladder",
            .name("sturdy ladder"),
            .description("A sturdy ladder leading up."),
            .isClimbable,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: ladder
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("climb ladder")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > climb ladder
            (We'll pretend you're climbing the sturdy ladder for now.)
            """)
        let finalState = try await engine.item("ladder")
        #expect(finalState.hasFlag(.isTouched) == true)
    }

    // MARK: - ActionID Testing

    @Test("Handler exposes correct ActionIDs")
    func testActionIDs() async throws {
        let handler = ClimbActionHandler()
        #expect(handler.actions.isEmpty)
    }

    @Test("Handler exposes correct VerbIDs")
    func testVerbIDs() async throws {
        let handler = ClimbActionHandler()
        #expect(handler.verbs.contains(.climb))
        #expect(handler.verbs.contains(.scale))
        #expect(handler.verbs.count == 2)
    }

    @Test("Handler requires light")
    func testRequiresLightProperty() async throws {
        let handler = ClimbActionHandler()
        #expect(handler.requiresLight == true)
    }
}
