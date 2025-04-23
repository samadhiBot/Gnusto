import CustomDump
import Testing

@testable import GnustoEngine

@MainActor
@Suite("OpenActionHandler Tests")
struct OpenActionHandlerTests {
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
            Verb(id: "open")
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

    @Test("Open item successfully")
    func testOpenItemSuccessfully() async throws {
        // Arrange
        let closedBox = Item(id: "box", name: "wooden box", properties: .container, .openable) // Starts closed
        let (engine, mockIO, location, _, _) = await Self.setupTestEnvironment(itemsToAdd: [closedBox])
        engine.debugAddItem(id: closedBox.id, name: closedBox.name, properties: closedBox.properties, parent: .location(location.id))
        #expect(engine.itemSnapshot(with: "box")?.hasProperty(.open) == false)

        let handler = OpenActionHandler()
        let command = Command(verbID: "open", directObject: "box", rawInput: "open box")

        // Act
        try await handler.perform(command: command, engine: engine)

        // Assert
        let finalItemState = engine.itemSnapshot(with: "box")
        #expect(finalItemState?.hasProperty(.open) == true, "Item should gain .open property")
        #expect(finalItemState?.hasProperty(.touched) == true, "Item should gain .touched property")
        let output = await mockIO.flush()
        expectNoDifference(output, "You open the wooden box.")
    }

    @Test("Open fails with no direct object")
    func testOpenFailsWithNoObject() async throws {
        // Arrange
        let (engine, mockIO, _, _, _) = await Self.setupTestEnvironment()
        let handler = OpenActionHandler()
        let command = Command(verbID: "open", rawInput: "open")

        // Act
        try await handler.perform(command: command, engine: engine)

        // Assert
        let output = await mockIO.flush()
        expectNoDifference(output, "Open what?")
    }

    @Test("Open fails item not accessible")
    func testOpenFailsItemNotAccessible() async throws {
        // Arrange
        let closedBox = Item(id: "box", name: "wooden box", properties: .container, .openable)
        let (engine, _, _, _, _) = await Self.setupTestEnvironment(itemsToAdd: [closedBox])
        engine.debugAddItem(id: closedBox.id, name: closedBox.name, properties: closedBox.properties, parent: .nowhere) // Inaccessible

        let handler = OpenActionHandler()
        let command = Command(verbID: "open", directObject: "box", rawInput: "open box")

        // Act & Assert
        await #expect(throws: ActionError.itemNotAccessible("box")) {
            try await handler.perform(command: command, engine: engine)
        }
    }

    @Test("Open fails item not openable")
    func testOpenFailsItemNotOpenable() async throws {
        // Arrange
        let rock = Item(id: "rock", name: "heavy rock", properties: []) // No .openable
        let (engine, _, location, _, _) = await Self.setupTestEnvironment(itemsToAdd: [rock])
        engine.debugAddItem(id: rock.id, name: rock.name, properties: rock.properties, parent: .location(location.id))

        let handler = OpenActionHandler()
        let command = Command(verbID: "open", directObject: "rock", rawInput: "open rock")

        // Act & Assert
        await #expect(throws: ActionError.itemNotOpenable("rock")) {
            try await handler.perform(command: command, engine: engine)
        }
    }

    @Test("Open fails item already open")
    func testOpenFailsItemAlreadyOpen() async throws {
        // Arrange
        let openBox = Item(id: "box", name: "wooden box", properties: .container, .openable, .open) // Starts open
        let (engine, _, location, _, _) = await Self.setupTestEnvironment(itemsToAdd: [openBox])
        engine.debugAddItem(id: openBox.id, name: openBox.name, properties: openBox.properties, parent: .location(location.id))

        let handler = OpenActionHandler()
        let command = Command(verbID: "open", directObject: "box", rawInput: "open box")

        // Act & Assert
        await #expect(throws: ActionError.itemAlreadyOpen("box")) {
            try await handler.perform(command: command, engine: engine)
        }
    }

    @Test("Open fails item is locked")
    func testOpenFailsItemIsLocked() async throws {
        // Arrange
        let lockedChest = Item(id: "chest", name: "iron chest", properties: .container, .openable, .locked) // Locked
        let (engine, _, location, _, _) = await Self.setupTestEnvironment(itemsToAdd: [lockedChest])
        engine.debugAddItem(id: lockedChest.id, name: lockedChest.name, properties: lockedChest.properties, parent: .location(location.id))

        let handler = OpenActionHandler()
        let command = Command(verbID: "open", directObject: "chest", rawInput: "open chest")

        // Act & Assert
        await #expect(throws: ActionError.itemIsLocked("chest")) {
            try await handler.perform(command: command, engine: engine)
        }
    }
}
