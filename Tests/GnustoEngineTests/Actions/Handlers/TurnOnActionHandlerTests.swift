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
            .name("brass lantern"),
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
            blueprint: game,
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
        let finalItemState = try await engine.item("lamp")
        #expect(finalItemState.hasFlag(.isOn) == true)
        #expect(finalItemState.hasFlag(.isTouched) == true)

        let output = await mockIO.flush()
        expectNoDifference(output, "The brass lantern is now on.")
    }

    @Test("Turn on light source in dark location (causes room description)")
    func testTurnOnLightSourceInDarkLocation() async throws {
        // Arrange
        let darkRoom = Location(
            id: "darkRoom",
            .name("Dark Room"),
            .description("This is a dark room that should now be lit.")
        )
        let lamp = Item(
            id: "lamp",
            .name("brass lantern"),
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
            blueprint: game,
            parser: parser,
            ioHandler: mockIO
        )

        // Verify room is dark initially
        let initiallyLit = await engine.scopeResolver.isLocationLit(locationID: "darkRoom")
        #expect(initiallyLit == false)

        let command = Command(
            verb: .turnOn,
            directObject: .item("lamp"),
            rawInput: "turn on lamp"
        )

        // Act
        await engine.execute(command: command)

        // Assert
        let finalItemState = try await engine.item("lamp")
        #expect(finalItemState.hasFlag(.isOn) == true)
        #expect(finalItemState.hasFlag(.isTouched) == true)

        let output = await mockIO.flush()
        // Assert: Only expect the direct handler message
        expectNoDifference(
            output,
            "The brass lantern is now on. You can see your surroundings now."
        )

        // Assert: Verify the room is now lit
        let finallyLit = await engine.scopeResolver.isLocationLit(locationID: "darkRoom")
        #expect(finallyLit == true, "Room should be lit after turning on the lamp.")
    }

    @Test("Try to turn on item already on")
    func testTurnOnItemAlreadyOn() async throws {
        // Arrange
        let lamp = Item(
            id: "lamp",
            .name("brass lantern"),
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
            blueprint: game,
            parser: parser,
            ioHandler: mockIO
        )

        let command = Command(
            verb: .turnOn,
            directObject: .item("lamp"),
            rawInput: "turn on lamp"
        )

        // Act & Assert: Expect error during validation
        await #expect(throws: ActionResponse.custom("It's already on.")) {
            try await handler.validate(
                context: ActionContext(
                    command: command,
                    engine: engine,
                    stateSnapshot: engine.gameState
                )
            )
        }

        // Verify item state didn’t change unexpectedly - should NOT be touched if validation fails
        let finalItemState = try await engine.item("lamp")
        #expect(finalItemState.hasFlag(.isOn) == true) // Should still be on
        #expect(finalItemState.hasFlag(.isTouched) == false) // Should NOT be touched
    }

    @Test("Try to turn on non-device item")
    func testTurnOnNonDeviceItem() async throws {
        // Arrange
        let lamp = Item(
            id: "lamp",
            .name("brass lantern"),
            .description("A brass lantern."),
            .in(.player),
            .isTakable,
        )
        let game = MinimalGame(items: [lamp])
        let mockIO = await MockIOHandler()
        let parser = StandardParser()
        let engine = await GameEngine(
            blueprint: game,
            parser: parser,
            ioHandler: mockIO
        )

        let command = Command(
            verb: .turnOn,
            directObject: .item("lamp"),
            rawInput: "turn on lamp"
        )

        // Act & Assert
        await #expect(throws: ActionResponse.prerequisiteNotMet("You can't turn that on.")) {
            try await handler.validate(
                context: ActionContext(
                    command: command,
                    engine: engine,
                    stateSnapshot: engine.gameState
                )
            )
        }

        let finalItemState = try await engine.item("lamp")
        #expect(finalItemState.hasFlag(.isOn) == false) // Should not gain .on
        #expect(finalItemState.hasFlag(.isTouched) == false) // Should NOT be touched
    }

    @Test("Try to turn on item not accessible")
    func testTurnOnItemNotAccessible() async throws {
        // Arrange
        let lamp = Item(
            id: "lamp",
            .name("brass lantern"),
            .description("A brass lantern."),
            .in(.nowhere), // Not accessible
            .isLightSource,
            .isTakable,
        )
        let game = MinimalGame(items: [lamp])
        let mockIO = await MockIOHandler()
        let parser = StandardParser()
        let engine = await GameEngine(
            blueprint: game,
            parser: parser,
            ioHandler: mockIO
        )

        let command = Command(
            verb: .turnOn,
            directObject: .item("lamp"),
            rawInput: "turn on lamp"
        )

        // Act & Assert: Expect parser error because item is out of scope
        await #expect(throws: ActionResponse.itemNotAccessible("lamp")) {
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
            .name("Dark Room"),
            .description("A dark room.")
        )
        let radio = Item(
            id: "radio",
            .name("portable radio"),
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
            blueprint: game,
            parser: parser,
            ioHandler: mockIO
        )

        let command = Command(
            verb: .turnOn,
            directObject: .item("radio"),
            rawInput: "turn on radio"
        )

        // Act
        await engine.execute(command: command)

        // Assert
        let finalItemState = try await engine.item("radio")
        #expect(finalItemState.hasFlag(.isOn) == true)
        #expect(finalItemState.hasFlag(.isTouched) == true)

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
            .name("brass lantern"),
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
            blueprint: game,
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
        let finalItemState = try await engine.item("lamp")
        #expect(finalItemState.hasFlag(.isOn) == true)
        #expect(finalItemState.hasFlag(.isTouched) == true)

        let output = await mockIO.flush()
        expectNoDifference(output, "The brass lantern is now on.")
    }

    @Test("Turn on light in already-lit room does NOT trigger room description")
    func testTurnOnLightInAlreadyLitRoom() async throws {
        // Arrange: Create a room that is already lit (inherently lit)
        let litRoom = Location(
            id: "livingRoom",
            .name("Living Room"),
            .description("A cozy living room."),
            .inherentlyLit // Room is already lit
        )
        let lamp = Item(
            id: "lamp",
            .name("brass lantern"),
            .description("A brass lantern."),
            .in(.location(litRoom.id)), // Lamp is in the room
            .isDevice,
            .isLightSource,
            .isTakable
        )
        let sword = Item(
            id: "sword",
            .name("sword"),
            .in(.location(litRoom.id))
        )

        let game = MinimalGame(
            player: Player(in: litRoom.id),
            locations: [litRoom],
            items: [lamp, sword]
        )
        let mockIO = await MockIOHandler()
        let parser = StandardParser()
        let engine = await GameEngine(
            blueprint: game,
            parser: parser,
            ioHandler: mockIO
        )

        // Verify room is lit initially (so turning on lamp shouldn't trigger description)
        let initiallyLit = await engine.playerLocationIsLit()
        #expect(initiallyLit == true, "Room should be lit initially")

        // First, take the lamp
        await engine.execute(command: Command(verb: .take, directObject: .item("lamp"), rawInput: "take lamp"))
        _ = await mockIO.flush() // Clear the "Taken." message

        // Act: Turn on the lamp in the already-lit room
        let command = Command(verb: .turnOn, directObject: .item("lamp"), rawInput: "turn on lamp")
        await engine.execute(command: command)

        // Assert: Only expect the turn-on message, NO room description
        let output = await mockIO.flush()
        expectNoDifference(output, "The brass lantern is now on.")

        // Verify the lamp is on and touched
        let finalItemState = try await engine.item("lamp")
        #expect(finalItemState.hasFlag(.isOn) == true)
        #expect(finalItemState.hasFlag(.isTouched) == true)

        // Verify room is still lit (should not have changed)
        let finallyLit = await engine.playerLocationIsLit()
        #expect(finallyLit == true, "Room should still be lit")
    }

    @Test("Debug lighting states when turning on lamp in lit room")
    func testDebugLightingStates() async throws {
        // Arrange: Use exactly the same setup as Zork1's living room
        let livingRoom = Location(
            id: "livingRoom",
            .name("Living Room"),
            .description("""
                You are in the living room. There is a doorway to the east, a wooden door with
                strange gothic lettering to the west, which appears to be nailed shut, a trophy case,
                and a large oriental rug in the center of the room.
                """),
            .inherentlyLit
        )
        let lamp = Item(
            id: "lamp",
            .name("brass lantern"),
            .description("There is a brass lantern (battery-powered) here."),
            .in(.location(livingRoom.id)),
            .isDevice,
            .isLightSource,
            .isTakable
        )
        let sword = Item(
            id: "sword",
            .name("sword"),
            .in(.location(livingRoom.id))
        )

        let game = MinimalGame(
            player: Player(in: livingRoom.id),
            locations: [livingRoom],
            items: [lamp, sword]
        )
        let mockIO = await MockIOHandler()
        let parser = StandardParser()
        let engine = await GameEngine(
            blueprint: game,
            parser: parser,
            ioHandler: mockIO
        )

        // Check initial state
        let initiallyLit = await engine.playerLocationIsLit()
        print("🔍 Initially lit: \(initiallyLit)")

        // Take the lamp first
        await engine.execute(command: Command(verb: .take, directObject: .item("lamp"), rawInput: "take lamp"))
        _ = await mockIO.flush() // Clear the "Taken." message

        // Check state after taking lamp
        let afterTakingLamp = await engine.playerLocationIsLit()
        print("🔍 After taking lamp: \(afterTakingLamp)")

        // Turn on the lamp
        await engine.execute(command: Command(verb: .turnOn, directObject: .item("lamp"), rawInput: "turn on lamp"))

        // Check final state
        let afterTurningOnLamp = await engine.playerLocationIsLit()
        print("🔍 After turning on lamp: \(afterTurningOnLamp)")

        let output = await mockIO.flush()
        print("🔍 Output: \(output)")

        // The key insight: if initiallyLit == afterTurningOnLamp, no room description should appear
        #expect(initiallyLit == true, "Room should be initially lit (inherently)")
        #expect(afterTurningOnLamp == true, "Room should still be lit after turning on lamp")
        #expect(initiallyLit == afterTurningOnLamp, "Lighting state should not change")

        // The output should only contain the turn-on message
        #expect(output == "The brass lantern is now on.", "Should only show turn-on message, no room description")
    }
}
