import CustomDump
import Testing

@testable import GnustoEngine

@Suite("KickActionHandler Tests")
struct KickActionHandlerTests {
    let handler = KickActionHandler()

    @Test("Kick validates missing direct object")
    func testKickValidatesMissingDirectObject() async throws {
        // Given
        let (engine, _) = await GameEngine.test()

        let command = Command(verb: .kick, rawInput: "kick")
        let context = ActionContext(command: command, engine: engine)

        // When / Then
        await #expect(throws: ActionResponse.prerequisiteNotMet("Kick what?")) {
            try await handler.validate(context: context)
        }
    }

    @Test("Kick validates item not found")
    func testKickValidatesItemNotFound() async throws {
        // Given
        let (engine, _) = await GameEngine.test()

        let command = Command(verb: .kick, directObject: .item("nonexistent"), rawInput: "kick nonexistent")
        let context = ActionContext(command: command, engine: engine)

        // When / Then
        await #expect(throws: ActionResponse.itemNotAccessible("nonexistent")) {
            try await handler.validate(context: context)
        }
    }

    @Test("Kick validates item not reachable")
    func testKickValidatesItemNotReachable() async throws {
        // Given
        let distantRock = Item(
            id: "distant_rock",
            .name("distant rock"),
            .in(.nowhere)
        )

        let game = MinimalGame(items: [distantRock])
        let (engine, _) = await GameEngine.test(blueprint: game)

        let command = Command(verb: .kick, directObject: .item("distant_rock"), rawInput: "kick distant rock")
        let context = ActionContext(command: command, engine: engine)

        // When / Then
        await #expect(throws: ActionResponse.itemNotAccessible("distant_rock")) {
            try await handler.validate(context: context)
        }
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

        let game = MinimalGame(items: [goblin])
        let (engine, _) = await GameEngine.test(blueprint: game)

        let command = Command(verb: .kick, directObject: .item("goblin"), rawInput: "kick goblin")
        let context = ActionContext(command: command, engine: engine)

        // When
        let result = try await handler.process(context: context)

        // Then
        #expect(result.message!.contains("I don't think the goblin would appreciate that."))
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

        let game = MinimalGame(items: [ball])
        let (engine, _) = await GameEngine.test(blueprint: game)

        let command = Command(verb: .kick, directObject: .item("ball"), rawInput: "kick ball")
        let context = ActionContext(command: command, engine: engine)

        // When
        let result = try await handler.process(context: context)

        // Then
        #expect(result.message!.contains("Ouch! You hurt your foot kicking the ball."))
    }

    @Test("Kick fixed object shows hurt foot message")
    func testKickFixedObjectShowsHurtFootMessage() async throws {
        // Given
        let wall = Item(
            id: "wall",
            .name("wall"),
            .in(.location(.startRoom))
        )

        let game = MinimalGame(items: [wall])
        let (engine, _) = await GameEngine.test(blueprint: game)

        let command = Command(verb: .kick, directObject: .item("wall"), rawInput: "kick wall")
        let context = ActionContext(command: command, engine: engine)

        // When
        let result = try await handler.process(context: context)

        // Then
        #expect(result.message!.contains("Ouch! You hurt your foot kicking the wall."))
    }

    @Test("Kick updates state correctly")
    func testKickUpdatesStateCorrectly() async throws {
        // Given
        let rock = Item(
            id: "rock",
            .name("rock"),
            .in(.location(.startRoom))
        )

        let game = MinimalGame(items: [rock])
        let (engine, _) = await GameEngine.test(blueprint: game)

        let command = Command(verb: .kick, directObject: .item("rock"), rawInput: "kick rock")
        let context = ActionContext(command: command, engine: engine)

        // When
        let result = try await handler.process(context: context)

        // Then
        #expect(result.changes.count >= 1)

        // Should have touched the item
        let hasTouchedChange = result.changes.contains(where: { change in
            change.entityID == .item("rock") &&
            change.attribute == .itemAttribute(.isTouched) &&
            change.newValue == true
        })
        #expect(hasTouchedChange)
    }

    @Test("Kick integration test")
    func testKickIntegrationTest() async throws {
        // Given
        let box = Item(
            id: "box",
            .name("box"),
            .in(.location(.startRoom)),
            .isTakable
        )

        let game = MinimalGame(items: [box])
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        let command = Command(verb: .kick, directObject: .item("box"), rawInput: "kick box")

        // When
        await engine.execute(command: command)

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, "Ouch! You hurt your foot kicking the box.")
    }
}
