import Testing
import CustomDump // For diffing complex types
@testable import GnustoEngine

@Suite("TurnOnActionHandler Tests")
struct TurnOnActionHandlerTests {
    let handler = TurnOnActionHandler()

    @Test("Successfully turn on a light source in inventory")
    func testTurnOnLightSourceInInventory() async throws {
        // Arrange
        let lamp = Item(
            id: "lamp",
            name: "brass lantern",
            .description("A brass lantern."),
            .in(.player),
            .isDevice,
            .isLightSource,
            .isTakable,
        )
        let game = MinimalGame(items: [lamp])
        let mockIO = await MockIOHandler()
        let parser = StandardParser()
        let engine = await GameEngine(
            game: game,
            parser: parser,
            ioHandler: mockIO
        )

        let parseResult = parser.parse(
            input: "turn on lamp",
            vocabulary: await engine.gameState.vocabulary,
            gameState: await engine.gameState
        )
        let command = try parseResult.get()

        // Act
        await engine.execute(command: command)

        // Assert
        let finalItemState = await engine.item("lamp")
        #expect(finalItemState?.hasFlag(.isOn) == true)
        #expect(finalItemState?.hasFlag(.isTouched) == true)

        let output = await mockIO.flush()
        expectNoDifference(output, "The brass lantern is now on.")
    }

    @Test("Turn on light source in dark location (causes room description)")
    func testTurnOnLightSourceInDarkLocation() async throws {
        // Arrange
        let darkRoom = Location(
            id: "darkRoom",
            name: "Dark Room",
            .description("This is a dark room that should now be lit.")
        )
        let lamp = Item(
            id: "lamp",
            name: "brass lantern",
            .description("A brass lantern."),
            .in(.location(darkRoom.id)),
            .isDevice,
            .isLightSource,
            .isTakable,
        )
        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: [darkRoom],
            items: [lamp]
        )
        let mockIO = await MockIOHandler()
        let parser = StandardParser()
        let engine = await GameEngine(
            game: game,
            parser: parser,
            ioHandler: mockIO
        )

        // Verify room is dark initially
        let initiallyLit = await engine.scopeResolver.isLocationLit(locationID: "darkRoom")
        #expect(initiallyLit == false)

        let command = Command(
            verbID: "turn on",
            directObject: "lamp",
            rawInput: "turn on lamp"
        )

        // Act
        await engine.execute(command: command)

        // Assert
        let finalItemState = await engine.item("lamp")
        #expect(finalItemState?.hasFlag(.isOn) == true)
        #expect(finalItemState?.hasFlag(.isTouched) == true)

        let output = await mockIO.flush()
        // Assert: Only expect the direct handler message
        expectNoDifference(output, "The brass lantern is now on.")

