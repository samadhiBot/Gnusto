import Testing
import CustomDump
@testable import GnustoEngine

@MainActor
@Suite("TurnOffActionHandler Tests")
struct TurnOffActionHandlerTests {
    let handler = TurnOffActionHandler()

    @Test("TURN OFF turns off a light source in a dark room makes everything dark")
    func testTurnOffLightSource() async throws {
        let room = Location(
            id: "room",
            name: "Test Room",
            longDescription: "You are here."
        )
        let lamp = Item(
            id: "lamp",
            name: "lamp",
            shortDescription: "A brass lamp",
            longDescription: "A brass lamp is here.",
            properties: .lightSource, .device, .on,
            parent: .player
        )

        let game = MinimalGame(
            player: Player(in: "room"),
            locations: [room],
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

        try await handler.perform(command: command, engine: engine)

        let output = await mockIO.flush()
        expectNoDifference(output, """
            The lamp is now off.
            It is now pitch black. You are likely to be eaten by a grue.
            """)
        let finalItemState = engine.itemSnapshot(with: "lamp")
        #expect(finalItemState?.hasProperty(.on) == false)
        #expect(finalItemState?.hasProperty(.touched) == true)
    }

    @Test("TURN OFF fails for non-light source")
    func testTurnOffNonLightSource() async throws {
        let room = Location(
            id: "room",
            name: "Test Room",
            longDescription: "You are here.",
            properties: .inherentlyLit
        )
        let book = Item(
            id: "book",
            name: "book",
            shortDescription: "A dusty book",
            longDescription: "A dusty book lies here.",
            parent: .location(room.id)
        )

        let game = MinimalGame(
            player: Player(in: "room"),
            locations: [room],
            items: [book]
        )
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        let command = Command(verbID: "turn off", directObject: "book", rawInput: "turn off book")

        await #expect(throws: ActionError.prerequisiteNotMet("You can't turn that off.")) {
            try await handler.validate(command: command, engine: engine)
        }
    }

