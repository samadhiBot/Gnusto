import CustomDump
import Testing

@testable import GnustoEngine

@Suite("DropActionHandler Tests")
struct DropActionHandlerTests {
    @Test("Drop item successfully")
    func testDropItemSuccessfully() async throws {
        // Arrange: Create item
        let testItem = Item(
            id: "key",
            .name("brass key"),
            .in(.player),
            .isTakable
        )
        let initialParent = testItem.parent
        let initialTouched = testItem.hasFlag(.isTouched)
        let initialWorn = testItem.hasFlag(.isWorn)

        let game = MinimalGame(items: testItem)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)
        let finalLocation = await engine.playerLocationID

        #expect(try await engine.item("key").parent == .player)  // Verify setup
        #expect(await engine.gameState.changeHistory.isEmpty)

        // Act
        try await engine.execute("drop key")

        // Assert Final State
        let finalItemState = try await engine.item("key")
        #expect(finalItemState.parent == .location(finalLocation), "Item should be in the room")
        #expect(finalItemState.hasFlag(.isTouched) == true, "Item should have .touched property")  // Qualified

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > drop key
            Dropped.
            """)

        // Assert Change History
        let expectedChanges = expectedDropChanges(
            itemID: "key",
            initialParent: initialParent,
            newLocation: finalLocation,
            initialTouched: initialTouched,
            initialWorn: initialWorn
        )
        let changeHistory = await engine.gameState.changeHistory
        expectNoDifference(changeHistory, expectedChanges)
    }

    @Test("Drop fails with no direct object")
    func testDropFailsWithNoObject() async throws {
        // Arrange
        let (engine, mockIO) = await GameEngine.test()

        // Act
        try await engine.execute("drop")

        // Assert: Expect error from validate()
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > drop
            Drop what?
            """)
    }

    @Test("Drop fails when item not held")
    func testDropFailsWhenNotHeld() async throws {
        // Arrange: Item exists but is in the room
        let testItem = Item(
            id: "key",
            .name("brass key"),
            .in(.location(.startRoom)),
            .isTakable
        )

        let game = MinimalGame(items: testItem)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        #expect(try await engine.item("key").parent == .location(.startRoom))
        #expect(await engine.gameState.changeHistory.isEmpty)

        // Act
        try await engine.execute("drop key")

        // Assert Final State (Unchanged)
        let finalItemState = try await engine.item("key")
        #expect(finalItemState.parent == .location(.startRoom), "Item should still be in the room")

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > drop key
            You aren’t holding the brass key.
            """)

        // Assert Change History (Should be empty)
        #expect(await engine.gameState.changeHistory.isEmpty)
    }

    @Test("Drop worn item successfully removes worn property")
    func testDropWornItemSuccessfully() async throws {
        // Arrange: Create a wearable item
        let testItem = Item(
            id: "cloak",
            .name("dark cloak"),
            .in(.player),
            .isTakable,
            .isWearable,
            .isWorn
        )
        let initialParent = testItem.parent
        let initialTouched = testItem.hasFlag(.isTouched)
        let initialWorn = testItem.hasFlag(.isWorn)

        let game = MinimalGame(items: testItem)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)
        let finalLocation = await engine.playerLocationID

        #expect(try await engine.item("cloak").parent == .player)
        #expect(try await engine.item("cloak").hasFlag(.isWorn) == true)  // Qualified
        #expect(await engine.gameState.changeHistory.isEmpty)

        // Act
        try await engine.execute("drop cloak")

        // Assert Final State
        let finalItemState = try await engine.item("cloak")
        #expect(finalItemState.parent == .location(finalLocation), "Item should be in the room")
        #expect(finalItemState.hasFlag(.isWorn) == false, "Item should NOT have .worn property")  // Qualified
        #expect(finalItemState.hasFlag(.isTouched) == true, "Item should have .touched property")  // Qualified

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > drop cloak
            Dropped.
            """)

        // Assert Change History
        let expectedChanges = expectedDropChanges(
            itemID: "cloak",
            initialParent: initialParent,
            newLocation: finalLocation,
            initialTouched: initialTouched,
            initialWorn: initialWorn
        )
        let changeHistory = await engine.gameState.changeHistory
        expectNoDifference(changeHistory, expectedChanges)
    }
}

extension DropActionHandlerTests {
    /// Helper to create the expected StateChange array for successful drop.
    private func expectedDropChanges(
        itemID: ItemID,
        initialParent: ParentEntity,
        newLocation: LocationID,
        initialTouched: Bool,
        initialWorn: Bool
    ) -> [StateChange] {
        var changes: [StateChange] = []

        // Parent change
        changes.append(
            StateChange(
                entityID: .item(itemID),
                attribute: .itemParent,
                oldValue: .parentEntity(initialParent),
                newValue: .parentEntity(.location(newLocation))
            )
        )

        // Touched change (if needed)
        if !initialTouched {
            changes.append(
                StateChange(
                    entityID: .item(itemID),
                    attribute: .itemAttribute(.isTouched),
                    newValue: true,
                )
            )
        }

        // Update pronoun
        changes.append(
            StateChange(
                entityID: .global,
                attribute: .pronounReference(pronoun: "it"),
                newValue: .entityReferenceSet([.item(itemID)])
            )
        )

        // Worn change (if needed)
        if initialWorn {
            changes.append(
                StateChange(
                    entityID: .item(itemID),
                    attribute: .itemAttribute(.isWorn),
                    oldValue: true,
                    newValue: false
                )
            )
        }

        return changes
    }
}
