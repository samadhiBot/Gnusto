import Testing
import CustomDump // For diffing complex types
@testable import GnustoEngine

@MainActor
@Suite("TurnOnActionHandler Tests")
struct TurnOnActionHandlerTests {

    // MARK: - Test Setup Helpers

    /// Shared setup logic for creating a test environment.
    ///
    /// - Parameters:
    ///   - itemsToAdd: Items to add to the initial game state.
    ///   - initialLocation: The starting location for the player.
    ///   - initialProperties: Initial properties for the test item (lamp).
    ///   - initialItemParent: Initial parent for the test item (lamp).
    ///   - makeRoomDark: If true, the initial location will not be inherently lit.
    /// - Returns: A tuple containing the configured engine, mock IO, test item ID, and test location ID.
    static func setupTestEnvironment(
        itemsToAdd: [Item] = [],
        initialLocation: Location = Location(id: "room", name: "Test Room", description: "A room.", properties: [.inherentlyLit]), // Lit by default
        initialProperties: Set<ItemProperty> = [.device, .lightSource, .takable],
        initialItemParent: ParentEntity = .location("room"),
        makeRoomDark: Bool = false
    ) async -> (
        engine: GameEngine,
        mockIO: MockIOHandler,
        testItemID: ItemID,
        testLocationID: LocationID
    ) {
        var finalLocation = initialLocation
        if makeRoomDark {
            let darkRoom = initialLocation
            darkRoom.properties.remove(.inherentlyLit)
            finalLocation = darkRoom
        }

        let testItemID: ItemID = "lamp"
        let testItem = Item(
            id: testItemID,
            name: "brass lantern",
            description: "A brass lantern.",
            properties: initialProperties,
            size: 10
        )

        // Combine provided items with the essential test item
        var allItems = itemsToAdd
        allItems.append(testItem)

        let player = Player(currentLocationID: finalLocation.id)
        let vocabulary = Vocabulary.build(items: allItems, verbs: [Verb(id: "turn on")]) // Basic vocab
        let initialGameState = GameState.initial(
            initialLocations: [finalLocation],
            initialItems: allItems,
            initialPlayer: player,
            vocabulary: vocabulary
        )

        let mockIO = await MockIOHandler()
        let engine = GameEngine(
            initialState: initialGameState,
            parser: StandardParser(), // Using standard parser
            ioHandler: mockIO
        )

        // Place the test item in the world correctly using the correct method
        engine.updateItemParent(itemID: testItemID, newParent: initialItemParent)

        return (engine, mockIO, testItemID, finalLocation.id)
    }

    // MARK: - Tests

    @Test("Successfully turn on a light source in inventory")
    func testTurnOnLightSourceInInventory() async throws {
        // Arrange
        let (engine, mockIO, testItemID, _) = await Self.setupTestEnvironment(initialItemParent: .player)
        let handler = TurnOnActionHandler()
        let command = Command(verbID: "turn on", directObject: testItemID, rawInput: "turn on lamp")

        // Act
        try await handler.perform(command: command, engine: engine)

        // Assert
        let finalItemState = engine.itemSnapshot(with: testItemID)
        #expect(finalItemState?.hasProperty(.on) == true)
        #expect(finalItemState?.hasProperty(.touched) == true)

        let output = await mockIO.flush()
        expectNoDifference(output, "The brass lantern is now on.")
    }

    @Test("Turn on light source in dark location (causes room description)")
    func testTurnOnLightSourceInDarkLocation() async throws {
        // Arrange
        let roomDesc = "This is a dark room that should now be lit."
        let darkRoom = Location(id: "darkRoom", name: "Dark Room", description: roomDesc) // Not inherently lit
        let (engine, mockIO, testItemID, _) = await Self.setupTestEnvironment(
            initialLocation: darkRoom,
            initialItemParent: .location("darkRoom"),
            makeRoomDark: true // Ensure it starts dark
        )

        // Verify room is dark initially
        let initiallyLit = engine.scopeResolver.isLocationLit(locationID: "darkRoom")
        #expect(initiallyLit == false)

        let handler = TurnOnActionHandler()
        let command = Command(verbID: "turn on", directObject: testItemID, rawInput: "turn on lamp")

        // Act
        try await handler.perform(command: command, engine: engine)

        // Assert
        let finalItemState = engine.itemSnapshot(with: testItemID)
        #expect(finalItemState?.hasProperty(.on) == true)
        #expect(finalItemState?.hasProperty(.touched) == true)

        let output = await mockIO.flush()
        // Expect turn on message *followed by* the room description
        let expectedOutput = """
            The brass lantern is now on.
            --- Dark Room ---
            \(roomDesc)
            You can see:
              A brass lantern
            """
        expectNoDifference(output, expectedOutput)
    }

