import Testing
import CustomDump
@testable import GnustoEngine

@MainActor
@Suite("TurnOffActionHandler Tests")
struct TurnOffActionHandlerTests {

    // MARK: - Test Setup Helpers

    /// Shared setup logic, adapted from TurnOnActionHandlerTests.
    static func setupTestEnvironment(
        itemsToAdd: [Item] = [],
        initialLocation: Location = Location(id: "room", name: "Test Room", description: "A room.", properties: [.inherentlyLit]), // Lit by default
        initialProperties: Set<ItemProperty> = [.device, .lightSource, .takable, .on], // Start with .on by default for turning off
        initialItemParent: ParentEntity = .location("room"),
        makeRoomDarkInitially: Bool = false // To test going from lit to dark
    ) async -> (
        engine: GameEngine,
        mockIO: MockIOHandler,
        testItemID: ItemID,
        testLocationID: LocationID
    ) {
        var finalLocation = initialLocation
        if makeRoomDarkInitially {
            let darkRoom = initialLocation
            darkRoom.properties.remove(.inherentlyLit)
            finalLocation = darkRoom
            // We rely on the lamp being ON initially to light the room
        }

        let testItemID: ItemID = "lamp"
        let testItem = Item(
            id: testItemID,
            name: "brass lantern",
            description: "A brass lantern.",
            properties: initialProperties,
            size: 10
        )

        var allItems = itemsToAdd
        allItems.append(testItem)

        let player = Player(in: finalLocation.id)
        let vocabulary = Vocabulary.build(items: allItems, verbs: [Verb(id: "turn off")])
        let initialGameState = GameState(
            locations: [finalLocation],
            items: allItems,
            player: player,
            vocabulary: vocabulary
        )

        let mockIO = await MockIOHandler()
        let engine = GameEngine(
            initialState: initialGameState,
            parser: StandardParser(),
            ioHandler: mockIO
        )

        engine.updateItemParent(itemID: testItemID, newParent: initialItemParent)

        return (engine, mockIO, testItemID, finalLocation.id)
    }

    // MARK: - Tests

    @Test("Successfully turn off a light source in inventory")
    func testTurnOffLightSourceInInventory() async throws {
        // Arrange
        let (engine, mockIO, testItemID, _) = await Self.setupTestEnvironment(initialItemParent: .player)
        let handler = TurnOffActionHandler()
        let command = Command(verbID: "turn off", directObject: testItemID, rawInput: "turn off lamp")

        // Act
        try await handler.perform(command: command, engine: engine)

        // Assert
        let finalItemState = engine.itemSnapshot(with: testItemID)
        #expect(finalItemState?.hasProperty(.on) == false)
        #expect(finalItemState?.hasProperty(.touched) == true)

        let output = await mockIO.flush()
        expectNoDifference(output, "The brass lantern is now off.")
    }

    @Test("Turn off light source making a room pitch black")
    func testTurnOffLightSourceCausesDarkness() async throws {
        // Arrange: Start with lamp ON in a room that is ONLY lit by the lamp
        let roomDesc = "This room will become dark."
        let darkRoom = Location(id: "darkRoom", name: "Dark Room", description: roomDesc)
        let (engine, mockIO, testItemID, roomID) = await Self.setupTestEnvironment(
            initialLocation: darkRoom,
            initialProperties: [.device, .lightSource, .takable, .on], // Lamp is ON
            initialItemParent: .location(darkRoom.id), // Lamp in the room
            makeRoomDarkInitially: true // Room relies on the lamp
        )

        // Verify room is lit initially ONLY because of the lamp
        let initiallyLit = engine.scopeResolver.isLocationLit(locationID: roomID)
        #expect(initiallyLit == true)

        let handler = TurnOffActionHandler()
        let command = Command(verbID: "turn off", directObject: testItemID, rawInput: "turn off lamp")

        // Act
        try await handler.perform(command: command, engine: engine)

        // Assert
        let finalItemState = engine.itemSnapshot(with: testItemID)
        #expect(finalItemState?.hasProperty(.on) == false)
        #expect(finalItemState?.hasProperty(.touched) == true)

        let output = await mockIO.flush()
        let expectedOutput = """
        The brass lantern is now off.
        It is now pitch black. You are likely to be eaten by a grue.
        """
        expectNoDifference(output, expectedOutput)

        // Verify room is now dark
        let finallyLit = engine.scopeResolver.isLocationLit(locationID: roomID)
        #expect(finallyLit == false)
    }

