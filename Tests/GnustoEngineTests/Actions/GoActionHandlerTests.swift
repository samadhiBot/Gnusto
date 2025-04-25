import CustomDump
import Testing

@testable import GnustoEngine

@MainActor
struct GoActionHandlerTests {
    @Test("Go successfully changes location")
    func testGoSuccessfullyChangesLocation() async throws {
        let startRoom = Location(
            id: "startRoom",
            name: "Start Room",
            description: "You are here.",
            properties: .inherentlyLit
        )
        let endRoom = Location(
            id: "endRoom",
            name: "End Room",
            description: "You went there.",
            properties: .inherentlyLit
        )
        startRoom.exits[.north] = Exit(destination: "endRoom")

        #expect(startRoom.exits[.north] == Exit(destination: "endRoom"))
        #expect(startRoom.exits[.south] == nil)

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

        let handler = GoActionHandler()
        // Command representing "go north" or just "north"
        let command = Command(verbID: "north", direction: .north, rawInput: "north")

        // Act
        try await handler.perform(command: command, engine: engine)

        // Assert
        // Check player location changed
        let finalPlayerLocation = engine.playerLocationID()
        #expect(finalPlayerLocation == "endRoom", "Player should be in the end room")

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
        let startRoom = Location(id: "startRoom", name: "Start Room", description: "You are here.")
        let game = MinimalGame()
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = GameEngine(
            game: game,
            parser: mockParser,
            ioHandler: mockIO
        )

        #expect(startRoom.exits[.south] == nil) // Verify no south exit

        let handler = GoActionHandler()
        let command = Command(verbID: "south", direction: .south, rawInput: "south")

        // Act & Assert: Expect specific error
        await #expect(throws: ActionError.invalidDirection) {
            try await handler.perform(command: command, engine: engine)
        }

        // Assert: Player location did not change
        let finalPlayerLocation = engine.playerLocationID()
        #expect(finalPlayerLocation == "startRoom", "Player should still be in the start room")
    }

    @Test("Go fails for closed door")
    func testGoFailsClosedDoor() async throws {
        // Arrange: Locations with a closed door exit
        let startRoom = Location(id: "startRoom", name: "Start Room", description: "You are here.")
        let endRoom = Location(id: "end", name: "End Room", description: "You went there.")
        startRoom.exits[.north] = Exit(
            destination: "end",
            isDoor: true,
            isOpen: false // Door, explicitly closed
        )
        let game = MinimalGame(locations: [startRoom, endRoom])
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
        #expect(finalPlayerLocation == "startRoom")
    }

    @Test("Go fails for locked door")
    func testGoFailsLockedDoor() async throws {
        // Arrange: Locations with a locked (but potentially open) door exit
        let startRoom = Location(id: "startRoom", name: "Start Room", description: "You are here.")
        let endRoom = Location(id: "end", name: "End Room", description: "You went there.")
        startRoom.exits[.north] = Exit(
            destination: "end",
            isDoor: true,
            isOpen: true,
            isLocked: true // Note: A door can be locked but technically open (e.g., gate)
        )

        let game = MinimalGame(locations: [startRoom, endRoom])
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
        #expect(finalPlayerLocation == "startRoom")
    }

    @Test("Go fails with specific blocked message")
    func testGoFailsBlockedMessage() async throws {
        // Arrange: Locations with an exit having a blockedMessage
        let startRoom = Location(id: "startRoom", name: "Start Room", description: "You are here.")
        let endRoom = Location(id: "end", name: "End Room", description: "You went there.")
        startRoom.exits[.north] = Exit(
            destination: "end",
            blockedMessage: "A chasm blocks your path."
        )

        let game = MinimalGame(locations: [startRoom, endRoom])
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
        await #expect(throws: ActionError.directionIsBlocked("A chasm blocks your path.")) {
            try await handler.perform(command: command, engine: engine)
        }

        // Assert: Player location did not change
        let finalPlayerLocation = engine.playerLocationID()
        #expect(finalPlayerLocation == "startRoom")
    }
}
