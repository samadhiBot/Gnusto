import CustomDump
import Testing

@testable import GnustoEngine

@MainActor
@Suite("DropActionHandler Tests")
struct DropActionHandlerTests {
    let handler = DropActionHandler()

    // Helper to create the expected StateChange array for successful drop
    private func expectedDropChanges(
        itemID: ItemID,
        oldProperties: Set<ItemProperty>,
        newLocation: LocationID
    ) -> [StateChange] {
        var finalProperties = oldProperties
        finalProperties.insert(.touched)
        finalProperties.remove(.worn)

        var changes: [StateChange] = [
            StateChange(
                entityId: .item(itemID),
                propertyKey: .itemParent,
                oldValue: .parentEntity(.player),
                newValue: .parentEntity(.location(newLocation))
            )
        ]

        if oldProperties != finalProperties {
            changes.append(StateChange(
                entityId: .item(itemID),
                propertyKey: .itemProperties,
                oldValue: .itemProperties(oldProperties),
                newValue: .itemProperties(finalProperties)
            ))
        }
        // No pronoun changes expected for dropping (currently)
        return changes
    }

    @Test("Drop item successfully")
    func testDropItemSuccessfully() async throws {
        // Arrange: Create item
        let testItem = Item(
            id: "key",
            name: "brass key",
            properties: .takable,
            parent: .player
        )
        let initialProperties = testItem.properties

        let game = MinimalGame(items: [testItem])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        let finalLocation = engine.playerLocationID()

        #expect(engine.itemSnapshot(with: "key")?.parent == .player) // Verify setup
        #expect(engine.gameState.changeHistory.isEmpty == true)

        let command = Command(verbID: "drop", directObject: "key", rawInput: "drop key")

        // Act: Use engine.execute for full pipeline
        await engine.execute(command: command)

        // Assert Final State
        let finalItemState = engine.itemSnapshot(with: "key")
        #expect(finalItemState?.parent == .location(finalLocation), "Item should be in the room")
        #expect(finalItemState?.hasProperty(.touched) == true, "Item should have .touched property")

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "Dropped.")

        // Assert Change History
        let expectedChanges = expectedDropChanges(itemID: "key", oldProperties: initialProperties, newLocation: finalLocation)
        expectNoDifference(engine.gameState.changeHistory, expectedChanges)
    }

    @Test("Drop fails with no direct object")
    func testDropFailsWithNoObject() async throws {
        // Arrange
        let game = MinimalGame()
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
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
            properties: .takable,
            parent: .location("startRoom")
        )

        let game = MinimalGame(items: [testItem])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        #expect(engine.itemSnapshot(with: "key")?.parent == .location("startRoom"))
        #expect(engine.gameState.changeHistory.isEmpty == true)

        let command = Command(verbID: "drop", directObject: "key", rawInput: "drop key")

        // Act: Use engine.execute for full pipeline
        await engine.execute(command: command)

        // Assert Final State (Unchanged)
        let finalItemState = engine.itemSnapshot(with: "key")
        #expect(finalItemState?.parent == .location("startRoom"), "Item should still be in the room")

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "You aren't holding the brass key.")

        // Assert Change History (Should be empty)
        #expect(engine.gameState.changeHistory.isEmpty == true)
    }

    @Test("Drop worn item successfully removes worn property")
    func testDropWornItemSuccessfully() async throws {
        // Arrange: Create a wearable item
        let testItem = Item(
            id: "cloak",
            name: "dark cloak",
            properties: .takable, .wearable, .worn, // Start worn
            parent: .player
        )
        let initialProperties = testItem.properties

        let game = MinimalGame(items: [testItem])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        let finalLocation = engine.playerLocationID()

        #expect(engine.itemSnapshot(with: "cloak")?.parent == .player)
        #expect(engine.itemSnapshot(with: "cloak")?.hasProperty(.worn) == true)
        #expect(engine.gameState.changeHistory.isEmpty == true)

        let command = Command(verbID: "drop", directObject: "cloak", rawInput: "drop cloak")

        // Act: Use engine.execute for full pipeline
        await engine.execute(command: command)

        // Assert Final State
        let finalItemState = engine.itemSnapshot(with: "cloak")
        #expect(finalItemState?.parent == .location(finalLocation), "Item should be in the room")
        #expect(finalItemState?.hasProperty(.worn) == false, "Item should NOT have .worn property")
        #expect(finalItemState?.hasProperty(.touched) == true, "Item should have .touched property")

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "Dropped.")

        // Assert Change History
        let expectedChanges = expectedDropChanges(itemID: "cloak", oldProperties: initialProperties, newLocation: finalLocation)
        expectNoDifference(engine.gameState.changeHistory, expectedChanges)
    }

    @Test("Drop fixed item fails")
    func testDropFixedItemFails() async throws {
        // Arrange: Fixed item held by player
        let testItem = Item(
            id: "sword-in-stone",
            name: "sword in stone",
            properties: .fixed, // Item cannot be dropped
            parent: .player // Hypothetically held
        )
        let game = MinimalGame(items: [testItem])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
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
