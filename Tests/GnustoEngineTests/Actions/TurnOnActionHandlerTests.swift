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
        let parser = StandardParser()
        let engine = GameEngine(
            game: game,
            parser: parser,
            ioHandler: mockIO
        )

        let parseResult = parser.parse(input: "turn on lamp", vocabulary: engine.gameState.vocabulary, gameState: engine.gameState)
        let command = try parseResult.get()

        // Act
        await engine.execute(command: command)

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
        let parser = StandardParser()
        let engine = GameEngine(
            game: game,
            parser: parser,
            ioHandler: mockIO
        )

        // Verify room is dark initially
        let initiallyLit = engine.scopeResolver.isLocationLit(locationID: "darkRoom")
        #expect(initiallyLit == false)

        let parseResult = parser.parse(input: "turn on lamp", vocabulary: engine.gameState.vocabulary, gameState: engine.gameState)
        let command = try parseResult.get()

        // Act
        await engine.execute(command: command)

        // Assert
        let finalItemState = engine.itemSnapshot(with: "lamp")
        #expect(finalItemState?.hasProperty(.on) == true)
        #expect(finalItemState?.hasProperty(.touched) == true)

        let output = await mockIO.flush()
        // Assert: Only expect the direct handler message
        expectNoDifference(output, "The brass lantern is now on.")

        // Assert: Verify the room is now lit
        let finallyLit = engine.scopeResolver.isLocationLit(locationID: "darkRoom")
        #expect(finallyLit == true, "Room should be lit after turning on the lamp.")
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
        let parser = StandardParser()
        let engine = GameEngine(
            game: game,
            parser: parser,
            ioHandler: mockIO
        )

        let parseResult = parser.parse(input: "turn on lamp", vocabulary: engine.gameState.vocabulary, gameState: engine.gameState)
        let command = try parseResult.get()

        // Act & Assert: Expect error during validation
        await #expect(throws: ActionError.customResponse("It's already on.")) {
            try await handler.validate(command: command, engine: engine)
        }

        // Verify item state didn't change unexpectedly - should NOT be touched if validation fails
        let finalItemState = engine.itemSnapshot(with: "lamp")
        #expect(finalItemState?.hasProperty(.on) == true) // Should still be on
        #expect(finalItemState?.hasProperty(.touched) == false) // Should NOT be touched
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
        let parser = StandardParser()
        let engine = GameEngine(
            game: game,
            parser: parser,
            ioHandler: mockIO
        )

        let parseResult = parser.parse(input: "turn on lamp", vocabulary: engine.gameState.vocabulary, gameState: engine.gameState)
        let command = try parseResult.get()

        // Act & Assert
        await #expect(throws: ActionError.prerequisiteNotMet("You can't turn that on.")) {
            try await handler.validate(command: command, engine: engine) // Changed to validate
        }

        let finalItemState = engine.itemSnapshot(with: "lamp")
        #expect(finalItemState?.hasProperty(.on) == false) // Should not gain .on
        #expect(finalItemState?.hasProperty(.touched) == false) // Should NOT be touched
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
        let parser = StandardParser()
        let engine = GameEngine(
            game: game,
            parser: parser,
            ioHandler: mockIO
        )

        // Act & Assert: Expect parser error because item is out of scope
        let expectedError = ParseError.itemNotInScope(noun: "lamp")
        #expect(throws: expectedError) {
            _ = try parser.parse(input: "turn on lamp", vocabulary: engine.gameState.vocabulary, gameState: engine.gameState).get()
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
        let parser = StandardParser()
        let engine = GameEngine(
            game: game,
            parser: parser,
            ioHandler: mockIO
        )

        let parseResult = parser.parse(input: "turn on radio", vocabulary: engine.gameState.vocabulary, gameState: engine.gameState)
        let command = try parseResult.get()

        // Act
        await engine.execute(command: command)

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
        let parser = StandardParser()
        let engine = GameEngine(
            game: game,
            parser: parser,
            ioHandler: mockIO
        )

        let parseResult = parser.parse(input: "light lamp", vocabulary: engine.gameState.vocabulary, gameState: engine.gameState)
        let command = try parseResult.get()

        // Act
        await engine.execute(command: command)

        // Assert: Same expectations
        let finalItemState = engine.itemSnapshot(with: "lamp")
        #expect(finalItemState?.hasProperty(.on) == true)
        #expect(finalItemState?.hasProperty(.touched) == true)

        let output = await mockIO.flush()
        expectNoDifference(output, "The brass lantern is now on.")
    }
}
