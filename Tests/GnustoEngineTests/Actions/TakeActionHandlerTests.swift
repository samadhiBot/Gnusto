import CustomDump
import Testing
@testable import GnustoEngine

@Suite("TakeActionHandler Tests")
struct TakeActionHandlerTests {

    // Helper function to create data for a basic test setup
    static func createTestData(itemsToAdd: [Item] = [], initialLocation: Location = Location(id: "room1", name: "Test Room", description: "A room for testing.")) -> (items: [Item], location: Location, player: Player, vocab: Vocabulary) {
        let player = Player(currentLocationID: initialLocation.id)
        // Include all needed verbs for handler tests in this suite
        let verbs = [
            Verb(id: "take")
            // Add other verbs tested in this file here if needed
        ]
        let vocabulary = Vocabulary.build(items: itemsToAdd, verbs: verbs)
        return (items: itemsToAdd, location: initialLocation, player: player, vocab: vocabulary)
    }

    @Test("Take item successfully")
    @MainActor
    func testTakeItemSuccessfully() async throws {
        // Arrange: Create data
        let testItem = Item(id: "key", name: "brass key", properties: [.takable], size: 3) // Give size
        var testData = Self.createTestData(itemsToAdd: [testItem])
        testData.player.carryingCapacity = 10 // Set capacity

        // Arrange: Create engine and mocks within the test function context
        let mockIO = await MockIOHandler()
        let mockParser = MockParser() // Not used directly
        let initialState = GameState.initial(
            initialLocations: [testData.location],
            initialItems: [], // Start empty, add via debugAddItem
            initialPlayer: testData.player,
            vocabulary: testData.vocab
        )
        let engine = GameEngine(initialState: initialState, parser: mockParser, ioHandler: mockIO)

        // Arrange: Set up initial state using engine methods
        engine.debugAddItem(id: testItem.id, name: testItem.name, properties: testItem.properties, parent: .location(testData.location.id)) // Place in room

        let handler = TakeActionHandler()
        let command = Command(verbID: "take", directObject: "key", rawInput: "take key")

        // Act
        try await handler.perform(command: command, engine: engine)

        // Assert
        // Check item parent changed
        let finalItemState = engine.itemSnapshot(with: "key")
        #expect(finalItemState?.parent == .player, "Item should be held by player")

        // Check item has .touched property
        #expect(finalItemState?.hasProperty(.touched) == true, "Item should have .touched property")

        // Check output message
        let output = await mockIO.recordedOutput
        #expect(output.contains { $0.text == "Taken." }, "Expected 'Taken.' message")
    }

    @Test("Take item fails when already held")
    @MainActor
    func testTakeItemFailsWhenAlreadyHeld() async throws {
        // Arrange: Create data
        let testItem = Item(id: "key", name: "brass key", properties: [.takable])
        let testData = Self.createTestData(itemsToAdd: [testItem])

        // Arrange: Create engine and mocks within the test function context
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let initialState = GameState.initial(
            initialLocations: [testData.location],
            initialItems: [],
            initialPlayer: testData.player,
            vocabulary: testData.vocab
        )
        let engine = GameEngine(initialState: initialState, parser: mockParser, ioHandler: mockIO)

        // Arrange: Set up initial state using engine methods
        engine.debugAddItem(id: testItem.id, name: testItem.name, properties: testItem.properties, parent: .player) // Place with player

        let handler = TakeActionHandler()
        let command = Command(verbID: "take", directObject: "key", rawInput: "take key")

        // Act
        // Perform the action directly; expect it not to throw.
        try await handler.perform(command: command, engine: engine)

        // Assert
        // Check item parent DID NOT change
        let finalItemState = engine.itemSnapshot(with: "key")
        #expect(finalItemState?.parent == .player, "Item should still be held by player")

        // Check output message
        let output = await mockIO.recordedOutput
        #expect(output.contains { $0.text == "You already have that." }, "Expected 'You already have that.' message")
    }