    @Test("Try to turn on item already on")
    func testTurnOnItemAlreadyOn() async throws {
        // Arrange
        let (engine, mockIO, testItemID, _) = await Self.setupTestEnvironment(
            initialProperties: [.device, .lightSource, .takable, .on], // Start with .on
            initialItemParent: .player
        )
        let handler = TurnOnActionHandler()
        let command = Command(verbID: "turn on", directObject: testItemID, rawInput: "turn on lamp")

        // Act
        try await handler.perform(command: command, engine: engine)

        // Assert
        let finalItemState = engine.itemSnapshot(with: testItemID)
        #expect(finalItemState?.hasProperty(.on) == true) // Should still be on
        #expect(finalItemState?.hasProperty(.touched) == true) // Should still be touched

        let output = await mockIO.flush()
        expectNoDifference(output, "It's already on.")
    }

    @Test("Try to turn on non-device item")
    func testTurnOnNonDeviceItem() async throws {
        // Arrange
        let (engine, mockIO, testItemID, _) = await Self.setupTestEnvironment(
            initialProperties: [.takable], // Not a device
            initialItemParent: .player
        )
        let handler = TurnOnActionHandler()
        let command = Command(verbID: "turn on", directObject: testItemID, rawInput: "turn on lamp")

        // Act & Assert
        await #expect(throws: ActionError.prerequisiteNotMet("You can't turn that on.")) {
            try await handler.perform(command: command, engine: engine)
        }

        let finalItemState = engine.itemSnapshot(with: testItemID)
        #expect(finalItemState?.hasProperty(.on) == false) // Should not gain .on
        #expect(finalItemState?.hasProperty(.touched) == true) // Should be touched

        let output = await mockIO.flush()
        #expect(output.isEmpty)
    }

    @Test("Try to turn on item that is not reachable (in closed container)")
    func testTurnOnItemInClosedContainer() async throws {
        // Arrange
        let container = Item(id: "box", name: "wooden box", properties: [.container, .openable, .takable]) // Starts closed
        let (engine, mockIO, testItemID, _) = await Self.setupTestEnvironment(
            itemsToAdd: [container],
            initialItemParent: .item("box") // Lamp inside the box
        )
        engine.updateItemParent(itemID: "box", newParent: .player) // Player holds the box

        let handler = TurnOnActionHandler()
        let command = Command(verbID: "turn on", directObject: testItemID, rawInput: "turn on lamp")

        // Act & Assert
        await #expect(throws: ActionError.itemNotAccessible(testItemID)) {
            try await handler.perform(command: command, engine: engine)
        }

        let finalItemState = engine.itemSnapshot(with: testItemID)
        #expect(finalItemState?.hasProperty(.on) == false)
        #expect(finalItemState?.hasProperty(.touched) == false) // Should not be touched if not accessible

        let output = await mockIO.flush()
        #expect(output.isEmpty)
    }

    @Test("Turn on non-light source device (no room description)")
    func testTurnOnNonLightSourceDevice() async throws {
        // Arrange
        let darkRoom = Location(id: "darkRoom", name: "Dark Room", description: "A dark room.")
        let (engine, mockIO, testItemID, _) = await Self.setupTestEnvironment(
            initialLocation: darkRoom,
            initialProperties: [.device, .takable], // Device, but not light source
            initialItemParent: .player,
            makeRoomDark: true
        )
        let handler = TurnOnActionHandler()
        let command = Command(verbID: "turn on", directObject: testItemID, rawInput: "turn on lamp")

        // Act
        try await handler.perform(command: command, engine: engine)

        // Assert
        let finalItemState = engine.itemSnapshot(with: testItemID)
        #expect(finalItemState?.hasProperty(.on) == true)
        #expect(finalItemState?.hasProperty(.touched) == true)

        let output = await mockIO.flush()
        // Only expect the turn on message, no room description
        expectNoDifference(output, "The brass lantern is now on.")

        // Verify room is still dark
        let finallyLit = engine.scopeResolver.isLocationLit(locationID: "darkRoom")
        #expect(finallyLit == false)
    }

    @Test("Command without direct object")
    func testTurnOnWithoutDirectObject() async throws {
        // Arrange
        let (engine, mockIO, _, _) = await Self.setupTestEnvironment(initialItemParent: .player)
        let handler = TurnOnActionHandler()
        // Command missing directObject
        let command = Command(verbID: "turn on", rawInput: "turn on")

        // Act
        try await handler.perform(command: command, engine: engine)

        // Assert
        let output = await mockIO.flush()
        expectNoDifference(output, "Turn on what?")
    }
}
