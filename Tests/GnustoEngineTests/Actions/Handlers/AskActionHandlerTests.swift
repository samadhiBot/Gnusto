import CustomDump
import Testing
@testable import GnustoEngine

@Suite("AskActionHandler Tests")
struct AskActionHandlerTests {
    let handler = AskActionHandler()

    @Test("Ask requires direct object")
    func testAskRequiresDirectObject() async throws {
        // Given
        let game = MinimalGame()
        let mockIO = await MockIOHandler()
        let engine = await GameEngine(
            blueprint: game,
            parser: MockParser(),
            ioHandler: mockIO
        )

        let command = Command(verb: .ask, rawInput: "ask")
        let context = ActionContext(command: command, engine: engine)

        // When/Then
        await #expect(throws: ActionResponse.prerequisiteNotMet("Ask whom?")) {
            try await handler.validate(context: context)
        }
    }

    @Test("Ask requires indirect object")
    func testAskRequiresIndirectObject() async throws {
        // Given
        let character = Item(
            id: "wizard",
            .name("old wizard"),
            .isCharacter
        )
        let game = MinimalGame(items: [character])
        let mockIO = await MockIOHandler()
        let engine = await GameEngine(
            blueprint: game,
            parser: MockParser(),
            ioHandler: mockIO
        )

        let command = Command(
            verb: .ask,
            directObject: .item("wizard"),
            rawInput: "ask wizard"
        )
        let context = ActionContext(command: command, engine: engine)

        // When/Then
        await #expect(throws: ActionResponse.prerequisiteNotMet("Ask about what?")) {
            try await handler.validate(context: context)
        }
    }

    @Test("Ask requires character as direct object")
    func testAskRequiresCharacter() async throws {
        // Given
        let rock = Item(id: "rock", .name("rock"))
        let game = MinimalGame(items: [rock])
        let mockIO = await MockIOHandler()
        let engine = await GameEngine(
            blueprint: game,
            parser: MockParser(),
            ioHandler: mockIO
        )

        let command = Command(
            verb: .ask,
            directObject: .item("rock"),
            indirectObject: .item("rock"),
            rawInput: "ask rock about rock"
        )
        let context = ActionContext(command: command, engine: engine)

        // When/Then
        await #expect(throws: ActionResponse.prerequisiteNotMet("You can't ask the rock about anything.")) {
            try await handler.validate(context: context)
        }
    }

    @Test("Ask character about item")
    func testAskCharacterAboutItem() async throws {
        // Given
        let wizard = Item(
            id: "wizard",
            .name("old wizard"),
            .in(.location(.startRoom)),
            .isCharacter
        )
        let crystal = Item(
            id: "crystal",
            .name("magic crystal"),
            .in(.location(.startRoom))
        )
        let game = MinimalGame(items: [wizard, crystal])
        let mockIO = await MockIOHandler()
        let engine = await GameEngine(
            blueprint: game,
            parser: MockParser(),
            ioHandler: mockIO
        )

        let command = Command(
            verb: .ask,
            directObject: .item("wizard"),
            indirectObject: .item("crystal"),
            rawInput: "ask wizard about crystal"
        )
        let context = ActionContext(command: command, engine: engine)

        // When
        try await handler.validate(context: context)
        let result = try await handler.process(context: context)

        // Then
        #expect(result.message == "Old wizard doesn't seem to know anything about magic crystal.")
        #expect(result.stateChanges.count == 2) // touched flag + pronoun update
    }

    @Test("Ask character about player")
    func testAskCharacterAboutPlayer() async throws {
        // Given
        let wizard = Item(
            id: "wizard",
            .name("old wizard"),
            .in(.location(.startRoom)),
            .isCharacter
        )
        let game = MinimalGame(items: [wizard])
        let mockIO = await MockIOHandler()
        let engine = await GameEngine(
            blueprint: game,
            parser: MockParser(),
            ioHandler: mockIO
        )

        let command = Command(
            verb: .ask,
            directObject: .item("wizard"),
            indirectObject: .player,
            rawInput: "ask wizard about me"
        )
        let context = ActionContext(command: command, engine: engine)

        // When
        try await handler.validate(context: context)
        let result = try await handler.process(context: context)

        // Then
        #expect(result.message == "Old wizard doesn't seem to know anything about yourself.")
    }

    @Test("Ask character about location")
    func testAskCharacterAboutLocation() async throws {
        // Given
        let wizard = Item(
            id: "wizard",
            .name("old wizard"),
            .in(.location(.startRoom)),
            .isCharacter
        )
        let game = MinimalGame(items: [wizard])
        let mockIO = await MockIOHandler()
        let engine = await GameEngine(
            blueprint: game,
            parser: MockParser(),
            ioHandler: mockIO
        )

        let command = Command(
            verb: .ask,
            directObject: .item("wizard"),
            indirectObject: .location(.startRoom),
            rawInput: "ask wizard about room"
        )
        let context = ActionContext(command: command, engine: engine)

        // When
        try await handler.validate(context: context)
        let result = try await handler.process(context: context)

        // Then
        #expect(result.message == "Old wizard doesn't seem to know anything about Void.")
    }

    @Test("Ask inaccessible character fails")
    func testAskInaccessibleCharacterFails() async throws {
        // Given
        let wizard = Item(
            id: "wizard",
            .name("old wizard"),
            .in(.nowhere),
            .isCharacter
        )
        let game = MinimalGame(items: [wizard])
        let mockIO = await MockIOHandler()
        let engine = await GameEngine(
            blueprint: game,
            parser: MockParser(),
            ioHandler: mockIO
        )

        let command = Command(
            verb: .ask,
            directObject: .item("wizard"),
            indirectObject: .item("wizard"),
            rawInput: "ask wizard about wizard"
        )
        let context = ActionContext(command: command, engine: engine)

        // When/Then
        await #expect(throws: ActionResponse.itemNotAccessible("wizard")) {
            try await handler.validate(context: context)
        }
    }
}