    @Test("Try to turn off item already off")
    func testTurnOffItemAlreadyOff() async throws {
        // Arrange
        let (engine, mockIO, testItemID, _) = await Self.setupTestEnvironment(
            initialProperties: [.device, .lightSource, .takable], // Starts OFF
            initialItemParent: .player
        )
        let handler = TurnOffActionHandler()
        let command = Command(verbID: "turn off", directObject: testItemID, rawInput: "turn off lamp")

        // Act
        try await handler.perform(command: command, engine: engine)

        // Assert
        let finalItemState = engine.itemSnapshot(with: testItemID)
        #expect(finalItemState?.hasProperty(.on) == false) // Should still be off
        #expect(finalItemState?.hasProperty(.touched) == true) // Should be touched

        let output = await mockIO.flush()
        expectNoDifference(output, "It's already off.")
    }

    @Test("Try to turn off non-device item")
    func testTurnOffNonDeviceItem() async throws {
        // Arrange
        let (engine, mockIO, testItemID, _) = await Self.setupTestEnvironment(
            initialProperties: [.takable, .on], // Not a device, but somehow .on (test edge case)
            initialItemParent: .player
        )
        let handler = TurnOffActionHandler()
        let command = Command(verbID: "turn off", directObject: testItemID, rawInput: "turn off lamp")

        // Act & Assert
        await #expect(throws: ActionError.prerequisiteNotMet("You can't turn that off.")) {
            try await handler.perform(command: command, engine: engine)
        }

        let finalItemState = engine.itemSnapshot(with: testItemID)
        #expect(finalItemState?.hasProperty(.on) == true) // Should not lose .on
        #expect(finalItemState?.hasProperty(.touched) == true) // Should be touched

        let output = await mockIO.flush()
        #expect(output.isEmpty)
    }

    @Test("Try to turn off item that is not reachable (in closed container)")
    func testTurnOffItemInClosedContainer() async throws {
        // Arrange
        let container = Item(id: "box", name: "wooden box", properties: [.container, .openable, .takable]) // Starts closed
        let (engine, mockIO, testItemID, _) = await Self.setupTestEnvironment(
            itemsToAdd: [container],
            initialProperties: [.device, .lightSource, .takable, .on], // Lamp ON inside
            initialItemParent: .item("box") // Lamp inside the box
        )
        engine.updateItemParent(itemID: "box", newParent: .player) // Player holds the box

        let handler = TurnOffActionHandler()
        let command = Command(verbID: "turn off", directObject: testItemID, rawInput: "turn off lamp")

        // Act & Assert
        await #expect(throws: ActionError.itemNotAccessible(testItemID)) {
            try await handler.perform(command: command, engine: engine)
        }

        let finalItemState = engine.itemSnapshot(with: testItemID)
        #expect(finalItemState?.hasProperty(.on) == true) // Should stay on
        #expect(finalItemState?.hasProperty(.touched) == false) // Should not be touched

        let output = await mockIO.flush()
        #expect(output.isEmpty)
    }

    @Test("Turn off non-light source device (no darkness message)")
    func testTurnOffNonLightSourceDevice() async throws {
        // Arrange
        // Start in a lit room
        let (engine, mockIO, testItemID, roomID) = await Self.setupTestEnvironment(
            initialProperties: [.device, .takable, .on], // Device ON, but not light source
            initialItemParent: .player
        )
        let handler = TurnOffActionHandler()
        let command = Command(verbID: "turn off", directObject: testItemID, rawInput: "turn off lamp")

        // Verify room is lit initially (inherently)
        let initiallyLit = engine.scopeResolver.isLocationLit(locationID: roomID)
        #expect(initiallyLit == true)

        // Act
        try await handler.perform(command: command, engine: engine)

        // Assert
        let finalItemState = engine.itemSnapshot(with: testItemID)
        #expect(finalItemState?.hasProperty(.on) == false)
        #expect(finalItemState?.hasProperty(.touched) == true)

        let output = await mockIO.flush()
        // Only expect the turn off message, no darkness message
        expectNoDifference(output, "The brass lantern is now off.")

        // Verify room is still lit
        let finallyLit = engine.scopeResolver.isLocationLit(locationID: roomID)
        #expect(finallyLit == true)
    }

    @Test("Command without direct object")
    func testTurnOffWithoutDirectObject() async throws {
        // Arrange
        let (engine, mockIO, _, _) = await Self.setupTestEnvironment(initialItemParent: .player)
        let handler = TurnOffActionHandler()
        let command = Command(verbID: "turn off", rawInput: "turn off")

        // Act
        try await handler.perform(command: command, engine: engine)

        // Assert
        let output = await mockIO.flush()
        expectNoDifference(output, "Turn off what?")
    }
}
