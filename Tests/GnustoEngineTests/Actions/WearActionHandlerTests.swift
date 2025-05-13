import Testing
import CustomDump

@testable import GnustoEngine

@Suite("WearActionHandler Tests")
struct WearActionHandlerTests {
    // Keep handler instance for direct validation testing
    let handler = WearActionHandler()

    @Test("Wear held, wearable item successfully")
    func testWearItemSuccess() async throws {
        let cloak = Item(
            id: "cloak",
            .name("velvet cloak"),
            .in(.player),
            .isWearable,
            .isTakable
        )
        let game = MinimalGame(items: [cloak])
        let mockIO = await MockIOHandler()
        var mockParser = MockParser()
        let engine = await GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        let command = Command(
            verbID: .wear,
            directObject: "cloak",
            rawInput: "wear cloak"
        )
        mockParser.parseHandler = { _, _, _ in .success(command) }

        let initialItem = try await engine.item("cloak")
        #expect(initialItem?.hasFlag(.isWorn) == false)
        #expect(await engine.gameState.changeHistory.isEmpty)

        await engine.execute(command: command)

        let finalCloakState = try await engine.item("cloak")
        #expect(finalCloakState?.parent == .player)
        #expect(finalCloakState?.hasFlag(.isWorn) == true, "Cloak should have .worn property")
        #expect(finalCloakState?.hasFlag(.isTouched) == true, "Cloak should have .touched property")

        let output = await mockIO.flush()
        expectNoDifference(output, "You put on the velvet cloak.")

        let expectedChanges = [
            StateChange(
                entityID: .item("cloak"),
                attributeKey: .itemAttribute(.isWorn),
                oldValue: false,
                newValue: true,
            ),
            StateChange(
                entityID: .item("cloak"),
                attributeKey: .itemAttribute(.isTouched),
                oldValue: false,
                newValue: true,
            ),
            StateChange(
                entityID: .global,
                attributeKey: .pronounReference(pronoun: "it"),
                oldValue: nil,
                newValue: .itemIDSet(["cloak"])
            )
        ]
        let finalHistory = await engine.gameState.changeHistory
        expectNoDifference(finalHistory, expectedChanges)
    }

    @Test("Wear fails if item not held")
    func testWearItemNotHeld() async throws {
        let game = MinimalGame()
        let engine = await GameEngine(
            game: game,
            parser: MockParser(),
            ioHandler: await MockIOHandler()
        )

        let command = Command(
            verbID: .wear,
            directObject: "cloak",
            rawInput: "wear cloak"
        )

        await #expect(throws: ActionResponse.itemNotHeld("cloak")) {
            try await handler.validate(
                context: ActionContext(
                    command: command,
                    engine: engine,
                    stateSnapshot: engine.gameState
                )
            )
        }
        #expect(await engine.gameState.changeHistory.isEmpty)
    }

    @Test("Wear fails if item not wearable")
    func testWearItemNotWearable() async throws {
        let rock = Item(
            id: "rock",
            .name("heavy rock"),
            .in(.player),
            .isTakable
        )
        let game = MinimalGame(items: [rock])
        let engine = await GameEngine(
            game: game,
            parser: MockParser(),
            ioHandler: await MockIOHandler()
        )

        let command = Command(
            verbID: .wear,
            directObject: "rock",
            rawInput: "wear rock"
        )

        await #expect(throws: ActionResponse.itemNotWearable("rock")) {
            try await handler.validate(
                context: ActionContext(
                    command: command,
                    engine: engine,
                    stateSnapshot: engine.gameState
                )
            )
        }
        #expect(await engine.gameState.changeHistory.isEmpty)
    }

    @Test("Wear fails if item already worn")
    func testWearItemAlreadyWorn() async throws {
        let cloak = Item(
            id: "cloak",
            .name("velvet cloak"),
            .in(.player),
            .isWearable,
            .isTakable,
            .isWorn
        )
        let game = MinimalGame(items: [cloak])
        let engine = await GameEngine(
            game: game,
            parser: MockParser(),
            ioHandler: await MockIOHandler()
        )

        let command = Command(
            verbID: .wear,
            directObject: "cloak",
            rawInput: "wear cloak"
        )

        await #expect(throws: ActionResponse.itemIsAlreadyWorn("cloak")) {
            try await handler.validate(
                context: ActionContext(
                    command: command,
                    engine: engine,
                    stateSnapshot: engine.gameState
                )
            )
        }
        #expect(await engine.gameState.changeHistory.isEmpty)
    }

    @Test("Wear fails with no direct object")
    func testWearNoObject() async throws {
        let game = MinimalGame()
        let engine = await GameEngine(
            game: game,
            parser: MockParser(),
            ioHandler: await MockIOHandler()
        )

        let command = Command(
            verbID: .wear,
            rawInput: "wear"
        )

        await #expect(throws: ActionResponse.prerequisiteNotMet("Wear what?")) {
            try await handler.validate(
                context: ActionContext(
                    command: command,
                    engine: engine,
                    stateSnapshot: engine.gameState
                )
            )
        }
        #expect(await engine.gameState.changeHistory.isEmpty)
    }
}
