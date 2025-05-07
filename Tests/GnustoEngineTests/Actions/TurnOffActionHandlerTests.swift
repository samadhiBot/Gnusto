import Testing
import CustomDump
@testable import GnustoEngine

@Suite("TurnOffActionHandler Tests")
struct TurnOffActionHandlerTests {
    let handler = TurnOffActionHandler()

    @Test("TURN OFF turns off a light source in a dark room makes everything dark")
    func testTurnOffLightSource() async throws {
        let room = Location(
            id: "room",
            name: "Test Room",
            description: "You are here."
        )
        let lamp = Item(
            id: "lamp",
            name: "lamp",
            parent: .player,
            attributes: [.isLightSource: true, .isDevice: true, .isOn: true]
        )

        let game = MinimalGame(
            player: Player(in: "room"),
            locations: [room],
            items: [lamp]
        )
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        let command = Command(verbID: "turn off", directObject: "lamp", rawInput: "turn off lamp")

        await engine.execute(command: command)

        let output = await mockIO.flush()
        expectNoDifference(output, """
            The lamp is now off.
            It is now pitch black. You are likely to be eaten by a grue.
            """)
        let finalItemState = await engine.item("lamp")
        #expect(finalItemState?.hasFlag(.isOn) == false)
        #expect(finalItemState?.hasFlag(.isTouched) == true)
    }

