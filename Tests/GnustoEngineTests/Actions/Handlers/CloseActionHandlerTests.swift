import CustomDump
import Testing

@testable import GnustoEngine

@Suite("CloseActionHandler Tests")
struct CloseActionHandlerTests {
    let handler = CloseActionHandler()

    @Test("Close open container successfully")
    func testCloseOpenContainerSuccessfully() async throws {
        let box = Item(
            id: "box",
            .name("wooden box"),
            .in(.location(.startRoom)),
            .isContainer,
            .isOpenable,
            .isOpen // Start open
        )
        let game = MinimalGame(items: [box])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            blueprint: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        let command = Command(
            verb: .close,
            directObject: .item("box"),
            rawInput: "close box"
        )

        // Initial state check
        let initialBox = try await engine.item("box")
        #expect(initialBox.attributes[.isOpen] == true)
        #expect(await engine.gameState.changeHistory.isEmpty)

        // Act
        await engine.execute(command: command)

        // Assert State Change
        let finalBox = try await engine.item("box")
        #expect(finalBox.attributes[.isOpen] == false)
        #expect(finalBox.attributes[.isTouched] == true)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "Closed.")

        // Assert Change History
        let changeHistory = await engine.gameState.changeHistory
        expectNoDifference(changeHistory, [
            StateChange(
                entityID: .item(box.id),
                attribute: .itemAttribute(.isOpen),
                oldValue: true, // Assume it was open before closing
                newValue: false
            ),
            StateChange(
                entityID: .item(box.id),
                attribute: .itemAttribute(.isTouched),
                newValue: true,
            ),
            StateChange(
                entityID: .global,
                attribute: .pronounReference(pronoun: "it"),
                newValue: .entityReferenceSet([.item(box.id)])
            ),
        ])
    }

    @Test("Close fails if already closed")
    func testCloseFailsIfAlreadyClosed() async throws {
        let box = Item(
            id: "box",
            .name("wooden box"),
            .in(.location(.startRoom)),
            .isContainer,
            .isOpenable
            // Starts closed by default (no .isOpen)
        )
        let game = MinimalGame(items: [box])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            blueprint: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        let command = Command(
            verb: .close,
            directObject: .item("box"),
            rawInput: "close box"
        )

        // Act: Use engine.execute for full pipeline
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "The wooden box is already closed.")

        // Assert Change History
        #expect(await engine.gameState.changeHistory.isEmpty)
    }

    @Test("Close fails if not openable")
    func testCloseFailsIfNotOpenable() async throws {
        let rock = Item(
            id: "rock",
            .name("smooth rock"),
            .in(.location(.startRoom))
            // isContainer/isOpenable are false by default
        )
        let game = MinimalGame(items: [rock])
        let engine = await GameEngine(
            blueprint: game,
            parser: MockParser(),
            ioHandler: await MockIOHandler()
        )

        let command = Command(
            verb: .close,
            directObject: .item("rock"),
            rawInput: "close rock"
        )

        // Act & Assert Error
        await #expect(throws: ActionResponse.itemNotClosable("rock")) {
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

    @Test("Close fails if item not accessible")
    func testCloseFailsIfNotAccessible() async throws {
        let box = Item(
            id: "box",
            .name("wooden box"),
            .in(.nowhere),
            .isOpenable,
            .isOpen // Start open
        )
        let game = MinimalGame(items: [box])
        let engine = await GameEngine(
            blueprint: game,
            parser: MockParser(),
            ioHandler: await MockIOHandler()
        )

        let command = Command(
            verb: .close,
            directObject: .item("box"),
            rawInput: "close box"
        )

        // Act & Assert Error
        await #expect(throws: ActionResponse.itemNotAccessible("box")) {
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

    @Test("Close fails with no direct object")
    func testCloseFailsWithNoObject() async throws {
        let game = MinimalGame()
        let engine = await GameEngine(
            blueprint: game,
            parser: MockParser(),
            ioHandler: await MockIOHandler()
        )

        let command = Command(
            verb: .close,
            rawInput: "close"
        )

        // Act & Assert Error
        await #expect(throws: ActionResponse.prerequisiteNotMet("Close what?")) {
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
