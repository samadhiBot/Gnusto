import CustomDump
import Testing

@testable import GnustoEngine

@Suite("ClimbOnActionHandler Tests")
struct ClimbOnActionHandlerTests {

    @Test("Climb on item gives default response")
    func testClimbOnItemGivesDefaultResponse() async throws {
        let chair = Item(
            id: "chair",
            .name("wooden chair"),
            .in(.location(.startRoom)),
            .isTakable
        )
        let game = MinimalGame(items: chair)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Initial state check
        let initialChair = try await engine.item("chair")
        #expect(initialChair.attributes[.isTouched] == nil)

        // Act
        try await engine.execute("climb on chair")

        // Assert State Change
        let finalChair = try await engine.item("chair")
        #expect(finalChair.hasFlag(.isTouched))

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > climb on chair
            You can’t climb on the wooden chair.
            """)
    }

    @Test("Climb on fails if item not accessible")
    func testClimbOnFailsIfNotAccessible() async throws {
        let chair = Item(
            id: "chair",
            .name("wooden chair"),
            .in(.nowhere),
            .isTakable
        )
        let game = MinimalGame(items: chair)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Act
        try await engine.execute("climb on chair")

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > climb on chair
            You can’t see any wooden chair here.
            """)
    }

    @Test("Climb on fails with no indirect object")
    func testClimbOnFailsWithNoObject() async throws {
        let (engine, mockIO) = await GameEngine.test()

        // Act
        try await engine.execute("climb on")

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > climb on
            Climb on what?
            """)
    }

    @Test("Climb on fails with non-item target")
    func testClimbOnFailsWithNonItemTarget() async throws {
        let (engine, mockIO) = await GameEngine.test()

        // Act
        try await engine.execute("climb on room")

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > climb on room
            You can only climb on specific items.
            """)
    }

    @Test("Climb on fails if item not reachable")
    func testClimbOnFailsIfNotReachable() async throws {
        let box = Item(
            id: "box",
            .name("locked box"),
            .in(.location(.startRoom)),
            .isContainer
            // Not open, so contents not reachable
        )
        let ladder = Item(
            id: "ladder",
            .name("small ladder"),
            .in(.item("box")),
            .isTakable
        )
        let game = MinimalGame(items: box, ladder)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Act
        try await engine.execute("climb on ladder")

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > climb on ladder
            You can’t see any small ladder here.
            """)
    }

    @Test("Climb on works on player inventory items")
    func testClimbOnWorksOnInventoryItems() async throws {
        let rope = Item(
            id: "rope",
            .name("climbing rope"),
            .in(.player),
            .isTakable
        )
        let game = MinimalGame(items: rope)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Act
        try await engine.execute("climb on rope")

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > climb on rope
            You can’t climb on the climbing rope.
            """)
    }

    @Test("Climb on works on large immovable items")
    func testClimbOnWorksOnImmovableItems() async throws {
        let tree = Item(
            id: "tree",
            .name("large oak tree"),
            .in(.location(.startRoom))
            // Not takable - immovable
        )
        let game = MinimalGame(items: tree)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Act
        try await engine.execute("climb on tree")

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > climb on tree
            You can’t climb on the large oak tree.
            """)

        // Assert State Change
        let finalTree = try await engine.item("tree")
        #expect(finalTree.hasFlag(.isTouched))
    }
}
