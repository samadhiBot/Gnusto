import Testing
import CustomDump

@testable import GnustoEngine

@MainActor
@Suite("WearActionHandler Tests")
struct WearActionHandlerTests {
    // Keep handler instance for direct validation testing
    let handler = WearActionHandler()

    @Test("Wear held, wearable item successfully")
    func testWearItemSuccess() async throws {
        let cloak = Item(
            id: "cloak",
            name: "cloak",
            properties: .takable, .wearable, // Held, wearable
            parent: .player
        )
        var game = MinimalGame(items: [cloak])
        let mockIO = await MockIOHandler()
        var mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        let command = Command(verbID: "wear", directObject: "cloak", rawInput: "wear cloak")
        mockParser.parseHandler = { _, _, _ in .success(command) }

        let initialProperties = await engine.itemSnapshot(with: "cloak")?.properties ?? []
        let initialHistory = await engine.gameState.changeHistory // Capture initial state
        #expect(initialProperties.contains(.worn) == false)
        #expect(initialHistory.isEmpty)

        // Act - Use engine.execute for success case
        await engine.execute(command: command)

        // Assert State Change
        let finalCloakState = await engine.itemSnapshot(with: "cloak")
        #expect(finalCloakState?.hasProperty(.worn) == true, "Cloak should have .worn property")
        #expect(finalCloakState?.hasProperty(.touched) == true, "Cloak should have .touched property")

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "You put on the cloak.")

        // Assert Change History
        let expectedChanges = [
            StateChange(
                objectId: "cloak",
                propertyKey: .itemProperties,
                oldValue: .itemProperties(initialProperties),
                newValue: .itemProperties([.takable, .wearable, .worn, .touched])
            ),
            StateChange(
                objectId: "cloak",
                propertyKey: .pronounReference(pronoun: "it"),
                oldValue: nil,
                newValue: .itemIDSet(["cloak"])
            )
        ]
        let finalHistory = await engine.gameState.changeHistory
        expectNoDifference(finalHistory, expectedChanges)
    }

    @Test("Wear fails if item not held")
    func testWearItemNotHeld() async throws {
        var game = MinimalGame() // Cloak doesn't exist here
        let engine = GameEngine(
            game: game,
            parser: MockParser(), // Parser needed for engine init
            ioHandler: await MockIOHandler() // IOHandler needed for engine init
        )

        let command = Command(verbID: "wear", directObject: "cloak", rawInput: "wear cloak")

        // Act & Assert Error (on validate)
        await #expect(throws: ActionError.itemNotHeld("cloak")) {
            try await handler.validate(command: command, engine: engine)
        }
        #expect(await engine.gameState.changeHistory.isEmpty)
    }

    @Test("Wear fails if item not wearable")
    func testWearItemNotWearable() async throws {
        let rock = Item(
            id: "rock",
            name: "rock",
            properties: .takable, // Held, but not wearable
            parent: .player
        )
        var game = MinimalGame(items: [rock])
        let engine = GameEngine(
            game: game,
            parser: MockParser(),
            ioHandler: await MockIOHandler()
        )

        let command = Command(verbID: "wear", directObject: "rock", rawInput: "wear rock")

        // Act & Assert Error (on validate)
        await #expect(throws: ActionError.itemNotWearable("rock")) {
            try await handler.validate(command: command, engine: engine)
        }
        #expect(await engine.gameState.changeHistory.isEmpty)
    }

    @Test("Wear fails if item already worn")
    func testWearItemAlreadyWorn() async throws {
        let cloak = Item(
            id: "cloak",
            name: "cloak",
            properties: .takable, .wearable, .worn, // Held, wearable, already worn
            parent: .player
        )
        var game = MinimalGame(items: [cloak])
        let engine = GameEngine(
            game: game,
            parser: MockParser(),
            ioHandler: await MockIOHandler()
        )

        let command = Command(verbID: "wear", directObject: "cloak", rawInput: "wear cloak")

        // Act & Assert Error (on validate)
        // Assuming the linter issue with ActionError is temporary
        await #expect(throws: ActionError.itemIsAlreadyWorn("cloak")) {
             try await handler.validate(command: command, engine: engine)
        }
        #expect(await engine.gameState.changeHistory.isEmpty)
    }

    @Test("Wear fails with no direct object")
    func testWearNoObject() async throws {
        var game = MinimalGame()
        let engine = GameEngine(
            game: game,
            parser: MockParser(),
            ioHandler: await MockIOHandler()
        )

        // Command with nil directObject
        let command = Command(verbID: "wear", rawInput: "wear")

        // Act & Assert Error (on validate)
        await #expect(throws: ActionError.prerequisiteNotMet("Wear what?")) {
             try await handler.validate(command: command, engine: engine)
        }
        #expect(await engine.gameState.changeHistory.isEmpty)
    }
}
