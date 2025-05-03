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
            properties: .takable, .readable,
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

        let command = Command(verbID: "read", directObject: "book", rawInput: "read book")

        // Act
        await engine.execute(command: command)

        // Assert
        let finalItemState = engine.item(with: "book")
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
            longDescription: "It's bright here.",
            properties: .inherentlyLit
        )

        let game = MinimalGame(
            player: Player(in: "litRoom"),
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

        let command = Command(verbID: "read", directObject: "sign", rawInput: "read sign")

        // Act
        await engine.execute(command: command)

        // Assert
        let finalItemState = engine.item(with: "sign")
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

        // Act & Assert
        await #expect(throws: ActionError.customResponse("Read what?")) {
            try await handler.validate(
                context: ActionContext(
                    command: command,
                    engine: engine,
                    stateSnapshot: engine.gameState
                )
            )
        }
        let output = await mockIO.flush()
        #expect(output.isEmpty)
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
            try await handler.validate(
                context: ActionContext(
                    command: command,
                    engine: engine,
                    stateSnapshot: engine.gameState
                )
            )
        }
    }

    @Test("Read fails item not readable")
    func testReadFailsItemNotReadable() async throws {
        // Arrange
        let rock = Item(
            id: "rock",
            name: "plain rock",
            parent: .location("startRoom")
        )

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
            try await handler.validate(
                context: ActionContext(
                    command: command,
                    engine: engine,
                    stateSnapshot: engine.gameState
                )
            )
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
            longDescription: "It's dark."
        )

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
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
            try await handler.validate(
                context: ActionContext(
                    command: command,
                    engine: engine,
                    stateSnapshot: engine.gameState
                )
            )
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
            readableText: ""
        )

        let game = MinimalGame(items: [blankPaper])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        let command = Command(verbID: "read", directObject: "paper", rawInput: "read paper")

        // Act
        await engine.execute(command: command)

        // Assert
        let finalItemState = engine.item(with: "paper")
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
            longDescription: "It's dark."
        )

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
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

        let command = Command(verbID: "read", directObject: "tablet", rawInput: "read tablet")

        // Act
        await engine.execute(command: command)

        // Assert
        let finalItemState = engine.item(with: "tablet")
        #expect(finalItemState?.hasProperty(.touched) == true)
        let output = await mockIO.flush()
        expectNoDifference(output, "Ancient Runes")
    }

    @Test("Read simple item marks touched")
    func testReadSimpleItem() async throws {
        // Arrange
        let scroll = Item(
            id: "scroll",
            name: "ancient scroll",
            readText: "Beware the Grue!",
            properties: ItemProperty.readable,
            parent: .location("startRoom")
        )
        let initialProperties = scroll.properties

        let game = MinimalGame(items: [scroll])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        #expect(engine.item(with: "scroll")?.hasProperty(ItemProperty.touched) == false)

        let command = Command(verbID: "read", directObject: "scroll", rawInput: "read scroll")

        // Act
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "Beware the Grue!")

        // Assert Final State
        let finalItemState = engine.item(with: "scroll")
        #expect(finalItemState?.hasProperty(ItemProperty.touched) == true)
    }

    @Test("Read item with empty text")
    func testReadItemEmptyText() async throws {
        // Arrange
        let note = Item(
            id: "note",
            name: "blank note",
            readText: "",
            properties: ItemProperty.readable,
            parent: .location("startRoom")
        )
        let initialProperties = note.properties

        let game = MinimalGame(items: [note])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        #expect(engine.item(with: "note")?.hasProperty(ItemProperty.touched) == false)

        let command = Command(verbID: "read", directObject: "note", rawInput: "read note")

        // Act
        await engine.execute(command: command)

        // Assert Output (Default message)
        let output = await mockIO.flush()
        expectNoDifference(output, "There's nothing written on the blank note.")

        // Assert Final State
        let finalItemState = engine.item(with: "note")
        #expect(finalItemState?.hasProperty(ItemProperty.touched) == true)
    }

    @Test("Read item with nil text")
    func testReadItemNilText() async throws {
        // Arrange
        let tablet = Item(
            id: "tablet",
            name: "stone tablet",
            properties: ItemProperty.readable,
            parent: .location("startRoom")
        )
        let initialProperties = tablet.properties

        let game = MinimalGame(items: [tablet])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        #expect(engine.item(with: "tablet")?.hasProperty(ItemProperty.touched) == false)

        let command = Command(verbID: "read", directObject: "tablet", rawInput: "read tablet")

        // Act
        await engine.execute(command: command)

        // Assert Output (Default message)
        let output = await mockIO.flush()
        expectNoDifference(output, "There's nothing written on the stone tablet.")

        // Assert Final State
        let finalItemState = engine.item(with: "tablet")
        #expect(finalItemState?.hasProperty(ItemProperty.touched) == true)
    }

    @Test("Read item not accessible")
    func testReadItemNotAccessible() async throws {
        // Arrange
        let book = Item(
            id: "book",
            name: "ancient book",
            readText: "Secrets within.",
            properties: ItemProperty.readable,
            parent: .nowhere
        )
        let game = MinimalGame(items: [book])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        let command = Command(verbID: "read", directObject: "book", rawInput: "read book")

        // Act
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "You can't see any such thing.")
    }

    @Test("Read non-readable item")
    func testReadNonReadableItem() async throws {
        // Arrange
        let rock = Item(
            id: "rock",
            name: "plain rock",
            parent: .location("startRoom")
        )
        let game = MinimalGame(items: [rock])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        let command = Command(verbID: "read", directObject: "rock", rawInput: "read rock")

        // Act
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "The plain rock isn't something you can read.")
    }

    @Test("Read item in dark room")
    func testReadInDarkRoom() async throws {
        // Arrange
        let darkRoom = Location(id: "darkRoom", name: "Dark Room")
        let scroll = Item(
            id: "scroll",
            name: "ancient scroll",
            readText: "Can't read this.",
            properties: ItemProperty.readable,
            parent: .location(darkRoom.id)
        )
        let game = MinimalGame(player: Player(in: darkRoom.id), locations: [darkRoom], items: [scroll])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        let command = Command(verbID: "read", directObject: "scroll", rawInput: "read scroll")

        // Act
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "It's too dark to do that.")
    }

    @Test("Read item providing light in dark room")
    func testReadSelfLitItemInDark() async throws {
        // Arrange
        let darkRoom = Location(id: "darkRoom", name: "Dark Room")
        let glowingTablet = Item(
            id: "tablet",
            name: "glowing tablet",
            readText: "Luminous secrets!",
            properties: ItemProperty.readable, ItemProperty.lightSource, ItemProperty.on,
            parent: .location(darkRoom.id)
        )
        let initialProperties = glowingTablet.properties

        let game = MinimalGame(player: Player(in: darkRoom.id), locations: [darkRoom], items: [glowingTablet])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
         #expect(engine.item(with: "tablet")?.hasProperty(ItemProperty.touched) == false)

        let command = Command(verbID: "read", directObject: "tablet", rawInput: "read tablet")

        // Act
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "Luminous secrets!")

        // Assert Final State
        let finalItemState = engine.item(with: "tablet")
        #expect(finalItemState?.hasProperty(ItemProperty.touched) == true)
    }

    @Test("Read item requires direct object")
    func testReadRequiresDirectObject() async throws {
        // Arrange
        let game = MinimalGame()
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        let command = Command(verbID: "read", rawInput: "read")

        // Act
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "Read what?")
    }
}
