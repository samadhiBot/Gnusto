import Testing
import CustomDump

@testable import GnustoEngine

@MainActor
@Suite("RemoveActionHandler Tests")
struct RemoveActionHandlerTests {
    let handler = RemoveActionHandler()
    let testLocationID = Location.ID("testRoom")

    // --- Helper Setup (Adapted from WearActionHandlerTests) ---
    func createTestEngine(
        itemsInInventory: [Item] = []
    ) async -> (GameEngine, MockIOHandler) {
        let location = Location(id: testLocationID, name: "Test Room", description: "A basic room.", properties: [.inherentlyLit])
        let player = Player(currentLocationID: location.id)

        var allItems: [Item.ID: Item] = [:]
        for item in itemsInInventory {
            // Assume items passed are intended to be in inventory (parent = .player)
            // Use the full initializer to ensure parentage is correct if Item becomes a struct
            allItems[item.id] = Item(id: item.id, name: item.name, properties: item.properties, parent: .player)
        }

        // Add relevant verbs to vocabulary
        let removeVerb = Verb(id: "remove", synonyms: ["doff", "take off"], syntax: [SyntaxRule(pattern: [.verb, .directObject])])
        let verbs = [removeVerb]
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

    @Test("Remove worn item successfully")
    func testRemoveItemSuccess() async throws {
        let cloak = Item(id: "cloak", name: "cloak", properties: [.takable, .wearable, .worn]) // Held, wearable, worn
        let (engine, mockIO) = await createTestEngine(itemsInInventory: [cloak])
        let command = Command(verbID: "remove", directObject: "cloak", rawInput: "remove cloak")

        // Initial state check
        #expect(engine.itemSnapshot(with: "cloak")?.hasProperty(.worn) == true)

        // Act
        try await handler.perform(command: command, engine: engine)

        // Assert State Change
        let finalCloakState = engine.itemSnapshot(with: "cloak")
        #expect(finalCloakState?.hasProperty(.worn) == false, "Cloak should NOT have .worn property")

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "You take off the cloak.")
    }

    @Test("Remove fails if item not worn (but held)")
    func testRemoveItemNotWorn() async throws {
        let cloak = Item(id: "cloak", name: "cloak", properties: [.takable, .wearable]) // Held, wearable, NOT worn
        let (engine, mockIO) = await createTestEngine(itemsInInventory: [cloak])
        let command = Command(verbID: "remove", directObject: "cloak", rawInput: "take off cloak")

        // Initial state check
        #expect(engine.itemSnapshot(with: "cloak")?.hasProperty(.worn) == false)

        // Act
        try await handler.perform(command: command, engine: engine)

        // Assert State Unchanged
        #expect(engine.itemSnapshot(with: "cloak")?.hasProperty(.worn) == false)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "You are not wearing the cloak.")
    }

    @Test("Remove fails if item not held")
    func testRemoveItemNotHeld() async throws {
        // Cloak is not in inventory in this setup
        let (engine, _) = await createTestEngine()
        let command = Command(verbID: "remove", directObject: "cloak", rawInput: "remove cloak")
        // Assume parser resolved "cloak", handler must verify it's held (or worn, implicitly meaning held)

        // Act & Assert Error
        // The handler should throw itemNotHeld (or similar check)
        await #expect(throws: ActionError.itemNotHeld("cloak")) {
             try await handler.perform(command: command, engine: engine)
        }
    }

    @Test("Remove fails with no direct object")
    func testRemoveNoObject() async throws {
        let (engine, mockIO) = await createTestEngine()
        // Command with nil directObject
        let command = Command(verbID: "remove", rawInput: "remove")

        // Act
        try await handler.perform(command: command, engine: engine)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "Remove what?")
    }
}
