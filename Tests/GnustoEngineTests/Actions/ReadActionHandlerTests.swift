import CustomDump
import Testing

@testable import GnustoEngine

@MainActor
@Suite("ReadActionHandler Tests")
struct ReadActionHandlerTests {
    @Test("Read item successfully (held)")
    func testReadItemSuccessfullyHeld() async throws {
        // Arrange
        let book = Item(
            id: "book",
            name: "dusty book",
            properties: .takable,
            .readable,
            parent: .player,
            readableText: "It reads: \"Beware the Grue!\""
        )

        let game = MinimalGame(items: [book])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        let handler = ReadActionHandler()
        let command = Command(verbID: "read", directObject: "book", rawInput: "read book")

        // Act
        try await handler.perform(command: command, engine: engine)

        // Assert
        let finalItemState = engine.itemSnapshot(with: "book")
        #expect(finalItemState?.hasProperty(.touched) == true)
        let output = await mockIO.flush()
        expectNoDifference(output, "It reads: \"Beware the Grue!\"")
    }

    @Test("Read item successfully (in lit room)")
    func testReadItemSuccessfullyInLitRoom() async throws {
        // Arrange
        let sign = Item(
            id: "sign",
            name: "warning sign",
            properties: .readable,
            parent: .location("litRoom"),
            readableText: "DANGER AHEAD"
        )
        let litRoom = Location(
            id: "litRoom",
            name: "Bright Room",
            description: "It's bright here.",
            properties: .inherentlyLit
        )

        let game = MinimalGame(
            locations: [litRoom],
            items: [sign]
        )
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        let handler = ReadActionHandler()
        let command = Command(verbID: "read", directObject: "sign", rawInput: "read sign")

        // Act
        try await handler.perform(command: command, engine: engine)

        // Assert
        let finalItemState = engine.itemSnapshot(with: "sign")
        #expect(finalItemState?.hasProperty(.touched) == true)
        let output = await mockIO.flush()
        expectNoDifference(output, "DANGER AHEAD")
    }

    @Test("Read fails with no direct object")
    func testReadFailsWithNoObject() async throws {
        // Arrange
        let game = MinimalGame()
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        let handler = ReadActionHandler()
        let command = Command(verbID: "read", rawInput: "read")

        // Act
        try await handler.perform(command: command, engine: engine)

        // Assert
        let output = await mockIO.flush()
        expectNoDifference(output, "Read what?")
    }

    @Test("Read fails item not accessible")
    func testReadFailsItemNotAccessible() async throws {
        // Arrange
        let scroll = Item(
            id: "scroll",
            name: "ancient scroll",
            properties: .readable,
            parent: .nowhere,
            readableText: "Secrets within"
        )

        let game = MinimalGame(items: [scroll])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        let handler = ReadActionHandler()
        let command = Command(verbID: "read", directObject: "scroll", rawInput: "read scroll")

        // Act & Assert
        await #expect(throws: ActionError.itemNotAccessible("scroll")) {
            try await handler.perform(command: command, engine: engine)
        }
    }

    @Test("Read fails item not readable")
    func testReadFailsItemNotReadable() async throws {
        // Arrange
        let rock = Item(
            id: "rock",
            name: "plain rock",
            parent: .location("startRoom")
        ) // No .readable

        let game = MinimalGame(items: [rock])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        let handler = ReadActionHandler()
        let command = Command(verbID: "read", directObject: "rock", rawInput: "read rock")

        // Act & Assert
        await #expect(throws: ActionError.itemNotReadable("rock")) {
            try await handler.perform(command: command, engine: engine)
        }
    }

    @Test("Read fails in dark room (item not lit)")
    func testReadFailsInDarkRoom() async throws {
        // Arrange
        let map = Item(
            id: "map",
            name: "folded map",
            properties: .takable, .readable,
            parent: .location("darkRoom"),
            readableText: "X marks the spot"
        )
        let darkRoom = Location(
            id: "darkRoom",
            name: "Pitch Black Room",
            description: "It's dark."
        ) // No .inherentlyLit

        let game = MinimalGame(
            locations: [darkRoom],
            items: [map]
        )
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        let handler = ReadActionHandler()
        let command = Command(verbID: "read", directObject: "map", rawInput: "read map")

        // Act & Assert
        await #expect(throws: ActionError.roomIsDark) {
            try await handler.perform(command: command, engine: engine)
        }
    }

     @Test("Read readable item with no text")
    func testReadReadableItemWithNoText() async throws {
        // Arrange
        let blankPaper = Item(
            id: "paper",
            name: "blank paper",
            properties: .takable, .readable,
            parent: .player,
            readableText: "" // Readable but empty string
        )

        let game = MinimalGame(items: [blankPaper])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        let handler = ReadActionHandler()
        let command = Command(verbID: "read", directObject: "paper", rawInput: "read paper")

        // Act
        try await handler.perform(command: command, engine: engine)

        // Assert
        let finalItemState = engine.itemSnapshot(with: "paper")
        #expect(finalItemState?.hasProperty(.touched) == true)
        let output = await mockIO.flush()
        expectNoDifference(output, "There's nothing written on the blank paper.")
    }

    @Test("Read lit item successfully in dark room")
    func testReadLitItemInDarkRoom() async throws {
        // Arrange
        let glowingTablet = Item(
            id: "tablet",
            name: "glowing tablet",
            properties: .lightSource, .on, .readable,
            parent: .location("darkRoom"),
            readableText: "Ancient Runes"
        )
        let darkRoom = Location(
            id: "darkRoom",
            name: "Pitch Black Room",
            description: "It's dark."
        )

        let game = MinimalGame(
            locations: [darkRoom],
            items: [glowingTablet]
        )
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        let handler = ReadActionHandler()
        let command = Command(verbID: "read", directObject: "tablet", rawInput: "read tablet")

        // Act
        try await handler.perform(command: command, engine: engine)

        // Assert
        let finalItemState = engine.itemSnapshot(with: "tablet")
        #expect(finalItemState?.hasProperty(.touched) == true)
        let output = await mockIO.flush()
        expectNoDifference(output, "Ancient Runes")
    }
}
