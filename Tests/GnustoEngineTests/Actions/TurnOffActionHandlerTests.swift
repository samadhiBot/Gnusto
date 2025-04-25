import Testing
import CustomDump
@testable import GnustoEngine

@MainActor
@Suite("TurnOffActionHandler Tests")
struct TurnOffActionHandlerTests {
    let handler = TurnOffActionHandler()

    @Test("Successfully turn off a light source in inventory")
    func testTurnOffLightSourceInInventory() async throws {
        // Arrange
        let lamp = Item(
            id: "lamp",
            name: "brass lantern",
            description: "A brass lantern.",
            properties: .device, .lightSource, .takable, .on,
            size: 10,
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
        let command = Command(verbID: "turn off", directObject: "lamp", rawInput: "turn off lamp")

        // Act
        try await handler.perform(command: command, engine: engine)

        // Assert
        let finalItemState = engine.itemSnapshot(with: "lamp")
        #expect(finalItemState?.hasProperty(.on) == false)
        #expect(finalItemState?.hasProperty(.touched) == true)

        let output = await mockIO.flush()
        expectNoDifference(output, "The brass lantern is now off.")
    }

    @Test("Turn off light source making a room pitch black")
    func testTurnOffLightSourceCausesDarkness() async throws {
        // Arrange: Start with lamp ON in a room that is ONLY lit by the lamp
        let darkRoom = Location(
            id: "darkRoom",
            name: "Dark Room",
            description: "This room will become dark."
        )
        let lamp = Item(
            id: "lamp",
            name: "brass lantern",
            description: "A brass lantern.",
            properties: .device, .lightSource, .takable, .on,
            size: 10,
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

        // Verify room is lit initially ONLY because of the lamp
        let initiallyLit = engine.scopeResolver.isLocationLit(locationID: darkRoom.id)
        #expect(initiallyLit == true)

        let command = Command(verbID: "turn off", directObject: "lamp", rawInput: "turn off lamp")

        // Act
        try await handler.perform(command: command, engine: engine)

        // Assert
        let finalItemState = engine.itemSnapshot(with: "lamp")
        #expect(finalItemState?.hasProperty(.on) == false)
        #expect(finalItemState?.hasProperty(.touched) == true)

        let output = await mockIO.flush()
        let expectedOutput = """
            The brass lantern is now off.
            It is now pitch black. You are likely to be eaten by a grue.
            """
        expectNoDifference(output, expectedOutput)

        // Verify room is now dark
        let finallyLit = engine.scopeResolver.isLocationLit(locationID: darkRoom.id)
        #expect(finallyLit == false)
    }

    @Test("Try to turn off item already off")
    func testTurnOffItemAlreadyOff() async throws {
        // Arrange
        let lamp = Item(
            id: "lamp",
            name: "brass lantern",
            description: "A brass lantern.",
            properties: .device, .lightSource, .takable, // Starts OFF
            size: 10,
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

        let command = Command(verbID: "turn off", directObject: "lamp", rawInput: "turn off lamp")

        // Act
        try await handler.perform(command: command, engine: engine)

        // Assert
        let finalItemState = engine.itemSnapshot(with: "lamp")
        #expect(finalItemState?.hasProperty(.on) == false) // Should still be off
        #expect(finalItemState?.hasProperty(.touched) == true) // Should be touched

        let output = await mockIO.flush()
        expectNoDifference(output, "It's already off.")
    }

    @Test("Try to turn off non-device item")
    func testTurnOffNonDeviceItem() async throws {
        // Arrange
        let lamp = Item(
            id: "lamp",
            name: "brass lantern",
            description: "A brass lantern.",
            properties: .takable, .on, // Not a device, but somehow .on (test edge case)
            size: 10,
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

        let command = Command(verbID: "turn off", directObject: "lamp", rawInput: "turn off lamp")

        // Act & Assert
        await #expect(throws: ActionError.prerequisiteNotMet("You can't turn that off.")) {
            try await handler.perform(command: command, engine: engine)
        }

        let finalItemState = engine.itemSnapshot(with: "lamp")
        #expect(finalItemState?.hasProperty(.on) == true) // Should not lose .on
        #expect(finalItemState?.hasProperty(.touched) == true) // Should be touched

        let output = await mockIO.flush()
        #expect(output.isEmpty)
    }

    @Test("Try to turn off item that is not reachable (in closed container)")
    func testTurnOffItemInClosedContainer() async throws {
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
            properties: .device, .lightSource, .takable, .on, // Lamp ON inside
            size: 10,
            parent: .item(container.id)
        )
        let game = MinimalGame(items: [container, lamp])
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        let command = Command(verbID: "turn off", directObject: "lamp", rawInput: "turn off lamp")

        // Act & Assert
        await #expect(throws: ActionError.itemNotAccessible("lamp")) {
            try await handler.perform(command: command, engine: engine)
        }

        let finalItemState = engine.itemSnapshot(with: "lamp")
        #expect(finalItemState?.hasProperty(.on) == true) // Should stay on
        #expect(finalItemState?.hasProperty(.touched) == false) // Should not be touched

        let output = await mockIO.flush()
        #expect(output.isEmpty)
    }

    @Test("Turn off non-light source device (no darkness message)")
    func testTurnOffNonLightSourceDevice() async throws {
        // Arrange
        // Start in a lit room
        let lightRoom = Location(
            id: "lightRoom",
            name: "Light Room",
            description: "This room will become dark.",
            properties: .inherentlyLit
        )
        let lamp = Item(
            id: "lamp",
            name: "brass lantern",
            description: "A brass lantern.",
            properties: .device, .lightSource, .takable, .on,
            size: 10,
            parent: .location(lightRoom.id)
        )
        let game = MinimalGame(
            player: Player(in: "lightRoom"),
            locations: [lightRoom],
            items: [lamp]
        )
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        let command = Command(verbID: "turn off", directObject: "lamp", rawInput: "turn off lamp")

        // Verify room is lit initially (inherently)
        let initiallyLit = engine.scopeResolver.isLocationLit(locationID: lightRoom.id)
        #expect(initiallyLit == true)

        // Act
        try await handler.perform(command: command, engine: engine)

        // Assert
        let finalItemState = engine.itemSnapshot(with: "lamp")
        #expect(finalItemState?.hasProperty(.on) == false)
        #expect(finalItemState?.hasProperty(.touched) == true)

        let output = await mockIO.flush()
        // Only expect the turn off message, no darkness message
        expectNoDifference(output, "The brass lantern is now off.")

        // Verify room is still lit
        let finallyLit = engine.scopeResolver.isLocationLit(locationID: lightRoom.id)
        #expect(finallyLit == true)
    }

    @Test("Command without direct object")
    func testTurnOffWithoutDirectObject() async throws {
        // Arrange
        let game = MinimalGame()
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        let command = Command(verbID: "turn off", rawInput: "turn off")

        // Act
        try await handler.perform(command: command, engine: engine)

        // Assert
        let output = await mockIO.flush()
        expectNoDifference(output, "Turn off what?")
    }
}
