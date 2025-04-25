import Testing
import CustomDump

@testable import GnustoEngine

@MainActor
@Suite("WearActionHandler Tests")
struct WearActionHandlerTests {
    let handler = WearActionHandler()

    @Test("Wear held, wearable item successfully")
    func testWearItemSuccess() async throws {
        let cloak = Item(
            id: "cloak",
            name: "cloak",
            properties: .takable, .wearable, // Held, wearable
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
        let game = MinimalGame()
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )

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
        let rock = Item(
            id: "rock",
            name: "rock",
            properties: .takable, // Held, but not wearable
            parent: .player
        )
        let game = MinimalGame(items: [rock])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )

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
        let cloak = Item(
            id: "cloak",
            name: "cloak",
            properties: .takable, .wearable, .worn, // Held, wearable, already worn
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
        let game = MinimalGame()
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        // Command with nil directObject
        let command = Command(verbID: "wear", rawInput: "wear")

        // Act
        try await handler.perform(command: command, engine: engine)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "Wear what?")
    }
}
