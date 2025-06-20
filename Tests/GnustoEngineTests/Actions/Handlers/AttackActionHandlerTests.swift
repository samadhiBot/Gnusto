import CustomDump
import Testing

@testable import GnustoEngine

@Suite("AttackActionHandler Tests")
struct AttackActionHandlerTests {

    @Test("Attack validates missing direct object")
    func testAttackValidatesMissingDirectObject() async throws {
        // Given
        let (engine, mockIO) = await GameEngine.test()

        // When / Then
        try await engine.execute("attack")

        let output = await mockIO.flush()
        expectNoDifference(output, """
            > attack
            Attack what?
            """)
    }

    @Test("Attack validates item not found")
    func testAttackValidatesItemNotFound() async throws {
        // Given
        let (engine, mockIO) = await GameEngine.test()

        // When / Then
        try await engine.execute("attack nonexistent")

        let output = await mockIO.flush()
        expectNoDifference(output, """
            > attack nonexistent
            You can’t see any such thing.
            """)
    }

    @Test("Attack validates unknown (not yet met) item not reachable")
    func testAttackValidatesUnknownItemNotReachable() async throws {
        // Given
        let distantGoblin = Item(
            id: "distantGoblin",
            .name("distant goblin"),
            .synonyms("goblin"),
            .in(.nowhere),
            .isCharacter
        )

        let game = MinimalGame(items: distantGoblin)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When / Then
        try await engine.execute("attack the goblin")

        let output = await mockIO.flush()
        expectNoDifference(output, """
            > attack the goblin
            You can’t see any such thing.
            """)
    }

    @Test("Attack validates item met but not reachable")
    func testAttackValidatesItemMetButNotReachable() async throws {
        // Given
        let here = Location(
            id: "startRoom",
            .inherentlyLit
        )
        let distantLand = Location(
            id: "distantLand",
            .inherentlyLit
        )
        let distantGoblin = Item(
            id: "distantGoblin",
            .name("distant goblin"),
            .synonyms("goblin"),
            .in(.location("distantLand")),
            .isCharacter,
            .isTouched
        )

        let game = MinimalGame(
            locations: here, distantLand,
            items: distantGoblin
        )
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When / Then
        try await engine.execute("attack the goblin")

        let output = await mockIO.flush()
        expectNoDifference(output, """
            > attack the goblin
            You can’t see the distant goblin.
            """)
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

        let game = MinimalGame(items: goblin, sword)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When / Then
        try await engine.execute("attack goblin with sword")

        let output = await mockIO.flush()
        expectNoDifference(output, """
            > attack goblin with sword
            You aren’t holding the sword.
            """)
    }

    @Test("Attack non-character object")
    func testAttackNonCharacterObject() async throws {
        // Given
        let rock = Item(
            id: "rock",
            .name("rock"),
            .in(.location(.startRoom))
        )

        let game = MinimalGame(items: rock)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("attack rock")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > attack rock
            I’ve known strange people, but fighting a rock?
            """)
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

        let game = MinimalGame(items: goblin)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("attack goblin")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > attack goblin
            Trying to attack a goblin with your bare hands is suicidal.
            """)
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

        let game = MinimalGame(items: goblin, sword)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("attack goblin with sword")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > attack goblin with sword
            Let’s hope it doesn’t come to that.
            """)
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

        let feather = Item(
            id: "feather",
            .name("feather"),
            .in(.player),
            .isTakable
        )

        let game = MinimalGame(items: goblin, feather)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("attack goblin with feather")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > attack goblin with feather
            Trying to attack the goblin with a feather is suicidal.
            """)
    }
}