    @Test("Take item fails when not present in location")
    @MainActor
    func testTakeItemFailsWhenNotPresent() async throws {
        // Arrange: Create data for an item that exists but isn't in the room
        let testItem = Item(id: "key", name: "brass key", properties: [.takable])
        let testData = Self.createTestData(itemsToAdd: [testItem])

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

        // Arrange: Add item but set parent to .nowhere (or another room if we had one)
        engine.debugAddItem(id: testItem.id, name: testItem.name, properties: testItem.properties, parent: .nowhere)

        let handler = TakeActionHandler()
        let command = Command(verbID: "take", directObject: "key", rawInput: "take key")

        // Act
        // Expect no throw, just a message
        try await handler.perform(command: command, engine: engine)

        // Assert
        // Check item parent DID NOT change
        let finalItemState = engine.itemSnapshot(with: "key")
        #expect(finalItemState?.parent == .nowhere, "Item should still be nowhere")

        // Check output message
        let output = await mockIO.recordedOutput
        #expect(output.contains { $0.text == "You don't see the brass key here." }, "Expected 'You don't see the... here.' message")
    }

    @Test("Take item fails when not takable")
    @MainActor
    func testTakeItemFailsWhenNotTakable() async throws {
        // Arrange: Create item *without* .takable property
        let testItem = Item(id: "rock", name: "heavy rock", properties: []) // No .takable
        let testData = Self.createTestData(itemsToAdd: [testItem])

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

        let handler = TakeActionHandler()
        let command = Command(verbID: "take", directObject: "rock", rawInput: "take rock")

        // Act & Assert: Expect specific ActionError
        await #expect(throws: ActionError.itemNotTakable("rock")) {
            try await handler.perform(command: command, engine: engine)
        }

        // Assert: Check item parent DID NOT change
        let finalItemState = engine.itemSnapshot(with: "rock")
        #expect(finalItemState?.parent == .location(testData.location.id), "Item should still be in the room")

