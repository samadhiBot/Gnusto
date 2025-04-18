import CustomDump
import Testing

@testable import GnustoEngine

@MainActor
@Suite("DropActionHandler Tests")
struct DropActionHandlerTests {
    // Helper function to create data for a basic test setup
    // Adapted from TakeActionHandlerTests
    static func createTestData(
        itemsToAdd: [Item] = [],
        initialLocation: Location = Location(id: "room1", name: "Test Room", description: "A room for testing.")
    ) async -> (
        items: [Item],
        location: Location,
        player: Player,
        vocab: Vocabulary
    ) {
        let player = Player(currentLocationID: initialLocation.id)
        // Include all needed verbs for handler tests in this suite
        let verbs = [
            Verb(id: "drop")
            // Add other verbs tested in this file here if needed
        ]
        let vocabulary = Vocabulary.build(items: itemsToAdd, verbs: verbs)
        return (items: itemsToAdd, location: initialLocation, player: player, vocab: vocabulary)
    }

    @Test("Drop item successfully")
    func testDropItemSuccessfully() async throws {
        // Arrange: Create item
        let testItem = Item(id: "key", name: "brass key", properties: [.takable]) // Size not needed for drop
        let testData = await Self.createTestData(itemsToAdd: [testItem])

        // Arrange: Create engine and mocks
        let mockIO = await MockIOHandler()
        let mockParser = MockParser() // Not used directly
        let initialState = GameState.initial(
            initialLocations: [testData.location],
            initialItems: [],
            initialPlayer: testData.player,
            vocabulary: testData.vocab
        )
        let engine = GameEngine(initialState: initialState, parser: mockParser, ioHandler: mockIO)

        // Arrange: Add item and place it with the player
        engine.debugAddItem(
            id: testItem.id,
            name: testItem.name,
            properties: testItem.properties,
            parent: .player
        )
        #expect(engine.itemSnapshot(with: "key")?.parent == .player) // Verify setup

        let handler = DropActionHandler()
        let command = Command(verbID: "drop", directObject: "key", rawInput: "drop key")

        // Act
        try await handler.perform(command: command, engine: engine)

        // Assert
        // Check item parent changed to current location
        let finalItemState = engine.itemSnapshot(with: "key")
        #expect(finalItemState?.parent == .location(testData.location.id), "Item should be in the room")

        // Check item still has .touched property (or gained it)
        #expect(finalItemState?.hasProperty(.touched) == true, "Item should have .touched property")

        // Check output message
        let output = await mockIO.flush()
        expectNoDifference(output, "Dropped.")
    }

    @Test("Drop fails with no direct object")
    func testDropFailsWithNoObject() async throws {
        // Arrange: Minimal setup
        let testData = await Self.createTestData()
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let initialState = GameState.initial(
            initialLocations: [testData.location],
            initialItems: [],
            initialPlayer: testData.player,
            vocabulary: testData.vocab
        )
        let engine = GameEngine(initialState: initialState, parser: mockParser, ioHandler: mockIO)

        let handler = DropActionHandler()
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
        let testItem = Item(id: "key", name: "brass key", properties: [.takable])
        let testData = await Self.createTestData(itemsToAdd: [testItem])

        // Arrange: Create engine and mocks
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let initialState = GameState.initial(
            initialLocations: [testData.location],
            initialItems: [],
            initialPlayer: testData.player,
            vocabulary: testData.vocab
        )
        let engine = GameEngine(initialState: initialState, parser: mockParser, ioHandler: mockIO)

        // Arrange: Add item and place it in the room
        engine.debugAddItem(id: testItem.id, name: testItem.name, properties: testItem.properties, parent: .location(testData.location.id))
        #expect(engine.itemSnapshot(with: "key")?.parent == .location(testData.location.id))

        let handler = DropActionHandler()
        let command = Command(verbID: "drop", directObject: "key", rawInput: "drop key")

        // Act
        try await handler.perform(command: command, engine: engine)

        // Assert: Check item parent DID NOT change
        let finalItemState = engine.itemSnapshot(with: "key")
        #expect(finalItemState?.parent == .location(testData.location.id), "Item should still be in the room")

        // Assert: Check output message
        let output = await mockIO.flush()
        expectNoDifference(output, "You aren't holding that.")
    }

    @Test("Drop worn item successfully removes worn property")
    func testDropWornItemSuccessfully() async throws {
        // Arrange: Create a wearable item
        let testItem = Item(id: "cloak", name: "dark cloak", properties: [.takable, .wearable, .worn]) // Start worn
        let testData = await Self.createTestData(itemsToAdd: [testItem])

        // Arrange: Create engine and mocks
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let initialState = GameState.initial(
            initialLocations: [testData.location],
            initialItems: [],
            initialPlayer: testData.player,
            vocabulary: testData.vocab
        )
        let engine = GameEngine(initialState: initialState, parser: mockParser, ioHandler: mockIO)

        // Arrange: Add item and place it with the player (already marked worn)
        engine.debugAddItem(id: testItem.id, name: testItem.name, properties: testItem.properties, parent: .player)
        #expect(engine.itemSnapshot(with: "cloak")?.parent == .player)
        #expect(engine.itemSnapshot(with: "cloak")?.hasProperty(.worn) == true)

        let handler = DropActionHandler()
        let command = Command(verbID: "drop", directObject: "cloak", rawInput: "drop cloak")

        // Act
        try await handler.perform(command: command, engine: engine)

        // Assert
        // Check item parent changed to current location
        let finalItemState = engine.itemSnapshot(with: "cloak")
        #expect(finalItemState?.parent == .location(testData.location.id), "Item should be in the room")

        // Check item NO LONGER has .worn property
        #expect(finalItemState?.hasProperty(.worn) == false, "Item should NOT have .worn property")
        // Check it still has .touched
        #expect(finalItemState?.hasProperty(.touched) == true, "Item should have .touched property")

        // Check output message
        let output = await mockIO.flush()
        expectNoDifference(output, "Dropped.")
    }

    // Add more tests here...

}
