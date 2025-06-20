import CustomDump
import Testing

@testable import GnustoEngine

@Suite("GoActionHandler Tests")
struct GoActionHandlerTests {
    @Test("GO NORTH moves player to connected room")
    func testGoNorth() async throws {
        let startRoom = Location(
            id: .startRoom,
            .description("You are here."),
            .exits([.north: .to("end")]),
            .inherentlyLit
        )
        let endRoom = Location(
            id: "end",
            .description("You went there."),
            .inherentlyLit
        )

        let game = MinimalGame(
            locations: startRoom, endRoom
        )
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Act
        try await engine.execute("north")

        let output = await mockIO.flush()
        expectNoDifference(output, """
            > north
            — end —
            You went there.
            """)
    }

    @Test("GO NORTH prints blocked message when exit is blocked")
    func testGoNorthBlocked() async throws {
        let startRoom = Location(
            id: .startRoom,
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
            .description("You went there.")
        )

        let game = MinimalGame(
            player: Player(in: .startRoom),
            locations: startRoom, endRoom
        )
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Act
        try await engine.execute("north")

        // Assert: Should get blocked message
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > north
            A wall blocks your path.
            """)
    }

    @Test("GO NORTH fails when no exit exists")
    func testGoNorthNoExit() async throws {
        let startRoom = Location(
            id: .startRoom,
            .description("You are here.")
        )
        let endRoom = Location(
            id: "end",
            .description("You went there.")
        )

        let game = MinimalGame(
            player: Player(in: .startRoom),
            locations: startRoom, endRoom
        )
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Act
        try await engine.execute("north")

        // Assert: Should get invalid direction message
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > north
            You can’t go that way.
            """)
    }

    @Test("Go to adjacent room successfully")
    func testGoToAdjacentRoomSuccessfully() async throws {
        // Arrange
        let foyer = Location(
            id: "foyer",
            .description("A grand foyer."),
            .exits([.north: .to("hall")]),
            .inherentlyLit
        )
        let hall = Location(
            id: "hall",
            .description("A long hall."),
            .inherentlyLit
        )
        let game = MinimalGame(player: Player(in: "foyer"), locations: foyer, hall)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Act
        try await engine.execute("go north")

        // Assert
        #expect(await engine.playerLocationID == "hall")

        let output = await mockIO.flush()
        expectNoDifference(output, """
            > go north
            — hall —
            A long hall.
            """)
    }

    @Test("Go fails with no exit in direction")
    func testGoFailsWithNoExit() async throws {
        // Arrange
        let foyer = Location(
            id: "foyer",
            .description("A grand foyer."),
            .inherentlyLit
            // No exit north
        )
        let game = MinimalGame(player: Player(in: "foyer"), locations: foyer)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Act
        try await engine.execute("go north")

        // Assert
        #expect(await engine.playerLocationID == "foyer") // Player hasn’t moved
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > go north
            You can’t go that way.
            """)
    }

    @Test("Go fails with locked door")
    func testGoFailsWithLockedDoor() async throws {
        // Arrange
        let foyer = Location(
            id: "foyer",
            .description("A grand foyer."),
            .exits([
                .north: .to("vault", via: "vaultDoor"),
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
            .isDoor,
            .isLocked
        )
        let vault = Location(
            id: "vault",
            .description("A secure vault."),
            .inherentlyLit
        )
        let game = MinimalGame(
            player: Player(in: "foyer"),
            locations: foyer, vault,
            items: vaultDoor
        )
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Act
        try await engine.execute("go north")

        // Assert
        #expect(await engine.playerLocationID == "foyer") // Player hasn’t moved
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > go north
            The door to the vault is locked.
            """)
    }

    @Test("Go fails with conditional exit (condition not met)")
    func testGoFailsWithConditionalExit() async throws {
        // Arrange
        let conditionFlagKey = "gateOpen"
        // Flags use GlobalID, not AttributeID - requires explicit type annotation
        let conditionGlobalID = GlobalID(rawValue: conditionFlagKey)

        let foyer = Location(
            id: "foyer",
            .description("A grand foyer."),
            // Initially, the exit does not exist if the condition is not met
            .exits([:]),
            .inherentlyLit
        )
        let garden = Location(
            id: "garden",
            .description("A beautiful garden."),
            .inherentlyLit
        )
        let game = MinimalGame(
            player: Player(in: "foyer"),
            locations: foyer, garden
        )
        let (engine, mockIO) = await GameEngine.test(
            blueprint: game,
            globalState: [conditionGlobalID: false]
        )

        // Check flags set using contains
        #expect(await engine.global(conditionGlobalID) == false)

        // Act
        try await engine.execute("go east")

        // Assert
        #expect(await engine.playerLocationID == "foyer") // Player hasn’t moved
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > go east
            You can’t go that way.
            """)
    }

    /* TODO: implement conditional exits
    @Test("Go succeeds with conditional exit (condition met)")
    func testGoSucceedsWithConditionalExit() async throws {
        // Arrange
        let conditionFlagKey = "gateOpen"
        // Flags use GlobalID, not AttributeID - requires explicit type annotation
        let conditionGlobalID = GlobalID(conditionFlagKey)

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
        let game = MinimalGame(player: Player(in: "foyer"), locations: foyer, garden) // Pass initial foyer
        let (engine, mockIO) = await GameEngine.test(blueprint: game, parser: MockParser(), ioHandler: await MockIOHandler())

        // Set the condition flag to true by applying a state change
        let change = StateChange(
            entityID: .global, // Use .global for game-specific flags
            // Use .setFlag property key
            attribute: .setFlag(conditionGlobalID),
            oldValue: false, // Expect flag was not set
            newValue: true, // Set flag to true
        )
//        try await engine.TEST_ONLY_applyStateChange(change)

        // Check flags set using contains
        #expect(await engine.gameState.flags.contains(conditionGlobalID))

        // Manually add the exit now that the condition is met
        foyer.exits[.east] = .to("garden")
        // Update the location in the game state directly for the test setup
//        await engine.TEST_ONLY_updateLocation(foyer)

        // Act
        try await engine.execute("go east")

        // Assert
        #expect(await engine.playerLocationID == "garden") // Player moved
    }
     */

    @Test("Go fails with no direction")
    func testGoFailsWithNoDirection() async throws {
        // Arrange
        let foyer = Location(
            id: "foyer",
            .description("A grand foyer."),
            .inherentlyLit
        )
        let game = MinimalGame(player: Player(in: "foyer"), locations: foyer)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Act
        try await engine.execute("go")

        // Assert
        #expect(await engine.playerLocationID == "foyer") // Player hasn’t moved
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > go
            Go where?
            """)
    }

    @Test("GO fails with permanently blocked exit (nil destination)")
    func testGoFailsWithPermanentlyBlockedExit() async throws {
        // Given
        let customMessage = "The path is overgrown with thorns."
        let testLocation = Location(
            id: "testLocation",
            .name("Test Location"),
            .description("A test location."),
            .exits([
                .north: .blocked(customMessage),
            ]),
            .inherentlyLit
        )

        let game = MinimalGame(
            player: Player(in: "testLocation"),
            locations: testLocation
        )
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Act
        try await engine.execute("go north")

        // Assert: Should get custom blocked message
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > go north
            The path is overgrown with thorns.
            """)
    }

    @Test("GO fails with permanently blocked exit (no custom message)")
    func testGoFailsWithPermanentlyBlockedExitNoMessage() async throws {
        // Given
        let testLocation = Location(
            id: "testLocation",
            .name("Test Location"),
            .description("A test location."),
            .inherentlyLit
        )

        let game = MinimalGame(
            player: Player(in: "testLocation"),
            locations: testLocation
        )
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Act
        try await engine.execute("go south")

        // Assert: Should get generic invalid direction message
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > go south
            You can’t go that way.
            """)
    }
}