        // Assert: Verify the room is now lit
        let finallyLit = await engine.scopeResolver.isLocationLit(locationID: "darkRoom")
        #expect(finallyLit == true, "Room should be lit after turning on the lamp.")
    }

    @Test("Try to turn on item already on")
    func testTurnOnItemAlreadyOn() async throws {
        // Arrange
        let lamp = Item(
            id: "lamp",
            name: "brass lantern",
            .description("A brass lantern."),
            .in(.player),
            .isDevice,
            .isLightSource,
            .isOn,
            .isTakable,
        )
        let game = MinimalGame(items: [lamp])
        let mockIO = await MockIOHandler()
        let parser = StandardParser()
        let engine = await GameEngine(
            game: game,
            parser: parser,
            ioHandler: mockIO
        )

        let command = Command(
            verbID: "turn on",
            directObject: "lamp",
            rawInput: "turn on lamp"
        )

        // Act & Assert: Expect error during validation
        await #expect(throws: ActionError.customResponse("It's already on.")) {
            try await handler.validate(
                context: ActionContext(
                    command: command,
                    engine: engine,
                    stateSnapshot: engine.gameState
                )
            )
        }

        // Verify item state didn't change unexpectedly - should NOT be touched if validation fails
        let finalItemState = await engine.item("lamp")
        #expect(finalItemState?.hasFlag(.isOn) == true) // Should still be on
        #expect(finalItemState?.hasFlag(.isTouched) == false) // Should NOT be touched
    }

    @Test("Try to turn on non-device item")
    func testTurnOnNonDeviceItem() async throws {
        // Arrange
        let lamp = Item(
            id: "lamp",
            name: "brass lantern",
            .description("A brass lantern."),
            .in(.player),
            .isTakable,
        )
        let game = MinimalGame(items: [lamp])
        let mockIO = await MockIOHandler()
        let parser = StandardParser()
        let engine = await GameEngine(
            game: game,
            parser: parser,
            ioHandler: mockIO
        )

        let command = Command(
            verbID: "turn on",
            directObject: "lamp",
            rawInput: "turn on lamp"
        )

        // Act & Assert
        await #expect(throws: ActionError.prerequisiteNotMet("You can't turn that on.")) {
            try await handler.validate(
                context: ActionContext(
                    command: command,
                    engine: engine,
                    stateSnapshot: engine.gameState
                )
            )
        }

        let finalItemState = await engine.item("lamp")
        #expect(finalItemState?.hasFlag(.isOn) == false) // Should not gain .on
        #expect(finalItemState?.hasFlag(.isTouched) == false) // Should NOT be touched
    }

    @Test("Try to turn on item not accessible")
    func testTurnOnItemNotAccessible() async throws {
        // Arrange
        let lamp = Item(
            id: "lamp",
            name: "brass lantern",
            .description("A brass lantern."),
            .in(.nowhere), // Not accessible
            .isLightSource,
            .isTakable,
        )
        let game = MinimalGame(items: [lamp])
        let mockIO = await MockIOHandler()
        let parser = StandardParser()
        let engine = await GameEngine(
            game: game,
            parser: parser,
            ioHandler: mockIO
        )

        let command = Command(
            verbID: "turn on",
            directObject: "lamp",
            rawInput: "turn on lamp"
        )

        // Act & Assert: Expect parser error because item is out of scope
        await #expect(throws: ActionError.itemNotAccessible("lamp")) {
            try await handler.validate(
                context: ActionContext(
                    command: command,
                    engine: engine,
                    stateSnapshot: engine.gameState
                )
            )
        }
    }

    @Test("Turn on non-light source device (no room description)")
    func testTurnOnNonLightSourceDevice() async throws {
        // Arrange
        let darkRoom = Location(
            id: "darkRoom",
            name: "Dark Room",
            .description("A dark room.")
        )
        let radio = Item(
            id: "radio",
            name: "portable radio",
            .description("A portable radio."),
            .in(.player),
            .isDevice,
            .isTakable,
        )
        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: [darkRoom],
            items: [radio]
        )
        let mockIO = await MockIOHandler()
        let parser = StandardParser()
        let engine = await GameEngine(
            game: game,
            parser: parser,
            ioHandler: mockIO
        )

        let command = Command(
            verbID: "turn on",
            directObject: "radio",
            rawInput: "turn on radio"
        )

        // Act
        await engine.execute(command: command)

        // Assert
        let finalItemState = await engine.item("radio")
        #expect(finalItemState?.hasFlag(.isOn) == true)
        #expect(finalItemState?.hasFlag(.isTouched) == true)

        let output = await mockIO.flush()
        // Only expect the turn on message, no room description
        expectNoDifference(output, "The portable radio is now on.")

        // Verify room is still dark
        let finallyLit = await engine.scopeResolver.isLocationLit(locationID: "darkRoom")
        #expect(finallyLit == false)
    }

    @Test("Light alias works correctly")
    func testLightAlias() async throws {
        // Arrange
        let lamp = Item(
            id: "lamp",
            name: "brass lantern",
            .description("A brass lantern."),
            .in(.player),
            .isDevice,
            .isLightSource,
            .isTakable,
        )
        let game = MinimalGame(items: [lamp])
        let mockIO = await MockIOHandler()
        let parser = StandardParser()
        let engine = await GameEngine(
            game: game,
            parser: parser,
            ioHandler: mockIO
        )

        let parseResult = parser.parse(
            input: "light lamp",
            vocabulary: await engine.gameState.vocabulary,
            gameState: await engine.gameState
        )
        let command = try parseResult.get()

        // Act
        await engine.execute(command: command)

        // Assert: Same expectations
        let finalItemState = await engine.item("lamp")
        #expect(finalItemState?.hasFlag(.isOn) == true)
        #expect(finalItemState?.hasFlag(.isTouched) == true)

        let output = await mockIO.flush()
        expectNoDifference(output, "The brass lantern is now on.")
    }
}
