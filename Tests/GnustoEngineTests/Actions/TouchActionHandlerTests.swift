import CustomDump
import Testing

@testable import GnustoEngine

@MainActor
@Suite("TouchActionHandler Tests")
struct TouchActionHandlerTests {
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
        let player = Player(currentLocationID: initialLocation.id)
        let verbs = [
            Verb(id: "touch", synonyms: "feel", "rub", "pat", "pet")
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
        let initialState = GameState.initial(
            initialLocations: [testData.location],
            initialItems: [],
            initialPlayer: testData.player,
            vocabulary: testData.vocab
        )
        let engine = GameEngine(initialState: initialState, parser: mockParser, ioHandler: mockIO)
        return (engine, mockIO, testData.location, testData.player, testData.vocab)
    }

    @Test("Touch item successfully in location")
    func testTouchItemSuccessfullyInLocation() async throws {
        // Arrange
        let testItem = Item(id: "rock", name: "smooth rock") // Not necessarily takable
        let (engine, mockIO, location, _, _) = await Self.setupTestEnvironment(itemsToAdd: [testItem])
        engine.debugAddItem(id: testItem.id, name: testItem.name, parent: .location(location.id))

        let handler = TouchActionHandler()
        let command = Command(verbID: "touch", directObject: "rock", rawInput: "touch rock")

        // Act
        try await handler.perform(command: command, engine: engine)

        // Assert
        let finalItemState = engine.itemSnapshot(with: "rock")
        #expect(finalItemState?.hasProperty(.touched) == true, "Item should gain .touched property")
        let output = await mockIO.flush()
        expectNoDifference(output, "You feel nothing special.")
    }

    @Test("Touch item successfully held")
    func testTouchItemSuccessfullyHeld() async throws {
        // Arrange
        let testItem = Item(id: "key", name: "brass key", properties: .takable)
        let (engine, mockIO, _, _, _) = await Self.setupTestEnvironment(itemsToAdd: [testItem])
        engine.debugAddItem(id: testItem.id, name: testItem.name, properties: testItem.properties, parent: .player) // Held by player

        let handler = TouchActionHandler()
        let command = Command(verbID: "touch", directObject: "key", rawInput: "touch key")

        // Act
        try await handler.perform(command: command, engine: engine)

        // Assert
        let finalItemState = engine.itemSnapshot(with: "key")
        #expect(finalItemState?.hasProperty(.touched) == true)
        let output = await mockIO.flush()
        expectNoDifference(output, "You feel nothing special.")
    }

    @Test("Touch fails with no direct object")
    func testTouchFailsWithNoObject() async throws {
        // Arrange
        let (engine, mockIO, _, _, _) = await Self.setupTestEnvironment()
        let handler = TouchActionHandler()
        let command = Command(verbID: "touch", rawInput: "touch")

        // Act
        try await handler.perform(command: command, engine: engine)

        // Assert
        let output = await mockIO.flush()
        expectNoDifference(output, "Touch what?")
    }

    @Test("Touch fails item not accessible")
    func testTouchFailsItemNotAccessible() async throws {
        // Arrange
        let testItem = Item(id: "ghost", name: "ghostly form")
        let (engine, _, _, _, _) = await Self.setupTestEnvironment(itemsToAdd: [testItem])
        // Add item but make it inaccessible
        engine.debugAddItem(id: testItem.id, name: testItem.name, parent: .nowhere)

        let handler = TouchActionHandler()
        let command = Command(verbID: "touch", directObject: "ghost", rawInput: "touch ghost")

        // Act & Assert
        await #expect(throws: ActionError.itemNotAccessible("ghost")) {
            try await handler.perform(command: command, engine: engine)
        }
    }

    @Test("Touch item successfully in open container")
    func testTouchItemInOpenContainer() async throws {
        // Arrange
        let container = Item(id: "box", name: "wooden box", properties: .container, .open)
        let itemInside = Item(id: "gem", name: "ruby gem")
        let (engine, mockIO, location, _, _) = await Self.setupTestEnvironment(itemsToAdd: [container, itemInside])
        engine.debugAddItem(id: container.id, name: container.name, properties: container.properties, parent: .location(location.id))
        engine.debugAddItem(id: itemInside.id, name: itemInside.name, parent: .item(container.id))

        let handler = TouchActionHandler()
        let command = Command(verbID: "touch", directObject: "gem", rawInput: "touch gem")

        // Act
        try await handler.perform(command: command, engine: engine)

        // Assert
        let finalItemState = engine.itemSnapshot(with: "gem")
        #expect(finalItemState?.hasProperty(.touched) == true)
        let output = await mockIO.flush()
        expectNoDifference(output, "You feel nothing special.")
    }

    @Test("Touch item successfully on surface")
    func testTouchItemOnSurface() async throws {
        // Arrange
        let surface = Item(id: "table", name: "wooden table", properties: .surface)
        let itemOnTop = Item(id: "book", name: "dusty book")
        let (engine, mockIO, location, _, _) = await Self.setupTestEnvironment(itemsToAdd: [surface, itemOnTop])
        engine.debugAddItem(id: surface.id, name: surface.name, properties: surface.properties, parent: .location(location.id))
        engine.debugAddItem(id: itemOnTop.id, name: itemOnTop.name, parent: .item(surface.id))

        let handler = TouchActionHandler()
        let command = Command(verbID: "touch", directObject: "book", rawInput: "touch book")

        // Act
        try await handler.perform(command: command, engine: engine)

        // Assert
        let finalItemState = engine.itemSnapshot(with: "book")
        #expect(finalItemState?.hasProperty(.touched) == true)
        let output = await mockIO.flush()
        expectNoDifference(output, "You feel nothing special.")
    }

    @Test("Touch fails item in closed container")
    func testTouchFailsItemInClosedContainer() async throws {
        // Arrange
        let container = Item(id: "chest", name: "locked chest", properties: .container) // Closed by default
        let itemInside = Item(id: "coin", name: "gold coin")
        let (engine, _, location, _, _) = await Self.setupTestEnvironment(itemsToAdd: [container, itemInside])
        engine.debugAddItem(id: container.id, name: container.name, properties: container.properties, parent: .location(location.id))
        engine.debugAddItem(id: itemInside.id, name: itemInside.name, parent: .item(container.id))
        #expect(container.hasProperty(.open) == false) // Verify closed

        let handler = TouchActionHandler()
        let command = Command(verbID: "touch", directObject: "coin", rawInput: "touch coin")

        // Act & Assert
        await #expect(throws: ActionError.prerequisiteNotMet("The locked chest is closed.")) {
            try await handler.perform(command: command, engine: engine)
        }
    }
}
