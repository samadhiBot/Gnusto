import Testing
import CustomDump
@testable import GnustoEngine

@MainActor
@Suite("WearActionHandler Tests")
struct WearActionHandlerTests {
    let handler = WearActionHandler()
    let testLocationID = Location.ID("testRoom")

    // --- Helper Setup ---
    func createTestEngine(
        itemsInInventory: [Item] = []
    ) async -> (GameEngine, MockIOHandler) {
        let location = Location(id: testLocationID, name: "Test Room", description: "A basic room.", properties: .inherentlyLit)
        let player = Player(currentLocationID: location.id)

        var allItems: [Item.ID: Item] = [:]
        for item in itemsInInventory {
            // Assume items passed are intended to be in inventory
            allItems[item.id] = Item(id: item.id, name: item.name, properties: item.properties, parent: .player)
        }

        // Add relevant verbs to vocabulary
        let wearVerb = Verb(
            id: "wear",
            synonyms: "don",
            syntax: [SyntaxRule(.verb, .directObject)]
        )
        let verbs = [wearVerb]
        let vocab = Vocabulary.build(items: Array(allItems.values), verbs: verbs)

        let initialState = GameState(
            locations: [location.id: location],
            items: allItems,
            player: player,
            vocabulary: vocab
        )

        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            initialState: initialState,
            parser: mockParser,
            ioHandler: mockIO
        )

        return (engine, mockIO)
    }

    // --- Tests ---

    @Test("Wear held, wearable item successfully")
    func testWearItemSuccess() async throws {
        let cloak = Item(id: "cloak", name: "cloak", properties: .takable, .wearable) // Held, wearable
        let (engine, mockIO) = await createTestEngine(itemsInInventory: [cloak])
        let command = Command(verbID: "wear", directObject: "cloak", rawInput: "wear cloak")

        // Initial state check
        #expect(engine.itemSnapshot(with: "cloak")?.hasProperty(.worn) == false)

        // Act
        try await handler.perform(command: command, engine: engine)

        // Assert State Change
        let finalCloakState = engine.itemSnapshot(with: "cloak")
        #expect(finalCloakState?.hasProperty(.worn) == true, "Cloak should have .worn property")

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "You put on the cloak.")
    }

    @Test("Wear fails if item not held")
    func testWearItemNotHeld() async throws {
        // Cloak is not in inventory in this setup
        let (engine, _) = await createTestEngine()
        let command = Command(verbID: "wear", directObject: "cloak", rawInput: "wear cloak")
        // We assume parser resolved "cloak" to an ID, even if not held,
        // but the handler must verify it *is* held.

        // Act & Assert Error
        // The handler should throw itemNotHeld before checking wearability
        await #expect(throws: ActionError.itemNotHeld("cloak")) {
             try await handler.perform(command: command, engine: engine)
        }
    }

    @Test("Wear fails if item not wearable")
    func testWearItemNotWearable() async throws {
        let rock = Item(id: "rock", name: "rock", properties: .takable) // Held, but not wearable
        let (engine, _) = await createTestEngine(itemsInInventory: [rock])
        let command = Command(verbID: "wear", directObject: "rock", rawInput: "wear rock")

        // Act & Assert Error
        await #expect(throws: ActionError.itemNotWearable("rock")) {
             try await handler.perform(command: command, engine: engine)
        }

        // Assert State Unchanged
        #expect(engine.itemSnapshot(with: "rock")?.hasProperty(.worn) == false)
    }

    @Test("Wear fails if item already worn")
    func testWearItemAlreadyWorn() async throws {
        let cloak = Item(id: "cloak", name: "cloak", properties: .takable, .wearable, .worn) // Held, wearable, already worn
        let (engine, mockIO) = await createTestEngine(itemsInInventory: [cloak])
        let command = Command(verbID: "wear", directObject: "cloak", rawInput: "wear cloak")

        // Act
        try await handler.perform(command: command, engine: engine)

        // Assert State Unchanged
        #expect(engine.itemSnapshot(with: "cloak")?.hasProperty(.worn) == true)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "You are already wearing the cloak.")
    }

    @Test("Wear fails with no direct object")
    func testWearNoObject() async throws {
        let (engine, mockIO) = await createTestEngine()
        // Command with nil directObject
        let command = Command(verbID: "wear", rawInput: "wear")

        // Act
        try await handler.perform(command: command, engine: engine)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "Wear what?")
    }
}
