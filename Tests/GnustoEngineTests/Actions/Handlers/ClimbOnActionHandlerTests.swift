import CustomDump
import Testing

@testable import GnustoEngine

@Suite("ClimbOnActionHandler Tests")
struct ClimbOnActionHandlerTests {
    let handler = ClimbOnActionHandler()

    @Test("Climb on item gives default response")
    func testClimbOnItemGivesDefaultResponse() async throws {
        let chair = Item(
            id: "chair",
            .name("wooden chair"),
            .in(.location(.startRoom)),
            .isTakable
        )
        let game = MinimalGame(items: [chair])
        let (engine, mockIO) = await GameEngine.test()

        let command = Command(
            verb: .climbOn,
            indirectObject: .item("chair"),
            rawInput: "climb on chair"
        )

        // Initial state check
        let initialChair = try await engine.item("chair")
        #expect(initialChair.attributes[.isTouched] == nil)
        #expect(await engine.gameState.changeHistory.isEmpty)

        // Act
        await engine.execute(command: command)

        // Assert State Change
        let finalChair = try await engine.item("chair")
        #expect(finalChair.hasFlag(.isTouched))

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "You can’t climb on the wooden chair.")

        // Assert changes
        let changeHistory = await engine.gameState.changeHistory
        expectNoDifference(changeHistory, [
            StateChange(
                entityID: .item(
                    ItemID(rawValue: "chair")
                ),
                attribute: .itemAttribute(
                    ItemAttributeID(rawValue: "isTouched")
                ),
                newValue: true
            ),
            StateChange(
                entityID: .global,
                attribute: .pronounReference(pronoun: "it"),
                newValue: .entityReferenceSet(
                    Set([
                        .item(
                            ItemID(rawValue: "chair")
                        )
                    ])
                )
            )

        ])
    }

    @Test("Climb on fails if item not accessible")
    func testClimbOnFailsIfNotAccessible() async throws {
        let chair = Item(
            id: "chair",
            .name("wooden chair"),
            .in(.nowhere),
            .isTakable
        )
        let game = MinimalGame(items: [chair])
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        let command = Command(
            verb: .climbOn,
            indirectObject: .item("chair"),
            rawInput: "climb on chair"
        )

        // Act
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "You can’t see any such thing.")

        #expect(await engine.gameState.changeHistory.isEmpty)
    }

    @Test("Climb on fails with no indirect object")
    func testClimbOnFailsWithNoObject() async throws {
        let (engine, mockIO) = await GameEngine.test()

        // Act
        try await engine.execute("climb on")

        // Assert: Expect error from validate()
        let output = await mockIO.flush()
        expectNoDifference(output, "Climb on what?")

        #expect(await engine.gameState.changeHistory.isEmpty)
    }

    @Test("Climb on fails with non-item target")
    func testClimbOnFailsWithNonItemTarget() async throws {
        let (engine, mockIO) = await GameEngine.test()

        let command = Command(
            verb: .climbOn,
            indirectObject: .location(.startRoom),
            rawInput: "climb on room"
        )

        // Act
        await engine.execute(command: command)

        // Assert: Expect error from validate()
        let output = await mockIO.flush()
        expectNoDifference(output, "You can’t climb on that.")

        #expect(await engine.gameState.changeHistory.isEmpty)
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
        let game = MinimalGame(items: [box, ladder])
        let (engine, mockIO) = await GameEngine.test()

        let command = Command(
            verb: .climbOn,
            indirectObject: .item("ladder"),
            rawInput: "climb on ladder"
        )

        // Act
        await engine.execute(command: command)

        // Assert: Expect error from validate()
        let output = await mockIO.flush()
        expectNoDifference(output, "You can’t see any such thing.")

        #expect(await engine.gameState.changeHistory.isEmpty)
    }

    @Test("Climb on works on player inventory items")
    func testClimbOnWorksOnInventoryItems() async throws {
        let rope = Item(
            id: "rope",
            .name("climbing rope"),
            .in(.player),
            .isTakable
        )
        let game = MinimalGame(items: [rope])
        let (engine, mockIO) = await GameEngine.test()

        let command = Command(
            verb: .climbOn,
            indirectObject: .item("rope"),
            rawInput: "climb on rope"
        )

        // Act
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "You can’t climb on the climbing rope.")
    }

    @Test("Climb on works on large immovable items")
    func testClimbOnWorksOnImmovableItems() async throws {
        let tree = Item(
            id: "tree",
            .name("large oak tree"),
            .in(.location(.startRoom))
            // Not takable - immovable
        )
        let game = MinimalGame(items: [tree])
        let (engine, mockIO) = await GameEngine.test()

        let command = Command(
            verb: .climbOn,
            indirectObject: .item("tree"),
            rawInput: "climb on tree"
        )

        // Act
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "You can’t climb on the large oak tree.")
    }

    @Test("Climb on works on items on surfaces")
    func testClimbOnWorksOnItemsOnSurfaces() async throws {
        let table = Item(
            id: "table",
            .name("wooden table"),
            .in(.location(.startRoom)),
            .isSurface,
            .isOpen
        )
        let stool = Item(
            id: "stool",
            .name("small stool"),
            .in(.item("table")),
            .isTakable
        )
        let game = MinimalGame(items: [table, stool])
        let (engine, mockIO) = await GameEngine.test()

        let command = Command(
            verb: .climbOn,
            indirectObject: .item("stool"),
            rawInput: "climb on stool"
        )

        // Act
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "You can’t climb on the small stool.")
    }
}
