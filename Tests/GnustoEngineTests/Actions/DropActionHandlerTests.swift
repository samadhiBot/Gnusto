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
            name: "brass key",
            parent: .player,
            attributes: [
                .isTakable: true
            ]
        )
        let initialParent = testItem.parent
        let initialTouched = testItem.hasFlag(.isTouched)
        let initialWorn = testItem.hasFlag(.isWorn)

        let game = MinimalGame(items: [testItem])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        let finalLocation = await engine.gameState.player.currentLocationID

        #expect(await engine.item("key")?.parent == .player) // Verify setup
        #expect(await engine.gameState.changeHistory.isEmpty == true)

        let command = Command(verbID: "drop", directObject: "key", rawInput: "drop key")

        // Act: Use engine.execute for full pipeline
        await engine.execute(command: command)

        // Assert Final State
        let finalItemState = await engine.item("key")
        #expect(finalItemState?.parent == .location(finalLocation), "Item should be in the room")
        #expect(finalItemState?.hasFlag(.isTouched) == true, "Item should have .touched property") // Qualified

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "Dropped.")

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
        let game = MinimalGame()
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        let command = Command(verbID: "drop", rawInput: "drop") // No direct object

        // Act
        await engine.execute(command: command)

        // Assert: Expect error from validate()
        let output = await mockIO.flush()
        expectNoDifference(output, "Drop what?")
    }

    @Test("Drop fails when item not held")
    func testDropFailsWhenNotHeld() async throws {
        // Arrange: Item exists but is in the room
        let testItem = Item(
            id: "key",
            name: "brass key",
            parent: .location("startRoom"),
            attributes: [
                .isTakable: true
            ]
        )

        let game = MinimalGame(items: [testItem])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        #expect(await engine.item("key")?.parent == .location("startRoom"))
        #expect(await engine.gameState.changeHistory.isEmpty == true)

        let command = Command(verbID: "drop", directObject: "key", rawInput: "drop key")

        // Act: Use engine.execute for full pipeline
        await engine.execute(command: command)

        // Assert Final State (Unchanged)
        let finalItemState = await engine.item("key")
        #expect(finalItemState?.parent == .location("startRoom"), "Item should still be in the room")

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "You aren't holding the brass key.")

        // Assert Change History (Should be empty)
        #expect(await engine.gameState.changeHistory.isEmpty == true)
    }

    @Test("Drop worn item successfully removes worn property")
    func testDropWornItemSuccessfully() async throws {
        // Arrange: Create a wearable item
        let testItem = Item(
            id: "cloak",
            name: "dark cloak",
            parent: .player,
            attributes: [
                .isTakable: true,
                .isWearable: true,
                .isWorn: true
            ]
        )
        let initialParent = testItem.parent
        let initialTouched = testItem.hasFlag(.isTouched)
        let initialWorn = testItem.hasFlag(.isWorn)

        let game = MinimalGame(items: [testItem])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        let finalLocation = await engine.gameState.player.currentLocationID

        #expect(await engine.item("cloak")?.parent == .player)
        #expect(await engine.item("cloak")?.hasFlag(.isWorn) == true) // Qualified
        #expect(await engine.gameState.changeHistory.isEmpty == true)

        let command = Command(verbID: "drop", directObject: "cloak", rawInput: "drop cloak")

        // Act: Use engine.execute for full pipeline
        await engine.execute(command: command)

        // Assert Final State
        let finalItemState = await engine.item("cloak")
        #expect(finalItemState?.parent == .location(finalLocation), "Item should be in the room")
        #expect(finalItemState?.hasFlag(.isWorn) == false, "Item should NOT have .worn property") // Qualified
        #expect(finalItemState?.hasFlag(.isTouched) == true, "Item should have .touched property") // Qualified

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "Dropped.")

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

    @Test("Drop fixed item fails")
    func testDropFixedItemFails() async throws {
        // Arrange: Fixed item held by player
        let testItem = Item(
            id: "sword-in-stone",
            name: "sword in stone",
            parent: .player, // Hypothetically held
            attributes: [
                .isFixed: true
            ]
        )
        let game = MinimalGame(items: [testItem])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        let command = Command(verbID: "drop", directObject: "sword-in-stone", rawInput: "drop sword")

        // Act
        await engine.execute(command: command)

        // Assert: Expect error from validate()
        let output = await mockIO.flush()
        expectNoDifference(output, "You can't drop the sword in stone.")
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
        changes.append(StateChange(
            entityID: .item(itemID),
            attributeKey: .itemParent,
            oldValue: .parentEntity(initialParent),
            newValue: .parentEntity(.location(newLocation))
        ))

        // Touched change (if needed)
        if !initialTouched {
            changes.append(StateChange(
                entityID: .item(itemID),
                attributeKey: .itemAttribute(.isTouched),
                oldValue: nil,
                newValue: true,
            ))
        }

        // Update pronoun
        changes.append(StateChange(
            entityID: .global,
            attributeKey: .pronounReference(pronoun: "it"),
            oldValue: nil,
            newValue: .itemIDSet([itemID])
        ))

        // Worn change (if needed)
        if initialWorn {
            changes.append(StateChange(
                entityID: .item(itemID),
                attributeKey: .itemAttribute(.isWorn),
                oldValue: true,
                newValue: false
            ))
        }

        return changes
    }
}
