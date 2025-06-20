import CustomDump
import Testing

@testable import GnustoEngine

@Suite("ClimbActionHandler Tests")
struct ClimbActionHandlerTests {
    // MARK: - No Object Tests

    @Test("Climb with no object asks what to climb")
    func testClimbNoObject() async throws {
        let (engine, mockIO) = await GameEngine.test()

        // Act
        try await engine.execute("climb")

        // Assert
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > climb
            Climb what?
            """)
    }

    // MARK: - Exit Traversal Tests

    @Test("Climb stairs to go up")
    func testClimbStairsGoesUp() async throws {
        // Arrange: Create locations with stairs exit
        let kitchen = Location(
            id: "kitchen",
            .name("Kitchen"),
            .exits([
                .up: .to("attic", via: "stairs")
            ]),
            .inherentlyLit,
            .localGlobals("stairs")
        )

        let attic = Location(
            id: "attic",
            .name("Attic"),
            .inherentlyLit
        )

        let stairs = Item(
            id: "stairs",
            .name("stairs"),
            .synonyms("staircase", "stairway", "steps"),
            .isClimbable,
            .in(.nowhere)  // Global item
        )

        let player = Player(in: "kitchen")
        let game = MinimalGame(
            player: player,
            locations: kitchen, attic,
            items: stairs
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Act
        try await engine.execute("climb stairs")

        // Assert: Player should have moved to attic
        let finalPlayerLocation = try await engine.playerLocation()
        #expect(finalPlayerLocation.id == "attic")

        // Check that stairs is marked as touched
        let finalStairs = try await engine.item("stairs")
        #expect(finalStairs.hasFlag(.isTouched))

        let output = await mockIO.flush()
        expectNoDifference(output, """
            > climb stairs
            — Attic —

            You are in a nondescript location.
            """)
    }

    @Test("Climb ladder to go down")
    func testClimbLadderGoesDown() async throws {
        // Arrange: Create a scenario where ladder enables going down
        let topRoom = Location(
            id: "top",
            .name("Top"),
            .exits([
                .down: .to("bottom", via: "ladder")
            ]),
            .inherentlyLit,
            .localGlobals("ladder")
        )

        let bottomRoom = Location(
            id: "bottom",
            .name("Bottom"),
            .inherentlyLit
        )

        let ladder = Item(
            id: "ladder",
            .name("wooden ladder"),
            .synonyms("ladder"),
            .adjectives("wooden", "rickety"),
            .isClimbable,
            .in(.nowhere)  // Global item
        )

        let player = Player(in: "top")
        let game = MinimalGame(
            player: player,
            locations: topRoom, bottomRoom,
            items: ladder
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Act
        try await engine.execute("climb ladder")

        // Assert: Player should have moved to bottom
        let finalPlayerLocation = try await engine.playerLocation()
        #expect(finalPlayerLocation.id == "bottom")

        let output = await mockIO.flush()
        expectNoDifference(output, """
            > climb ladder
            — Bottom —

            You are in a nondescript location.
            """)
    }

    @Test("Climb rope enables multiple directions")
    func testClimbRopeMultipleDirections() async throws {
        // Arrange: Test rope that enables both up and down
        let middleRoom = Location(
            id: "middle",
            .name("Middle"),
            .exits([
                .up: .to("top", via: "rope"),
                .down: .to("bottom", via: "rope"),
            ]),
            .inherentlyLit,
            .localGlobals("rope")
        )

        let topRoom = Location(id: "top", .name("Top"), .inherentlyLit)
        let bottomRoom = Location(id: "bottom", .name("Bottom"), .inherentlyLit)

        let rope = Item(
            id: "rope",
            .name("rope"),
            .synonyms("rope", "hemp", "coil"),
            .isClimbable,
            .in(.nowhere)  // Global item
        )

        let player = Player(in: "middle")
        let game = MinimalGame(
            player: player,
            locations: middleRoom, topRoom, bottomRoom,
            items: rope
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Act
        try await engine.execute("climb rope")

        // Assert: Should prioritize up over down (consistent direction ordering)
        let finalPlayerLocation = try await engine.playerLocation()
        #expect(finalPlayerLocation.id == "top")

        let output = await mockIO.flush()
        expectNoDifference(output, """
            > climb rope
            — Top —

            You are in a nondescript location.
            """)
    }

    // MARK: - Global Object Validation Tests

    @Test("Climb stairs when not present in location")
    func testClimbStairsNotPresent() async throws {
        // Arrange: Location without stairs in localGlobals
        let room = Location(
            id: "room",
            .name("Empty Room"),
            .inherentlyLit
            // No localGlobals with stairs
        )

        let stairs = Item(
            id: "stairs",
            .name("stairs"),
            .isClimbable,
            .in(.nowhere)  // Global item
        )

        let player = Player(in: "room")
        let game = MinimalGame(
            player: player,
            locations: room,
            items: stairs
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Act
        try await engine.execute("climb stairs")

        // Assert: Should get error message
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > climb stairs
            You can’t see any stairs here.
            """)
    }

    // MARK: - Regular Climbing Tests

    @Test("Climb climbable object (not used by exits)")
    func testClimbClimbableObject() async throws {
        // Arrange: Climbable tree not used by any exits
        let tree = Item(
            id: "tree",
            .name("oak tree"),
            .synonyms("tree", "oak"),
            .isClimbable,
            .in(.location(.startRoom))
        )

        let game = MinimalGame(items: tree)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Act
        try await engine.execute("climb tree")

        // Assert: Should get default climbing message
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > climb tree
            You climb the oak tree.
            """)

        // Check that tree is marked as touched
        let finalTree = try await engine.item("tree")
        #expect(finalTree.hasFlag(.isTouched))
    }

    @Test("Climb non-climbable object")
    func testClimbNonClimbableObject() async throws {
        // Arrange: Non-climbable table
        let table = Item(
            id: "table",
            .name("wooden table"),
            .synonyms("table"),
            .adjectives("wooden"),
            .in(.location(.startRoom))
            // No .isClimbable flag
        )

        let game = MinimalGame(items: table)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Act
        try await engine.execute("climb table")

        // Assert: Should get error message
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > climb table
            You can’t climb the wooden table.
            """)
    }

    // MARK: - Error Cases

    @Test("Climb item not in scope fails validation")
    func testClimbItemNotInScope() async throws {
        // Arrange: Item exists but not reachable
        let distantTree = Item(
            id: "tree",
            .name("distant tree"),
            .isClimbable,
            .in(.location("distantPlace"))  // Not in player's location
        )

        let game = MinimalGame(items: distantTree)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Act
        try await engine.execute("climb tree")

        // Assert: Should get error message
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > climb tree
            You can’t see any tree here.
            """)
    }

    @Test("Climb nonexistent item fails validation")
    func testClimbNonexistentItem() async throws {
        let (engine, mockIO) = await GameEngine.test()

        // Act
        try await engine.execute("climb nonexistent")

        // Assert: Should get error message
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > climb nonexistent
            You can’t see any such thing.
            """)
    }

    @Test("Climb non-item entity")
    func testClimbNonItemEntity() async throws {
        let (engine, mockIO) = await GameEngine.test()

        // Act
        try await engine.execute("climb me")

        // Assert: Should get error message
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > climb me
            You can’t climb yourself.
            """)
    }

    // MARK: - Movement Failure Tests

    @Test("Climb stairs with blocked exit")
    func testClimbStairsBlockedExit() async throws {
        // Arrange: Stairs present but exit is blocked
        let room = Location(
            id: "room",
            .name("Room"),
            .exits([
                .up: .to("attic", via: "stairs", else: "The ceiling is too low.")
            ]),
            .inherentlyLit,
            .localGlobals("stairs")
        )

        let attic = Location(
            id: "attic",
            .name("Attic"),
            .inherentlyLit
        )

        let stairs = Item(
            id: "stairs",
            .name("stairs"),
            .isClimbable,
            .in(.nowhere)
        )

        let player = Player(in: "room")
        let game = MinimalGame(
            player: player,
            locations: room, attic,
            items: stairs
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Act
        try await engine.execute("climb stairs")

        // Assert: Should get the blocked exit message
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > climb stairs
            The ceiling is too low.
            """)
    }

    @Test("Climb stairs with no exit fails")
    func testClimbStairsNoExit() async throws {
        // Arrange: Stairs present but no exit in any direction
        let room = Location(
            id: "room",
            .name("Room"),
            .inherentlyLit,
            .localGlobals("stairs")
            // No exits at all
        )

        let stairs = Item(
            id: "stairs",
            .name("stairs"),
            .isClimbable,
            .in(.nowhere)
        )

        let player = Player(in: "room")
        let game = MinimalGame(
            player: player,
            locations: room,
            items: stairs
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Act
        try await engine.execute("climb stairs")

        // Assert: Should default to regular climbing behavior since no exit uses stairs
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > climb stairs
            You climb the stairs.
            """)
    }

    @Test("Climb stairs from lit to dark room shows transition and custom darkness message")
    func testClimbToDarkRoomWithCustomMessage() async throws {
        // Arrange: Kitchen (lit) with stairs leading to dark attic
        let kitchen = Location(
            id: "kitchen",
            .name("Kitchen"),
            .exits([
                .up: .to("attic", via: "stairs")
            ]),
            .inherentlyLit,
            .localGlobals("stairs")
        )

        let attic = Location(
            id: "attic",
            .name("Attic"),
            .description("A dark attic.")
            // No .inherentlyLit, so it's dark
        )

        let stairs = Item(
            id: "stairs",
            .name("stairs"),
            .isClimbable,
            .in(.nowhere)
        )

        let game = MinimalGame(
            player: Player(in: "kitchen"),
            locations: kitchen, attic,
            items: stairs
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Act
        try await engine.execute("climb stairs")

        // Assert: Player moved to attic
        let finalPlayerLocation = try await engine.playerLocation()
        #expect(finalPlayerLocation.id == "attic")

        // Assert: Output contains both transition and darkness messages
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > climb stairs
            You are plunged into darkness.
            It is pitch black. You can’t see a thing.
            """)
    }

    @Test("Climb stairs from lit to lit room shows normal room description (no transition message)")
    func testClimbToLitRoomNoTransitionMessage() async throws {
        // Arrange: Kitchen (lit) with stairs leading to lit living room
        let kitchen = Location(
            id: "kitchen",
            .name("Kitchen"),
            .exits([
                .up: .to("livingroom", via: "stairs")
            ]),
            .inherentlyLit,
            .localGlobals("stairs")
        )

        let livingRoom = Location(
            id: "livingroom",
            .name("Living Room"),
            .description("A cozy living room."),
            .inherentlyLit
        )

        let stairs = Item(
            id: "stairs",
            .name("stairs"),
            .isClimbable,
            .in(.nowhere)
        )

        let game = MinimalGame(
            player: Player(in: "kitchen"),
            locations: kitchen, livingRoom,
            items: stairs
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Act
        try await engine.execute("climb stairs")

        // Assert: Player moved to living room
        let finalPlayerLocation = try await engine.playerLocation()
        #expect(finalPlayerLocation.id == "livingroom")

        // Assert: Output shows normal room description (no transition message since both rooms are lit)
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > climb stairs
            — Living Room —
            A cozy living room.
            """)
    }
}
