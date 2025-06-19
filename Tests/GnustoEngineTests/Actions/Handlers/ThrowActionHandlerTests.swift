import CustomDump
import Testing

@testable import GnustoEngine

@Suite("ThrowActionHandler Tests")
struct ThrowActionHandlerTests {
    let handler = ThrowActionHandler()

    @Test("Throw validates missing direct object")
    func testThrowValidatesMissingDirectObject() async throws {
        // Given
        let mockParser = MockParser()
        let (engine, mockIO) = await GameEngine.test(blueprint: game, parser: mockParser, ioHandler: mockIO)

        let command = Command(verb: .throwItem, rawInput: "throw")
        let context = ActionContext(command: command, engine: engine)

        // When / Then
        await #expect(throws: ActionResponse.prerequisiteNotMet("Throw what?")) {
            try await handler.validate(context: context)
        }
    }

    @Test("Throw validates item not held")
    func testThrowValidatesItemNotHeld() async throws {
        // Given
        let rock = Item(
            id: "rock",
            .name("rock"),
            .in(.location(.startRoom))
        )

        let game = MinimalGame(items: [rock])
        let mockParser = MockParser()
        let (engine, mockIO) = await GameEngine.test(blueprint: game, parser: mockParser, ioHandler: mockIO)

        let command = Command(verb: .throwItem, directObject: .item("rock"), rawInput: "throw rock")
        let context = ActionContext(command: command, engine: engine)

        // When / Then
        await #expect(throws: ActionResponse.itemNotHeld("rock")) {
            try await handler.validate(context: context)
        }
    }

    @Test("Throw validates target exists when specified")
    func testThrowValidatesTargetExistsWhenSpecified() async throws {
        // Given
        let ball = Item(
            id: "ball",
            .name("ball"),
            .in(.player)
        )

        let game = MinimalGame(items: [ball])
        let mockParser = MockParser()
        let (engine, mockIO) = await GameEngine.test(blueprint: game, parser: mockParser, ioHandler: mockIO)

        let command = Command(
            verb: .throwItem,
            directObject: .item("ball"),
            indirectObject: .item("nonexistent"),
            rawInput: "throw ball at nonexistent"
        )
        let context = ActionContext(command: command, engine: engine)

        // When / Then
        await #expect(throws: ActionResponse.itemNotAccessible("nonexistent")) {
            try await handler.validate(context: context)
        }
    }

    @Test("Throw validates target reachable when specified")
    func testThrowValidatesTargetReachableWhenSpecified() async throws {
        // Given
        let ball = Item(
            id: "ball",
            .name("ball"),
            .in(.player)
        )

        let distantTarget = Item(
            id: "distant_target",
            .name("target"),
            .in(.location("faraway"))
        )

        let game = MinimalGame(items: [ball, distantTarget])
        let mockParser = MockParser()
        let (engine, mockIO) = await GameEngine.test(blueprint: game, parser: mockParser, ioHandler: mockIO)

        let command = Command(
            verb: .throwItem,
            directObject: .item("ball"),
            indirectObject: .item("distant_target"),
            rawInput: "throw ball at target"
        )
        let context = ActionContext(command: command, engine: engine)

        // When / Then
        await #expect(throws: ActionResponse.itemNotAccessible("distant_target")) {
            try await handler.validate(context: context)
        }
    }

    @Test("Throw passes validation for held item")
    func testThrowPassesValidationForHeldItem() async throws {
        // Given
        let ball = Item(
            id: "ball",
            .name("ball"),
            .in(.player)
        )

        let game = MinimalGame(items: [ball])
        let mockParser = MockParser()
        let (engine, mockIO) = await GameEngine.test(blueprint: game, parser: mockParser, ioHandler: mockIO)

        let command = Command(verb: .throwItem, directObject: .item("ball"), rawInput: "throw ball")
        let context = ActionContext(command: command, engine: engine)

        // When / Then - Should not throw
        try await handler.validate(context: context)
    }

    @Test("Throw passes validation for held item with reachable target")
    func testThrowPassesValidationForHeldItemWithReachableTarget() async throws {
        // Given
        let ball = Item(
            id: "ball",
            .name("ball"),
            .in(.player)
        )

        let target = Item(
            id: "target",
            .name("target"),
            .in(.location(.startRoom))
        )

        let game = MinimalGame(items: [ball, target])
        let mockParser = MockParser()
        let (engine, mockIO) = await GameEngine.test(blueprint: game, parser: mockParser, ioHandler: mockIO)

        let command = Command(
            verb: .throwItem,
            directObject: .item("ball"),
            indirectObject: .item("target"),
            rawInput: "throw ball at target"
        )
        let context = ActionContext(command: command, engine: engine)

        // When / Then - Should not throw
        try await handler.validate(context: context)
    }

    @Test("Throw item without target")
    func testThrowItemWithoutTarget() async throws {
        // Given
        let ball = Item(
            id: "ball",
            .name("ball"),
            .in(.player)
        )

        let game = MinimalGame(items: [ball])
        let mockParser = MockParser()
        let (engine, mockIO) = await GameEngine.test(blueprint: game, parser: mockParser, ioHandler: mockIO)

        let command = Command(verb: .throwItem, directObject: .item("ball"), rawInput: "throw ball")
        let context = ActionContext(command: command, engine: engine)

        // When
        let result = try await handler.process(context: context)

        // Then
        #expect(result.message!.contains("You throw the ball, and it falls to the ground."))
    }

    @Test("Throw item at target")
    func testThrowItemAtTarget() async throws {
        // Given
        let ball = Item(
            id: "ball",
            .name("ball"),
            .in(.player)
        )

        let wall = Item(
            id: "wall",
            .name("wall"),
            .in(.location(.startRoom))
        )

        let game = MinimalGame(items: [ball, wall])
        let mockParser = MockParser()
        let (engine, mockIO) = await GameEngine.test(blueprint: game, parser: mockParser, ioHandler: mockIO)

        let command = Command(
            verb: .throwItem,
            directObject: .item("ball"),
            indirectObject: .item("wall"),
            rawInput: "throw ball at wall"
        )
        let context = ActionContext(command: command, engine: engine)

        // When
        let result = try await handler.process(context: context)

        // Then
        #expect(result.message!.contains("You throw the ball at the wall. It bounces off harmlessly."))
    }

    @Test("Throw item at character")
    func testThrowItemAtCharacter() async throws {
        // Given
        let ball = Item(
            id: "ball",
            .name("ball"),
            .in(.player)
        )

        let troll = Item(
            id: "troll",
            .name("troll"),
            .in(.location(.startRoom)),
            .isCharacter
        )

        let game = MinimalGame(items: [ball, troll])
        let mockParser = MockParser()
        let (engine, mockIO) = await GameEngine.test(blueprint: game, parser: mockParser, ioHandler: mockIO)

        let command = Command(
            verb: .throwItem,
            directObject: .item("ball"),
            indirectObject: .item("troll"),
            rawInput: "throw ball at troll"
        )
        let context = ActionContext(command: command, engine: engine)

        // When
        let result = try await handler.process(context: context)

        // Then
        #expect(result.message!.contains("You throw the ball at the troll."))
    }

    @Test("Throw weapon at character")
    func testThrowWeaponAtCharacter() async throws {
        // Given
        let knife = Item(
            id: "knife",
            .name("knife"),
            .in(.player),
            .isWeapon
        )

        let goblin = Item(
            id: "goblin",
            .name("goblin"),
            .in(.location(.startRoom)),
            .isCharacter
        )

        let game = MinimalGame(items: [knife, goblin])
        let mockParser = MockParser()
        let (engine, mockIO) = await GameEngine.test(blueprint: game, parser: mockParser, ioHandler: mockIO)

        let command = Command(
            verb: .throwItem,
            directObject: .item("knife"),
            indirectObject: .item("goblin"),
            rawInput: "throw knife at goblin"
        )
        let context = ActionContext(command: command, engine: engine)

        // When
        let result = try await handler.process(context: context)

        // Then
        #expect(result.message!.contains("You throw the knife at the goblin."))
    }

    @Test("Throw self reference")
    func testThrowSelfReference() async throws {
        // Given
        let mockParser = MockParser()
        let (engine, mockIO) = await GameEngine.test(blueprint: game, parser: mockParser, ioHandler: mockIO)

        let command = Command(
            verb: .throwItem,
            directObject: .player,
            rawInput: "throw me"
        )
        let context = ActionContext(command: command, engine: engine)

        // When
        let result = try await handler.process(context: context)

        // Then
        #expect(result.message!.contains("You can't throw yourself."))
    }

    @Test("Throw updates state correctly")
    func testThrowUpdatesStateCorrectly() async throws {
        // Given
        let ball = Item(
            id: "ball",
            .name("ball"),
            .in(.player)
        )

        let game = MinimalGame(items: [ball])
        let mockParser = MockParser()
        let (engine, mockIO) = await GameEngine.test(blueprint: game, parser: mockParser, ioHandler: mockIO)

        let command = Command(verb: .throwItem, directObject: .item("ball"), rawInput: "throw ball")
        let context = ActionContext(command: command, engine: engine)

        // When
        let result = try await handler.process(context: context)

        // Then
        #expect(result.changes.count >= 1)

        // Check that the ball was moved from player to current location
        let moveChange = result.changes.first { change in
            change.attribute == .itemParent
        }
        #expect(moveChange != nil)
    }
}
