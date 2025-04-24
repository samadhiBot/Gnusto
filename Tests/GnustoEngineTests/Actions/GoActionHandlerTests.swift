import CustomDump
import Testing

@testable import GnustoEngine

@MainActor
@Suite("GoActionHandler Tests")
struct GoActionHandlerTests {
    @Test("Go successfully changes location")
    func testGoSuccessfullyChangesLocation() async throws {
        let loc1 = Location(
            id: "startRoom",
            name: "Start Room",
            description: "You are here.",
            properties: .inherentlyLit
        )
        let loc2 = Location(
            id: "endRoom",
            name: "End Room",
            description: "You went there.",
            properties: .inherentlyLit
        )
        loc1.exits[.north] = Exit(destination: "endRoom")

        #expect(loc1.exits[.north] == Exit(destination: "endRoom"))
        #expect(loc1.exits[.north] == nil)

        let game = MinimalGame(
            locations: [loc1, loc2]
        )
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        let handler = GoActionHandler()
        // Command representing "go north" or just "north"
        let command = Command(verbID: "north", direction: .north, rawInput: "north")

        // Act
        try await handler.perform(command: command, engine: engine)

        // Assert
        // Check player location changed
        let finalPlayerLocation = engine.playerLocationID()
        #expect(finalPlayerLocation == "end", "Player should be in the end room")

        // Check new location was described
        let output = await mockIO.flush()
        expectNoDifference(output, """
            --- End Room ---
            You went there.
            """
        )
    }

    @Test("Go fails for invalid direction")
    func testGoFailsInvalidDirection() async throws {
        // Arrange: Location with no exit to the south
        let loc1 = Location(
            id: "start",
            name: "Start Room",
            description: "You are here."
        )

        let game = MinimalGame(
            locations: [loc1]
        )
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        #expect(loc1.exits[.south] == nil) // Verify no south exit

        let handler = GoActionHandler()
        let command = Command(verbID: "south", direction: .south, rawInput: "south")

        // Act & Assert: Expect specific error
        await #expect(throws: ActionError.invalidDirection) {
            try await handler.perform(command: command, engine: engine)
        }

        // Assert: Player location did not change
        let finalPlayerLocation = engine.playerLocationID()
        #expect(finalPlayerLocation == "start", "Player should still be in the start room")
    }

    @Test("Go fails for closed door")
    func testGoFailsClosedDoor() async throws {
        // Arrange: Locations with a closed door exit
        let loc1 = Location(id: "start", name: "Start Room", description: "You are here.")
        let loc2 = Location(id: "end", name: "End Room", description: "You went there.")
        loc1.exits[.north] = Exit(destination: "end", isDoor: true, isOpen: false) // Door, explicitly closed

        let game = MinimalGame(
            locations: [loc1, loc2]
        )
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        let handler = GoActionHandler()
        let command = Command(verbID: "north", direction: .north, rawInput: "north")

        // Act & Assert: Expect specific error
        // Check the error message includes the direction
        await #expect(throws: ActionError.directionIsBlocked("The north door is closed.")) {
            try await handler.perform(command: command, engine: engine)
        }

        // Assert: Player location did not change
        let finalPlayerLocation = engine.playerLocationID()
        #expect(finalPlayerLocation == "start")
    }

    @Test("Go fails for locked door")
    func testGoFailsLockedDoor() async throws {
        // Arrange: Locations with a locked (but potentially open) door exit
        let loc1 = Location(id: "start", name: "Start Room", description: "You are here.")
        let loc2 = Location(id: "end", name: "End Room", description: "You went there.")
        // Note: A door can be locked but technically open (e.g., gate)
        loc1.exits[.north] = Exit(destination: "end", isDoor: true, isOpen: true, isLocked: true)

        let game = MinimalGame(
            locations: [loc1, loc2]
        )
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        let handler = GoActionHandler()
        let command = Command(verbID: "north", direction: .north, rawInput: "north")

        // Act & Assert: Expect specific error
        await #expect(throws: ActionError.directionIsBlocked("The north door seems to be locked.")) {
            try await handler.perform(command: command, engine: engine)
        }

        // Assert: Player location did not change
        let finalPlayerLocation = engine.playerLocationID()
        #expect(finalPlayerLocation == "start")
    }

    @Test("Go fails with specific blocked message")
    func testGoFailsBlockedMessage() async throws {
        // Arrange: Locations with an exit having a blockedMessage
        let loc1 = Location(id: "start", name: "Start Room", description: "You are here.")
        let loc2 = Location(id: "end", name: "End Room", description: "You went there.")
        let blockMsg = "A chasm blocks your path."
        loc1.exits[.north] = Exit(destination: "end", blockedMessage: blockMsg)

        let game = MinimalGame(
            locations: [loc1, loc2]
        )
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        let handler = GoActionHandler()
        let command = Command(verbID: "north", direction: .north, rawInput: "north")

        // Act & Assert: Expect specific error with the custom message
        await #expect(throws: ActionError.directionIsBlocked(blockMsg)) {
            try await handler.perform(command: command, engine: engine)
        }

        // Assert: Player location did not change
        let finalPlayerLocation = engine.playerLocationID()
        #expect(finalPlayerLocation == "start")
    }

    // Add more tests here...
}
