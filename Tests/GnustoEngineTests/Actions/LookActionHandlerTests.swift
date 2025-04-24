import Testing
import CustomDump

@testable import GnustoEngine

@MainActor
@Suite("LookActionHandler Tests")
struct LookActionHandlerTests {
    let handler = LookActionHandler()

    @Test("LOOK in lit room describes room and lists items")
    func testLookInLitRoom() async throws {
        let item1 = Item(id: "widget", name: "shiny widget")
        let item2 = Item(id: "gizmo", name: "blue gizmo")

        let game = MinimalGame(
            items: [item1, item2]
        )
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        let command = Command(verbID: "look", rawInput: "look")

        try await handler.perform(command: command, engine: engine)

        let output = await mockIO.flush()
        expectNoDifference(output, """
            --- Test Room ---
            A basic room.
            You can see:
              A blue gizmo
              A shiny widget
            """
        )
    }

    @Test("LOOK in dark room prints darkness message")
    func testLookInDarkRoom() async throws {
        let item1 = Item(id: "widget", name: "shiny widget")

        let game = MinimalGame(
            items: [item1]
        )
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        let command = Command(verbID: "look", rawInput: "look")

        try await handler.perform(command: command, engine: engine)

        let output = await mockIO.flush()
        expectNoDifference(output, "It is pitch black. You are likely to be eaten by a grue.")
    }

    @Test("LOOK in lit room (via player light) describes room and lists items")
    func testLookInRoomLitByPlayer() async throws {
        let activeLamp = Item(id: "lamp", name: "lamp", properties: .lightSource, .on, .takable)
        let item1 = Item(id: "widget", name: "shiny widget")

        let game = MinimalGame(
            items: [activeLamp, item1]
        )
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        let command = Command(verbID: "look", rawInput: "look")

        try await handler.perform(command: command, engine: engine)

        let output = await mockIO.flush()
        expectNoDifference(output, """
            --- Test Room ---
            A basic room.
            You can see:
              A shiny widget
            """
        )
    }

    // --- LOOK AT (item) Tests (Less affected by scope changes for now) ---

    @Test("LOOK AT item shows description")
    func testLookAtItem() async throws {
        let item = Item(id: "rock", name: "plain rock", description: "It looks like a rock.")

        let game = MinimalGame(
            items: [item]
        )
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        let command = Command(verbID: "examine", directObject: "rock", rawInput: "x rock")

        try await handler.perform(command: command, engine: engine)

        let output = await mockIO.flush()
        expectNoDifference(output, "It looks like a rock.")
    }

    @Test("LOOK AT item with no description shows default message")
    func testLookAtItemNoDescription() async throws {
        let item = Item(id: "pebble", name: "small pebble") // No description

        let game = MinimalGame(
            items: [item]
        )
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        let command = Command(verbID: "look", directObject: "pebble", rawInput: "l pebble")

        try await handler.perform(command: command, engine: engine)

        let output = await mockIO.flush()
        expectNoDifference(output, "You see nothing special about the small pebble.")
    }

    // TODO: Add tests for LOOK AT container (open/closed/transparent) and surface - currently handled in handler, maybe move to engine?
    // TODO: Add test for LOOK AT item in dark room (should fail if item not reachable)
}
