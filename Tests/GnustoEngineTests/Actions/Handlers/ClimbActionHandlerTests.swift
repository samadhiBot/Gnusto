import Testing
import CustomDump
@testable import GnustoEngine

@Suite("ClimbActionHandler Tests")
struct ClimbActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("CLIMB syntax works")
    func testClimbSyntax() async throws {
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
        try await engine.execute("climb")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > climb
            Climb what?
            """)
    }

    @Test("CLIMB DIRECTOBJECT syntax works")
    func testClimbDirectObjectSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let tree = Item(
            id: "tree",
            .name("tall tree"),
            .description("A tall oak tree."),
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
        try await engine.execute("climb tree")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > climb tree
            You climb the tall tree.
            """)

        let finalState = try await engine.item("tree")
        #expect(finalState.hasFlag(.isTouched) == true)
    }

    @Test("ASCEND syntax works")
    func testAscendSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let ladder = Item(
            id: "ladder",
            .name("wooden ladder"),
            .description("A sturdy wooden ladder."),
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
        try await engine.execute("ascend ladder")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > ascend ladder
            You climb the wooden ladder.
            """)
    }

    // MARK: - Validation Testing

    @Test("Cannot climb target not in scope")
    func testCannotClimbTargetNotInScope() async throws {
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
            .description("A tree in another room."),
            .isClimbable,
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
            You can’t see any such thing.
            """)
    }

    @Test("Cannot climb yourself")
    func testCannotClimbYourself() async throws {
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
        try await engine.execute("climb me")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > climb me
            You can’t climb yourself.
            """)
    }

    @Test("Requires light to climb")
    func testRequiresLight() async throws {
        // Given: Dark room with climbable object
        let darkRoom = Location(
            id: "darkRoom",
            .name("Dark Room"),
            .description("A pitch black room.")
        )

        let tree = Item(
            id: "tree",
            .name("tall tree"),
            .description("A tall oak tree."),
            .isClimbable,
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
            It is pitch black. You can’t see a thing.
            """)
    }

    // MARK: - Processing Testing

    @Test("Climb climbable object succeeds")
    func testClimbClimbableObject() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let rope = Item(
            id: "rope",
            .name("thick rope"),
            .description("A thick climbing rope."),
            .isClimbable,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: rope
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("climb rope")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > climb rope
            You climb the thick rope.
            """)

        let finalState = try await engine.item("rope")
        #expect(finalState.hasFlag(.isTouched) == true)
    }

    @Test("Climb non-climbable object fails")
    func testClimbNonClimbableObject() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let table = Item(
            id: "table",
            .name("heavy table"),
            .description("A heavy wooden table."),
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: table
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("climb table")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > climb table
            You can’t climb the heavy table.
            """)

        let finalState = try await engine.item("table")
        #expect(finalState.hasFlag(.isTouched) == true)
    }

    @Test("Climb object that enables exit traversal")
    func testClimbObjectEnablesExitTraversal() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit,
            .exits([
                .up: .to("upperRoom", via: "stairs")
            ])
        )

        let upperRoom = Location(
            id: "upperRoom",
            .name("Upper Room"),
            .inherentlyLit
        )

        let stairs = Item(
            id: "stairs",
            .name("wooden stairs"),
            .description("A set of wooden stairs leading up."),
            .isClimbable,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom, upperRoom,
            items: stairs
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("climb stairs")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > climb stairs

            — Upper Room —

            """)

        // Verify player moved
        let playerLocation = await engine.playerLocationID
        #expect(playerLocation == "upperRoom")
    }

    @Test("Climbing sets isTouched flag")
    func testClimbingSetsTouchedFlag() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let wall = Item(
            id: "wall",
            .name("stone wall"),
            .description("A rough stone wall."),
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: wall
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("climb wall")

        // Then
        let finalState = try await engine.item("wall")
        #expect(finalState.hasFlag(.isTouched) == true)
    }

    // MARK: - Intent Testing

    @Test("Handler exposes correct Intents")
    func testIntents() async throws {
        let handler = ClimbActionHandler()
        // ClimbActionHandler doesn’t specify actions, so it should be empty
        #expect(handler.actions.isEmpty)
    }

    @Test("Handler exposes correct Verbs")
    func testVerbs() async throws {
        let handler = ClimbActionHandler()
        #expect(handler.verbs.contains(.climb))
        #expect(handler.verbs.contains(.ascend))
        #expect(handler.verbs.count == 2)
    }

    @Test("Handler requires light")
    func testRequiresLightProperty() async throws {
        let handler = ClimbActionHandler()
        #expect(handler.requiresLight == true)
    }
}
