import CustomDump
import Testing

@testable import GnustoEngine

@Suite("KickActionHandler Tests")
struct KickActionHandlerTests {

    @Test("Kick validates missing direct object")
    func testKickValidatesMissingDirectObject() async throws {
        // Given
        let (engine, mockIO) = await GameEngine.test()

        // When / Then
        try await engine.execute("kick")

        let output = await mockIO.flush()
        expectNoDifference(output, """
            > kick
            Kick what?
            """)
    }

    @Test("Kick validates item not found")
    func testKickValidatesItemNotFound() async throws {
        // Given
        let (engine, mockIO) = await GameEngine.test()

        // When / Then
        try await engine.execute("kick nonexistent")

        let output = await mockIO.flush()
        expectNoDifference(output, """
            > kick nonexistent
            You can’t see any such thing.
            """)
    }

    @Test("Kick validates item not reachable")
    func testKickValidatesItemNotReachable() async throws {
        // Given
        let distantRock = Item(
            id: "distant_rock",
            .name("distant rock"),
            .in(.nowhere)
        )

        let game = MinimalGame(items: distantRock)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When / Then
        try await engine.execute("kick distant rock")

        let output = await mockIO.flush()
        expectNoDifference(output, """
            > kick distant rock
            You can’t see any distant rock here.
            """)
    }

    @Test("Kick character shows appropriate message")
    func testKickCharacterShowsAppropriateMessage() async throws {
        // Given
        let goblin = Item(
            id: "goblin",
            .name("goblin"),
            .in(.location(.startRoom)),
            .isCharacter
        )

        let game = MinimalGame(items: goblin)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("kick goblin")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > kick goblin
            I don’t think the goblin would appreciate that.
            """)
    }

    @Test("Kick takable object shows appropriate message")
    func testKickTakableObjectShowsAppropriateMessage() async throws {
        // Given
        let ball = Item(
            id: "ball",
            .name("ball"),
            .in(.location(.startRoom)),
            .isTakable
        )

        let game = MinimalGame(items: ball)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("kick ball")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > kick ball
            Ouch! You hurt your foot kicking the ball.
            """)
    }

    @Test("Kick fixed object shows hurt foot message")
    func testKickFixedObjectShowsHurtFootMessage() async throws {
        // Given
        let wall = Item(
            id: "wall",
            .name("wall"),
            .in(.location(.startRoom))
        )

        let game = MinimalGame(items: wall)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("kick wall")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > kick wall
            Ouch! You hurt your foot kicking the wall.
            """)
    }

    @Test("Kick updates state correctly")
    func testKickUpdatesStateCorrectly() async throws {
        // Given
        let rock = Item(
            id: "rock",
            .name("rock"),
            .in(.location(.startRoom))
        )

        let game = MinimalGame(items: rock)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("kick rock")

        // Then - Check state was updated
        let finalRock = try await engine.item("rock")
        #expect(finalRock.hasFlag(.isTouched))

        let output = await mockIO.flush()
        expectNoDifference(output, """
            > kick rock
            Ouch! You hurt your foot kicking the rock.
            """)
    }
}
