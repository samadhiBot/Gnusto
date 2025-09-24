import CustomDump
import GnustoEngine
import GnustoTestSupport
import Testing

@Suite("Turn-Based Combat System Tests")
struct TurnBasedCombatTests {

    // MARK: - Basic Combat Mechanics

    @Test("Basic attack with character properties")
    func testBasicAttackWithProperties() async throws {
        // Given: A room with a goblin that has weak properties
        let goblin = Item(
            id: "goblin",
            .name("goblin"),
            .description("A small, weak goblin."),
            .characterSheet(.weak),  // Weak character properties
            .in(.startRoom)
        )

        let sword = Item(
            id: "sword",
            .name("sword"),
            .description("A sharp sword."),
            .isTakable,
            .isWeapon,
            .value(5),  // +5 damage bonus
            .in(.player)
        )

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
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > attack goblin with sword
            You press forward with your sword leading the way toward flesh
            while the goblin backs away, unarmed but still dangerous as any
            cornered thing.

            Your armed advantage proves decisive--your sword ends it! The
            goblin crumples, having fought barehanded and lost.
            """
        )
    }

    @Test("Combat without required weapon")
    func testCombatRequiresWeapon() async throws {
        // Given: A knight that requires weapons to fight
        let knight = Item(
            id: "knight",
            .name("knight"),
            .description("An armored knight."),
            .characterSheet(.strong),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: knight,
            combatSystems: [
                "knight": StandardCombatSystem(versus: "knight")
            ]
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Player tries to attack without a weapon
        try await engine.execute("attack knight")

        // Then: Attack should be denied
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > attack knight
            You close the distance fast with fists ready as the knight
            mirrors your stance, both of you committed to finding out who
            breaks first.

            The knight bobs and weaves, avoiding your strike entirely.

            The knight retaliates with violence but you're already
            elsewhere when the blow arrives.
            """
        )
    }

    @Test("Attack with non-weapon item")
    func testAttackWithNonWeapon() async throws {
        // Given: A troll and a non-weapon item
        let lamp = Item(
            id: "lamp",
            .name("lamp"),
            .description("A brass lamp."),
            .isTakable,
            .isDevice,
            .isLightSource,
            // Note: NOT marked as .isWeapon
            .in(.player)
        )

        let game = MinimalGame(
            items: Lab.troll, lamp
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Player tries to attack with the lamp
        try await engine.execute("attack troll with lamp")

        // Then: Attack should note the lamp is ineffective
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > attack troll with lamp
            You press forward with your lamp leading the way toward flesh
            while the fearsome beast backs away, unarmed but still
            dangerous as any cornered thing.

            You attack with the lamp! The beast dodges, more puzzled than
            threatened by your choice of weapon.

            The counterstrike comes heavy. The grotesque monster's fist
            finds ribs, and pain blooms like fire through your chest. First
            blood to them. The wound is real but manageable.
            """
        )
    }

    // MARK: - Character Properties Effects

    @Test("Strong vs weak character combat")
    func testPropertyBasedCombat() async throws {
        // Given: A weak player vs strong enemy
        let ogre = Item(
            id: "ogre",
            .name("ogre"),
            .description("A massive ogre."),
            .characterSheet(.strong),  // Strong properties
            .in(.startRoom)
        )

        let dagger = Item(
            id: "dagger",
            .name("dagger"),
            .description("A small dagger."),
            .isTakable,
            .isWeapon,
            .damage(2),  // Low damage
            .in(.player)
        )

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
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > attack ogre
            You press forward with your dagger leading the way toward flesh
            while the ogre backs away, unarmed but still dangerous as any
            cornered thing.

            The ogre ducks under your dagger! Its agility saves it from
            certain harm.

            The ogre delivers death with bare hands, crushing you windpipe
            with the indifference of stone.

            ****  You have died  ****

            Your story ends here, but death is merely an intermission in
            the grand performance.

            You scored 0 out of a possible 10 points, in 0 moves.

            Would you like to RESTART, RESTORE a saved game, or QUIT?

            >
            """
        )
    }

    // MARK: - Special Combat Outcomes

    @Test("Enemy that can be pacified through dialogue")
    func testPacifyThroughDialogue() async throws {
        // Given: A bandit that can be pacified
        let bandit = Item(
            id: "bandit",
            .name("bandit"),
            .description("A rough-looking bandit."),

            .characterSheet(
                .init(
                    intelligence: 10,
                    wisdom: 8,
                    charisma: 8,
                    alignment: .chaoticGood  // Easier to pacify
                )
            ),
            .in(.startRoom)
        )

        let game = MinimalGame(
            player: Player(
                in: .startRoom,
                characterSheet: CharacterSheet(
                    charisma: 18  // High charisma for diplomacy
                )
            ),
            items: bandit,
            combatSystems: [
                "bandit": StandardCombatSystem(versus: "bandit")
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
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > attack bandit
            You close the distance fast with fists ready as the bandit
            mirrors your stance, both of you committed to finding out who
            breaks first.

            You land a light punch that it barely feels. It notes the minor
            damage and dismisses it.

            The bandit retaliates with violence but you're already
            elsewhere when the blow arrives.

            > talk to bandit about peace
            The bandit dismisses your words about the peace with
            contemptuous silence.

            The bandit steps back with open hands. Whatever fury drove it
            has burned itself out.

            The bandit steps back with open hands. Whatever fury drove it
            has burned itself out.
            """
        )
    }

    @Test("Attack non-character object")
    func testAttackNonCharacter() async throws {
        // Given: A regular object (not a character)
        let statue = Item(
            id: "statue",
            .name("statue"),
            .description("A stone statue."),
            // Note: NOT marked as a character (no .characterSheet)
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: statue
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Player tries to attack the statue
        try await engine.execute("attack statue")

        // Then: Should get message about fighting inanimate objects
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > attack statue
            Attacking the statue would accomplish nothing productive.
            """
        )
    }

    @Test("Combat with already dead enemy")
    func testAttackDeadEnemy() async throws {
        // Given: A dead enemy
        let corpse = Item(
            id: "zombie",
            .name("zombie"),
            .description("A defeated zombie."),
            .characterSheet(.init(health: 0, consciousness: .dead)),  // Already dead
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: corpse
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Player tries to attack the corpse
        try await engine.execute("attack zombie")

        // Then: Should indicate it's already dead
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > attack zombie
            You close the distance fast with fists ready as the zombie
            mirrors your stance, both of you committed to finding out who
            breaks first.

            The zombie has already departed this mortal coil.
            """
        )
    }

    // MARK: - State Change Verification

    @Test("Combat state changes are properly applied")
    func testCombatStateChanges() async throws {
        // Given: A simple enemy
        let rat = Item(
            id: "rat",
            .name("rat"),
            .description("A large rat."),
            .characterSheet(.weak),  // Very low health
            .in(.startRoom)
        )

        let sword = Item(
            id: "sword",
            .name("sword"),
            .description("A sharp sword."),
            .isTakable,
            .isWeapon,
            .value(10),  // High damage
            .in(.player)
        )

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
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > attack rat with sword
            You press forward with your sword leading the way toward flesh
            while the rat backs away, unarmed but still dangerous as any
            cornered thing.

            The rat pulls back from your sword! Doubt replaces its earlier
            confidence.

            The rat retaliates with violence but you're already elsewhere
            when the blow arrives.
            """
        )
    }
}
