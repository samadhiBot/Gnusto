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
        await mockIO.expectOutput(
            """
            > attack goblin with sword
            Armed and hungry for violence, you strike with your sword as
            the goblin can only dodge and weave against the advantage of
            sharpened metal.

            Your sword finds its mark at last! The goblin staggers once,
            then falls forever silent.
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
        await mockIO.expectOutput(
            """
            > attack knight
            No weapons needed as you attack with pure violence while the
            knight braces for the inevitable collision of flesh and bone.

            The knight manages to deflect its your blow.

            The knight's counter-strike punches through air, missing by the
            width of good instincts.
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
        await mockIO.expectOutput(
            """
            > attack troll with lamp
            You drive forward with your lamp seeking its purpose as the
            fearsome beast meets you barehanded, flesh against steel in the
            oldest gamble.

            You swing the lamp at the creature with desperate creativity!
            He prepare to defend against your improvised assault.

            The angry beast swings back hard but his fist finds nothing but
            the memory of where you stood.
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
        await mockIO.expectOutput(
            """
            > attack ogre
            Armed and hungry for violence, you strike with your dagger as
            the ogre can only dodge and weave against the advantage of
            sharpened metal.

            The ogre nimbly dodges and twists away from your dagger, using
            speed to compensate for being unarmed.

            The ogre's counter-strike punches through air, missing by the
            width of good instincts.
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
        await mockIO.expectOutput(
            """
            > attack bandit
            No weapons needed as you attack with pure violence while the
            bandit braces for the inevitable collision of flesh and bone.

            You catch the bandit with minimal force, the blow almost
            gentle. It registers the wound with annoyance.

            The bandit's counter-punch goes wide, rage making the strike
            clumsy and predictable.

            > talk to bandit about peace
            The subject of the peace cannot bridge the chasm between you
            and the bandit.

            The fight leaves the bandit entirely. It stand passive now, all
            hostility forgotten.

            The bandit answers with raw violence, a clubbing strike that
            finds you but lacks the angle to truly hurt. Pain flickers and
            dies. Your body has more important work.
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
        await mockIO.expectOutput(
            """
            > attack statue
            The statue is immune to your hostility.
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
        await mockIO.expectOutput(
            """
            > attack zombie
            No weapons needed as you attack with pure violence while the
            zombie braces for the inevitable collision of flesh and bone.

            The zombie is beyond such concerns now, being dead.
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
        await mockIO.expectOutput(
            """
            > attack rat with sword
            Armed and hungry for violence, you strike with your sword as
            the rat can only dodge and weave against the advantage of
            sharpened metal.

            Your sword finds its mark at last! The rat staggers once, then
            falls forever silent.
            """
        )
    }
}
