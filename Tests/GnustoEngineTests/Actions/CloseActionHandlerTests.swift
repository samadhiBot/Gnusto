import CustomDump
import Testing

@testable import GnustoEngine

@MainActor
@Suite("CloseActionHandler Tests")
struct CloseActionHandlerTests {
    let handler = CloseActionHandler()

    // Helper to create the expected StateChange array for successful close
    private func expectedCloseChanges(
        itemID: ItemID,
        oldProperties: Set<ItemProperty>
    ) -> [StateChange] {
        var finalProperties = oldProperties
        finalProperties.insert(.touched)

        if oldProperties != finalProperties {
            let change = StateChange(
                entityId: .item(itemID),
                propertyKey: .itemProperties,
                oldValue: .itemPropertySet(oldProperties),
                newValue: .itemPropertySet(finalProperties)
            )
            return [change]
        }
        // No pronoun changes expected for closing
        return []
    }

    // Helper to create the expected StateChange for setting isOpen to false
    private func expectedIsOpenFalseChange(itemID: ItemID) -> StateChange {
        StateChange(
            entityId: .item(itemID),
            propertyKey: .itemAttribute(.isOpen),
            oldValue: .bool(true), // Assumes it was true before closing
            newValue: .bool(false)
        )
    }

    @Test("Close open container successfully")
    func testCloseOpenContainerSuccessfully() async throws {
        let box = Item(
            id: "box",
            name: "wooden box",
            parent: .location("startRoom"),
            attributes: [
                .isContainer: true,
                .isOpenable: true,
                .isOpen: true // Start open
            ]
        )
        let game = MinimalGame(items: [box])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        let command = Command(verbID: "close", directObject: "box", rawInput: "close box")

        // Initial state check
        let initialBox = await engine.item("box")
        #expect(initialBox?.attributes[.isOpen] == .bool(true)) // Qualified key
        #expect(engine.gameState.changeHistory.isEmpty)

        // Act
        await engine.execute(command: command)

        // Assert State Change
        let finalBox = await engine.item("box")
        #expect(finalBox?.attributes[.isOpen] == .bool(false)) // Qualified key
        #expect(finalBox?.hasFlag(PropertyID.isTouched) == true)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "You close the wooden box.")

        // Assert Change History
        let expectedChanges = [
            StateChange(
                entityId: .item("box"),
                propertyKey: .itemAttribute(.isOpen), // Correct key
                oldValue: .bool(true),
                newValue: .bool(false)
            ),
            StateChange(
                entityId: .item("box"),
                propertyKey: .itemAttribute(.isTouched), // Correct key
                oldValue: .bool(false), // Assuming not touched before close
                newValue: .bool(true)
            ),
            StateChange(
                entityId: .global,
                propertyKey: .pronounReference(pronoun: "it"),
                oldValue: nil, // Assuming previous 'it' is irrelevant
                newValue: .itemIDSet(["box"])
            )
        ]
        expectNoDifference(engine.gameState.changeHistory, expectedChanges)
    }

    @Test("Close fails if already closed")
    func testCloseFailsIfAlreadyClosed() async throws {
        let box = Item(
            id: "box",
            name: "wooden box",
            parent: .location("startRoom"),
            attributes: [
                .isContainer: true,
                .isOpenable: true
                // Starts closed by default (no .isOpen: true)
            ]
        )
        let game = MinimalGame(items: [box])
        let engine = GameEngine(
            game: game,
            parser: MockParser(),
            ioHandler: await MockIOHandler()
        )

        let command = Command(verbID: "close", directObject: "box", rawInput: "close box")

        // Act & Assert Error
        await #expect(throws: ActionError.customResponse("It's already closed.")) {
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

    @Test("Close fails if not openable")
    func testCloseFailsIfNotOpenable() async throws {
        let rock = Item(
            id: "rock",
            name: "smooth rock",
            parent: .location("startRoom")
            // isContainer/isOpenable are false by default
        )
        let game = MinimalGame(items: [rock])
        let engine = GameEngine(
            game: game,
            parser: MockParser(),
            ioHandler: await MockIOHandler()
        )

        let command = Command(verbID: "close", directObject: "rock", rawInput: "close rock")

        // Act & Assert Error
        await #expect(throws: ActionError.itemNotOpenable("rock")) {
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

    @Test("Close fails if item not accessible")
    func testCloseFailsIfNotAccessible() async throws {
        let box = Item(
            id: "box",
            name: "distant box",
            parent: .nowhere,
            attributes: [
                .isOpenable: true,
                .isOpen: true // Start open
            ]
        )
        let game = MinimalGame(items: [box])
        let engine = GameEngine(
            game: game,
            parser: MockParser(),
            ioHandler: await MockIOHandler()
        )

        let command = Command(verbID: "close", directObject: "box", rawInput: "close box")

        // Act & Assert Error
        await #expect(throws: ActionError.itemNotAccessible("box")) {
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

    @Test("Close fails with no direct object")
    func testCloseFailsWithNoObject() async throws {
        let game = MinimalGame()
        let engine = GameEngine(
            game: game,
            parser: MockParser(),
            ioHandler: await MockIOHandler()
        )

        let command = Command(verbID: "close", rawInput: "close")

        // Act & Assert Error
        await #expect(throws: ActionError.customResponse("Close what?")) {
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