    @Test("TURN OFF fails for non-existent item")
    func testTurnOffNonExistentItem() async throws {
        let room = Location(
            id: "room",
            name: "Test Room",
            longDescription: "You are here."
        )

        let game = MinimalGame(
            player: Player(in: "room"),
            locations: [room]
        )
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        let command = Command(verbID: "turn off", directObject: "lamp", rawInput: "turn off lamp")

        // Expect internalEngineError when item ID doesn't exist in gameState
        await #expect(throws: ActionError.internalEngineError("Parser resolved non-existent item ID 'lamp'.")) {
            try await handler.validate(command: command, engine: engine)
        }
    }

    @Test("Successfully turn off a light source in inventory")
    func testTurnOffLightSourceInInventory() async throws {
        let lamp = Item(
            id: "lamp",
            name: "brass lantern",
            longDescription: "A brass lantern.",
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

        try await handler.perform(command: command, engine: engine)

        let finalItemState = engine.itemSnapshot(with: "lamp")
        #expect(finalItemState?.hasProperty(.on) == false)
        #expect(finalItemState?.hasProperty(.touched) == true)

        let output = await mockIO.flush()
        expectNoDifference(output, "The brass lantern is now off.")
    }

    @Test("Turn off light source making a room pitch black")
    func testTurnOffLightSourceCausesDarkness() async throws {
        let darkRoom = Location(
            id: "darkRoom",
            name: "Dark Room",
            longDescription: "This room will become dark."
        )
        let lamp = Item(
            id: "lamp",
            name: "brass lantern",
            longDescription: "A brass lantern.",
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

        let initiallyLit = engine.scopeResolver.isLocationLit(locationID: darkRoom.id)
        #expect(initiallyLit == true)

        let command = Command(verbID: "turn off", directObject: "lamp", rawInput: "turn off lamp")

        try await handler.perform(command: command, engine: engine)

        let finalItemState = engine.itemSnapshot(with: "lamp")
        #expect(finalItemState?.hasProperty(.on) == false)
        #expect(finalItemState?.hasProperty(.touched) == true)

        let output = await mockIO.flush()
        let expectedOutput = """
            The brass lantern is now off.
            It is now pitch black. You are likely to be eaten by a grue.
            """
        expectNoDifference(output, expectedOutput)

        let finallyLit = engine.scopeResolver.isLocationLit(locationID: darkRoom.id)
        #expect(finallyLit == false)
    }

    @Test("Try to turn off item already off")
    func testTurnOffItemAlreadyOff() async throws {
        let lamp = Item(
            id: "lamp",
            name: "brass lantern",
            longDescription: "A brass lantern.",
            properties: .device, .lightSource, .takable,
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

        // Act & Assert: Expect error during validation
        await #expect(throws: ActionError.customResponse("It's already off.")) {
             try await handler.validate(command: command, engine: engine)
        }

        // Check state remains unchanged - touched should NOT be added if validation fails
        let finalItemState = engine.itemSnapshot(with: "lamp")
        #expect(finalItemState?.hasProperty(.on) == false)
        #expect(finalItemState?.hasProperty(.touched) == false)
    }

    @Test("Try to turn off non-device item")
    func testTurnOffNonDeviceItem() async throws {
        let lamp = Item(
            id: "lamp",
            name: "brass lantern",
            longDescription: "A brass lantern.",
            properties: .takable, .on,
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

        // Act & Assert: Expect error during validation
        await #expect(throws: ActionError.prerequisiteNotMet("You can't turn that off.")) {
             try await handler.validate(command: command, engine: engine)
        }
        // Check state remains unchanged - touched should NOT be added if validation fails
        let finalItemState = engine.itemSnapshot(with: "lamp")
        #expect(finalItemState?.hasProperty(.on) == true)
        #expect(finalItemState?.hasProperty(.touched) == false)
    }

    @Test("Try to turn off item not accessible")
    func testTurnOffItemNotAccessible() async throws {
        let lamp = Item(
            id: "lamp",
            name: "brass lantern",
            longDescription: "A brass lantern.",
            properties: .device, .lightSource, .takable, .on,
            size: 10,
            parent: .nowhere
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

        await #expect(throws: ActionError.itemNotAccessible("lamp")) {
            try await handler.perform(command: command, engine: engine)
        }
    }

    @Test("Extinguish alias works correctly")
    func testExtinguishAlias() async throws {
        let darkRoom = Location(
            id: "darkRoom",
            name: "Dark Room",
            longDescription: "This room will become dark."
        )
        let lamp = Item(
            id: "lamp",
            name: "brass lantern",
            longDescription: "A brass lantern.",
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

        let command = Command(verbID: "extinguish", directObject: "lamp", rawInput: "extinguish lamp")

        try await handler.perform(command: command, engine: engine)

        let finalItemState = engine.itemSnapshot(with: "lamp")
        #expect(finalItemState?.hasProperty(.on) == false)
        #expect(finalItemState?.hasProperty(.touched) == true)

        let output = await mockIO.flush()
        let expectedOutput = """
            The brass lantern is now off.
            It is now pitch black. You are likely to be eaten by a grue.
            """
        expectNoDifference(output, expectedOutput)
    }

    @Test("Blow Out alias works correctly")
    func testBlowOutAlias() async throws {
        let darkRoom = Location(
            id: "darkRoom",
            name: "Dark Room",
            longDescription: "This room will become dark."
        )
        let lamp = Item(
            id: "lamp",
            name: "brass lantern",
            longDescription: "A brass lantern.",
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

        let command = Command(verbID: "blow out", directObject: "lamp", rawInput: "blow out lamp")

        try await handler.perform(command: command, engine: engine)

        let finalItemState = engine.itemSnapshot(with: "lamp")
        #expect(finalItemState?.hasProperty(.on) == false)
        #expect(finalItemState?.hasProperty(.touched) == true)

        let output = await mockIO.flush()
        let expectedOutput = """
            The brass lantern is now off.
            It is now pitch black. You are likely to be eaten by a grue.
            """
        expectNoDifference(output, expectedOutput)
    }
}
