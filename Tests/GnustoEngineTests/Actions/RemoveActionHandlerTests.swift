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
            parent: .player,
            attributes: [
                .isTakable: true,
                .isWearable: true,
                .isWorn: true
            ]
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
        #expect(engine.item("cloak")?.hasFlag(.isWorn) == true)
        let initialHistory = engine.gameState.changeHistory
        #expect(initialHistory.isEmpty)

        // Act
        await engine.execute(command: command)

        // Assert State Change
        let finalCloakState = await engine.item("cloak")
        #expect(finalCloakState?.parent == .location("startRoom"))
        #expect(finalCloakState?.hasFlag(.isWorn) == false, "Cloak should NOT have .isWorn flag")
        #expect(finalCloakState?.hasFlag(.isTouched) == true, "Cloak should have .isTouched flag") // Ensure touched is added

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "You take off the cloak.")

        // Assert Change History
        let expectedChanges = [
            StateChange(
                entityID: .item("cloak"),
                attributeKey: .itemParent,
                oldValue: .parentEntity(.player),
                newValue: .parentEntity(.location("startRoom"))
            ),
            StateChange(
                entityID: .item("cloak"),
                attributeKey: .itemAttribute(.isWorn),
                oldValue: true,
                newValue: false
            ),
            StateChange(
                entityID: .item("cloak"),
                attributeKey: .itemAttribute(.isTouched),
                oldValue: false,
                newValue: true
            ),
        ]
        let finalHistory = engine.gameState.changeHistory
        expectNoDifference(finalHistory, expectedChanges)
    }

    @Test("Remove fails if item not worn (but held)")
    func testRemoveItemNotWorn() async throws {
        let cloak = Item(
            id: "cloak",
            name: "cloak",
            parent: .player,
            attributes: [
                .isTakable: true,
                .isWearable: true
            ]
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

    @Test("Remove fails if item is fixed (cursed)")
    func testRemoveFailsIfFixed() async throws {
        let amulet = Item(
            id: "amulet",
            name: "cursed amulet",
            parent: .player,
            attributes: [
                .isWearable: true,
                .isWorn: true,
                .isFixed: true
            ]
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
