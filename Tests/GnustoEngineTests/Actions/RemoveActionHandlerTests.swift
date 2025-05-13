import Testing
import CustomDump

@testable import GnustoEngine

@Suite("RemoveActionHandler Tests")
struct RemoveActionHandlerTests {
    let handler = RemoveActionHandler()

    @Test("Remove worn item successfully")
    func testRemoveItemSuccess() async throws {
        let cloak = Item(
            id: "cloak",
            .in(.player),
            .isTakable,
            .isWearable,
            .isWorn
        )
        let game = MinimalGame(items: [cloak])
        let mockIO = await MockIOHandler()
        let engine = await GameEngine(
            game: game,
            parser: StandardParser(),
            ioHandler: mockIO
        )

        let command = Command(
            verbID: .remove,
            directObject: "cloak",
            rawInput: "remove cloak"
        )

        // Initial state check
        #expect(try await engine.item("cloak").hasFlag(.isWorn) == true)
        let initialHistory = await engine.gameState.changeHistory
        #expect(initialHistory.isEmpty)

        // Act
        await engine.execute(command: command)

        // Assert State Change
        let finalCloakState = try await engine.item("cloak")
        #expect(finalCloakState.parent == .player)
        #expect(finalCloakState.hasFlag(.isWorn) == false, "Cloak should NOT have .isWorn flag")
        #expect(finalCloakState.hasFlag(.isTouched) == true, "Cloak should have .isTouched flag") // Ensure touched is added

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "You take off the cloak.")

        // Assert Change History
        let expectedChanges = [
            StateChange(
                entityID: .item("cloak"),
                attributeKey: .itemAttribute(.isWorn),
                oldValue: true,
                newValue: false
            ),
            StateChange(
                entityID: .item("cloak"),
                attributeKey: .itemAttribute(.isTouched),
                oldValue: nil,
                newValue: true
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

    @Test("Remove fails if item not worn (but held)")
    func testRemoveItemNotWorn() async throws {
        let cloak = Item(
            id: "cloak",
            .in(.player),
            .isTakable,
            .isWearable
        )
        let game = MinimalGame(items: [cloak])
        let engine = await GameEngine(
            game: game,
            parser: MockParser(),
            ioHandler: await MockIOHandler()
        )

        let command = Command(
            verbID: .remove,
            directObject: "cloak",
            rawInput: "take off cloak"
        )

        // Act & Assert Error (on validate)
        await #expect(throws: ActionResponse.itemIsNotWorn("cloak")) {
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

    @Test("Remove fails if item not held")
    func testRemoveItemNotHeld() async throws {
        let game = MinimalGame() // Cloak doesn't exist here
        let engine = await GameEngine(
            game: game,
            parser: MockParser(),
            ioHandler: await MockIOHandler()
        )

        let command = Command(
            verbID: .remove,
            directObject: "cloak",
            rawInput: "remove cloak"
        )

        // Act & Assert Error (on validate)
        await #expect(throws: ActionResponse.itemNotAccessible("cloak")) {
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

    @Test("Remove fails with no direct object")
    func testRemoveNoObject() async throws {
        let game = MinimalGame()
        let engine = await GameEngine(
            game: game,
            parser: MockParser(),
            ioHandler: await MockIOHandler()
        )

        // Command with nil directObject
        let command = Command(
            verbID: .remove,
            rawInput: "remove"
        )

        // Act & Assert Error (on validate)
        await #expect(throws: ActionResponse.prerequisiteNotMet("Remove what?")) {
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

    @Test("Remove fails if item is fixed scenery (which can be worn)")
    func testRemoveFailsIfFixed() async throws {
        let amulet = Item(
            id: "amulet",
            .name("cursed amulet"),
            .in(.player),
            .isScenery,
            .isWearable,
            .isWorn
        )
        let game = MinimalGame(items: [amulet])
        let engine = await GameEngine(
            game: game,
            parser: MockParser(),
            ioHandler: await MockIOHandler()
        )

        let command = Command(
            verbID: .remove,
            directObject: "amulet",
            rawInput: "remove amulet"
        )

        // Act & Assert Error (on validate)
        await #expect(throws: ActionResponse.itemNotRemovable("amulet")) {
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
