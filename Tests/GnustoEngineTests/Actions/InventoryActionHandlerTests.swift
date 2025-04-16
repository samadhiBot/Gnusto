import CustomDump
import Testing

@testable import GnustoEngine

@Suite("InventoryActionHandler Tests")
struct InventoryActionHandlerTests {

    // Helper function (adapted from Drop/Take tests)
    static func createTestData(itemsToAdd: [Item] = [], initialLocation: Location = Location(id: "room1", name: "Test Room", description: "A room for testing.")) -> (items: [Item], location: Location, player: Player, vocab: Vocabulary) {
        let player = Player(currentLocationID: initialLocation.id)
        let verbs = [Verb(id: "inventory")] // Ensure INVENTORY verb exists
        let vocabulary = Vocabulary.build(items: itemsToAdd, verbs: verbs)
        return (items: itemsToAdd, location: initialLocation, player: player, vocab: vocabulary)
    }

    @Test("Inventory shows items held")
    @MainActor
    func testInventoryShowsItemsHeld() async throws {
        // Arrange: Items held by player
        let item1 = Item(id: "key", name: "brass key")
        let item2 = Item(id: "lamp", name: "brass lamp")
        let testData = Self.createTestData(itemsToAdd: [item1, item2])

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

        // Arrange: Add items and place with player
        engine.debugAddItem(id: item1.id, name: item1.name, properties: item1.properties, parent: .player)
        engine.debugAddItem(id: item2.id, name: item2.name, properties: item2.properties, parent: .player)

        let handler = InventoryActionHandler()
        let command = Command(verbID: "inventory", rawInput: "inventory")

        // Act
        try await handler.perform(command: command, engine: engine)

        // Assert
        let output = await mockIO.flush()
        expectNoDifference(output, """
            You are carrying:
              A brass lamp
              A brass key
            """
        )
    }

    @Test("Inventory shows empty message")
    @MainActor
    func testInventoryShowsEmptyMessage() async throws {
        // Arrange: No items held by player
        let testData = Self.createTestData()

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

        let handler = InventoryActionHandler()
        let command = Command(verbID: "inventory", rawInput: "inventory")

        // Act
        try await handler.perform(command: command, engine: engine)

        // Assert
        let output = await mockIO.flush()
        expectNoDifference(output, "You are empty-handed.")
    }
}
