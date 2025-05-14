import CustomDump
import Testing

@testable import GnustoEngine

@Suite("ReadActionHandler Tests")
struct ReadActionHandlerTests {
    @Test("Read item successfully (held)")
    func testReadItemSuccessfullyHeld() async throws {
        // Arrange
        let book = Item(
            id: "book",
            .name("dusty book"),
            .in(.player),
            .readText("It reads: \"Beware the Grue!\""),
            .isTakable,
            .isReadable
        )

        let game = MinimalGame(items: [book])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        let command = Command(
            verbID: .read,
            directObject: .item(ItemID("book")),
            rawInput: "read book"
        )

        // Act
        await engine.execute(command: command)

        // Assert
        let finalItemState = try await engine.item("book")
        #expect(finalItemState.hasFlag(.isTouched) == true)
        let output = await mockIO.flush()
        expectNoDifference(output, "It reads: \"Beware the Grue!\"")
    }

    @Test("Read item successfully (in lit room)")
    func testReadItemSuccessfullyInLitRoom() async throws {
        // Arrange
        let sign = Item(
            id: "sign",
            .name("warning sign"),
            .in(.location("litRoom")),
            .readText("DANGER AHEAD"),
            .isReadable
        )
        let litRoom = Location(
            id: "litRoom",
            .name("Bright Room"),
            .description("It's bright here."),
            .inherentlyLit
        )

        let game = MinimalGame(
            player: Player(in: "litRoom"),
            locations: [litRoom],
            items: [sign]
        )
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        let command = Command(
            verbID: .read,
            directObject: .item(ItemID("sign")),
            rawInput: "read sign"
        )

        // Act
        await engine.execute(command: command)

        // Assert
        let finalItemState = try await engine.item("sign")
        #expect(finalItemState.hasFlag(.isTouched) == true)
        let output = await mockIO.flush()
        expectNoDifference(output, "DANGER AHEAD")
    }

    @Test("Read fails with no direct object")
    func testReadFailsWithNoObject() async throws {
        // Arrange
        let game = MinimalGame()
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        let handler = ReadActionHandler()
        let command = Command(
            verbID: .read,
            rawInput: "read"
        )

        // Act & Assert
        await #expect(throws: ActionResponse.custom("Read what?")) {
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
            .name("ancient scroll"),
            .in(.nowhere),
            .readText("Secrets within"),
            .isReadable
        )

        let game = MinimalGame(items: [scroll])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        let handler = ReadActionHandler()
        let command = Command(
            verbID: .read,
            directObject: .item(ItemID("scroll")),
            rawInput: "read scroll"
        )