    @Test("TURN OFF fails for non-light source")
    func testTurnOffNonLightSource() async throws {
        let room = Location(
            id: "room",
            name: "Test Room",
            description: "You are here.",
            isLit: true
        )
        let book = Item(
            id: "book",
            name: "book",
            parent: .location(room.id)
        )

        let game = MinimalGame(
            player: Player(in: "room"),
            locations: [room],
            items: [book]
        )
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        let command = Command(verbID: "turn off", directObject: "book", rawInput: "turn off book")

        await #expect(throws: ActionError.prerequisiteNotMet("You can't turn that off.")) {
            try await handler.validate(
                context: ActionContext(
                    command: command,
                    engine: engine,
                    stateSnapshot: engine.gameState
                )
            )
        }
    }

    @Test("TURN OFF fails for non-existent item")
    func testTurnOffNonExistentItem() async throws {
        let room = Location(
            id: "room",
            name: "Test Room",
            description: "You are here."
        )

        let game = MinimalGame(
            player: Player(in: "room"),
            locations: [room]
        )
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        let command = Command(verbID: "turn off", directObject: "lamp", rawInput: "turn off lamp")

        // Expect internalEngineError when item ID doesn't exist in gameState
        await #expect(throws: ActionError.internalEngineError("Parser resolved non-existent item ID 'lamp'.")) {
            try await handler.validate(
                context: ActionContext(
                    command: command,
                    engine: engine,
                    stateSnapshot: engine.gameState
                )
            )
        }
    }

    @Test("Successfully turn off a light source in inventory")
    func testTurnOffLightSourceInInventory() async throws {
        let lamp = Item(
            id: "lamp",
            name: "brass lantern",
            description: "A brass lantern.",
            parent: .player,
            attributes: [
                .isDevice: true,
                .isLightSource: true,
                .isTakable: true,
                .isOn: true,
                .size: 10
            ]
        )
        let game = MinimalGame(items: [lamp])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        let command = Command(verbID: "turn off", directObject: "lamp", rawInput: "turn off lamp")

        await engine.execute(command: command)

        let finalItemState = await engine.item("lamp")
        #expect(finalItemState?.hasFlag(.isOn) == false)
        #expect(finalItemState?.hasFlag(.isTouched) == true)

        let output = await mockIO.flush()
        expectNoDifference(output, "The brass lantern is now off.")
    }

    @Test("Turn off light source making a room pitch black")
    func testTurnOffLightSourceCausesDarkness() async throws {
        let darkRoom = Location(
            id: "darkRoom",
            name: "Dark Room",
            description: "This room will become dark."
        )
        let lamp = Item(
            id: "lamp",
            name: "brass lantern",
            description: "A brass lantern.",
            parent: .location(darkRoom.id),
            attributes: [.isDevice: true, .isLightSource: true, .isTakable: true, .isOn: true, .size: .int(10)]
        )
        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: [darkRoom],
            items: [lamp]
        )
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        let initiallyLit = await engine.scopeResolver.isLocationLit(locationID: darkRoom.id)
        #expect(initiallyLit == true)

        let command = Command(verbID: "turn off", directObject: "lamp", rawInput: "turn off lamp")

        await engine.execute(command: command)

        let finalItemState = await engine.item("lamp")
        #expect(finalItemState?.hasFlag(.isOn) == false)
        #expect(finalItemState?.hasFlag(.isTouched) == true)

        let output = await mockIO.flush()
        let expectedOutput = """
            The brass lantern is now off.
            It is now pitch black. You are likely to be eaten by a grue.
            """
        expectNoDifference(output, expectedOutput)

        let finallyLit = await engine.scopeResolver.isLocationLit(locationID: darkRoom.id)
        #expect(finallyLit == false)
    }

    @Test("Try to turn off item already off")
    func testTurnOffItemAlreadyOff() async throws {
        let lamp = Item(
            id: "lamp",
            name: "brass lantern",
            description: "A brass lantern.",
            parent: .player,
            attributes: [.isDevice: true, .isLightSource: true, .isTakable: true, .size: .int(10)]
        )
        let game = MinimalGame(items: [lamp])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        let command = Command(verbID: "turn off", directObject: "lamp", rawInput: "turn off lamp")

        // Act & Assert: Expect error during validation
        await #expect(throws: ActionError.customResponse("It's already off.")) {
             try await handler.validate(
                context: ActionContext(
                    command: command,
                    engine: engine,
                    stateSnapshot: engine.gameState
                )
            )
        }

        // Check state remains unchanged - touched should NOT be added if validation fails
        let finalItemState = await engine.item("lamp")
        #expect(finalItemState?.hasFlag(.isOn) == false)
        #expect(finalItemState?.hasFlag(.isTouched) == false)
    }

    @Test("Try to turn off non-device item")
    func testTurnOffNonDeviceItem() async throws {
        let lamp = Item(
            id: "lamp",
            name: "brass lantern",
            description: "A brass lantern.",
            parent: .player,
            attributes: [.isTakable: true, .isOn: true, .size: .int(10)]
        )
        let game = MinimalGame(items: [lamp])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        let command = Command(verbID: "turn off", directObject: "lamp", rawInput: "turn off lamp")

        // Act & Assert: Expect error during validation
        await #expect(throws: ActionError.prerequisiteNotMet("You can't turn that off.")) {
             try await handler.validate(
                context: ActionContext(
                    command: command,
                    engine: engine,
                    stateSnapshot: engine.gameState
                )
            )
        }
        // Check state remains unchanged - touched should NOT be added if validation fails
        let finalItemState = await engine.item("lamp")
        #expect(finalItemState?.hasFlag(.isOn) == true)
        #expect(finalItemState?.hasFlag(.isTouched) == false)
    }

    @Test("Try to turn off item not accessible")
    func testTurnOffItemNotAccessible() async throws {
        let lamp = Item(
            id: "lamp",
            name: "brass lantern",
            description: "A brass lantern.",
            parent: .nowhere,
            attributes: [.isDevice: true, .isLightSource: true, .isTakable: true, .isOn: true, .size: .int(10)]
        )
        let game = MinimalGame(items: [lamp])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )
        let command = Command(verbID: "turn off", directObject: "lamp", rawInput: "turn off lamp")

        // Act: Execute the command
        await engine.execute(command: command)

        // Assert: Check IOHandler output for the expected error message
        let output = await mockIO.flush()
        // The specific error message comes from GameEngine.report(actionError:)
        expectNoDifference(output, "You can't see any such thing.")
    }

    @Test("Extinguish alias works correctly")
    func testExtinguishAlias() async throws {
        // Arrange
        let lamp = Item(
            id: "lamp",
            name: "brass lantern",
            parent: .location("darkRoom"),
            attributes: [.isDevice: true, .isLightSource: true, .isTakable: true, .isOn: true]
        )
        let darkRoom = Location(
            id: "darkRoom",
            name: "Pitch Black Room",
            description: "It's dark."
        )
        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: [darkRoom],
            items: [lamp]
        )
        let mockIO = await MockIOHandler()
        // Use the real parser to test alias resolution
        let parser = StandardParser()
        let engine = await GameEngine(
            game: game,
            parser: parser, // Use StandardParser
            ioHandler: mockIO
        )

        // Act
        // Parse the raw input first
        let parseResult = await parser.parse(input: "extinguish lamp", vocabulary: await engine.gameState.vocabulary, gameState: await engine.gameState)
        let command = try parseResult.get() // Get the parsed command

        // Execute the parsed command
        await engine.execute(command: command)

        // Assert
        let finalItemState = await engine.item("lamp")
        #expect(finalItemState?.hasFlag(.isOn) == false)
        #expect(finalItemState?.hasFlag(.isTouched) == true)

        let output = await mockIO.flush()
        let expectedOutput = """
            The brass lantern is now off.
            It is now pitch black. You are likely to be eaten by a grue.
            """
        expectNoDifference(output, expectedOutput)
    }

    @Test("Blow Out alias works correctly")
    func testBlowOutAlias() async throws {
        // Arrange
        let lamp = Item(
            id: "lamp",
            name: "brass lantern",
            parent: .location("darkRoom"),
            attributes: [.isDevice: true, .isLightSource: true, .isTakable: true, .isOn: true]
        )
        let darkRoom = Location(
            id: "darkRoom",
            name: "Pitch Black Room",
            description: "It's dark."
        )
        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: [darkRoom],
            items: [lamp]
        )
        let mockIO = await MockIOHandler()
        // Use the real parser to test alias resolution
        let parser = StandardParser()
        let engine = await GameEngine(
            game: game,
            parser: parser, // Use StandardParser
            ioHandler: mockIO
        )

        // Act
        // Parse the raw input first
        let parseResult = await parser.parse(input: "blow out lamp", vocabulary: await engine.gameState.vocabulary, gameState: await engine.gameState)
        let command = try parseResult.get() // Get the parsed command

        // Execute the parsed command
        await engine.execute(command: command)

        // Assert
        let finalItemState = await engine.item("lamp")
        #expect(finalItemState?.hasFlag(.isOn) == false)
        #expect(finalItemState?.hasFlag(.isTouched) == true)

        let output = await mockIO.flush()
        let expectedOutput = """
            The brass lantern is now off.
            It is now pitch black. You are likely to be eaten by a grue.
            """
        expectNoDifference(output, expectedOutput)
    }
}
