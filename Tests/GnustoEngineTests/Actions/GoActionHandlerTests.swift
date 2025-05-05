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
            description: "You are here.",
            exits: [.north: Exit(destination: "end")],
            inherentlyLit: true
        )
        let endRoom = Location(
            id: "end",
            name: "End Room",
            description: "You went there.",
            inherentlyLit: true
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
            description: "You are here.",
            exits: [.north: Exit(destination: "end", blockedMessage: "A wall blocks your path.")]
        )
        let endRoom = Location(
            id: "end",
            name: "End Room",
            description: "You went there."
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
            try await handler.validate(
                context: ActionContext(
                    command: command,
                    engine: engine,
                    stateSnapshot: engine.gameState
                )
            )
        }

        let output = await mockIO.flush()
        #expect(output.isEmpty, "Expected no output when GO is blocked.")
    }

    @Test("GO NORTH fails when no exit exists")
    func testGoNorthNoExit() async throws {
        let startRoom = Location(
            id: "startRoom",
            name: "Start Room",
            description: "You are here."
        )
        let endRoom = Location(
            id: "end",
            name: "End Room",
            description: "You went there."
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
            try await handler.validate(
                context: ActionContext(
                    command: command,
                    engine: engine,
                    stateSnapshot: engine.gameState
                )
            )
        }

        let output = await mockIO.flush()
        #expect(output.isEmpty, "Expected no output when direction is invalid.")
    }

    @Test("Go to adjacent room successfully")
    func testGoToAdjacentRoomSuccessfully() async throws {
        // Arrange
        let foyer = Location(
            id: "foyer",
            name: "Foyer",
            description: "A grand foyer.",
            exits: [.north: Exit(destination: "hall")],
            inherentlyLit: true
        )
        let hall = Location(
            id: "hall",
            name: "Hall",
            description: "A long hall.",
            inherentlyLit: true
        )
        let game = MinimalGame(player: Player(in: "foyer"), locations: [foyer, hall])
        let engine = GameEngine(game: game, parser: MockParser(), ioHandler: await MockIOHandler())

        let command = Command(verbID: "go", direction: .north, rawInput: "go north")

        // Act
        await engine.execute(command: command)

        // Assert
        #expect(engine.gameState.player.currentLocationID == "hall")
        // Output handled by GameEngine's look after move, not tested here directly
    }

    @Test("Go fails with no exit in direction")
    func testGoFailsWithNoExit() async throws {
        // Arrange
        let foyer = Location(
            id: "foyer",
            name: "Foyer",
            description: "A grand foyer.",
            inherentlyLit: true
            // No exit north
        )
        let game = MinimalGame(player: Player(in: "foyer"), locations: [foyer])
        let mockIO = await MockIOHandler()
        let engine = GameEngine(game: game, parser: MockParser(), ioHandler: mockIO)

        let command = Command(verbID: "go", direction: .north, rawInput: "go north")

        // Act
        await engine.execute(command: command)

        // Assert
        #expect(engine.gameState.player.currentLocationID == "foyer") // Player hasn't moved
        let output = await mockIO.flush()
        expectNoDifference(output, "You can't go that way.")
    }

    @Test("Go fails with locked door")
    func testGoFailsWithLockedDoor() async throws {
        // Arrange
        let foyer = Location(
            id: "foyer",
            name: "Foyer",
            description: "A grand foyer.",
            exits: [.north: Exit(destination: "vault", isLocked: true)], // Locked exit
            inherentlyLit: true
        )
        let vault = Location(
            id: "vault",
            name: "Vault",
            description: "A secure vault.",
            inherentlyLit: true
        )
        let game = MinimalGame(player: Player(in: "foyer"), locations: [foyer, vault])
        let mockIO = await MockIOHandler()
        let engine = GameEngine(game: game, parser: MockParser(), ioHandler: mockIO)

        let command = Command(verbID: "go", direction: .north, rawInput: "go north")

        // Act
        await engine.execute(command: command)

        // Assert
        #expect(engine.gameState.player.currentLocationID == "foyer") // Player hasn't moved
        let output = await mockIO.flush()
        expectNoDifference(output, "The way is locked.") // Assuming a generic locked message
    }

    @Test("Go fails with conditional exit (condition not met)")
    func testGoFailsWithConditionalExit() async throws {
        // Arrange
        let conditionFlag = "gateOpen"
        let foyer = Location(
            id: "foyer",
            name: "Foyer",
            description: "A grand foyer.",
            exits: [.east: Exit(destination: "garden", conditionFlag: conditionFlag)],
            inherentlyLit: true
        )
        let garden = Location(
            id: "garden",
            name: "Garden",
            description: "A beautiful garden.",
            inherentlyLit: true
        )
        let game = MinimalGame(player: Player(in: "foyer"), locations: [foyer, garden])
        let engine = GameEngine(game: game, parser: MockParser(), ioHandler: await MockIOHandler())

        // Ensure condition flag is initially false
        #expect(await engine.hasFlag(.gameSpecificState(key: conditionFlag)) == false)

        let command = Command(verbID: "go", direction: .east, rawInput: "go east")

        // Act
        await engine.execute(command: command)

        // Assert
        #expect(engine.gameState.player.currentLocationID == "foyer") // Player hasn't moved
        // Output depends on how conditional failures are handled, maybe default 'You can't go that way.'
    }

    @Test("Go succeeds with conditional exit (condition met)")
    func testGoSucceedsWithConditionalExit() async throws {
        // Arrange
        let conditionFlag = "gateOpen"
        let foyer = Location(
            id: "foyer",
            name: "Foyer",
            description: "A grand foyer.",
            exits: [.east: Exit(destination: "garden", conditionFlag: conditionFlag)],
            inherentlyLit: true
        )
        let garden = Location(
            id: "garden",
            name: "Garden",
            description: "A beautiful garden.",
            inherentlyLit: true
        )
        let game = MinimalGame(player: Player(in: "foyer"), locations: [foyer, garden])
        let engine = GameEngine(game: game, parser: MockParser(), ioHandler: await MockIOHandler())

        // Set the condition flag to true
        try await engine.setGlobalFlag(key: conditionFlag, value: true)
        #expect(await engine.hasFlag(.gameSpecificState(key: conditionFlag)) == true)

        let command = Command(verbID: "go", direction: .east, rawInput: "go east")

        // Act
        await engine.execute(command: command)

        // Assert
        #expect(engine.gameState.player.currentLocationID == "garden") // Player moved
    }

    @Test("Go fails with no direction")
    func testGoFailsWithNoDirection() async throws {
        // Arrange
        let foyer = Location(
            id: "foyer",
            name: "Foyer",
            description: "A grand foyer.",
            inherentlyLit: true
        )
        let game = MinimalGame(player: Player(in: "foyer"), locations: [foyer])
        let mockIO = await MockIOHandler()
        let engine = GameEngine(game: game, parser: MockParser(), ioHandler: mockIO)

        let command = Command(verbID: "go", rawInput: "go") // No direction

        // Act
        await engine.execute(command: command)

        // Assert
        #expect(engine.gameState.player.currentLocationID == "foyer") // Player hasn't moved
        let output = await mockIO.flush()
        expectNoDifference(output, "Go where?")
    }
}