        // Act & Assert
        await #expect(throws: ActionResponse.itemNotAccessible("scroll")) {
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
            .name("plain rock"),
            .in(.location(.startRoom))
        )

        let game = MinimalGame(items: [rock])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        let handler = ReadActionHandler()
        let command = Command(
            verbID: .read,
            directObject: .item(ItemID("rock")),
            rawInput: "read rock"
        )

        // Act & Assert
        await #expect(throws: ActionResponse.itemNotReadable("rock")) {
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
            .name("folded map"),
            .in(.location("darkRoom")),
            .readText("X marks the spot"),
            .isTakable,
            .isReadable
        )
        let darkRoom = Location(
            id: "darkRoom",
            .name("Pitch Black Room"),
            .description("It's dark.")
        )

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: [darkRoom],
            items: [map]
        )
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        let handler = ReadActionHandler()
        let command = Command(
            verbID: .read,
            directObject: .item(ItemID("map")),
            rawInput: "read map"
        )

        // Act & Assert
        await #expect(
            throws: ActionResponse.roomIsDark
        ) {
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
            .name("blank paper"),
            .in(.player),
            .readText(""),
            .isTakable,
            .isReadable
        )

        let game = MinimalGame(items: [blankPaper])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        let command = Command(
            verbID: .read,
            directObject: .item(ItemID("paper")),
            rawInput: "read paper"
        )

        // Act
        await engine.execute(command: command)

        // Assert
        let finalItemState = try await engine.item("paper")
        #expect(finalItemState.hasFlag(.isTouched) == true)
        let output = await mockIO.flush()
        expectNoDifference(output, "There's nothing written on the blank paper.")
    }

    @Test("Read lit item successfully in dark room")
    func testReadLitItemInDarkRoom() async throws {
        // Arrange
        let glowingTablet = Item(
            id: "tablet",
            .name("glowing tablet"),
            .in(.location("darkRoom")),
            .isLightSource,
            .isOn,
            .isReadable,
            .readText("Ancient Runes"),
        )
        let darkRoom = Location(
            id: "darkRoom",
            .name("Pitch Black Room"),
            .description("It's dark.")
        )

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: [darkRoom],
            items: [glowingTablet]
        )
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        let command = Command(
            verbID: .read,
            directObject: .item(ItemID("tablet")),
            rawInput: "read tablet"
        )

        // Act
        await engine.execute(command: command)

        // Assert
        let finalItemState = try await engine.item("tablet")
        #expect(finalItemState.hasFlag(.isTouched) == true)
        let output = await mockIO.flush()
        expectNoDifference(output, "Ancient Runes")
    }

    @Test("Read simple item marks touched")
    func testReadSimpleItem() async throws {
        // Arrange
        let scroll = Item(
            id: "scroll",
            .name("ancient scroll"),
            .in(.location(.startRoom)),
            .readText("Beware the Grue!"),
            .isReadable
        )

        let game = MinimalGame(items: [scroll])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        #expect(try await engine.item("scroll").hasFlag(.isTouched) == false)

        let command = Command(
            verbID: .read,
            directObject: .item(ItemID("scroll")),
            rawInput: "read scroll"
        )

        // Act
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "Beware the Grue!")

        // Assert Final State
        let finalItemState = try await engine.item("scroll")
        #expect(finalItemState.hasFlag(.isTouched) == true)
    }

    @Test("Read item with empty text")
    func testReadItemEmptyText() async throws {
        // Arrange
        let note = Item(
            id: "note",
            .name("blank note"),
            .in(.location(.startRoom)),
            .readText(""),
            .isReadable
        )

        let game = MinimalGame(items: [note])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        #expect(try await engine.item("note").hasFlag(.isTouched) == false)

        let command = Command(
            verbID: .read,
            directObject: .item(ItemID("note")),
            rawInput: "read note"
        )

        // Act
        await engine.execute(command: command)

        // Assert Output (Default message)
        let output = await mockIO.flush()
        expectNoDifference(output, "There's nothing written on the blank note.")

        // Assert Final State
        let finalItemState = try await engine.item("note")
        #expect(finalItemState.hasFlag(.isTouched) == true)
    }

    @Test("Read item with nil text")
    func testReadItemNilText() async throws {
        // Arrange
        let tablet = Item(
            id: "tablet",
            .name("stone tablet"),
            .in(.location(.startRoom)),
            .isReadable
        )

        let game = MinimalGame(items: [tablet])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        #expect(try await engine.item("tablet").hasFlag(.isTouched) == false)

        let command = Command(
            verbID: .read,
            directObject: .item(ItemID("tablet")),
            rawInput: "read tablet"
        )

        // Act
        await engine.execute(command: command)

        // Assert Output (Default message)
        let output = await mockIO.flush()
        expectNoDifference(output, "There's nothing written on the stone tablet.")

        // Assert Final State
        let finalItemState = try await engine.item("tablet")
        #expect(finalItemState.hasFlag(.isTouched) == true)
    }

    @Test("Read item not accessible")
    func testReadItemNotAccessible() async throws {
        // Arrange
        let book = Item(
            id: "book",
            .name("ancient book"),
            .in(.nowhere),
            .readText("Secrets within."),
            .isReadable
        )
        let game = MinimalGame(items: [book])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        let command = Command(
            verbID: .read,
            directObject: .item(ItemID("book")),
            rawInput: "read book"
        )

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
            .name("plain rock"),
            .in(.location(.startRoom))
        )
        let game = MinimalGame(items: [rock])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        let command = Command(
            verbID: .read,
            directObject: .item(ItemID("rock")),
            rawInput: "read rock"
        )

        // Act
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "The plain rock isn't something you can read.")
    }

    @Test("Read item in dark room")
    func testReadInDarkRoom() async throws {
        // Arrange
        let darkRoom = Location(
            id: "darkRoom",
            .name("Dark Room"),
            .description("A dark, dark room.")
        )
        let scroll = Item(
            id: "scroll",
            .name("ancient scroll"),
            .in(.location(darkRoom.id)),
            .readText("Can't read this."),
            .isReadable
        )
        let game = MinimalGame(player: Player(in: darkRoom.id), locations: [darkRoom], items: [scroll])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        let command = Command(
            verbID: .read,
            directObject: .item(ItemID("scroll")),
            rawInput: "read scroll"
        )

        // Act
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "It's too dark to do that.")
    }

    @Test("Read item providing light in dark room")
    func testReadSelfLitItemInDark() async throws {
        // Arrange
        let darkRoom = Location(
            id: "darkRoom",
            .name("Dark Room"),
            .description("A dark, dark room.")
        )
        let glowingTablet = Item(
            id: "tablet",
            .name("glowing tablet"),
            .in(.location(darkRoom.id)),
            .readText("Luminous secrets!"),
            .isReadable,
            .isLightSource,
            .isOn
        )

        let game = MinimalGame(player: Player(in: darkRoom.id), locations: [darkRoom], items: [glowingTablet])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        #expect(try await engine.item("tablet").hasFlag(.isTouched) == false)

        let command = Command(
            verbID: .read,
            directObject: .item(ItemID("tablet")),
            rawInput: "read tablet"
        )

        // Act
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "Luminous secrets!")

        // Assert Final State
        let finalItemState = try await engine.item("tablet")
        #expect(finalItemState.hasFlag(.isTouched) == true)
    }

    @Test("Read item requires direct object")
    func testReadRequiresDirectObject() async throws {
        // Arrange
        let game = MinimalGame()
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        let command = Command(
            verbID: .read,
            rawInput: "read"
        )

        // Act
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "Read what?")
    }

    @Test("Read item inside held container")
    func testReadItemInsideHeldContainer() async throws {
        // Arrange
        let box = Item(
            id: "box",
            .name("wooden box"),
            .in(.player),
            .isTakable,
            .isContainer,
            .isOpen
        )
        let note = Item(
            id: "note",
            .name("folded note"),
            .in(.item("box")),
            .readText("Meet at midnight."),
            .isReadable
        )

        let game = MinimalGame(items: [box, note])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        let command = Command(
            verbID: .read,
            directObject: .item(ItemID("note")),
            rawInput: "read note"
        )

        // Act
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "Meet at midnight.")

        // Assert Final State
        let finalItemState = try await engine.item("note")
        #expect(finalItemState.hasFlag(.isTouched) == true)
    }

    @Test("Read item inside container in room")
    func testReadItemInsideContainerInRoom() async throws {
        // Arrange
        let chest = Item(
            id: "chest",
            .name("iron chest"),
            .in(.location(.startRoom)),
            .isContainer,
            .isOpen
        )
        let letter = Item(
            id: "letter",
            .name("sealed letter"),
            .in(.item("chest")),
            .readText("Important news."),
            .isReadable
        )

        let game = MinimalGame(items: [chest, letter])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        let command = Command(
            verbID: .read,
            directObject: .item(ItemID("letter")),
            rawInput: "read letter"
        )

        // Act
        await engine.execute(command: command)

        // Assert Output
        let output = await mockIO.flush()
        expectNoDifference(output, "Important news.")

        // Assert Final State
        let finalItemState = try await engine.item("letter")
        #expect(finalItemState.hasFlag(.isTouched) == true)
    }

    @Test("Read fails item inside closed container")
    func testReadFailsItemInsideClosedContainer() async throws {
        // Arrange
        let lockedBox = Item(
            id: "lockedBox",
            .name("locked box"),
            .in(.location(.startRoom)),
            .isContainer,
            .isLockable
        )
        let secret = Item(
            id: "secret",
            .name("secret paper"),
            .in(.item("lockedBox")),
            .readText("Top Secret!"),
            .isReadable
        )

        let game = MinimalGame(items: [lockedBox, secret])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        let command = Command(
            verbID: .read,
            directObject: .item(ItemID("secret")),
            rawInput: "read secret"
        )

        // Act & Assert
        await engine.execute(command: command)
        let output = await mockIO.flush()
        expectNoDifference(output, "You can't see any such thing.")

        // Also assert the item wasn't touched
        let finalSecretState = try await engine.item("secret")
        #expect(finalSecretState.hasFlag(.isTouched) == false)
    }
}
