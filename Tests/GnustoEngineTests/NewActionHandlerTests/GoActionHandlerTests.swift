import CustomDump
import Testing

@testable import GnustoEngine

@Suite("GoActionHandler Tests")
struct GoActionHandlerTests {
    let handler = GoActionHandler()
    var game: MinimalGame!
    var engine: GameEngine!
    var mockIO: MockIOHandler!

    var westRoom: Location!
    var eastRoom: Location!
    var northRoom: Location!
    var southRoom: Location!
    var door: Item!

    @Before
    func setup() {
        westRoom = Location(
            id: "westRoom",
            .name("West Room"),
            .description("You are in the west room."),
            .exit(.east, to: "eastRoom", through: "door"),
            .exit(.north, to: "northRoom")
        )
        eastRoom = Location(
            id: "eastRoom",
            .name("East Room"),
            .description("You are in the east room."),
            .exit(.west, to: "westRoom", through: "door")
        )
        northRoom = Location(
            id: "northRoom",
            .name("North Room"),
            .description("You are in the north room."),
            .exit(.south, to: "westRoom"),
            .exit(.east, to: "blockedExit")  // Permanently blocked
        )
        southRoom = Location(
            id: "southRoom",
            .name("South Room"),
            .description("You are in the south room."),
            .exit(.north, to: "westRoom", blockedMessage: "A large boulder blocks the way.")
        )

        door = Item(
            id: "door",
            .name("heavy oak door"),
            .description("A heavy oak door."),
            .isDoor,
            .isOpenable,
            .in(.location("westRoom"))
        )

        game = MinimalGame(
            player: Player(in: "westRoom"),
            locations: [westRoom, eastRoom, northRoom, southRoom],
            items: [door]
        )

        (engine, mockIO) = await GameEngine.test(blueprint: game)
    }

    // MARK: - Syntax Rule Testing

    @Test("GO NORTH syntax works")
    func testGoNorthSyntax() async throws {
        try await engine.execute("go north")
        let output = await mockIO.flush()
        #expect(output.contains("North Room"))
        let playerLocation = await engine.playerLocationID
        #expect(playerLocation == "northRoom")
    }

    @Test("N alias works")
    func testNorthAlias() async throws {
        try await engine.execute("n")
        let output = await mockIO.flush()
        #expect(output.contains("North Room"))
    }

    @Test("WALK verb synonym works")
    func testWalkSynonym() async throws {
        try await engine.execute("walk north")
        let output = await mockIO.flush()
        #expect(output.contains("North Room"))
    }

    // MARK: - Validation Testing

    @Test("Fails when no exit exists in direction")
    func testValidationFailsWithNoExit() async throws {
        try await engine.execute("go south")
        let output = await mockIO.flush()
        #expect(output.contains("You can't go that way."))
    }

    @Test("Fails with custom blocked message")
    func testValidationFailsWithCustomBlockedMessage() async throws {
        try await engine.updatePlayer { $0.parent = .location("southRoom") }
        await mockIO.flush()

        try await engine.execute("go north")
        let output = await mockIO.flush()
        #expect(output.contains("A large boulder blocks the way."))
    }

    @Test("Fails with permanently blocked exit (nil destination)")
    func testValidationFailsWithPermanentlyBlockedExit() async throws {
        try await engine.updatePlayer { $0.parent = .location("northRoom") }
        await mockIO.flush()

        try await engine.execute("go east")
        let output = await mockIO.flush()
        #expect(output.contains("You can't go that way."))
    }

    @Test("Fails when door is closed")
    func testValidationFailsWhenDoorIsClosed() async throws {
        // Door is closed by default
        try await engine.execute("go east")
        let output = await mockIO.flush()
        #expect(output.contains("The heavy oak door is closed."))
    }

    @Test("Fails when door is locked")
    func testValidationFailsWhenDoorIsLocked() async throws {
        try await engine.update(item: "door") {
            $0.setFlag(.isLocked)
        }
        try await engine.execute("go east")
        let output = await mockIO.flush()
        #expect(output.contains("The heavy oak door is locked."))
    }

    // MARK: - Processing Testing

    @Test("Successfully moves player through open door")
    func testProcessSucceedsWithOpenDoor() async throws {
        try await engine.update(item: "door") {
            $0.setFlag(.isOpen)
        }

        try await engine.execute("go east")
        let output = await mockIO.flush()
        #expect(output.contains("East Room"))

        let playerLocation = await engine.playerLocationID
        #expect(playerLocation == "eastRoom")
    }

    @Test("Successfully moves player to new location")
    func testProcessSucceedsNormalMove() async throws {
        try await engine.execute("n")
        let playerLocation = await engine.playerLocationID
        #expect(playerLocation == "northRoom")

        await mockIO.flush()

        try await engine.execute("s")
        let newPlayerLocation = await engine.playerLocationID
        #expect(newPlayerLocation == "westRoom")
    }

    // MARK: - ActionID Testing

    @Test("GO action resolves to GoActionHandler")
    func testGoActionID() async throws {
        let parser = StandardParser()
        let command = try parser.parse("go north")
        let resolvedAction = await engine.resolveAction(for: command)
        #expect(isNotNil(resolvedAction))
        #expect(resolvedAction?.handler is GoActionHandler)
    }
}
