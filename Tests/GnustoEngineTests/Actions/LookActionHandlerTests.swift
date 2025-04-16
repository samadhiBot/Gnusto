import Testing
import CustomDump

@testable import GnustoEngine

@Suite("LookActionHandler Tests")
struct LookActionHandlerTests {
    let handler = LookActionHandler()
    let testLocationID = Location.ID("testRoom")

    // --- Helper Setup ---
    func createTestEngine(
        locationProperties: Set<LocationProperty> = [],
        itemsInLocation: [Item] = [],
        itemsInInventory: [Item] = [],
        itemToExamine: Item? = nil // For LOOK AT tests
    ) async -> (GameEngine, MockIOHandler) {
        let location = Location(id: testLocationID, name: "Test Room", description: "A basic room.", properties: locationProperties)
        let player = Player(currentLocationID: location.id)

        var allItems: [Item.ID: Item] = [:]
        for item in itemsInLocation {
            allItems[item.id] = Item(id: item.id, name: item.name, description: item.description, properties: item.properties, parent: .location(location.id))
        }
        for item in itemsInInventory {
            allItems[item.id] = Item(id: item.id, name: item.name, properties: item.properties, parent: .player)
        }
        if let item = itemToExamine {
            // Ensure the item to examine exists in the state, typically in the location
             if allItems[item.id] == nil {
                 allItems[item.id] = Item(id: item.id, name: item.name, description: item.description, properties: item.properties, parent: .location(location.id))
             }
        }

        // Build vocabulary from items and the LOOK verb
        let lookVerb = Verb(id: "look", synonyms: ["l", "examine", "x"])
        let vocab = Vocabulary.build(items: Array(allItems.values), verbs: [lookVerb])

        let initialState = GameState(
            locations: [location.id: location],
            items: allItems,
            player: player,
            vocabulary: vocab
        )

        let mockIO = await MockIOHandler()
        let mockParser = MockParser() // Not used directly by handler
        let engine = await GameEngine(
            initialState: initialState,
            parser: mockParser,
            ioHandler: mockIO
            // Uses default ScopeResolver
        )

        return (engine, mockIO)
    }

    // --- LOOK (in location) Tests ---

    @Test("LOOK in lit room describes room and lists items")
    @MainActor
    func testLookInLitRoom() async throws {
        let item1 = Item(id: "widget", name: "shiny widget")
        let item2 = Item(id: "gizmo", name: "blue gizmo")
        let (engine, mockIO) = await createTestEngine(locationProperties: [.inherentlyLit], itemsInLocation: [item1, item2])
        let command = Command(verbID: "look", rawInput: "look")

        try await handler.perform(command: command, engine: engine)

        let output = await mockIO.flush()
        expectNoDifference(output, """
            --- Test Room ---
            A basic room.
            You can see:
              A shiny widget
              A blue gizmo
            """
        )
    }

    @Test("LOOK in dark room prints darkness message")
    @MainActor
    func testLookInDarkRoom() async throws {
        let item1 = Item(id: "widget", name: "shiny widget")
        let (engine, mockIO) = await createTestEngine(itemsInLocation: [item1]) // Dark room
        let command = Command(verbID: "look", rawInput: "look")

        try await handler.perform(command: command, engine: engine)

        let output = await mockIO.flush()
        expectNoDifference(output, "It is pitch black. You are likely to be eaten by a grue.")
    }

    @Test("LOOK in lit room (via player light) describes room and lists items")
    @MainActor
    func testLookInRoomLitByPlayer() async throws {
        let activeLamp = Item(id: "lamp", name: "lamp", properties: [.lightSource, .on, .takable])
        let item1 = Item(id: "widget", name: "shiny widget")
        let (engine, mockIO) = await createTestEngine(itemsInLocation: [item1], itemsInInventory: [activeLamp])
        let command = Command(verbID: "look", rawInput: "look")

        try await handler.perform(command: command, engine: engine)

        let output = await mockIO.flush()
        expectNoDifference(output, """
            --- Test Room ---
            A basic room.
            You can see:
              A shiny widget
            """
        )
    }

    // --- LOOK AT (item) Tests (Less affected by scope changes for now) ---

    @Test("LOOK AT item shows description")
    @MainActor
    func testLookAtItem() async throws {
        let item = Item(id: "rock", name: "plain rock", description: "It looks like a rock.")
        let (engine, mockIO) = await createTestEngine(locationProperties: [.inherentlyLit], itemToExamine: item)
        let command = Command(verbID: "examine", directObject: "rock", rawInput: "x rock")

        try await handler.perform(command: command, engine: engine)

        let output = await mockIO.flush()
        expectNoDifference(output, "It looks like a rock.")
    }

    @Test("LOOK AT item with no description shows default message")
    @MainActor
    func testLookAtItemNoDescription() async throws {
        let item = Item(id: "pebble", name: "small pebble") // No description
        let (engine, mockIO) = await createTestEngine(locationProperties: [.inherentlyLit], itemToExamine: item)
        let command = Command(verbID: "look", directObject: "pebble", rawInput: "l pebble")

        try await handler.perform(command: command, engine: engine)

        let output = await mockIO.flush()
        expectNoDifference(output, "You see nothing special about the small pebble.")
    }

    // TODO: Add tests for LOOK AT container (open/closed/transparent) and surface - currently handled in handler, maybe move to engine?
    // TODO: Add test for LOOK AT item in dark room (should fail if item not reachable)
}
