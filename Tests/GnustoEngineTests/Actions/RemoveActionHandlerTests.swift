import Testing
import CustomDump

@testable import GnustoEngine

@MainActor
@Suite("RemoveActionHandler Tests")
struct RemoveActionHandlerTests {
    let handler = RemoveActionHandler()

    @Test("Remove worn item successfully")
    func testRemoveItemSuccess() async throws {
        let cloak = Item(
            id: "cloak",
            name: "cloak",
            properties: .takable, .wearable, .worn, // Held, wearable, worn
            parent: .player
        )

        let game = MinimalGame(items: [cloak])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )

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
        let cloak = Item(
            id: "cloak",
            name: "cloak",
            properties: .takable, .wearable, // Held, wearable, NOT worn
            parent: .player
        )

        let game = MinimalGame(items: [cloak])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )

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
        let game = MinimalGame()
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )

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
        let game = MinimalGame()
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        // Command with nil directObject
        let command = Command(verbID: "remove", rawInput: "remove")

        // Act
        try await handler.perform(command: command, engine: engine)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "Remove what?")
    }
}
