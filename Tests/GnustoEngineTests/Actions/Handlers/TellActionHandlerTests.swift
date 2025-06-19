import CustomDump
import Testing
@testable import GnustoEngine

@Suite("TellActionHandler Tests")
struct TellActionHandlerTests {
    let handler = TellActionHandler()

    @Test("Tell requires direct object")
    func testTellRequiresDirectObject() async throws {
        // Given
        let game = MinimalGame()
        let mockIO = await MockIOHandler()
        let engine = await GameEngine.test(
            blueprint: game,
            parser: MockParser(),
            ioHandler: mockIO
        )

        let command = Command(verb: .tell, rawInput: "tell")
        let context = ActionContext(command: command, engine: engine)

        // When/Then
        await #expect(throws: ActionResponse.prerequisiteNotMet("Tell whom?")) {
            try await handler.validate(context: context)
        }
    }

    @Test("Tell requires indirect object")
    func testTellRequiresIndirectObject() async throws {
        // Given
        let character = Item(
            id: "wizard",
            .name("old wizard"),
            .isCharacter
        )
        let game = MinimalGame(items: [character])
        let mockIO = await MockIOHandler()
        let engine = await GameEngine.test(
            blueprint: game,
            parser: MockParser(),
            ioHandler: mockIO
        )

        let command = Command(
            verb: .tell,
            directObject: .item("wizard"),
            rawInput: "tell wizard"
        )
        let context = ActionContext(command: command, engine: engine)

        // When/Then
        await #expect(throws: ActionResponse.prerequisiteNotMet("Tell about what?")) {
            try await handler.validate(context: context)
        }
    }

    @Test("Tell requires character as direct object")
    func testTellRequiresCharacter() async throws {
        // Given
        let rock = Item(id: "rock", .name("rock"))
        let game = MinimalGame(items: [rock])
        let mockIO = await MockIOHandler()
        let engine = await GameEngine.test(
            blueprint: game,
            parser: MockParser(),
            ioHandler: mockIO
        )

        let command = Command(
            verb: .tell,
            directObject: .item("rock"),
            indirectObject: .item("rock"),
            rawInput: "tell rock about rock"
        )
        let context = ActionContext(command: command, engine: engine)

        // When/Then
        await #expect(throws: ActionResponse.prerequisiteNotMet("You can't tell the rock about anything.")) {
            try await handler.validate(context: context)
        }
    }

    @Test("Tell character about item")
    func testTellCharacterAboutItem() async throws {
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
        let engine = await GameEngine.test(
            blueprint: game,
            parser: MockParser(),
            ioHandler: mockIO
        )

        let command = Command(
            verb: .tell,
            directObject: .item("wizard"),
            indirectObject: .item("crystal"),
            rawInput: "tell wizard about crystal"
        )
        let context = ActionContext(command: command, engine: engine)

        // When
        try await handler.validate(context: context)
        let result = try await handler.process(context: context)

        // Then
        #expect(result.message == "Old wizard listens politely to what you say about magic crystal.")
        #expect(result.changes.count == 2) // touched flag + pronoun update
    }

    @Test("Tell character about player")
    func testTellCharacterAboutPlayer() async throws {
        // Given
        let wizard = Item(
            id: "wizard",
            .name("old wizard"),
            .in(.location(.startRoom)),
            .isCharacter
        )
        let game = MinimalGame(items: [wizard])
        let mockIO = await MockIOHandler()
        let engine = await GameEngine.test(
            blueprint: game,
            parser: MockParser(),
            ioHandler: mockIO
        )

        let command = Command(
            verb: .tell,
            directObject: .item("wizard"),
            indirectObject: .player,
            rawInput: "tell wizard about me"
        )
        let context = ActionContext(command: command, engine: engine)

        // When
        try await handler.validate(context: context)
        let result = try await handler.process(context: context)

        // Then
        #expect(result.message == "Old wizard listens politely to what you say about yourself.")
    }

    @Test("Tell character about location")
    func testTellCharacterAboutLocation() async throws {
        // Given
        let wizard = Item(
            id: "wizard",
            .name("old wizard"),
            .in(.location(.startRoom)),
            .isCharacter
        )
        let game = MinimalGame(items: [wizard])
        let mockIO = await MockIOHandler()
        let engine = await GameEngine.test(
            blueprint: game,
            parser: MockParser(),
            ioHandler: mockIO
        )

        let command = Command(
            verb: .tell,
            directObject: .item("wizard"),
            indirectObject: .location(.startRoom),
            rawInput: "tell wizard about room"
        )
        let context = ActionContext(command: command, engine: engine)

        // When
        try await handler.validate(context: context)
        let result = try await handler.process(context: context)

        // Then
        #expect(result.message == "Old wizard listens politely to what you say about Void.")
    }

    @Test("Tell inaccessible character fails")
    func testTellInaccessibleCharacterFails() async throws {
        // Given
        let wizard = Item(
            id: "wizard",
            .name("old wizard"),
            .in(.nowhere),
            .isCharacter
        )
        let game = MinimalGame(items: [wizard])
        let mockIO = await MockIOHandler()
        let engine = await GameEngine.test(
            blueprint: game,
            parser: MockParser(),
            ioHandler: mockIO
        )

        let command = Command(
            verb: .tell,
            directObject: .item("wizard"),
            indirectObject: .item("wizard"),
            rawInput: "tell wizard about wizard"
        )
        let context = ActionContext(command: command, engine: engine)

        // When/Then
        await #expect(throws: ActionResponse.itemNotAccessible("wizard")) {
            try await handler.validate(context: context)
        }
    }
}
