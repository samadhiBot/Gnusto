import CustomDump
import Testing

@testable import GnustoEngine

@MainActor
@Suite("CloseActionHandler Tests")
struct CloseActionHandlerTests {
    let handler = CloseActionHandler()

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
        #expect(initialBox?.attributes[.isOpen] == true)
        #expect(engine.gameState.changeHistory.isEmpty)

        // Act
        await engine.execute(command: command)

        // Assert State Change
        let finalBox = engine.item("box")
        #expect(finalBox?.attributes[.isOpen] == false)
        #expect(finalBox?.attributes[.isTouched] == true)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "Closed.")

        // Assert Change History
        expectNoDifference(engine.gameState.changeHistory, [
            StateChange(
                entityId: .item(box.id),
                attributeKey: .itemAttribute(.isOpen),
                oldValue: true, // Assume it was open before closing
                newValue: false
            ),
            StateChange(
                entityId: .item(box.id),
                attributeKey: .itemAttribute(.isTouched),
                oldValue: false,
                newValue: true,
            ),
            StateChange(
                entityId: .global,
                attributeKey: .pronounReference(pronoun: "it"),
                oldValue: nil,
                newValue: .itemIDSet([box.id])
            ),
        ])
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
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        let command = Command(verbID: "close", directObject: "box", rawInput: "close box")

        // Act: Use engine.execute for full pipeline
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "The wooden box is already closed.")

        // Assert Change History
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
        await #expect(throws: ActionError.itemNotClosable("rock")) {
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
        await #expect(throws: ActionError.prerequisiteNotMet("Close what?")) {
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
