import CustomDump
import Testing

@testable import GnustoEngine

@MainActor
@Suite("DropActionHandler Tests")
struct DropActionHandlerTests {
    let handler = DropActionHandler()

    @Test("Drop item successfully")
    func testDropItemSuccessfully() async throws {
        // Arrange: Create item
        let testItem = Item(
            id: "key",
            name: "brass key",
            properties: .takable,
            parent: .player
        )

        let game = MinimalGame(items: [testItem])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        #expect(engine.itemSnapshot(with: "key")?.parent == .player) // Verify setup

        let command = Command(verbID: "drop", directObject: "key", rawInput: "drop key")

        // Act
        try await handler.perform(command: command, engine: engine)

        // Assert
        // Check item parent changed to current location
        let finalItemState = engine.itemSnapshot(with: "key")
        #expect(finalItemState?.parent == .location("startRoom"), "Item should be in the room")

        // Check item still has .touched property (or gained it)
        #expect(finalItemState?.hasProperty(.touched) == true, "Item should have .touched property")

        // Check output message
        let output = await mockIO.flush()
        expectNoDifference(output, "Dropped.")
    }

    @Test("Drop fails with no direct object")
    func testDropFailsWithNoObject() async throws {
        // Arrange: Minimal setup
        let game = MinimalGame()
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        let command = Command(verbID: "drop", rawInput: "drop") // No direct object
        #expect(command.directObject == nil)

        // Act
        try await handler.perform(command: command, engine: engine)

        // Assert
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

        let command = Command(verbID: "drop", directObject: "key", rawInput: "drop key")

        // Act
        try await handler.perform(command: command, engine: engine)

        // Assert: Check item parent DID NOT change
        let finalItemState = engine.itemSnapshot(with: "key")
        #expect(finalItemState?.parent == .location("startRoom"), "Item should still be in the room")

        // Assert: Check output message
        let output = await mockIO.flush()
        expectNoDifference(output, "You don't have the brass key.")
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

        let game = MinimalGame(items: [testItem])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        #expect(engine.itemSnapshot(with: "cloak")?.parent == .player)
        #expect(engine.itemSnapshot(with: "cloak")?.hasProperty(.worn) == true)

        let command = Command(verbID: "drop", directObject: "cloak", rawInput: "drop cloak")

        // Act
        try await handler.perform(command: command, engine: engine)

        // Assert
        // Check item parent changed to current location
        let finalItemState = engine.itemSnapshot(with: "cloak")
        #expect(finalItemState?.parent == .location("startRoom"), "Item should be in the room")

        // Check item NO LONGER has .worn property
        #expect(finalItemState?.hasProperty(.worn) == false, "Item should NOT have .worn property")
        // Check it still has .touched
        #expect(finalItemState?.hasProperty(.touched) == true, "Item should have .touched property")

        // Check output message
        let output = await mockIO.flush()
        expectNoDifference(output, "Dropped.")
    }
}
