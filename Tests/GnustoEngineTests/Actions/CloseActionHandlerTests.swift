import CustomDump
import Testing

@testable import GnustoEngine

@MainActor
@Suite("CloseActionHandler Tests")
struct CloseActionHandlerTests {
    let handler = CloseActionHandler() // Keep for error tests

    // Helper to create the expected StateChange array for successful close
    private func expectedCloseChanges(
        itemID: ItemID,
        oldProperties: Set<ItemProperty>
    ) -> [StateChange] {
        var finalProperties = oldProperties
        finalProperties.remove(.open)
        finalProperties.insert(.touched)

        var changes: [StateChange] = []

        if oldProperties != finalProperties {
            changes.append(StateChange(
                entityId: .item(itemID),
                propertyKey: .itemProperties,
                oldValue: .itemProperties(oldProperties),
                newValue: .itemProperties(finalProperties)
            ))
        }
        // No pronoun changes expected for closing
        return changes
    }

    @Test("Close item successfully")
    func testCloseItemSuccessfully() async throws {
        // Arrange
        let box = Item(
            id: "box",
            name: "wooden box",
            properties: .container, .openable, .open,
            parent: .location("startRoom")
        )
        let initialProperties = box.properties // Capture initial state

        let game = MinimalGame(items: [box])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        #expect(engine.itemSnapshot(with: "box")?.hasProperty(.open) == true)
        #expect(engine.gameState.changeHistory.isEmpty == true)

        let command = Command(verbID: "close", directObject: "box", rawInput: "close box")

        // Act: Use engine.execute for full pipeline
        await engine.execute(command: command)

        // Assert Final State
        let finalItemState = engine.itemSnapshot(with: "box")
        #expect(finalItemState?.hasProperty(.open) == false, "Item should lose .open property")
        #expect(finalItemState?.hasProperty(.touched) == true, "Item should gain .touched property")

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "You close the wooden box.")

        // Assert Change History
        let expectedChanges = expectedCloseChanges(itemID: "box", oldProperties: initialProperties)
        expectNoDifference(engine.gameState.changeHistory, expectedChanges)
    }

    @Test("Close item that is already touched")
    func testCloseItemAlreadyTouched() async throws {
        // Arrange: Item is openable, open, and already touched
        let box = Item(
            id: "box",
            name: "wooden box",
            properties: .container, .openable, .open, .touched, // Start touched
            parent: .location("startRoom")
        )
        let initialProperties = box.properties // Includes .touched

        let game = MinimalGame(items: [box])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        #expect(engine.itemSnapshot(with: "box")?.hasProperty(.open) == true)
        #expect(engine.itemSnapshot(with: "box")?.hasProperty(.touched) == true)
        #expect(engine.gameState.changeHistory.isEmpty == true)

        let command = Command(verbID: "close", directObject: "box", rawInput: "close box")

        // Act: Use engine.execute for full pipeline
        await engine.execute(command: command)

        // Assert Final State
        let finalItemState = engine.itemSnapshot(with: "box")
        #expect(finalItemState?.hasProperty(.open) == false, "Item should lose .open property")
        #expect(finalItemState?.hasProperty(.touched) == true, "Item should still have .touched property")

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "You close the wooden box.")

        // Assert Change History
        let expectedChanges = expectedCloseChanges(itemID: "box", oldProperties: initialProperties)
        // Change should still happen because .open is removed
        #expect(!expectedChanges.isEmpty)
        expectNoDifference(engine.gameState.changeHistory, expectedChanges)
    }

    @Test("Close fails with no direct object")
    func testCloseFailsWithNoObject() async throws {
        // Arrange
        let game = MinimalGame()
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        let command = Command(verbID: "close", rawInput: "close")

        // Act & Assert: Expect error from validate()
        await #expect(throws: ActionError.prerequisiteNotMet("Close what?")) {
            try await handler.perform(command: command, engine: engine)
        }
        #expect(await mockIO.recordedOutput.isEmpty == true)
    }

    @Test("Close fails item not accessible")
    func testCloseFailsItemNotAccessible() async throws {
        // Arrange: Item exists but is in .nowhere
        let game = MinimalGame(
            items: [
                Item(id: "box", name: "wooden box", properties: .container, .openable, .open, parent: .nowhere),
            ]
        )
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        let command = Command(verbID: "close", directObject: "box", rawInput: "close box")

        // Act & Assert: Expect error from validate()
        await #expect(throws: ActionError.itemNotAccessible("box")) {
            try await handler.perform(command: command, engine: engine)
        }
        #expect(await mockIO.recordedOutput.isEmpty == true)
    }

    @Test("Close fails item not closeable")
    func testCloseFailsItemNotCloseable() async throws {
        // Arrange
        let rock = Item(
            id: "rock",
            name: "heavy rock",
            parent: .location("startRoom")
        ) // Not .openable
        let game = MinimalGame(items: [rock])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        let command = Command(verbID: "close", directObject: "rock", rawInput: "close rock")

        // Act & Assert: Expect error from validate()
        await #expect(throws: ActionError.itemNotCloseable("rock")) {
            try await handler.perform(command: command, engine: engine)
        }
        #expect(await mockIO.recordedOutput.isEmpty == true)
    }

    @Test("Close fails item already closed")
    func testCloseFailsItemAlreadyClosed() async throws {
        // Arrange
        let box = Item(
            id: "box",
            name: "wooden box",
            properties: .container, .openable, // Starts closed
            parent: .location("startRoom")
        )
        let game = MinimalGame(items: [box])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        #expect(engine.itemSnapshot(with: "box")?.hasProperty(.open) == false)
        #expect(engine.gameState.changeHistory.isEmpty == true)

        let command = Command(verbID: "close", directObject: "box", rawInput: "close box")

        // Act: Use engine.execute for full pipeline
        await engine.execute(command: command)

        // Assert Final State (Unchanged)
        let finalItemState = engine.itemSnapshot(with: "box")
        #expect(finalItemState?.hasProperty(.open) == false)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "The wooden box is already closed.")

        // Assert Change History (Should be empty)
        #expect(engine.gameState.changeHistory.isEmpty == true)
    }
}
