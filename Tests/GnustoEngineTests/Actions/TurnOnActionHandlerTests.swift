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
            longDescription: "A brass lantern.",
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
            longDescription: "This is a dark room that should now be lit."
        )
        let lamp = Item(
            id: "lamp",
            name: "brass lantern",
            longDescription: "A brass lantern.",
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
            longDescription: "A brass lantern.",
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

        // Act & Assert: Expect specific error
        await #expect(throws: ActionError.prerequisiteNotMet("It's already on.")) {
            try await handler.perform(command: command, engine: engine)
        }

        // Verify item state didn't change unexpectedly
        let finalItemState = engine.itemSnapshot(with: "lamp")
        #expect(finalItemState?.hasProperty(.on) == true) // Should still be on
        #expect(finalItemState?.hasProperty(.touched) == true) // Should still be touched
    }

    @Test("Try to turn on non-device item")
    func testTurnOnNonDeviceItem() async throws {
        // Arrange
        let lamp = Item(
            id: "lamp",
            name: "brass lantern",
            longDescription: "A brass lantern.",
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
    }

    @Test("Try to turn on item not accessible")
    func testTurnOnItemNotAccessible() async throws {
        // Arrange
        let lamp = Item(
            id: "lamp",
            name: "brass lantern",
            longDescription: "A brass lantern.",
            properties: .device, .lightSource, .takable,
            parent: .nowhere // Not accessible
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
        await #expect(throws: ActionError.itemNotAccessible("lamp")) {
            try await handler.perform(command: command, engine: engine)
        }
    }

    @Test("Turn on non-light source device (no room description)")
    func testTurnOnNonLightSourceDevice() async throws {
        // Arrange
        let darkRoom = Location(
            id: "darkRoom",
            name: "Dark Room",
            longDescription: "A dark room."
        )
        let radio = Item(
            id: "radio",
            name: "portable radio",
            longDescription: "A portable radio.",
            properties: .device, .takable,
            parent: .player
        )
        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: [darkRoom],
            items: [radio]
        )
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        let command = Command(verbID: "turn on", directObject: "radio", rawInput: "turn on radio")

        // Act
        try await handler.perform(command: command, engine: engine)

        // Assert
        let finalItemState = engine.itemSnapshot(with: "radio")
        #expect(finalItemState?.hasProperty(.on) == true)
        #expect(finalItemState?.hasProperty(.touched) == true)

        let output = await mockIO.flush()
        // Only expect the turn on message, no room description
        expectNoDifference(output, "The portable radio is now on.")

        // Verify room is still dark
        let finallyLit = engine.scopeResolver.isLocationLit(locationID: "darkRoom")
        #expect(finallyLit == false)
    }

    @Test("Light alias works correctly")
    func testLightAlias() async throws {
        // Arrange: Same setup as testTurnOnLightSourceInInventory
        let lamp = Item(
            id: "lamp",
            name: "brass lantern",
            longDescription: "A brass lantern.",
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

        // Use "light lamp" command
        let command = Command(verbID: "light", directObject: "lamp", rawInput: "light lamp")

        // Act
        try await handler.perform(command: command, engine: engine)

        // Assert: Same expectations
        let finalItemState = engine.itemSnapshot(with: "lamp")
        #expect(finalItemState?.hasProperty(.on) == true)
        #expect(finalItemState?.hasProperty(.touched) == true)

        let output = await mockIO.flush()
        expectNoDifference(output, "The brass lantern is now on.")
    }
}
