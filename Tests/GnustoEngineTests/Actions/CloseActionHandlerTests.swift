import CustomDump
import Testing

@testable import GnustoEngine

@MainActor
@Suite("CloseActionHandler Tests")
struct CloseActionHandlerTests {
    let handler = CloseActionHandler()

    // Helper to create the expected StateChange array for successful close
    private func expectedCloseChanges(
        itemID: ItemID,
        oldProperties: Set<ItemProperty>
    ) -> [StateChange] {
        var finalProperties = oldProperties
        finalProperties.insert(.touched)

        if oldProperties != finalProperties {
            let change = StateChange(
                entityId: .item(itemID),
                propertyKey: .itemProperties,
                oldValue: .itemPropertySet(oldProperties),
                newValue: .itemPropertySet(finalProperties)
            )
            return [change]
        }
        // No pronoun changes expected for closing
        return []
    }

    // Helper to create the expected StateChange for setting isOpen to false
    private func expectedIsOpenFalseChange(itemID: ItemID) -> StateChange {
        StateChange(
            entityId: .item(itemID),
            propertyKey: .itemDynamicValue(key: .isOpen),
            oldValue: .bool(true), // Assumes it was true before closing
            newValue: .bool(false)
        )
    }

    @Test("Close item successfully")
    func testCloseItemSuccessfully() async throws {
        // Arrange
        let box = Item(
            id: "box",
            name: "wooden box",
            properties: .container, .openable,
            dynamicValues: [.isOpen: true],
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
        #expect(engine.item(with: "box")?.dynamicValues["isOpen"]?.toBool == true)
        #expect(engine.gameState.changeHistory.isEmpty == true)

        let command = Command(
            verbID: "close",
            directObject: "box",
            rawInput: "close box"
        )

        // Act: Use engine.execute for full pipeline
        await engine.execute(command: command)

        // Assert Final State
        let finalItemState = engine.item(with: "box")
        #expect(finalItemState?.dynamicValues["isOpen"]?.toBool == false, "Item should lose .open property")
        #expect(finalItemState?.hasProperty(.touched) == true, "Item should gain .touched property")

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "Closed.")

        // Assert Change History
        // Construct the expected change for isOpen going from true to false
        let expectedOpenChange = StateChange(
            entityId: .item("box"),
            propertyKey: .itemDynamicValue(key: .isOpen),
            oldValue: .bool(true),
            newValue: .bool(false)
        )

        // Construct the expected change for adding .touched
        var expectedTouchedProps = initialProperties
        expectedTouchedProps.insert(.touched)
        let expectedTouchedChange = StateChange(
            entityId: .item("box"),
            propertyKey: .itemProperties,
            oldValue: .itemPropertySet(initialProperties),
            newValue: .itemPropertySet(expectedTouchedProps)
        )

        // The history should contain both changes
        let expectedChanges = [expectedOpenChange, expectedTouchedChange]
        expectNoDifference(engine.gameState.changeHistory, expectedChanges)
    }

    @Test("Close item that is already touched")
    func testCloseItemAlreadyTouched() async throws {
        // Arrange: Item is openable, open, and already touched
        let box = Item(
            id: "box",
            name: "wooden box",
            properties: .container, .openable, .touched, // Start touched
            dynamicValues: [.isOpen: true],
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

        #expect(engine.item(with: "box")?.dynamicValues["isOpen"]?.toBool == true)
        #expect(engine.item(with: "box")?.hasProperty(.touched) == true)
        #expect(engine.gameState.changeHistory.isEmpty == true)

        let command = Command(
            verbID: "close",
            directObject: "box",
            rawInput: "close box"
        )

        // Act: Use engine.execute for full pipeline
        await engine.execute(command: command)

        // Assert Final State
        let finalItemState = engine.item(with: "box")
        #expect(finalItemState?.dynamicValues["isOpen"]?.toBool == false, "Item should lose .open property")
        #expect(finalItemState?.hasProperty(.touched) == true, "Item should still have .touched property")

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "Closed.")

        // Assert Change History
        // Construct the expected change for isOpen going from true to false
        let expectedOpenChange = StateChange(
            entityId: .item("box"),
            propertyKey: .itemDynamicValue(key: .isOpen),
            oldValue: .bool(true),
            newValue: .bool(false)
        )

        // Since it starts touched, only the isOpen change should be present
        let expectedChanges = [expectedOpenChange]
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

        let command = Command(
            verbID: "close",
            rawInput: "close"
        )

        // Act
        await engine.execute(command: command)

        // Assert: Check output instead of thrown error
        let output = await mockIO.flush()
        expectNoDifference(output, "Close what?")
    }

    @Test("Close fails item not accessible")
    func testCloseFailsItemNotAccessible() async throws {
        // Arrange: Item exists but is in .nowhere
        let game = MinimalGame(
            items: [
                Item(
                    id: "box",
                    name: "wooden box",
                    properties: .container, .openable,
                    parent: .nowhere
                ),
            ]
        )
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        let command = Command(
            verbID: "close",
            directObject: "box",
            rawInput: "close box"
        )

        // Act
        await engine.execute(command: command)

        // Assert: Check output instead of thrown error
        let output = await mockIO.flush()
        expectNoDifference(output, "You can't see any such thing.") // Standard Zork message
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

        let command = Command(
            verbID: "close",
            directObject: "rock",
            rawInput: "close rock"
        )

        // Act
        await engine.execute(command: command)

        // Assert: Check output instead of thrown error
        let output = await mockIO.flush()
        expectNoDifference(output, "The heavy rock is not something you can close.")
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
        #expect(engine.item(with: "box")?.dynamicValues["isOpen"] == nil)
        #expect(engine.gameState.changeHistory.isEmpty == true)

        let command = Command(
            verbID: "close",
            directObject: "box",
            rawInput: "close box"
        )

        // Act: Use engine.execute for full pipeline
        await engine.execute(command: command)

        // Assert Final State (Unchanged)
        let finalItemState = engine.item(with: "box")
        #expect(finalItemState?.dynamicValues["isOpen"]?.toBool == nil)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "The wooden box is already closed.")

        // Assert Change History (Should be empty)
        #expect(engine.gameState.changeHistory.isEmpty == true)
    }
}
