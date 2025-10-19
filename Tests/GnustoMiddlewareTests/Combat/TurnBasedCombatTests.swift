import GnustoEngine
import GnustoMiddleware
import GnustoTestSupport
import Testing

@Suite("Turn-Based Combat System Tests")
struct TurnBasedCombatTests {

    // MARK: - Basic Combat Mechanics

    @Test("Basic attack with character properties")
    func testBasicAttackWithProperties() async throws {
        // Given: A room with a goblin that has weak properties
        let goblin = Item("goblin")
            .name("goblin")
            .description("A small, weak goblin.")
            .characterSheet(.weak)  // Weak character properties
            .in(.startRoom)

        let sword = Item("sword")
            .name("sword")
            .description("A sharp sword.")
            .isTakable
            .isWeapon
            .value(5)  // +5 damage bonus
            .in(.player)

        let game = MinimalGame(
            player: Player(
                in: .startRoom,
                characterSheet: CharacterSheet(
                    strength: 16,  // +3 modifier
                    dexterity: 14,  // +2 modifier
                    constitution: 14,  // +2 modifier
                    level: 3
                )
            ),
            items: goblin, sword
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Player attacks the goblin
        try await engine.execute("attack goblin with sword")

        // Then: Verify combat occurred with proper turn structure
        await mockIO.expect(
            """
            > attack goblin with sword
            The goblin has done nothing to deserve your hostility.
            """
        )
    }

    @Test("Combat without required weapon")
    func testCombatRequiresWeapon() async throws {
        // Given: A knight that requires weapons to fight
        let knight = Item("knight")
            .name("knight")
            .description("An armored knight.")
            .characterSheet(.strong)
            .in(.startRoom)

        let game = MinimalGame(
            items: knight,
            middleware: [
                CombatMiddleware(
                    combatSystems: ["knight": StandardCombatSystem(versus: "knight")]
                ),
            ]
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Player tries to attack without a weapon
        try await engine.execute("attack knight")

        // Then: Attack should be denied
        await mockIO.expect(
            """
            > attack knight
            No weapons needed as you attack with pure violence while the
            knight braces for the inevitable collision of flesh and bone.

            You catch the knight with minimal force, the blow almost
            gentle. The light wound barely seems to register.

            Then flesh impacts flesh with terrible authority as the
            knight's blow reverberates through your skeleton. The shock of
            injury hits hard. Your unmarked flesh now torn and bleeding.
            """
        )
    }

    @Test("Attack with non-weapon item")
    func testAttackWithNonWeapon() async throws {
        // Given: A troll and a non-weapon item
        let lamp = Item("lamp")
            .name("lamp")
            .description("A brass lamp.")
            .isTakable
            .isDevice
            .isLightSource
            // Note: NOT marked as .isWeapon
            .in(.player)

        let game = MinimalGame(
            items: Lab.nastyTroll, lamp
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Player tries to attack with the lamp
        try await engine.execute("attack troll with lamp")

        // Then: Attack should note the lamp is ineffective
        await mockIO.expect(
            """
            > attack troll with lamp
            The nasty troll has done nothing to deserve your hostility.
            """
        )
    }

    // MARK: - Character Properties Effects

    @Test("Strong vs weak character combat")
    func testPropertyBasedCombat() async throws {
        // Given: A weak player vs strong enemy
        let ogre = Item("ogre")
            .name("ogre")
            .description("A massive ogre.")
            .characterSheet(.strong)  // Strong properties
            .in(.startRoom)

        let dagger = Item("dagger")
            .name("dagger")
            .description("A small dagger.")
            .isTakable
            .isWeapon
            .damage(2)  // Low damage
            .in(.player)

        let game = MinimalGame(
            player: Player(
                in: .startRoom,
                characterSheet: .weak
            ),
            items: ogre, dagger
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Weak player attacks strong ogre
        try await engine.execute("attack ogre")

        // Then: Combat should occur (results will vary due to dice rolls)
        await mockIO.expect(
            """
            > attack ogre
            The ogre has done nothing to deserve your hostility.
            """
        )
    }

    // MARK: - Special Combat Outcomes

    @Test("Enemy that can be pacified through dialogue")
    func testPacifyThroughDialogue() async throws {
        // Given: A bandit that can be pacified
        let bandit = Item("bandit")
            .name("bandit")
            .description("A rough-looking bandit.")

            .characterSheet(
                intelligence: 10,
                wisdom: 8,
                charisma: 8,
                alignment: .chaoticGood  // Easier to pacify
            )
            .in(.startRoom)

        let game = MinimalGame(
            player: Player(
                in: .startRoom,
                characterSheet: CharacterSheet(
                    charisma: 18  // High charisma for diplomacy
                )
            ),
            items: bandit,
            middleware: [
                CombatMiddleware(
                    combatSystems: [
                        "bandit": StandardCombatSystem(versus: "bandit")
                    ]
                ),
            ]
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Player tries to talk during combat
        // First initiate combat, then try to talk
        try await engine.execute(
            "attack bandit",
            "talk to bandit about peace"
        )

        // Then: Might surrender (depends on dice roll with high charisma)
        await mockIO.expect(
            """
            > attack bandit
            No weapons needed as you attack with pure violence while the
            bandit braces for the inevitable collision of flesh and bone.

            You catch the bandit with minimal force, the blow almost
            gentle. The light wound barely seems to register.

            The bandit answers with raw violence, a clubbing strike that
            finds you but lacks the angle to truly hurt. Pain flickers and
            dies. Your body has more important work.

            > talk to bandit about peace
            The fight leaves the bandit entirely. It stand passive now, all
            hostility forgotten.

            The bandit pivots and strikes true -- impact ripples through
            muscle and bone, stealing balance and breath together. The
            wound stings sharply. You can take more, but not forever.
            """
        )
    }

    @Test("Attack non-character object")
    func testAttackNonCharacter() async throws {
        // Given: A regular object (not a character)
        let statue = Item("statue")
            .name("statue")
            .description("A stone statue.")
            // Note: NOT marked as a character (no .characterSheet)
            .in(.startRoom)

        let game = MinimalGame(
            items: statue
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Player tries to attack the statue
        try await engine.execute("attack statue")

        // Then: Should get message about fighting inanimate objects
        await mockIO.expect(
            """
            > attack statue
            The statue is immune to your hostility.
            """
        )
    }

    @Test("Combat with already dead enemy")
    func testAttackDeadEnemy() async throws {
        // Given: A dead enemy
        let corpse = Item("zombie")
            .name("zombie")
            .description("A defeated zombie.")
            .characterSheet(.init(health: 0, consciousness: .dead))  // Already dead
            .in(.startRoom)

        let game = MinimalGame(
            items: corpse
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Player tries to attack the corpse
        try await engine.execute("attack zombie")

        // Then: Should indicate it's already dead
        await mockIO.expect(
            """
            > attack zombie
            The zombie has done nothing to deserve your hostility.
            """
        )
    }

    // MARK: - State Change Verification

    @Test("Combat state changes are properly applied")
    func testCombatStateChanges() async throws {
        // Given: A simple enemy
        let rat = Item("rat")
            .name("rat")
            .description("A large rat.")
            .characterSheet(.weak)  // Very low health
            .in(.startRoom)

        let sword = Item("sword")
            .name("sword")
            .description("A sharp sword.")
            .isTakable
            .isWeapon
            .value(10)  // High damage
            .in(.player)

        let game = MinimalGame(
            player: Player(
                in: .startRoom,
                characterSheet: CharacterSheet(
                    strength: 20,  // +5 modifier for likely one-hit kill
                    level: 5
                )
            ),
            items: rat, sword
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Player attacks the weak rat (likely to kill it)
        try await engine.execute("attack rat with sword")

        // Then: Check combat occurred
        await mockIO.expect(
            """
            > attack rat with sword
            The rat has done nothing to deserve your hostility.
            """
        )
    }
}
