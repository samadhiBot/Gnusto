import CustomDump
import GnustoEngine
import GnustoTestSupport
import Testing

@Suite("ClimbActionHandler Tests")
struct ClimbActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("CLIMB syntax works")
    func testClimbSyntax() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("climb")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > climb
            Climb what?
            """
        )
    }

    @Test("CLIMB DIRECTOBJECT syntax works")
    func testClimbDirectObjectSyntax() async throws {
        // Given
        let tree = Item(
            id: "tree",
            .name("tall tree"),
            .description("A tall oak tree."),
            .isClimbable,
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: tree
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("climb tree")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > climb tree
            You climb the tall tree.
            """
        )

        let finalState = try await engine.item("tree")
        #expect(await finalState.hasFlag(.isTouched) == true)
    }

    @Test("ASCEND syntax works")
    func testAscendSyntax() async throws {
        // Given
        let ladder = Item(
            id: "ladder",
            .name("wooden ladder"),
            .description("A sturdy wooden ladder."),
            .isClimbable,
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: ladder
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("ascend ladder")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > ascend ladder
            You climb the wooden ladder.
            """
        )
    }

    // MARK: - Validation Testing

    @Test("Cannot climb target not in scope")
    func testCannotClimbTargetNotInScope() async throws {
        // Given
        let anotherRoom = Location(
            id: "anotherRoom",
            .name("Another Room"),
            .inherentlyLit
        )

        let remoteTree = Item(
            id: "remoteTree",
            .name("tree"),
            .description("A tree in another room."),
            .isClimbable,
            .in("anotherRoom")
        )

        let game = MinimalGame(
            locations: anotherRoom,
            items: remoteTree
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("climb tree")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > climb tree
            Any such thing lurks beyond your reach.
            """
        )
    }

    @Test("Cannot climb yourself")
    func testCannotClimbYourself() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("climb me")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > climb me
            The logistics of climbing oneself prove insurmountable.
            """
        )
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
            .in("darkRoom")
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
        expectNoDifference(
            output,
            """
            > climb tree
            The darkness here is absolute, consuming all light and hope of
            sight.
            """
        )
    }

    // MARK: - Processing Testing

    @Test("Climb climbable object succeeds")
    func testClimbClimbableObject() async throws {
        // Given
        let rope = Item(
            id: "rope",
            .name("thick rope"),
            .description("A thick climbing rope."),
            .isClimbable,
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: rope
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("climb rope")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > climb rope
            You climb the thick rope.
            """
        )

        let finalState = try await engine.item("rope")
        #expect(await finalState.hasFlag(.isTouched) == true)
    }

    @Test("Climb non-climbable object fails")
    func testClimbNonClimbableObject() async throws {
        // Given
        let table = Item(
            id: "table",
            .name("heavy table"),
            .description("A heavy wooden table."),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: table
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("climb table")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > climb table
            The heavy table stubbornly resists your attempts to climb it.
            """
        )

        let finalState = try await engine.item("table")
        #expect(await finalState.hasFlag(.isTouched) == true)
    }

    @Test("Climb object that enables exit traversal")
    func testClimbObjectEnablesExitTraversal() async throws {
        // Given
        let roundRoom = Location(
            id: "roundRoom",
            .name("Round Room"),
            .description("This is a round room with a set of wooden stairs leading up."),
            .inherentlyLit,
            .exits(
                .up("upperRoom", via: "stairs"),
            )
        )

        let upperRoom = Location(
            id: "upperRoom",
            .name("Upper Room"),
            .inherentlyLit
        )

        let stairs = Item(
            id: "stairs",
            .name("wooden stairs"),
            .description("You see a polished set of wooden stairs leading up."),
            .omitDescription,
            .isClimbable,
            .isPlural,
            .in("roundRoom")
        )

        let game = MinimalGame(
            player: Player(in: "roundRoom"),
            locations: roundRoom, upperRoom,
            items: stairs
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute(
            """
            look
            examine the stairs
            climb stairs
            """
        )

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > look
            --- Round Room ---

            This is a round room with a set of wooden stairs leading up.

            > examine the stairs
            You see a polished set of wooden stairs leading up.

            > climb stairs
            --- Upper Room ---

            This location is still under construction. The game developers
            apologize for any inconvenience.
            """
        )

        // Verify player moved
        let playerLocation = try await engine.player.location.id
        #expect(playerLocation == "upperRoom")
    }

    @Test("Climbing sets isTouched flag")
    func testClimbingSetsTouchedFlag() async throws {
        // Given
        let wall = Item(
            id: "wall",
            .name("stone wall"),
            .description("A rough stone wall."),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: wall
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("climb wall")

        // Then
        let finalState = try await engine.item("wall")
        #expect(await finalState.hasFlag(.isTouched) == true)
    }

    // MARK: - Intent Testing

    @Test("Handler exposes correct Verbs")
    func testVerbs() async throws {
        let handler = ClimbActionHandler()
        #expect(handler.synonyms.contains(.climb))
        #expect(handler.synonyms.contains(.ascend))
        #expect(handler.synonyms.count == 2)
    }

    @Test("Handler requires light")
    func testRequiresLightProperty() async throws {
        let handler = ClimbActionHandler()
        #expect(handler.requiresLight == true)
    }
}
