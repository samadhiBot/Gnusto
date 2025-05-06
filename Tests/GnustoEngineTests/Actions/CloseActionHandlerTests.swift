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
        initialAttributes: [AttributeID: StateValue]
    ) -> [StateChange] {
        var changes: [StateChange] = []

        // Change 1: isOpen becomes false
        changes.append(
            StateChange(
                entityId: .item(itemID),
                attributeKey: .itemAttribute(.isOpen),
                oldValue: true, // Assume it was open before closing
                newValue: false
            )
        )

        // Change 2: Item touched (if needed)
        if initialAttributes[.isTouched] != true {
            changes.append(
                StateChange(
                    entityId: .item(itemID),
                    attributeKey: .itemAttribute(.isTouched),
                    oldValue: false,
                    newValue: true,
                )
            )
        }

        // Change 3: Pronoun "it"
        changes.append(
             StateChange(
                 entityId: .global,
                 attributeKey: .pronounReference(pronoun: "it"),
                 oldValue: nil,
                 newValue: .itemIDSet([itemID])
             )
        )

        return changes
    }

    // Helper to create the expected StateChange for setting isOpen to false
    private func expectedIsOpenFalseChange(itemID: ItemID) -> StateChange {
        StateChange(
            entityId: .item(itemID),
            attributeKey: .itemAttribute(.isOpen),
            oldValue: true, // Assumes it was true before closing
            newValue: false
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
        let initialBox = engine.item("box")
        #expect(initialBox?.attributes[.isOpen] == true) // Qualified key
        #expect(engine.gameState.changeHistory.isEmpty)

        // Act
        await engine.execute(command: command)

        // Assert State Change
        let finalBox = engine.item("box")
        #expect(finalBox?.attributes[.isOpen] == false) // Qualified key
        #expect(finalBox?.hasFlag(.isTouched) == true)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "You close the wooden box.")

        // Assert Change History
        let expectedChanges = expectedCloseChanges(itemID: "box", initialAttributes: initialBox?.attributes ?? [:])
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
