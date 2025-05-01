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
        var mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        let command = Command(verbID: "remove", directObject: "cloak", rawInput: "remove cloak")
        mockParser.parseHandler = { _, _, _ in .success(command) }

        // Initial state check
        let initialProperties = engine.item(with: "cloak")?.properties ?? []
        #expect(initialProperties.contains(.worn) == true)
        let initialHistory = engine.gameState.changeHistory
        #expect(initialHistory.isEmpty)

        // Act
        await engine.execute(command: command)

        // Assert State Change
        let finalCloakState = engine.item(with: "cloak")
        #expect(finalCloakState?.hasProperty(.worn) == false, "Cloak should NOT have .worn property")
        #expect(finalCloakState?.hasProperty(.touched) == true, "Cloak should have .touched property") // Ensure touched is added

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "You take off the cloak.")

        // Assert Change History
        let expectedChanges = [
            StateChange(
                entityId: .item("cloak"),
                propertyKey: .itemProperties,
                oldValue: .itemProperties(initialProperties),
                newValue: .itemProperties([.takable, .wearable, .touched]) // .worn removed, .touched added
            ),
            StateChange(
                entityId: .global,
                propertyKey: .pronounIt,
                oldValue: nil,
                newValue: .itemIDSet(["cloak"])
            )
        ]
        let finalHistory = engine.gameState.changeHistory
        expectNoDifference(finalHistory, expectedChanges)
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
        let engine = GameEngine(
            game: game,
            parser: MockParser(),
            ioHandler: await MockIOHandler()
        )

        let command = Command(verbID: "remove", directObject: "cloak", rawInput: "take off cloak")

        // Act & Assert Error (on validate)
        await #expect(throws: ActionError.itemIsNotWorn("cloak")) {
            try await handler.validate(command: command, engine: engine)
        }
        #expect(engine.gameState.changeHistory.isEmpty)
    }

    @Test("Remove fails if item not held")
    func testRemoveItemNotHeld() async throws {
        let game = MinimalGame() // Cloak doesn't exist here
        let engine = GameEngine(
            game: game,
            parser: MockParser(),
            ioHandler: await MockIOHandler()
        )

        let command = Command(verbID: "remove", directObject: "cloak", rawInput: "remove cloak")

        // Act & Assert Error (on validate)
        await #expect(throws: ActionError.itemNotHeld("cloak")) {
             try await handler.validate(command: command, engine: engine)
        }
        #expect(engine.gameState.changeHistory.isEmpty)
    }

    @Test("Remove fails with no direct object")
    func testRemoveNoObject() async throws {
        let game = MinimalGame()
        let engine = GameEngine(
            game: game,
            parser: MockParser(),
            ioHandler: await MockIOHandler()
        )

        // Command with nil directObject
        let command = Command(verbID: "remove", rawInput: "remove")

        // Act & Assert Error (on validate)
        await #expect(throws: ActionError.prerequisiteNotMet("Remove what?")) {
             try await handler.validate(command: command, engine: engine)
        }
        #expect(engine.gameState.changeHistory.isEmpty)
    }

    @Test("Remove fails if item is fixed (cursed)")
    func testRemoveFailsIfFixed() async throws {
        let amulet = Item(
            id: "amulet",
            name: "cursed amulet",
            properties: .wearable, .worn, .fixed, // Worn and fixed
            parent: .player
        )
        let game = MinimalGame(items: [amulet])
        let engine = GameEngine(
            game: game,
            parser: MockParser(),
            ioHandler: await MockIOHandler()
        )

        let command = Command(verbID: "remove", directObject: "amulet", rawInput: "remove amulet")

        // Act & Assert Error (on validate)
        await #expect(throws: ActionError.itemNotRemovable("amulet")) {
            try await handler.validate(command: command, engine: engine)
        }
        #expect(engine.gameState.changeHistory.isEmpty)
    }
}
