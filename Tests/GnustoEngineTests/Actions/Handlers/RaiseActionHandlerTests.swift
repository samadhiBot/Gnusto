import CustomDump
import Testing

@testable import GnustoEngine

@Suite("RaiseActionHandler Tests")
struct RaiseActionHandlerTests {
    let handler = RaiseActionHandler()

    @Test("Raise item gives default response")
    func testRaiseItemGivesDefaultResponse() async throws {
        let book = Item(
            id: "book",
            .name("heavy book"),
            .in(.location(.startRoom)),
            .isTakable
        )
        let game = MinimalGame(items: [book])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            blueprint: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        let command = Command(
            verb: .raise,
            directObject: .item("book"),
            rawInput: "raise book"
        )

        // Initial state check
        let initialBook = try await engine.item("book")
        #expect(initialBook.attributes[.isTouched] == nil)
        #expect(await engine.gameState.changeHistory.isEmpty)

        // Act
        await engine.execute(command: command)

        // Assert State Change
        let finalBook = try await engine.item("book")
        #expect(finalBook.attributes[.isTouched] == true)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "You can’t lift the heavy book.")

        // Assert Change History
        let changeHistory = await engine.gameState.changeHistory
        expectNoDifference(changeHistory, [
            StateChange(
                entityID: .item(book.id),
                attribute: .itemAttribute(.isTouched),
                newValue: true
            ),
            StateChange(
                entityID: .global,
                attribute: .pronounReference(pronoun: "it"),
                newValue: .entityReferenceSet([.item(book.id)])
            ),
        ])
    }

    @Test("Raise fails if item not accessible")
    func testRaiseFailsIfNotAccessible() async throws {
        let book = Item(
            id: "book",
            .name("heavy book"),
            .in(.nowhere),
            .isTakable
        )
        let game = MinimalGame(items: [book])
        let mockIO = await MockIOHandler()
        let engine = await GameEngine(
            blueprint: game,
            parser: MockParser(),
            ioHandler: mockIO
        )

        let command = Command(
            verb: .raise,
            directObject: .item("book"),
            rawInput: "raise book"
        )

        // Act & Assert Error
        await #expect(throws: Error.self) {
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

    @Test("Raise fails with no direct object")
    func testRaiseFailsWithNoObject() async throws {
        let game = MinimalGame()
        let mockIO = await MockIOHandler()
        let engine = await GameEngine(
            blueprint: game,
            parser: MockParser(),
            ioHandler: mockIO
        )

        let command = Command(
            verb: .raise,
            rawInput: "raise"
        )

        // Act
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "Raise what?")

        #expect(await engine.gameState.changeHistory.isEmpty)
    }

    @Test("Raise fails with non-item target")
    func testRaiseFailsWithNonItemTarget() async throws {
        let game = MinimalGame()
        let mockIO = await MockIOHandler()
        let engine = await GameEngine(
            blueprint: game,
            parser: MockParser(),
            ioHandler: mockIO
        )

        let command = Command(
            verb: .raise,
            directObject: .location(.startRoom),
            rawInput: "raise room"
        )

        // Act
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "You can only raise items.")

        #expect(await engine.gameState.changeHistory.isEmpty)
    }

    @Test("Raise fails if item not reachable")
    func testRaiseFailsIfNotReachable() async throws {
        let box = Item(
            id: "box",
            .name("locked box"),
            .in(.location(.startRoom)),
            .isContainer
            // Not open, so contents not reachable
        )
        let book = Item(
            id: "book",
            .name("hidden book"),
            .in(.item("box")),
            .isTakable
        )
        let game = MinimalGame(items: [box, book])
        let mockIO = await MockIOHandler()
        let engine = await GameEngine(
            blueprint: game,
            parser: MockParser(),
            ioHandler: mockIO
        )

        let command = Command(
            verb: .raise,
            directObject: .item("book"),
            rawInput: "raise book"
        )

        // Act
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "You can’t see any such thing.")

        #expect(await engine.gameState.changeHistory.isEmpty)
    }

    @Test("Raise works on player inventory items")
    func testRaiseWorksOnInventoryItems() async throws {
        let coin = Item(
            id: "coin",
            .name("gold coin"),
            .in(.player),
            .isTakable
        )
        let game = MinimalGame(items: [coin])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            blueprint: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        let command = Command(
            verb: .raise,
            directObject: .item("coin"),
            rawInput: "raise coin"
        )

        // Act
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "You can’t lift the gold coin.")

        // Assert State Change
        let finalCoin = try await engine.item("coin")
        #expect(finalCoin.attributes[.isTouched] == true)
    }
}
