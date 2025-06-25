import Testing
import CustomDump
@testable import GnustoEngine

@Suite("KickActionHandler Tests")
struct KickActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("KICK DIRECTOBJECT syntax works")
    func testKickDirectObjectSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .description("A room for testing."),
            .inherentlyLit
        )

        let rock = Item(
            id: "rock",
            .name("large rock"),
            .description("A big granite boulder."),
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: rock
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("kick rock")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > kick rock
            You can’t kick the large rock.
            """)

        let finalState = try await engine.item("rock")
        #expect(finalState.hasFlag(.isTouched) == true)
    }

    // MARK: - Validation Testing

    @Test("Cannot kick without specifying target")
    func testCannotKickWithoutTarget() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("kick")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > kick
            Kick what?
            """)
    }

    @Test("Cannot kick target not in scope")
    func testCannotKickTargetNotInScope() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let anotherRoom = Location(
            id: "anotherRoom",
            .name("Another Room"),
            .inherentlyLit
        )

        let remoteRock = Item(
            id: "remoteRock",
            .name("remote rock"),
            .description("A rock in another room."),
            .in(.location("anotherRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom, anotherRoom,
            items: remoteRock
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("kick rock")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > kick rock
            You can’t see any such thing.
            """)
    }

    @Test("Requires light to kick")
    func testRequiresLight() async throws {
        // Given: Dark room with an object to kick
        let darkRoom = Location(
            id: "darkRoom",
            .name("Dark Room"),
            .description("A pitch black room.")
        )

        let rock = Item(
            id: "rock",
            .name("large rock"),
            .description("A big granite boulder."),
            .in(.location("darkRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom,
            items: rock
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("kick rock")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > kick rock
            It is pitch black. You can’t see a thing.
            """)
    }

    // MARK: - Processing Testing

    @Test("Kick character gives special message")
    func testKickCharacter() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let troll = Item(
            id: "troll",
            .name("nasty troll"),
            .description("A brutish troll blocking the path."),
            .isCharacter,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: troll
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("kick troll")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > kick troll
            You can’t kick the nasty troll.
            """)

        let finalState = try await engine.item("troll")
        #expect(finalState.hasFlag(.isTouched) == true)
    }

    @Test("Kick regular object gives standard message")
    func testKickRegularObject() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let box = Item(
            id: "box",
            .name("wooden box"),
            .description("A sturdy wooden box."),
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: box
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("kick box")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > kick box
            You can’t kick the wooden box.
            """)

        let finalState = try await engine.item("box")
        #expect(finalState.hasFlag(.isTouched) == true)
    }

    @Test("Kick small object")
    func testKickSmallObject() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let pebble = Item(
            id: "pebble",
            .name("small pebble"),
            .description("A tiny pebble."),
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: pebble
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("kick pebble")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > kick pebble
            You can’t kick the small pebble.
            """)
    }

    @Test("Kick held item")
    func testKickHeldItem() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let ball = Item(
            id: "ball",
            .name("rubber ball"),
            .description("A bouncy rubber ball."),
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: ball
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("kick ball")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > kick ball
            You can’t kick the rubber ball.
            """)

        let finalState = try await engine.item("ball")
        #expect(finalState.hasFlag(.isTouched) == true)
    }

    @Test("Kicking sets isTouched flag")
    func testKickingSetsTouchedFlag() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let door = Item(
            id: "door",
            .name("wooden door"),
            .description("A heavy wooden door."),
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: door
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("kick door")

        // Then
        let finalState = try await engine.item("door")
        #expect(finalState.hasFlag(.isTouched) == true)
    }

    @Test("Kick multiple objects in sequence")
    func testKickMultipleObjects() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let table = Item(
            id: "table",
            .name("oak table"),
            .description("A solid oak table."),
            .in(.location("testRoom"))
        )

        let chair = Item(
            id: "chair",
            .name("wooden chair"),
            .description("A simple wooden chair."),
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: table, chair
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("kick table")
        try await engine.execute("kick chair")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > kick table
            You can’t kick the oak table.
            > kick chair
            You can’t kick the wooden chair.
            """)

        let tableState = try await engine.item("table")
        let chairState = try await engine.item("chair")
        #expect(tableState.hasFlag(.isTouched) == true)
        #expect(chairState.hasFlag(.isTouched) == true)
    }

    // MARK: - ActionID Testing

    @Test("Handler exposes correct ActionIDs")
    func testActionIDs() async throws {
        let handler = KickActionHandler()
        // KickActionHandler doesn’t specify actions, so it should be empty
        #expect(handler.actions.isEmpty)
    }

    @Test("Handler exposes correct VerbIDs")
    func testVerbIDs() async throws {
        let handler = KickActionHandler()
        #expect(handler.verbs.contains(.kick))
        #expect(handler.verbs.count == 1)
    }

    @Test("Handler requires light")
    func testRequiresLightProperty() async throws {
        let handler = KickActionHandler()
        #expect(handler.requiresLight == true)
    }
}
