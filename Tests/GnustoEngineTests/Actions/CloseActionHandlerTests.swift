import CustomDump
import Testing

@testable import GnustoEngine

@MainActor
@Suite("CloseActionHandler Tests")
struct CloseActionHandlerTests {
    // Helper function to create data for a basic test setup
    static func createTestData(
        itemsToAdd: [Item] = [],
        initialLocation: Location = Location(id: "room1", name: "Test Room", description: "A room for testing.")
    ) async -> (
        items: [Item],
        location: Location,
        player: Player,
        vocab: Vocabulary
    ) {
        let player = Player(in: initialLocation.id)
        let verbs = [
            Verb(id: "close")
        ]
        let vocabulary = Vocabulary.build(items: itemsToAdd, verbs: verbs)
        return (items: itemsToAdd, location: initialLocation, player: player, vocab: vocabulary)
    }

    // Helper to setup engine and mocks
    static func setupTestEnvironment(
        itemsToAdd: [Item] = [],
        initialLocation: Location = Location(id: "room1", name: "Test Room", description: "A room for testing.")
    ) async -> (GameEngine, MockIOHandler, Location, Player, Vocabulary) {
        let testData = await Self.createTestData(itemsToAdd: itemsToAdd, initialLocation: initialLocation)
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let initialState = GameState(
            locations: [testData.location],
            items: [],
            player: testData.player,
            vocabulary: testData.vocab
        )
        let engine = GameEngine(initialState: initialState, parser: mockParser, ioHandler: mockIO)
        return (engine, mockIO, testData.location, testData.player, testData.vocab)
    }

    @Test("Close item successfully")
    func testCloseItemSuccessfully() async throws {
        // Arrange
        let openBox = Item(id: "box", name: "wooden box", properties: .container, .openable, .open) // Starts open
        let (engine, mockIO, location, _, _) = await Self.setupTestEnvironment(itemsToAdd: [openBox])
        engine.debugAddItem(id: openBox.id, name: openBox.name, properties: openBox.properties, parent: .location(location.id))
        #expect(engine.itemSnapshot(with: "box")?.hasProperty(.open) == true)

        let handler = CloseActionHandler()
        let command = Command(verbID: "close", directObject: "box", rawInput: "close box")

        // Act
        try await handler.perform(command: command, engine: engine)

        // Assert
        let finalItemState = engine.itemSnapshot(with: "box")
        #expect(finalItemState?.hasProperty(.open) == false, "Item should lose .open property")
        #expect(finalItemState?.hasProperty(.touched) == true, "Item should gain .touched property")
        let output = await mockIO.flush()
        expectNoDifference(output, "You close the wooden box.")
    }

    @Test("Close fails with no direct object")
    func testCloseFailsWithNoObject() async throws {
        // Arrange
        let (engine, mockIO, _, _, _) = await Self.setupTestEnvironment()
        let handler = CloseActionHandler()
        let command = Command(verbID: "close", rawInput: "close")

        // Act
        try await handler.perform(command: command, engine: engine)

        // Assert
        let output = await mockIO.flush()
        expectNoDifference(output, "Close what?")
    }

    @Test("Close fails item not accessible")
    func testCloseFailsItemNotAccessible() async throws {
        // Arrange
        let openBox = Item(id: "box", name: "wooden box", properties: .container, .openable, .open)
        let (engine, _, _, _, _) = await Self.setupTestEnvironment(itemsToAdd: [openBox])
        engine.debugAddItem(id: openBox.id, name: openBox.name, properties: openBox.properties, parent: .nowhere) // Inaccessible

        let handler = CloseActionHandler()
        let command = Command(verbID: "close", directObject: "box", rawInput: "close box")

        // Act & Assert
        await #expect(throws: ActionError.itemNotAccessible("box")) {
            try await handler.perform(command: command, engine: engine)
        }
    }

    @Test("Close fails item not closeable")
    func testCloseFailsItemNotCloseable() async throws {
        // Arrange
        let rock = Item(id: "rock", name: "heavy rock", properties: []) // No .openable
        let (engine, _, location, _, _) = await Self.setupTestEnvironment(itemsToAdd: [rock])
        engine.debugAddItem(id: rock.id, name: rock.name, properties: rock.properties, parent: .location(location.id))

        let handler = CloseActionHandler()
        let command = Command(verbID: "close", directObject: "rock", rawInput: "close rock")

        // Act & Assert
        // Expecting .itemNotCloseable based on handler logic
        await #expect(throws: ActionError.itemNotCloseable("rock")) {
            try await handler.perform(command: command, engine: engine)
        }
    }

    @Test("Close fails item already closed")
    func testCloseFailsItemAlreadyClosed() async throws {
        // Arrange
        let closedBox = Item(id: "box", name: "wooden box", properties: .container, .openable) // Starts closed
        let (engine, _, location, _, _) = await Self.setupTestEnvironment(itemsToAdd: [closedBox])
        engine.debugAddItem(id: closedBox.id, name: closedBox.name, properties: closedBox.properties, parent: .location(location.id))

        let handler = CloseActionHandler()
        let command = Command(verbID: "close", directObject: "box", rawInput: "close box")

        // Act & Assert
        await #expect(throws: ActionError.itemAlreadyClosed("box")) {
            try await handler.perform(command: command, engine: engine)
        }
    }
}
