import GnustoEngine
import GnustoTestSupport
import Testing

@Suite("AttackActionHandler Tests")
struct AttackActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("ATTACK DIRECTOBJECT syntax works")
    func testAttackDirectObjectSyntax() async throws {
        // Given
        let game = MinimalGame(
            items: Lab.nastyTroll, Lab.axe
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("attack the troll", times: 5)

        // Then
        await mockIO.expect(
            """
            > attack the troll
            The nasty troll has done nothing to deserve your hostility.

            > attack the troll
            Starting a fight with the nasty troll would be
            counterproductive to your goals.

            > attack the troll
            Starting a fight with the nasty troll would be
            counterproductive to your goals.

            > attack the troll
            Attacking the nasty troll would complicate matters
            considerably.

            > attack the troll
            The nasty troll has done nothing to deserve your hostility.
            """
        )
    }

    @Test("ATTACK DIRECTOBJECT WITH INDIRECTOBJECT syntax works")
    func testAttackWithWeaponSyntax() async throws {
        // Given
        let dragon = Item("dragon")
            .name("red dragon")
            .adjectives("terrible", "awesome", "fierce")
            .synonyms("creature", "wyrm")
            .description("A fearsome red dragon.")
            .characterSheet(.boss)
            .in(.startRoom)

        let sword = Item("sword")
            .name("steel sword")
            .description("A sharp steel sword.")
            .isWeapon
            .isTakable
            .in(.player)

        let game = MinimalGame(
            items: dragon, sword
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("attack dragon with sword", times: 3)

        // Then
        await mockIO.expect(
            """
            > attack dragon with sword
            The red dragon has done nothing to deserve your hostility.

            > attack dragon with sword
            Starting a fight with the red dragon would be counterproductive
            to your goals.

            > attack dragon with sword
            Starting a fight with the red dragon would be counterproductive
            to your goals.
            """
        )
    }

    @Test("FIGHT syntax works")
    func testFightSyntax() async throws {
        // Given
        let orc = Item("orc")
            .name("angry orc")
            .description("A mighty orc warrior.")
            .characterSheet(.strong)
            .in(.startRoom)

        let game = MinimalGame(
            items: orc
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("fight the orc", times: 3)

        // Then
        await mockIO.expect(
            """
            > fight the orc
            The angry orc has done nothing to deserve your hostility.

            > fight the orc
            Starting a fight with the angry orc would be counterproductive
            to your goals.

            > fight the orc
            Starting a fight with the angry orc would be counterproductive
            to your goals.
            """
        )
    }

    @Test("HIT syntax works")
    func testHitSyntax() async throws {
        // Given
        let goblin = Item("goblin")
            .name("sneaky goblin")
            .description("A sneaky goblin.")
            .characterSheet(.weak)
            .in(.startRoom)

        let game = MinimalGame(
            items: goblin
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("hit the goblin", times: 3)

        // Then
        await mockIO.expect(
            """
            > hit the goblin
            The sneaky goblin has done nothing to deserve your hostility.

            > hit the goblin
            Starting a fight with the sneaky goblin would be
            counterproductive to your goals.

            > hit the goblin
            Starting a fight with the sneaky goblin would be
            counterproductive to your goals.
            """
        )
    }

    @Test("KILL syntax works")
    func testKillSyntax() async throws {
        // Given
        let spider = Item("spider")
            .name("giant spider")
            .description("A giant spider.")
            .characterSheet(.default)
            .in(.startRoom)

        let game = MinimalGame(items: spider)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("kill the giant spider", times: 3)

        // Then
        await mockIO.expect(
            """
            > kill the giant spider
            The giant spider has done nothing to deserve your hostility.

            > kill the giant spider
            Starting a fight with the giant spider would be
            counterproductive to your goals.

            > kill the giant spider
            Starting a fight with the giant spider would be
            counterproductive to your goals.
            """
        )
    }

    // MARK: - Validation Testing

    @Test("Cannot attack without specifying target")
    func testCannotAttackWithoutTarget() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("attack")

        // Then
        await mockIO.expect(
            """
            > attack
            Attack what?
            """
        )
    }

    @Test("Cannot attack target not in scope")
    func testCannotAttackTargetNotInScope() async throws {
        // Given
        let anotherRoom = Location("anotherRoom")
            .name("Another Room")
            .inherentlyLit

        let remoteTroll = Item("remoteTroll")
            .name("remote troll")
            .description("A troll in another room.")
            .characterSheet(.default)
            .in("anotherRoom")

        let game = MinimalGame(
            locations: anotherRoom,
            items: remoteTroll
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("attack troll")

        // Then
        await mockIO.expect(
            """
            > attack troll
            You cannot reach any such thing from here.
            """
        )
    }

    @Test("Cannot attack with weapon not held")
    func testCannotAttackWithWeaponNotHeld() async throws {
        // Given
        let sword = Item("sword")
            .name("steel sword")
            .description("A sharp steel sword.")
            .isWeapon
            .isTakable
            .in(.startRoom)

        let game = MinimalGame(
            items: Lab.nastyTroll, sword
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("attack troll with sword")

        // Then
        await mockIO.expect(
            """
            > attack troll with sword
            The nasty troll has done nothing to deserve your hostility.
            """
        )
    }

    @Test("Requires light to attack")
    func testRequiresLight() async throws {
        // Given: Dark room with character
        let darkRoom = Location("darkRoom")
            .name("Dark Room")
            .description("A pitch black room.")
        // Note: No .inherentlyLit property

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom,
            items: Lab.nastyTroll
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("attack troll")

        // Then
        await mockIO.expect(
            """
            > attack troll
            The darkness here is absolute, consuming all light and hope of
            sight.
            """
        )
    }

    // MARK: - Processing Testing

    @Test("Attack non-character gives appropriate message")
    func testAttackNonCharacter() async throws {
        // Given
        let rock = Item("rock")
            .name("large rock")
            .description("A large boulder.")
            .in(.startRoom)

        let game = MinimalGame(
            items: rock
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("attack rock")

        // Then
        await mockIO.expect(
            """
            > attack rock
            The large rock is immune to your hostility.
            """
        )

        let finalState = await engine.item("rock")
        #expect(await finalState.hasFlag(.isTouched) == true)
    }

    @Test("Attack boss character bare-handed is denied")
    func testAttackBossCharacterBareHandedDenied() async throws {
        // Given
        let dragon = Item("dragon")
            .name("red dragon")
            .adjectives("terrible", "awesome", "fierce")
            .synonyms("creature", "wyrm")
            .description("A fearsome red dragon.")
            .characterSheet(.boss)
            .in(.startRoom)

        let game = MinimalGame(
            items: dragon
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("attack the dragon")

        // Then
        await mockIO.expect(
            """
            > attack the dragon
            The red dragon has done nothing to deserve your hostility.
            """
        )
    }

    @Test("Attack character with non-weapon")
    func testAttackCharacterWithNonWeapon() async throws {
        // Given
        let bandit = Item("bandit")
            .name("dangerous bandit")
            .description("A dangerous bandit.")
            .characterSheet(.default)
            .in(.startRoom)

        let stick = Item("stick")
            .name("wooden stick")
            .description("A simple wooden stick.")
            .isTakable
            .in(.player)

        let game = MinimalGame(
            items: bandit, stick
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("attack the bandit with a stick")

        // Then
        await mockIO.expect(
            """
            > attack the bandit with a stick
            The dangerous bandit has done nothing to deserve your
            hostility.
            """
        )
    }

    @Test("Attack character with weapon")
    func testAttackCharacterWithWeapon() async throws {
        // Given
        let monster = Item("monster")
            .name("evil monster")
            .description("An evil monster.")
            .characterSheet(.agile)
            .in(.startRoom)

        let dagger = Item("dagger")
            .name("sharp dagger")
            .description("A sharp dagger.")
            .isWeapon
            .isTakable
            .in(.player)

        let game = MinimalGame(
            items: monster, dagger
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("attack the monster with my dagger", times: 3)

        // Then
        await mockIO.expect(
            """
            > attack the monster with my dagger
            The evil monster has done nothing to deserve your hostility.

            > attack the monster with my dagger
            Starting a fight with the evil monster would be
            counterproductive to your goals.

            > attack the monster with my dagger
            Starting a fight with the evil monster would be
            counterproductive to your goals.
            """
        )
    }

    @Test("Attack enemy with weapon")
    func testAttackEnemyWithWeapon() async throws {
        // Given
        let monster = Item("monster")
            .name("evil monster")
            .description("An evil monster.")
            .characterSheet(.init(isFighting: true))
            .in(.startRoom)

        let dagger = Item("dagger")
            .name("sharp dagger")
            .description("A sharp dagger.")
            .isWeapon
            .isTakable
            .in(.player)

        let game = MinimalGame(
            items: monster, dagger
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute(
            "look",
            "attack the monster with my dagger"
        )

        // Then
        await mockIO.expect(
            """
            > look
            --- Laboratory ---

            A laboratory in which strange experiments are being conducted.

            There is an evil monster here.

            > attack the monster with my dagger
            Attacking the evil monster would complicate matters
            considerably.
            """
        )
    }

    @Test("Attack character with unspecified weapon")
    func testAttackCharacterWithUnspecifiedWeapon() async throws {
        // Given
        let monster = Item("monster")
            .name("evil monster")
            .description("An evil monster.")
            .characterSheet(.agile)
            .in(.startRoom)

        let dagger = Item("dagger")
            .name("sharp dagger")
            .description("A sharp dagger.")
            .isWeapon
            .isTakable
            .in(.player)

        let game = MinimalGame(
            items: monster, dagger
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("stab the monster", times: 3)

        // Then
        await mockIO.expect(
            """
            > stab the monster
            The evil monster has done nothing to deserve your hostility.

            > stab the monster
            Starting a fight with the evil monster would be
            counterproductive to your goals.

            > stab the monster
            Starting a fight with the evil monster would be
            counterproductive to your goals.
            """
        )
    }

    // MARK: - Intent Testing

    @Test("Handler exposes correct Verbs")
    func testVerbs() async throws {
        let handler = AttackActionHandler()
        #expect(
            handler.synonyms == [
                .attack, .break, .destroy, .fight, .hit, .kill, .rip,
                .ruin, .shatter, .slay, .smash, .stab, .tear,
            ]
        )
    }

    @Test("Handler requires light")
    func testRequiresLightProperty() async throws {
        let handler = AttackActionHandler()
        #expect(handler.requiresLight == true)
    }
}
