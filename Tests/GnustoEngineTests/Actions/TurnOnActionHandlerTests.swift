import Testing
import CustomDump // For diffing complex types
@testable import GnustoEngine

@MainActor
@Suite("TurnOnActionHandler Tests")
struct TurnOnActionHandlerTests {
    let handler = TurnOnActionHandler()

    @Test("Successfully turn on a light source in inventory")
    func testTurnOnLightSourceInInventory() async throws {
        // Arrange
        let lamp = Item(
            id: "lamp",
            name: "brass lantern",
            description: "A brass lantern.",
            properties: .device, .lightSource, .takable,
            parent: .player
        )
        let game = MinimalGame(items: [lamp])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        let command = Command(verbID: "turn on", directObject: "lamp", rawInput: "turn on lamp")

        // Act
        try await handler.perform(command: command, engine: engine)

        // Assert
        let finalItemState = engine.itemSnapshot(with: "lamp")
        #expect(finalItemState?.hasProperty(.on) == true)
        #expect(finalItemState?.hasProperty(.touched) == true)

        let output = await mockIO.flush()
        expectNoDifference(output, "The brass lantern is now on.")
    }

    @Test("Turn on light source in dark location (causes room description)")
    func testTurnOnLightSourceInDarkLocation() async throws {
        // Arrange
        let darkRoom = Location(
            id: "darkRoom",
            name: "Dark Room",
            description: "This is a dark room that should now be lit."
        ) // Not inherently lit
        let lamp = Item(
            id: "lamp",
            name: "brass lantern",
            description: "A brass lantern.",
            properties: .device, .lightSource, .takable,
            parent: .location(darkRoom.id)
        )
        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: [darkRoom],
            items: [lamp]
        )
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        // Verify room is dark initially
        let initiallyLit = engine.scopeResolver.isLocationLit(locationID: "darkRoom")
        #expect(initiallyLit == false)

        let command = Command(verbID: "turn on", directObject: "lamp", rawInput: "turn on lamp")

        // Act
        try await handler.perform(command: command, engine: engine)

        // Assert
        let finalItemState = engine.itemSnapshot(with: "lamp")
        #expect(finalItemState?.hasProperty(.on) == true)
        #expect(finalItemState?.hasProperty(.touched) == true)

        let output = await mockIO.flush()
        // Expect turn on message *followed by* the room description
        let expectedOutput = """
            The brass lantern is now on.
            --- Dark Room ---
            This is a dark room that should now be lit.
            You can see:
              A brass lantern
            """
        expectNoDifference(output, expectedOutput)
    }

    @Test("Try to turn on item already on")
    func testTurnOnItemAlreadyOn() async throws {
        // Arrange
        let lamp = Item(
            id: "lamp",
            name: "brass lantern",
            description: "A brass lantern.",
            properties: .device, .lightSource, .takable, .on,
            parent: .player
        )
        let game = MinimalGame(items: [lamp])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        let command = Command(verbID: "turn on", directObject: "lamp", rawInput: "turn on lamp")

        // Act
        try await handler.perform(command: command, engine: engine)

        // Assert
        let finalItemState = engine.itemSnapshot(with: "lamp")
        #expect(finalItemState?.hasProperty(.on) == true) // Should still be on
        #expect(finalItemState?.hasProperty(.touched) == true) // Should still be touched

        let output = await mockIO.flush()
        expectNoDifference(output, "It's already on.")
    }

    @Test("Try to turn on non-device item")
    func testTurnOnNonDeviceItem() async throws {
        // Arrange
        let lamp = Item(
            id: "lamp",
            name: "brass lantern",
            description: "A brass lantern.",
            properties: .takable,
            parent: .player
        )
        let game = MinimalGame(items: [lamp])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        let command = Command(verbID: "turn on", directObject: "lamp", rawInput: "turn on lamp")

        // Act & Assert
        await #expect(throws: ActionError.prerequisiteNotMet("You can't turn that on.")) {
            try await handler.perform(command: command, engine: engine)
        }

        let finalItemState = engine.itemSnapshot(with: "lamp")
        #expect(finalItemState?.hasProperty(.on) == false) // Should not gain .on
        #expect(finalItemState?.hasProperty(.touched) == true) // Should be touched

        let output = await mockIO.flush()
        #expect(output.isEmpty)
    }

    @Test("Try to turn on item that is not reachable (in closed container)")
    func testTurnOnItemInClosedContainer() async throws {
        // Arrange
        let container = Item(
            id: "box",
            name: "wooden box",
            properties: .container, .openable, .takable, // Starts closed
            parent: .player
        )
        let lamp = Item(
            id: "lamp",
            name: "brass lantern",
            description: "A brass lantern.",
            properties: .device, .lightSource, .takable,
            parent: .item("box")
        )
        let game = MinimalGame(items: [container, lamp])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        let command = Command(verbID: "turn on", directObject: "lamp", rawInput: "turn on lamp")

        // Act & Assert
        await #expect(throws: ActionError.itemNotAccessible("lamp")) {
            try await handler.perform(command: command, engine: engine)
        }

        let finalItemState = engine.itemSnapshot(with: "lamp")
        #expect(finalItemState?.hasProperty(.on) == false)
        #expect(finalItemState?.hasProperty(.touched) == false) // Should not be touched if not accessible

        let output = await mockIO.flush()
        #expect(output.isEmpty)
    }

    @Test("Turn on non-light source device (no room description)")
    func testTurnOnNonLightSourceDevice() async throws {
        // Arrange
        let darkRoom = Location(
            id: "darkRoom",
            name: "Dark Room",
            description: "A dark room."
        )
        let lamp = Item(
            id: "lamp",
            name: "brass lantern",
            description: "A brass lantern.",
            properties: .device, .takable,
            parent: .player
        )
        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: [darkRoom],
            items: [lamp]
        )
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        let command = Command(verbID: "turn on", directObject: "lamp", rawInput: "turn on lamp")

        // Act
        try await handler.perform(command: command, engine: engine)

        // Assert
        let finalItemState = engine.itemSnapshot(with: "lamp")
        #expect(finalItemState?.hasProperty(.on) == true)
        #expect(finalItemState?.hasProperty(.touched) == true)

        let output = await mockIO.flush()
        // Only expect the turn on message, no room description
        expectNoDifference(output, "The brass lantern is now on.")

        // Verify room is still dark
        let finallyLit = engine.scopeResolver.isLocationLit(locationID: "darkRoom")
        #expect(finallyLit == false)
    }

    @Test("Command without direct object")
    func testTurnOnWithoutDirectObject() async throws {
        // Arrange
        let game = MinimalGame()
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        // Command missing directObject
        let command = Command(verbID: "turn on", rawInput: "turn on")

        // Act
        try await handler.perform(command: command, engine: engine)

        // Assert
        let output = await mockIO.flush()
        expectNoDifference(output, "Turn on what?")
    }
}
