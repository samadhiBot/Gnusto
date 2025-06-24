import Testing
import CustomDump
@testable import GnustoEngine

@Suite("AttackActionHandler Tests")
struct AttackActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("ATTACK DIRECTOBJECT syntax works")
    func testAttackDirectObjectSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .description("A room for testing."),
            .inherentlyLit
        )

        let troll = Item(
            id: "troll",
            .name("fierce troll"),
            .description("A fierce troll blocking your way."),
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
        try await engine.execute("attack troll")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > attack troll
            Trying to attack a fierce troll with your bare hands is suicidal.
            """)

        let finalState = try await engine.item("troll")
        #expect(finalState.hasFlag(.isTouched) == true)
    }

    @Test("ATTACK DIRECTOBJECT WITH INDIRECTOBJECT syntax works")
    func testAttackWithWeaponSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let dragon = Item(
            id: "dragon",
            .name("red dragon"),
            .description("A fearsome red dragon."),
            .isCharacter,
            .in(.location("testRoom"))
        )

        let sword = Item(
            id: "sword",
            .name("steel sword"),
            .description("A sharp steel sword."),
            .isWeapon,
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: dragon, sword
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("attack dragon with sword")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > attack dragon with sword
            You can't.
            """)
    }

    @Test("FIGHT syntax works")
    func testFightSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let orc = Item(
            id: "orc",
            .name("angry orc"),
            .description("An angry orc warrior."),
            .isCharacter,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: orc
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("fight orc")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > fight orc
            Trying to attack an angry orc with your bare hands is suicidal.
            """)
    }

    @Test("HIT syntax works")
    func testHitSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let goblin = Item(
            id: "goblin",
            .name("sneaky goblin"),
            .description("A sneaky goblin."),
            .isCharacter,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: goblin
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("hit goblin")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > hit goblin
            Trying to attack a sneaky goblin with your bare hands is suicidal.
            """)
    }

    @Test("KILL syntax works")
    func testKillSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let spider = Item(
            id: "spider",
            .name("giant spider"),
            .description("A giant spider."),
            .isCharacter,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: spider
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("kill spider")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > kill spider
            Trying to attack a giant spider with your bare hands is suicidal.
            """)
    }

    // MARK: - Validation Testing

    @Test("Cannot attack without specifying target")
    func testCannotAttackWithoutTarget() async throws {
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
        try await engine.execute("attack")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > attack
            What do you want to attack?
            """)
    }

    @Test("Cannot attack target not in scope")
    func testCannotAttackTargetNotInScope() async throws {
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

        let remoteTroll = Item(
            id: "remoteTroll",
            .name("remote troll"),
            .description("A troll in another room."),
            .isCharacter,
            .in(.location("anotherRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom, anotherRoom,
            items: remoteTroll
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("attack troll")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > attack troll
            You can't see any such thing.
            """)
    }

    @Test("Cannot attack with weapon not held")
    func testCannotAttackWithWeaponNotHeld() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let troll = Item(
            id: "troll",
            .name("fierce troll"),
            .description("A fierce troll."),
            .isCharacter,
            .in(.location("testRoom"))
        )

        let sword = Item(
            id: "sword",
            .name("steel sword"),
            .description("A sharp steel sword."),
            .isWeapon,
            .isTakable,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: troll, sword
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("attack troll with sword")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > attack troll with sword
            You aren't holding the steel sword.
            """)
    }

    @Test("Requires light to attack")
    func testRequiresLight() async throws {
        // Given: Dark room with character
        let darkRoom = Location(
            id: "darkRoom",
            .name("Dark Room"),
            .description("A pitch black room.")
            // Note: No .inherentlyLit property
        )

        let troll = Item(
            id: "troll",
            .name("fierce troll"),
            .description("A fierce troll."),
            .isCharacter,
            .in(.location("darkRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom,
            items: troll
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("attack troll")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > attack troll
            It is pitch black. You can't see a thing.
            """)
    }

    // MARK: - Processing Testing

    @Test("Attack non-character gives appropriate message")
    func testAttackNonCharacter() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let rock = Item(
            id: "rock",
            .name("large rock"),
            .description("A large boulder."),
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: rock
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("attack rock")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > attack rock
            I've known strange people, but fighting a large rock?
            """)

        let finalState = try await engine.item("rock")
        #expect(finalState.hasFlag(.isTouched) == true)
    }

    @Test("Attack character bare-handed")
    func testAttackCharacterBareHanded() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let warrior = Item(
            id: "warrior",
            .name("skilled warrior"),
            .description("A skilled warrior."),
            .isCharacter,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: warrior
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("attack warrior")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > attack warrior
            Trying to attack a skilled warrior with your bare hands is suicidal.
            """)

        let finalState = try await engine.item("warrior")
        #expect(finalState.hasFlag(.isTouched) == true)
    }

    @Test("Attack character with non-weapon")
    func testAttackCharacterWithNonWeapon() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let bandit = Item(
            id: "bandit",
            .name("dangerous bandit"),
            .description("A dangerous bandit."),
            .isCharacter,
            .in(.location("testRoom"))
        )

        let stick = Item(
            id: "stick",
            .name("wooden stick"),
            .description("A simple wooden stick."),
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: bandit, stick
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("attack bandit with stick")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > attack bandit with stick
            Trying to attack the dangerous bandit with a wooden stick is suicidal.
            """)
    }

    @Test("Attack character with weapon")
    func testAttackCharacterWithWeapon() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let monster = Item(
            id: "monster",
            .name("evil monster"),
            .description("An evil monster."),
            .isCharacter,
            .in(.location("testRoom"))
        )

        let dagger = Item(
            id: "dagger",
            .name("sharp dagger"),
            .description("A sharp dagger."),
            .isWeapon,
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: monster, dagger
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("attack monster with dagger")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > attack monster with dagger
            You can't.
            """)

        let finalState = try await engine.item("monster")
        #expect(finalState.hasFlag(.isTouched) == true)
    }

    // MARK: - ActionID Testing

    @Test("Handler exposes correct ActionIDs")
    func testActionIDs() async throws {
        let handler = AttackActionHandler()
        // AttackActionHandler doesn't specify actions, so it should be empty
        #expect(handler.actions.isEmpty)
    }

    @Test("Handler exposes correct VerbIDs")
    func testVerbIDs() async throws {
        let handler = AttackActionHandler()
        #expect(handler.verbs.contains(.attack))
        #expect(handler.verbs.contains(.fight))
        #expect(handler.verbs.contains(.hit))
        #expect(handler.verbs.contains(.kill))
        #expect(handler.verbs.contains(.slay))
        #expect(handler.verbs.contains(.stab))
        #expect(handler.verbs.count == 6)
    }

    @Test("Handler requires light")
    func testRequiresLightProperty() async throws {
        let handler = AttackActionHandler()
        #expect(handler.requiresLight == true)
    }
}
