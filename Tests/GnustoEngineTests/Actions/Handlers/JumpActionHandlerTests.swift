import Testing
import CustomDump
@testable import GnustoEngine

@Suite("JumpActionHandler Tests")
struct JumpActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("JUMP syntax works")
    func testJumpSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .description("A room for testing."),
            .inherentlyLit
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("jump")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > jump
            You jump in place.
            """)
    }

    @Test("JUMP DIRECTOBJECT syntax works")
    func testJumpDirectObjectSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .description("A room for testing."),
            .inherentlyLit
        )

        let log = Item(
            id: "log",
            .name("fallen log"),
            .description("A large fallen log."),
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: log
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("jump log")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > jump log
            You can’t jump over the fallen log.
            """)

        let finalState = try await engine.item("log")
        #expect(finalState.hasFlag(.isTouched) == true)
    }

    @Test("JUMP OVER DIRECTOBJECT syntax works")
    func testJumpOverDirectObjectSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .description("A room for testing."),
            .inherentlyLit
        )

        let stream = Item(
            id: "stream",
            .name("small stream"),
            .description("A small babbling stream."),
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: stream
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("jump over stream")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > jump over stream
            You can’t jump over the small stream.
            """)
    }

    @Test("LEAP syntax works")
    func testLeapSyntax() async throws {
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
        try await engine.execute("leap")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > leap
            You jump in place.
            """)
    }

    @Test("HOP syntax works")
    func testHopSyntax() async throws {
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
        try await engine.execute("hop")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > hop
            You jump in place.
            """)
    }

    // MARK: - Validation Testing

    @Test("Cannot jump target not in scope")
    func testCannotJumpTargetNotInScope() async throws {
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

        let remoteObstacle = Item(
            id: "remoteObstacle",
            .name("remote obstacle"),
            .description("An obstacle in another room."),
            .in(.location("anotherRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom, anotherRoom,
            items: remoteObstacle
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("jump obstacle")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > jump obstacle
            You can’t see any such thing.
            """)
    }

    @Test("Does not require light to jump")
    func testDoesNotRequireLight() async throws {
        // Given: Dark room
        let darkRoom = Location(
            id: "darkRoom",
            .name("Dark Room"),
            .description("A pitch black room.")
        )

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("jump")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > jump
            You jump in place.
            """)
    }

    // MARK: - Processing Testing

    @Test("Jump in place without object")
    func testJumpInPlace() async throws {
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
        try await engine.execute("jump")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > jump
            You jump in place.
            """)
    }

    @Test("Jump with character gives special message")
    func testJumpWithCharacter() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let troll = Item(
            id: "troll",
            .name("nasty troll"),
            .description("A nasty-looking troll."),
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
        try await engine.execute("jump troll")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > jump troll
            You can’t jump the nasty troll.
            """)

        let finalState = try await engine.item("troll")
        #expect(finalState.hasFlag(.isTouched) == true)
    }

    @Test("Jump with regular object gives standard message")
    func testJumpWithObject() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let boulder = Item(
            id: "boulder",
            .name("large boulder"),
            .description("A massive boulder."),
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: boulder
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("jump boulder")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > jump boulder
            You can’t jump over the large boulder.
            """)

        let finalState = try await engine.item("boulder")
        #expect(finalState.hasFlag(.isTouched) == true)
    }

    @Test("Jumping with object sets isTouched flag")
    func testJumpingSetsTouchedFlag() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let fence = Item(
            id: "fence",
            .name("wooden fence"),
            .description("A tall wooden fence."),
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: fence
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("jump fence")

        // Then
        let finalState = try await engine.item("fence")
        #expect(finalState.hasFlag(.isTouched) == true)
    }

    @Test("Jumping over object with OVER preposition")
    func testJumpOverWithPreposition() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let puddle = Item(
            id: "puddle",
            .name("mud puddle"),
            .description("A small mud puddle."),
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: puddle
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("jump over puddle")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > jump over puddle
            You can’t jump over the mud puddle.
            """)

        let finalState = try await engine.item("puddle")
        #expect(finalState.hasFlag(.isTouched) == true)
    }

    // MARK: - ActionID Testing

    @Test("Handler exposes correct ActionIDs")
    func testActionIDs() async throws {
        let handler = JumpActionHandler()
        // JumpActionHandler doesn’t specify actions, so it should be empty
        #expect(handler.actions.isEmpty)
    }

    @Test("Handler exposes correct VerbIDs")
    func testVerbIDs() async throws {
        let handler = JumpActionHandler()
        #expect(handler.verbs.contains(.jump))
        #expect(handler.verbs.contains(.leap))
        #expect(handler.verbs.contains(.hop))
        #expect(handler.verbs.count == 3)
    }

    @Test("Handler does not require light")
    func testRequiresLightProperty() async throws {
        let handler = JumpActionHandler()
        #expect(handler.requiresLight == false)
    }
}
