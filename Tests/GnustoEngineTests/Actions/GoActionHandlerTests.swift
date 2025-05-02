import CustomDump
import Testing

@testable import GnustoEngine

@MainActor
@Suite("GoActionHandler Tests")
struct GoActionHandlerTests {
    let handler = GoActionHandler()

    @Test("GO NORTH moves player to connected room")
    func testGoNorth() async throws {
        let startRoom = Location(
            id: "startRoom",
            name: "Start Room",
            longDescription: "You are here.",
            exits: [.north: Exit(destination: "end")],
            properties: .inherentlyLit
        )
        let endRoom = Location(
            id: "end",
            name: "End Room",
            longDescription: "You went there.",
            properties: .inherentlyLit
        )

        let game = MinimalGame(
            locations: [startRoom, endRoom]
        )
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        let command = Command(
            verbID: "go",
            direction: .north,
            rawInput: "north"
        )

        await engine.execute(command: command)

        let output = await mockIO.flush()
        expectNoDifference(output, "")
    }

    @Test("GO NORTH prints blocked message when exit is blocked")
    func testGoNorthBlocked() async throws {
        let startRoom = Location(
            id: "startRoom",
            name: "Start Room",
            longDescription: "You are here.",
            exits: [.north: Exit(destination: "end", blockedMessage: "A wall blocks your path.")]
        )
        let endRoom = Location(
            id: "end",
            name: "End Room",
            longDescription: "You went there."
        )

        let game = MinimalGame(
            player: Player(in: "startRoom"),
            locations: [startRoom, endRoom]
        )
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        let command = Command(
            verbID: "go",
            direction: .north,
            rawInput: "north"
        )

        await #expect(throws: ActionError.directionIsBlocked("A wall blocks your path.")) {
            try await handler.validate(command: command, engine: engine)
        }

        let output = await mockIO.flush()
        #expect(output.isEmpty, "Expected no output when GO is blocked.")
    }

    @Test("GO NORTH fails when no exit exists")
    func testGoNorthNoExit() async throws {
        let startRoom = Location(
            id: "startRoom",
            name: "Start Room",
            longDescription: "You are here."
        )
        let endRoom = Location(
            id: "end",
            name: "End Room",
            longDescription: "You went there."
        )

        let game = MinimalGame(
            player: Player(in: "startRoom"),
            locations: [startRoom, endRoom]
        )
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        let command = Command(
            verbID: "go",
            direction: .north,
            rawInput: "north"
        )

        await #expect(throws: ActionError.invalidDirection) {
            try await handler.validate(command: command, engine: engine)
        }

        let output = await mockIO.flush()
        #expect(output.isEmpty, "Expected no output when direction is invalid.")
    }
}
