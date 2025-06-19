import CustomDump
import Testing

@testable import GnustoEngine

@Suite("AttackActionHandler Tests")
struct AttackActionHandlerTests {
    let handler = AttackActionHandler()

    @Test("Attack validates missing direct object")
    func testAttackValidatesMissingDirectObject() async throws {
        // Given
        let (engine, mockIO) = await GameEngine.test()

        let command = Command(
            verb: .attack,
            rawInput: "attack"
        )
        let context = ActionContext(command: command, engine: engine)

        // When / Then
        await #expect(throws: ActionResponse.prerequisiteNotMet("Attack what?")) {
            try await handler.validate(context: context)
        }
    }

    @Test("Attack validates item not found")
    func testAttackValidatesItemNotFound() async throws {
        // Given
        let (engine, mockIO) = await GameEngine.test()

        let command = Command(
            verb: .attack,
            directObject: .item("nonexistent"),
            rawInput: "attack nonexistent"
        )
        let context = ActionContext(command: command, engine: engine)

        // When / Then
        await #expect(throws: ActionResponse.itemNotAccessible("nonexistent")) {
            try await handler.validate(context: context)
        }
    }

    @Test("Attack validates item not reachable")
    func testAttackValidatesItemNotReachable() async throws {
        // Given
        let distantGoblin = Item(
            id: "distant_goblin",
            .name("distant goblin"),
            .in(.nowhere),
            .isCharacter
        )

        let game = MinimalGame(items: [distantGoblin])
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        let command = Command(
            verb: .attack,
            directObject: .item("distant_goblin"),
            rawInput: "attack distant goblin"
        )
        let context = ActionContext(command: command, engine: engine)

        // When / Then
        await #expect(throws: ActionResponse.itemNotAccessible("distant_goblin")) {
            try await handler.validate(context: context)
        }
    }

    @Test("Attack with weapon validates weapon not held")
    func testAttackWithWeaponValidatesWeaponNotHeld() async throws {
        // Given
        let goblin = Item(
            id: "goblin",
            .name("goblin"),
            .in(.location(.startRoom)),
            .isCharacter
        )

        let sword = Item(
            id: "sword",
            .name("sword"),
            .in(.location(.startRoom)),
            .isWeapon
        )

        let game = MinimalGame(items: [goblin, sword])
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        let command = Command(
            verb: .attack,
            directObject: .item("goblin"),
            indirectObject: .item("sword"),
            rawInput: "attack goblin with sword"
        )
        let context = ActionContext(command: command, engine: engine)

        // When / Then
        await #expect(throws: ActionResponse.itemNotHeld("sword")) {
            try await handler.validate(context: context)
        }
    }

    @Test("Attack non-character object")
    func testAttackNonCharacterObject() async throws {
        // Given
        let rock = Item(
            id: "rock",
            .name("rock"),
            .in(.location(.startRoom))
        )

        let game = MinimalGame(items: [rock])
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        let command = Command(
            verb: .attack,
            directObject: .item("rock"),
            rawInput: "attack rock"
        )
        let context = ActionContext(command: command, engine: engine)

        // When
        let result = try await handler.process(context: context)

        // Then
        #expect(result.message!.contains("I've known strange people, but fighting a rock?"))
    }

    @Test("Attack character with bare hands")
    func testAttackCharacterWithBareHands() async throws {
        // Given
        let goblin = Item(
            id: "goblin",
            .name("goblin"),
            .in(.location(.startRoom)),
            .isCharacter
        )

        let game = MinimalGame(items: [goblin])
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        let command = Command(
            verb: .attack,
            directObject: .item("goblin"),
            rawInput: "attack goblin"
        )
        let context = ActionContext(command: command, engine: engine)

        // When
        let result = try await handler.process(context: context)

        // Then
        #expect(result.message!.contains("Trying to attack a goblin with your bare hands is suicidal."))
    }

    @Test("Attack character with weapon")
    func testAttackCharacterWithWeapon() async throws {
        // Given
        let goblin = Item(
            id: "goblin",
            .name("goblin"),
            .in(.location(.startRoom)),
            .isCharacter
        )

        let sword = Item(
            id: "sword",
            .name("sword"),
            .in(.player),
            .isWeapon
        )

        let game = MinimalGame(items: [goblin, sword])
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        let command = Command(
            verb: .attack,
            directObject: .item("goblin"),
            indirectObject: .item("sword"),
            rawInput: "attack goblin with sword"
        )
        let context = ActionContext(command: command, engine: engine)

        // When
        let result = try await handler.process(context: context)

        // Then
        #expect(result.message!.contains("Let's hope it doesn't come to that."))
    }

    @Test("Attack character with inappropriate weapon")
    func testAttackCharacterWithInappropriateWeapon() async throws {
        // Given
        let goblin = Item(
            id: "goblin",
            .name("goblin"),
            .in(.location(.startRoom)),
            .isCharacter
        )

        let lamp = Item(
            id: "lamp",
            .name("lamp"),
            .in(.player)
        )

        let game = MinimalGame(items: [goblin, lamp])
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        let command = Command(
            verb: .attack,
            directObject: .item("goblin"),
            indirectObject: .item("lamp"),
            rawInput: "attack goblin with lamp"
        )
        let context = ActionContext(command: command, engine: engine)

        // When
        let result = try await handler.process(context: context)

        // Then
        #expect(result.message!.contains("Trying to attack the goblin with a lamp is suicidal."))
    }

    @Test("Attack updates state correctly")
    func testAttackUpdatesStateCorrectly() async throws {
        // Given
        let goblin = Item(
            id: "goblin",
            .name("goblin"),
            .in(.location(.startRoom)),
            .isCharacter
        )

        let game = MinimalGame(items: [goblin])
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        let command = Command(
            verb: .attack,
            directObject: .item("goblin"),
            rawInput: "attack goblin"
        )
        let context = ActionContext(command: command, engine: engine)

        // When
        let result = try await handler.process(context: context)

        // Then
        #expect(result.changes.count >= 1)

        // Find the state change that marks the goblin as touched
        let touchedStateChange = result.changes.first { change in
            change.attribute == .itemAttribute(.isTouched)
        }
        #expect(touchedStateChange != nil)
    }
}
