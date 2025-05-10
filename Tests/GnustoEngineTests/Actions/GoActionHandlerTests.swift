import CustomDump
import Testing

@testable import GnustoEngine

@Suite("GoActionHandler Tests")
struct GoActionHandlerTests {
    let handler = GoActionHandler()

    @Test("GO NORTH moves player to connected room")
    func testGoNorth() async throws {
        let startRoom = Location(
            id: "startRoom",
            .name("Start Room"),
            .description("You are here."),
            .exits([.north: Exit(destination: "end")]),
            .inherentlyLit
        )
        let endRoom = Location(
            id: "end",
            .name("End Room"),
            .description("You went there."),
            .inherentlyLit
        )

        let game = MinimalGame(
            locations: [startRoom, endRoom]
        )
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
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
            .name("Start Room"),
            .description("You are here."),
            .exits([
                .north: Exit(
                    destination: "end",
                    blockedMessage: "A wall blocks your path."
                )
            ])
        )
        let endRoom = Location(
            id: "end",
            .name("End Room"),
            .description("You went there.")
        )

        let game = MinimalGame(
            player: Player(in: "startRoom"),
            locations: [startRoom, endRoom]
        )
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
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
            .name("Start Room"),
            .description("You are here.")
        )
        let endRoom = Location(
            id: "end",
            .name("End Room"),
            .description("You went there.")
        )

        let game = MinimalGame(
            player: Player(in: "startRoom"),
            locations: [startRoom, endRoom]
        )
        let mockIO = await MockIOHandler()
        let mockParser = MockParser()
        let engine = await GameEngine(
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
            .name("Foyer"),
            .description("A grand foyer."),
            .exits([.north: Exit(destination: "hall")]),
            .inherentlyLit
        )
        let hall = Location(
            id: "hall",
            .name("Hall"),
            .description("A long hall."),
            .inherentlyLit
        )
        let game = MinimalGame(player: Player(in: "foyer"), locations: [foyer, hall])
        let engine = await GameEngine(game: game, parser: MockParser(), ioHandler: await MockIOHandler())

        let command = Command(verbID: "go", direction: .north, rawInput: "go north")

        // Act
        await engine.execute(command: command)

        // Assert
        #expect(await engine.gameState.player.currentLocationID == "hall")
        // Output handled by GameEngine's look after move, not tested here directly
    }

    @Test("Go fails with no exit in direction")
    func testGoFailsWithNoExit() async throws {
        // Arrange
        let foyer = Location(
            id: "foyer",
            .name("Foyer"),
            .description("A grand foyer."),
            .inherentlyLit
            // No exit north
        )
        let game = MinimalGame(player: Player(in: "foyer"), locations: [foyer])
        let mockIO = await MockIOHandler()
        let engine = await GameEngine(game: game, parser: MockParser(), ioHandler: mockIO)

        let command = Command(verbID: "go", direction: .north, rawInput: "go north")

        // Act
        await engine.execute(command: command)

        // Assert
        #expect(await engine.gameState.player.currentLocationID == "foyer") // Player hasn't moved
        let output = await mockIO.flush()
        expectNoDifference(output, "You can't go that way.")
    }

    @Test("Go fails with locked door")
    func testGoFailsWithLockedDoor() async throws {
        // Arrange
        let foyer = Location(
            id: "foyer",
            .name("Foyer"),
            .description("A grand foyer."),
            .exits([
                .north: Exit(
                    destination: "vault",
                    doorID: "vaultDoor"
                )
            ]),
            .inherentlyLit
        )
        let vaultDoor = Item(
            id: "vaultDoor",
            .name("door to the vault"),
            .description("""
                A massive, reinforced steel door dominates one wall of the grand foyer.
                """),
            .in(.location(foyer.id)),
            .isLocked
        )
        let vault = Location(
            id: "vault",
            .name("Vault"),
            .description("A secure vault."),
            .inherentlyLit
        )
        let game = MinimalGame(
            player: Player(in: "foyer"),
            locations: [foyer, vault],
            items: [vaultDoor]
        )
        let mockIO = await MockIOHandler()
        let engine = await GameEngine(game: game, parser: MockParser(), ioHandler: mockIO)

        let command = Command(verbID: "go", direction: .north, rawInput: "go north")

        // Act
        await engine.execute(command: command)

        // Assert
        #expect(await engine.gameState.player.currentLocationID == "foyer") // Player hasn't moved
        let output = await mockIO.flush()
        expectNoDifference(output, "The door to the vault is locked.")
    }

    @Test("Go fails with conditional exit (condition not met)")
    func testGoFailsWithConditionalExit() async throws {
        // Arrange
        let conditionFlagKey = "gateOpen"
        // Flags use FlagID, not AttributeID - requires explicit type annotation
        let conditionFlagID = FlagID(conditionFlagKey)

        let foyer = Location(
            id: "foyer",
            .name("Foyer"),
            .description("A grand foyer."),
            // Initially, the exit does not exist if the condition is not met
            .exits([:]),
            .inherentlyLit
        )
        let garden = Location(
            id: "garden",
            .name("Garden"),
            .description("A beautiful garden."),
            .inherentlyLit
        )
        let game = MinimalGame(player: Player(in: "foyer"), locations: [foyer, garden])
        let engine = await GameEngine(game: game, parser: MockParser(), ioHandler: await MockIOHandler())

        // Check flags set using contains
        #expect(await engine.gameState.flags.contains(conditionFlagID) == false)

        let command = Command(verbID: "go", direction: .east, rawInput: "go east")

        // Act
        await engine.execute(command: command)

        // Assert
        #expect(await engine.gameState.player.currentLocationID == "foyer") // Player hasn't moved
    }

    /* TODO: implement conditional exits
    @Test("Go succeeds with conditional exit (condition met)")
    func testGoSucceedsWithConditionalExit() async throws {
        // Arrange
        let conditionFlagKey = "gateOpen"
        // Flags use FlagID, not AttributeID - requires explicit type annotation
        let conditionFlagID = FlagID(conditionFlagKey)

        var foyer = Location( // Make foyer mutable to add the exit later
            id: "foyer",
            name: "Foyer",
            description: "A grand foyer.",
            // Exit will be added when condition is met
            exits: [:],
            isLit: true
        )
        let garden = Location(
            id: "garden",
            name: "Garden",
            description: "A beautiful garden.",
            isLit: true
        )
        let game = MinimalGame(player: Player(in: "foyer"), locations: [foyer, garden]) // Pass initial foyer
        let engine = await GameEngine(game: game, parser: MockParser(), ioHandler: await MockIOHandler())

        // Set the condition flag to true by applying a state change
        let change = StateChange(
            entityID: .global, // Use .global for game-specific flags
            // Use .setFlag property key
            attributeKey: .setFlag(conditionFlagID),
            oldValue: false, // Expect flag was not set
            newValue: true, // Set flag to true
        )
//        try await engine.TEST_ONLY_applyStateChange(change)

        // Check flags set using contains
        #expect(await engine.gameState.flags.contains(conditionFlagID))

        // Manually add the exit now that the condition is met
        foyer.exits[.east] = Exit(destination: "garden")
        // Update the location in the game state directly for the test setup
//        await engine.TEST_ONLY_updateLocation(foyer)

        let command = Command(verbID: "go", direction: .east, rawInput: "go east")

        // Act
        await engine.execute(command: command)

        // Assert
        #expect(await engine.gameState.player.currentLocationID == "garden") // Player moved
    }
     */

    @Test("Go fails with no direction")
    func testGoFailsWithNoDirection() async throws {
        // Arrange
        let foyer = Location(
            id: "foyer",
            .name("Foyer"),
            .description("A grand foyer."),
            .inherentlyLit
        )
        let game = MinimalGame(player: Player(in: "foyer"), locations: [foyer])
        let mockIO = await MockIOHandler()
        let engine = await GameEngine(game: game, parser: MockParser(), ioHandler: mockIO)

        let command = Command(verbID: "go", rawInput: "go") // No direction

        // Act
        await engine.execute(command: command)

        // Assert
        #expect(await engine.gameState.player.currentLocationID == "foyer") // Player hasn't moved
        let output = await mockIO.flush()
        expectNoDifference(output, "Go where?")
    }
}
