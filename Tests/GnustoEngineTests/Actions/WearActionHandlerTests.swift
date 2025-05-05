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
            parent: .player,
            isTakable: true,
            isWearable: true
        )
        let game = MinimalGame(items: [cloak])
        let mockIO = await MockIOHandler()
        var mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        let command = Command(verbID: "wear", directObject: "cloak", rawInput: "wear cloak")
        mockParser.parseHandler = { _, _, _ in .success(command) }

        let initialItem = await engine.item(with: "cloak")
        #expect(initialItem?.hasFlag(PropertyID.isWorn) == false)
        #expect(engine.gameState.changeHistory.isEmpty)

        await engine.execute(command: command)

        let finalCloakState = await engine.item(with: "cloak")
        #expect(finalCloakState?.parent == .player)
        #expect(finalCloakState?.hasFlag(PropertyID.isWorn) == true, "Cloak should have .worn property")
        #expect(finalCloakState?.hasFlag(PropertyID.itemTouched) == true, "Cloak should have .touched property")

        let output = await mockIO.flush()
        expectNoDifference(output, "You put on the cloak.")

        let expectedChanges = [
            StateChange(
                entityId: .item("cloak"),
                propertyKey: .itemDynamicValue(key: .isWorn),
                oldValue: .bool(false),
                newValue: .bool(true)
            ),
            StateChange(
                entityId: .item("cloak"),
                propertyKey: .itemDynamicValue(key: .itemTouched),
                oldValue: .bool(false),
                newValue: .bool(true)
            ),
            StateChange(
                entityId: .global,
                propertyKey: .pronounReference(pronoun: "it"),
                oldValue: nil,
                newValue: .itemIDSet(["cloak"])
            )
        ]
        let finalHistory = engine.gameState.changeHistory
        expectNoDifference(finalHistory, expectedChanges)
    }

    @Test("Wear fails if item not held")
    func testWearItemNotHeld() async throws {
        let game = MinimalGame()
        let engine = GameEngine(
            game: game,
            parser: MockParser(),
            ioHandler: await MockIOHandler()
        )

        let command = Command(verbID: "wear", directObject: "cloak", rawInput: "wear cloak")

        await #expect(throws: ActionError.itemNotHeld("cloak")) {
            try await handler.validate(
                context: ActionContext(
                    command: command,
                    engine: engine,
                    stateSnapshot: engine.gameState
                )
            )
        }
        #expect(engine.gameState.changeHistory.isEmpty)
    }

    @Test("Wear fails if item not wearable")
    func testWearItemNotWearable() async throws {
        let rock = Item(
            id: "rock",
            name: "rock",
            parent: .player,
            isTakable: true
        )
        let game = MinimalGame(items: [rock])
        let engine = GameEngine(
            game: game,
            parser: MockParser(),
            ioHandler: await MockIOHandler()
        )

        let command = Command(verbID: "wear", directObject: "rock", rawInput: "wear rock")

        await #expect(throws: ActionError.itemNotWearable("rock")) {
            try await handler.validate(
                context: ActionContext(
                    command: command,
                    engine: engine,
                    stateSnapshot: engine.gameState
                )
            )
        }
        #expect(engine.gameState.changeHistory.isEmpty)
    }

    @Test("Wear fails if item already worn")
    func testWearItemAlreadyWorn() async throws {
        let cloak = Item(
            id: "cloak",
            name: "cloak",
            parent: .player,
            isTakable: true,
            isWearable: true,
            isWorn: true
        )
        let game = MinimalGame(items: [cloak])
        let engine = GameEngine(
            game: game,
            parser: MockParser(),
            ioHandler: await MockIOHandler()
        )

        let command = Command(verbID: "wear", directObject: "cloak", rawInput: "wear cloak")

        await #expect(throws: ActionError.itemIsAlreadyWorn("cloak")) {
             try await handler.validate(
                context: ActionContext(
                    command: command,
                    engine: engine,
                    stateSnapshot: engine.gameState
                )
            )
        }
        #expect(engine.gameState.changeHistory.isEmpty)
    }

    @Test("Wear fails with no direct object")
    func testWearNoObject() async throws {
        let game = MinimalGame()
        let engine = GameEngine(
            game: game,
            parser: MockParser(),
            ioHandler: await MockIOHandler()
        )

        let command = Command(verbID: "wear", rawInput: "wear")

        await #expect(throws: ActionError.prerequisiteNotMet("Wear what?")) {
             try await handler.validate(
                context: ActionContext(
                    command: command,
                    engine: engine,
                    stateSnapshot: engine.gameState
                )
            )
        }
        #expect(engine.gameState.changeHistory.isEmpty)
    }
}