        // Assert: Check NO message was printed by the handler (error is caught by engine)
        let output = await mockIO.recordedOutput
        #expect(output.isEmpty == true, "No output should be printed by handler on error")
    }

    @Test("Take fails with no direct object")
    @MainActor
    func testTakeFailsWithNoObject() async throws {
        // Arrange: Minimal setup, no specific items needed
        let testData = Self.createTestData()
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let initialState = GameState.initial(
            initialLocations: [testData.location],
            initialItems: [],
            initialPlayer: testData.player,
            vocabulary: testData.vocab
        )
        let engine = GameEngine(initialState: initialState, parser: mockParser, ioHandler: mockIO)

        let handler = TakeActionHandler()
        // Command with nil directObject
        let command = Command(verbID: "take", rawInput: "take")
        #expect(command.directObject == nil) // Verify command setup

        // Act
        // Expect no throw, just a message
        try await handler.perform(command: command, engine: engine)

        // Assert
        // Check output message
        let output = await mockIO.recordedOutput
        #expect(output.contains { $0.text == "Take what?" }, "Expected 'Take what?' message")

        // Assert: Check no other output occurred
        #expect(output.count == 1, "Only the 'Take what?' message should be printed")
    }

    @Test("Take item successfully from open container in room")
    @MainActor
    func testTakeItemSuccessfullyFromOpenContainerInRoom() async throws {
        // Arrange: Create container and item inside it
        let container = Item(id: "box", name: "wooden box", properties: [.container, .open]) // Open container
        let itemInContainer = Item(id: "gem", name: "ruby gem", properties: [.takable])
        let testData = Self.createTestData(itemsToAdd: [container, itemInContainer])

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

        // Arrange: Add items and set up hierarchy
        engine.debugAddItem(id: container.id, name: container.name, properties: container.properties, parent: .location(testData.location.id)) // Container in room
        engine.debugAddItem(id: itemInContainer.id, name: itemInContainer.name, properties: itemInContainer.properties, parent: .item(container.id)) // Item in container

        let handler = TakeActionHandler()
        let command = Command(verbID: "take", directObject: "gem", rawInput: "take gem") // Target the item inside

        // Act
        try await handler.perform(command: command, engine: engine)

        // Assert
        // Check item parent changed to player
        let finalItemState = engine.itemSnapshot(with: "gem")
        #expect(finalItemState?.parent == .player, "Item should be held by player")

        // Check item has .touched property
        #expect(finalItemState?.hasProperty(.touched) == true, "Item should have .touched property")

        // Check container state didn't change (still open, in room)
        let finalContainerState = engine.itemSnapshot(with: "box")
        #expect(finalContainerState?.parent == .location(testData.location.id))
        #expect(finalContainerState?.hasProperty(.open) == true)

        // Check output message
        let output = await mockIO.recordedOutput
        #expect(output.contains { $0.text == "Taken." }, "Expected 'Taken.' message")
    }

    @Test("Take item successfully from open container held by player")
    @MainActor
    func testTakeItemSuccessfullyFromOpenContainerHeld() async throws {
        // Arrange: Create container and item inside it
        let container = Item(id: "pouch", name: "leather pouch", properties: [.container, .open, .takable]) // Open & Takable
        let itemInContainer = Item(id: "coin", name: "gold coin", properties: [.takable])
        let testData = Self.createTestData(itemsToAdd: [container, itemInContainer])

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

        // Arrange: Add items and set up hierarchy
        engine.debugAddItem(id: container.id, name: container.name, properties: container.properties, parent: .player) // Container held by player
        engine.debugAddItem(id: itemInContainer.id, name: itemInContainer.name, properties: itemInContainer.properties, parent: .item(container.id)) // Item in container

        let handler = TakeActionHandler()
        let command = Command(verbID: "take", directObject: "coin", rawInput: "take coin") // Target the item inside

        // Act
        try await handler.perform(command: command, engine: engine)

        // Assert
        // Check item parent changed to player
        let finalItemState = engine.itemSnapshot(with: "coin")
        #expect(finalItemState?.parent == .player, "Item should be held by player")

        // Check item has .touched property
        #expect(finalItemState?.hasProperty(.touched) == true, "Item should have .touched property")

        // Check container state didn't change (still open, held by player)
        let finalContainerState = engine.itemSnapshot(with: "pouch")
        #expect(finalContainerState?.parent == .player)
        #expect(finalContainerState?.hasProperty(.open) == true)

        // Check output message
        let output = await mockIO.recordedOutput
        #expect(output.contains { $0.text == "Taken." }, "Expected 'Taken.' message")
    }

    @Test("Take item fails from closed container")
    @MainActor
    func testTakeItemFailsFromClosedContainer() async throws {
        // Arrange: Create a CLOSED container and item inside it
        let container = Item(id: "box", name: "wooden box", properties: [.container]) // Closed by default
        let itemInContainer = Item(id: "gem", name: "ruby gem", properties: [.takable])
        let testData = Self.createTestData(itemsToAdd: [container, itemInContainer])

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

        // Arrange: Add items and set up hierarchy
        engine.debugAddItem(id: container.id, name: container.name, properties: container.properties, parent: .location(testData.location.id)) // Container in room
        engine.debugAddItem(id: itemInContainer.id, name: itemInContainer.name, properties: itemInContainer.properties, parent: .item(container.id)) // Item in container
        #expect(container.hasProperty(.open) == false) // Verify container is closed

        let handler = TakeActionHandler()
        let command = Command(verbID: "take", directObject: "gem", rawInput: "take gem")

        // Act & Assert: Expect specific ActionError
        await #expect(throws: ActionError.containerIsClosed("box")) {
            try await handler.perform(command: command, engine: engine)
        }

        // Assert: Check item parent DID NOT change
        let finalItemState = engine.itemSnapshot(with: "gem")
        #expect(finalItemState?.parent == .item("box"), "Item should still be in the box")

        // Assert: Check NO message was printed by the handler
        let output = await mockIO.recordedOutput
        #expect(output.isEmpty == true, "No output should be printed by handler on error")
    }

    @Test("Take item fails from non-container item")
    @MainActor
    func testTakeItemFailsFromNonContainer() async throws {
        // Arrange: Create a non-container and an item 'inside' it (logically impossible but test setup)
        let nonContainer = Item(id: "statue", name: "stone statue", properties: [.takable]) // Not a container
        let itemInside = Item(id: "chip", name: "stone chip", properties: [.takable])
        let testData = Self.createTestData(itemsToAdd: [nonContainer, itemInside])

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

        // Arrange: Add items and set up hierarchy
        engine.debugAddItem(id: nonContainer.id, name: nonContainer.name, properties: nonContainer.properties, parent: .location(testData.location.id)) // Statue in room
        engine.debugAddItem(id: itemInside.id, name: itemInside.name, properties: itemInside.properties, parent: .item(nonContainer.id)) // Chip parented to statue
        #expect(nonContainer.hasProperty(.container) == false) // Verify statue is not container

        let handler = TakeActionHandler()
        let command = Command(verbID: "take", directObject: "chip", rawInput: "take chip from statue") // Target the chip

        // Act
        // Expect no throw, just a message
        try await handler.perform(command: command, engine: engine)

        // Assert: Check item parent DID NOT change
        let finalItemState = engine.itemSnapshot(with: "chip")
        #expect(finalItemState?.parent == .item("statue"), "Chip should still be parented to statue")

        // Assert: Check specific message was printed
        let output = await mockIO.recordedOutput
        #expect(output.contains { $0.text == "You can't take things out of the stone statue." }, "Expected non-container message")

        // Assert: Check no other output
        #expect(output.count == 1)
    }

    @Test("Take item fails when capacity exceeded")
    @MainActor
    func testTakeItemFailsWhenCapacityExceeded() async throws {
        // Arrange: Items with specific sizes
        let itemHeld = Item(id: "sword", name: "heavy sword", properties: [.takable], size: 8)
        let itemToTake = Item(id: "shield", name: "large shield", properties: [.takable], size: 7)
        var testData = Self.createTestData(itemsToAdd: [itemHeld, itemToTake])
        testData.player.carryingCapacity = 10 // Capacity lower than combined size

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

        // Arrange: Add items and set up hierarchy
        engine.debugAddItem(id: itemHeld.id, name: itemHeld.name, properties: itemHeld.properties, size: itemHeld.size, parent: .player) // Sword held by player
        engine.debugAddItem(id: itemToTake.id, name: itemToTake.name, properties: itemToTake.properties, size: itemToTake.size, parent: .location(testData.location.id)) // Shield in room

        // Verify initial weight calculation is correct (optional but good)
        let initialWeight = engine.gameState.player.currentInventoryWeight(allItems: engine.gameState.items)
        #expect(initialWeight == 8)

        let handler = TakeActionHandler()
        let command = Command(verbID: "take", directObject: "shield", rawInput: "take shield") // Try to take shield

        // Act & Assert: Expect specific ActionError
        await #expect(throws: ActionError.playerCannotCarryMore) {
            try await handler.perform(command: command, engine: engine)
        }

        // Assert: Check item parent DID NOT change
        let finalItemState = engine.itemSnapshot(with: "shield")
        #expect(finalItemState?.parent == .location(testData.location.id), "Shield should still be in the room")

        // Assert: Check NO message was printed by the handler
        let output = await mockIO.recordedOutput
        #expect(output.isEmpty == true, "No output should be printed by handler on error")
    }

    /// Tests that taking a wearable item successfully moves it to inventory but does not wear it.
    @Test("Take wearable item successfully (not worn)")
    @MainActor
    func testTakeWearableItemSuccessfully() async throws {
        // Arrange: Create a wearable item
        let testItem = Item(id: "cloak", name: "dark cloak", properties: [.takable, .wearable], size: 2)
        var testData = Self.createTestData(itemsToAdd: [testItem])
        testData.player.carryingCapacity = 10

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
        engine.debugAddItem(id: testItem.id, name: testItem.name, properties: testItem.properties, size: testItem.size, parent: .location(testData.location.id))

        let handler = TakeActionHandler()
        let command = Command(verbID: "take", directObject: "cloak", rawInput: "take cloak")

        // Act
        try await handler.perform(command: command, engine: engine)

        // Assert
        // Check item parent changed
        let finalItemState = engine.itemSnapshot(with: "cloak")
        #expect(finalItemState?.parent == .player, "Item should be held by player")

        // Check item has .touched property but NOT .worn
        #expect(finalItemState?.hasProperty(.touched) == true, "Item should have .touched property")
        #expect(finalItemState?.hasProperty(.worn) == false, "Item should NOT have .worn property after just taking")

        // Check output message
        let output = await mockIO.recordedOutput
        #expect(output.contains { $0.text == "Taken." }, "Expected 'Taken.' message")
    }

    // Add more tests here for failure cases...

}
