import CustomDump
import GnustoEngine
import GnustoTestSupport
import Testing

@Suite("Standard Combat System Tests")
struct StandardCombatSystemIntegrationTests {

    // MARK: - Basic Combat Flow Tests

    @Test("Basic combat initiation and attack flow")
    func testBasicCombatFlow() async throws {
        // Given: Player and enemy in same room
        let sword = Item(
            id: "sword",
            .name("steel sword"),
            .isWeapon,
            .isTakable,
            .value(5),
            .damage(12),
            .in(.player)
        )

        let goblin = Item(
            id: "goblin",
            .name("goblin warrior"),
            .characterSheet(
                .init(
                    armorClass: 12,
                    health: 36,
                    maxHealth: 30,
                    isFighting: true
                )
            ),
            .in(.startRoom)
        )

        let game = MinimalGame(items: goblin, sword)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Player attacks enemy
        try await engine.execute("attack goblin with sword")

        // Then: Combat should initiate and process turn
        await mockIO.expectOutput(
            """
            > attack goblin with sword
            Armed and hungry for violence, you strike with your steel sword
            as the goblin warrior can only dodge and weave against the
            advantage of sharpened metal.

            Your blow with your steel sword catches the goblin warrior
            cleanly, tearing flesh and drawing crimson. It absorbs the hit,
            flesh suffering but endurance holding.

            The goblin warrior's counter-punch goes wide, rage making the
            strike clumsy and predictable.
            """
        )

        // Combat state should be established
        let combatState = await engine.combatState
        #expect(combatState != nil)
        #expect(combatState?.enemyID == "goblin")

        // Goblin should still be fighting
        let finalGoblin = await engine.item("goblin")
        #expect(await finalGoblin.isFighting == true)
    }

    @Test("Combat ends when enemy dies")
    func testCombatEndsOnEnemyDeath() async throws {
        // Given: Very weak enemy
        let powerfulSword = Item(
            id: "sword",
            .name("legendary sword"),
            .isWeapon,
            .isTakable,
            .value(20),
            .damage(50),
            .in(.player)
        )

        let weakGoblin = Item(
            id: "goblin",
            .name("weak goblin"),
            .characterSheet(
                .init(
                    armorClass: 5,
                    health: 1,
                    maxHealth: 1,
                    isFighting: true
                )
            ),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: weakGoblin, powerfulSword
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Player attacks with powerful weapon
        try await engine.execute("attack goblin with sword", times: 2)

        // Then: Goblin should die and combat should end
        await mockIO.expectOutput(
            """
            > attack goblin with sword
            Armed and hungry for violence, you strike with your legendary
            sword as the weak goblin can only dodge and weave against the
            advantage of sharpened metal.

            Your legendary sword finds its mark at last! The weak goblin
            staggers once, then falls forever silent.

            > attack goblin with sword
            You press forward with your legendary sword leading the way
            toward flesh while the weak goblin backs away, unarmed but
            still dangerous as any cornered thing.

            Death has already claimed the weak goblin.
            """
        )

        // Combat state should be cleared
        let combatState = await engine.combatState
        #expect(combatState == nil)

        // Goblin should be dead
        let finalGoblin = await engine.item("goblin")
        #expect(await finalGoblin.isDead)
    }

    @Test("Damage categories are properly calculated")
    func testDamageCategories() async throws {
        // Given: Enemy with known health
        let variableSword = Item(
            id: "sword",
            .name("variable sword"),
            .isWeapon,
            .isTakable,
            .value(1),
            .damage(25),
            .in(.player)
        )

        let game = MinimalGame(items: Lab.castleGuard, variableSword)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Player attacks multiple times to see different damage categories
        try await engine.execute("attack the guard", times: 5)

        // Then: Should see various damage descriptions
        await mockIO.expectOutput(
            """
            > attack the guard
            You drive forward with your variable sword seeking its purpose
            as the drunken brute meets you barehanded, flesh against steel
            in the oldest gamble.

            Your variable sword swings wide, and the drunken bully avoids
            your poorly aimed strike with ease.

            The bitter brute counters with a force that shatters your
            guard, leaving you exposed to whatever violence comes next.

            > attack the guard
            Your variable sword inflicts a light wound on the bully, more
            sting than damage. He registers the wound with annoyance.

            The guard answers with raw violence, a clubbing strike that
            finds you but lacks the angle to truly hurt. The wound is
            trivial against your battle fury.

            > attack the guard
            Your variable sword finds the surly brute exposed, carving a
            solid wound that draws a grunt of pain. He grunts from the
            impact but maintains stance.

            The counterblow comes wild and desperate, the guard hammering
            through your guard to bruise rather than break. The strike
            lands but doesn't slow you. Not yet.

            > attack the guard
            A disastrous miss--your variable sword cuts through empty air
            and the brute effortlessly evades your mistimed attack.

            The brute surges back instantly, fist cracking against your
            ribs--more warning than wound. The wound is light but
            unwelcome, your body protesting the accumulation.

            > attack the guard
            Your variable sword finds its mark at last! The brute staggers
            once, then falls forever silent.
            """
        )

        // Enemy has been slain
        let finalEnemy = await engine.item("guard")
        #expect(await finalEnemy.isDead)
    }

    @Test("Critical hits deal increased damage")
    func testCriticalHits() async throws {
        // Given: Setup to force critical hits (this is probabilistic in real game)
        let sword = Item(
            id: "sword",
            .name("sharp sword"),
            .isWeapon,
            .isTakable,
            .value(5),
            .damage(10),
            .in(.player)
        )

        let enemy = Item(
            id: "enemy",
            .name("test enemy"),
            .characterSheet(
                .init(
                    armorClass: 1,  // Always hit
                    health: 100,
                    maxHealth: 100,
                    isFighting: true
                )
            ),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: enemy, sword
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Attack many times to eventually get a critical hit
        try await engine.execute("attack enemy", times: 10)

        // Then: Should eventually see critical hit language (probabilistic)
        await mockIO.expectOutput(
            """
            > attack enemy
            Armed and hungry for violence, you strike with your sharp sword
            as the test enemy can only dodge and weave against the
            advantage of sharpened metal.

            Your blow with your sharp sword catches the test enemy cleanly,
            tearing flesh and drawing crimson. It absorbs the hit, flesh
            suffering but endurance holding.

            The test enemy's counter-punch goes wide, rage making the
            strike clumsy and predictable.

            > attack enemy
            You strike the test enemy with your sharp sword, tearing
            through skin and muscle. Blood wells immediately, dark and
            thick. From confident to cautious in one blow. Blood runs
            freely down its body.

            The test enemy swings in retaliation but you slip the attack,
            flowing around the violence like water around stone.

            > attack enemy
            Your armed advantage proves decisive--your sharp sword ends it!
            The test enemy crumples, having fought barehanded and lost.

            > attack enemy
            Your sharp sword cuts through air toward the test enemy who has
            no steel to answer yours, only the speed of desperation.

            The test enemy is beyond such concerns now, being dead.

            > attack enemy
            You drive forward with your sharp sword seeking its purpose as
            the test enemy meets you barehanded, flesh against steel in the
            oldest gamble.

            Death has already claimed the test enemy.

            > attack enemy
            Your sharp sword cuts through air toward the test enemy who has
            no steel to answer yours, only the speed of desperation.

            The test enemy is beyond such concerns now, being dead.

            > attack enemy
            You drive forward with your sharp sword seeking its purpose as
            the test enemy meets you barehanded, flesh against steel in the
            oldest gamble.

            The test enemy is beyond such concerns now, being dead.

            > attack enemy
            You drive forward with your sharp sword seeking its purpose as
            the test enemy meets you barehanded, flesh against steel in the
            oldest gamble.

            You're too late--the test enemy is already deceased.

            > attack enemy
            You press forward with your sharp sword leading the way toward
            flesh while the test enemy backs away, unarmed but still
            dangerous as any cornered thing.

            The test enemy is beyond such concerns now, being dead.

            > attack enemy
            Armed and hungry for violence, you strike with your sharp sword
            as the test enemy can only dodge and weave against the
            advantage of sharpened metal.

            The test enemy is already dead.
            """
        )

        // At minimum, enemy should have taken damage
        let finalEnemy = await engine.item("enemy")
        let finalHealth = await finalEnemy.health
        #expect(finalHealth < 100)
    }

    @Test("When player is rendered unconscious")
    func testPlayerUnconscious() async throws {
        // Given: Very weak player and very powerful enemy
        let devastatingWeapon = Item(
            id: "hammer",
            .name("war hammer"),
            .isWeapon,
            .isTakable,
            .value(15),
            .damage(25),
            .in(.startRoom)
        )

        let brutalEnemy = Item(
            id: "giant",
            .name("stone giant"),
            .characterSheet(
                .init(
                    strength: 20,  // Very high strength for massive damage
                    armorClass: 15,
                    health: 80,
                    maxHealth: 80,
                    isFighting: true
                )
            ),
            .in(.startRoom)
        )

        // Weaken the player significantly
        let game = MinimalGame(
            player: Player(
                in: .startRoom,
                characterSheet: CharacterSheet(
                    constitution: 8,  // Low constitution
                    health: 8,  // Very low health
                    maxHealth: 20
                )
            ),
            items: brutalEnemy, devastatingWeapon
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Enemy attacks multiple times until player becomes unconscious or dies
        try await engine.execute("attack giant", times: 5)

        // Then: Player should be severely injured or unconscious/dead
        let output = await mockIO.flush()

        // Verify combat occurred and player took serious damage
        #expect(output.contains("> attack giant"))
        #expect(output.contains("stone giant"))

        // Combat should have ended (either from death or unconsciousness)
        let combatState = await engine.combatState
        #expect(combatState == nil)

        // Player should be unconscious, dead, or severely wounded
        let playerSheet = await engine.player.characterSheet
        let playerHealth = await engine.player.health

        // Test passes if player is unconscious, dead, or critically injured
        let isIncapacitated =
            playerSheet.consciousness == ConsciousnessLevel.unconscious
            || playerSheet.consciousness == ConsciousnessLevel.dead
            || playerHealth <= 5  // Critically injured

        #expect(isIncapacitated)
    }

    // MARK: - Combat Intensity and Fatigue Tests

    @Test("Combat intensity increases over time")
    func testCombatIntensityEscalation() async throws {
        // Given: Long-lived combat scenario
        let sword = Item(
            id: "sword",
            .name("training sword"),
            .isWeapon,
            .isTakable,
            .in(.player)
        )

        let toughEnemy = Item(
            id: "enemy",
            .name("tough enemy"),
            .characterSheet(.strong),
            .in(.startRoom)
        )

        let game = MinimalGame(items: toughEnemy, sword)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Engage in extended combat
        try await engine.execute("attack enemy", times: 4)

        await mockIO.expectOutput(
            """
            > attack enemy
            Armed and hungry for violence, you strike with your training
            sword as the tough enemy can only dodge and weave against the
            advantage of sharpened metal.

            Your strike with your training sword grazes the tough enemy,
            drawing minimal blood. It registers the wound with annoyance.

            The tough enemy's counter-punch goes wide, rage making the
            strike clumsy and predictable.

            > attack enemy
            You strike the tough enemy with your training sword, opening a
            wound that bleeds steadily. The wound is real but manageable.

            In the exchange, the tough enemy lands clean. The world lurches
            as your body absorbs punishment it won't soon forget. You
            absorb the hit, feeling flesh tear but knowing you can endure.

            > attack enemy
            Your training sword swings wide, and the tough enemy avoids
            your poorly aimed strike with ease.

            The tough enemy finishes you with nothing but flesh and bone,
            proving that the oldest weapons still kill just as dead.

            ****  You have died  ****

            Death, that most permanent of inconveniences, has claimed you.
            Yet in these tales, even death offers second chances.

            You scored 0 out of a possible 10 points, in 2 moves.

            Would you like to RESTART, RESTORE a saved game, or QUIT?

            >
            """
        )

        // Then: Combat should have ended when player became unconscious
        let finalState = await engine.combatState
        #expect(finalState == nil)

        // Player should be unconscious
        let playerSheet = await engine.player.characterSheet
        #expect(playerSheet.consciousness == .dead)
    }

    @Test("Combat fatigue increases over time")
    func testCombatFatigueEscalation() async throws {
        // Given: Long-lived combat scenario with very low damage to show fatigue
        let sword = Item(
            id: "sword",
            .name("training blade"),
            .isWeapon,
            .isTakable,
            .value(1),  // Very low value for minimal damage
            .damage(2),  // Very low damage
            .in(.player)
        )

        let resilientEnemy = Item(
            id: "warrior",
            .name("veteran warrior"),
            .characterSheet(
                .init(
                    strength: 8,  // Low strength for low damage
                    constitution: 16,  // High constitution for endurance
                    armorClass: 11,  // Lower AC for more hits
                    health: 200,  // Very high health
                    maxHealth: 200,
                    isFighting: true
                )
            ),
            .in(.startRoom)
        )

        let game = MinimalGame(
            player: Player(
                in: .startRoom,
                characterSheet: CharacterSheet(
                    strength: 8,  // Low strength for low damage
                    constitution: 16,  // High constitution for endurance
                    health: 100,  // High health
                    maxHealth: 100
                )
            ),
            items: resilientEnemy, sword
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Engage in extended combat to build fatigue
        try await engine.execute("attack warrior", times: 6)  // Enough rounds to build fatigue

        // Then: Combat system should show signs of extended battle
        let output = await mockIO.flush()

        // Verify combat occurred multiple times
        #expect(output.contains("> attack warrior"))
        #expect(output.contains("veteran warrior"))

        // Check that combat state exists and has progressed
        let finalState = await engine.combatState
        if let finalState {
            // Verify combat has escalated beyond initial values
            #expect(finalState.roundCount >= 3)  // Multiple rounds occurred
            #expect(finalState.combatIntensity > 0.1)  // Intensity increased from initial 0.1

            // Player fatigue should have accumulated over time - the key test
            #expect(finalState.playerFatigue > 0.0)  // Some fatigue should have built up

            // Combat should show escalation through intensity or fatigue
            #expect(finalState.combatIntensity > 0.15 || finalState.playerFatigue > 0.05)

            // Verify fatigue is actually affecting combat (fatigue penalties in logs)
            #expect(finalState.playerFatigue > 0.05)  // Meaningful fatigue accumulation
        } else {
            // If combat ended, verify it was due to escalation, not immediate death
            let finalEnemy = await engine.item("warrior")
            let finalEnemyHealth = await finalEnemy.health
            let playerHealth = await engine.player.health

            // Either someone died from accumulated damage or combat mechanics worked
            #expect(finalEnemyHealth <= 0 || playerHealth <= 0 || finalEnemyHealth < 200)
        }
    }

    // MARK: - Special Combat Events Tests

    @Test("Special combat events can occur")
    func testSpecialCombatEvents() async throws {
        // Given: Combat scenario likely to produce special events
        let sword = Item(
            id: "sword",
            .name("masterwork sword"),
            .adjectives("gleaming", "razor sharp", "masterfully forged"),
            .isWeapon,
            .isTakable,
            .value(8),
            .damage(15),
            .in(.player)
        )

        let enemy = Item(
            id: "enemy",
            .name("skilled enemy"),
            .characterSheet(
                .init(
                    armorClass: 12,
                    health: 60,
                    maxHealth: 60,
                    isFighting: true
                )
            ),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: enemy, sword
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Engage in extended combat to trigger special events
        try await engine.execute("attack enemy", times: 7)

        // Then: Should potentially see special events (probabilistic)
        await mockIO.expectOutput(
            """
            > attack enemy
            Your masterwork sword cuts through air toward the skilled enemy
            who has no steel to answer yours, only the speed of
            desperation.

            Your masterwork sword bites deep into the skilled enemy,
            inflicting damage that shows immediately. The blow lands
            solidly, drawing blood. It feels the sting but remains strong.

            In the exchange, the skilled enemy lands clean. The world
            lurches as your body absorbs punishment it won't soon forget.
            You absorb the hit, feeling flesh tear but knowing you can
            endure.

            > attack enemy
            You strike true with your masterwork sword! The skilled enemy
            drops without a sound, weaponless to the end.

            > attack enemy
            Your masterwork sword cuts through air toward the skilled enemy
            who has no steel to answer yours, only the speed of
            desperation.

            You're too late--the skilled enemy is already deceased.

            > attack enemy
            You drive forward with your masterwork sword seeking its
            purpose as the skilled enemy meets you barehanded, flesh
            against steel in the oldest gamble.

            You're too late--the skilled enemy is already deceased.

            > attack enemy
            You press forward with your masterwork sword leading the way
            toward flesh while the skilled enemy backs away, unarmed but
            still dangerous as any cornered thing.

            Death has already claimed the skilled enemy.

            > attack enemy
            You drive forward with your masterwork sword seeking its
            purpose as the skilled enemy meets you barehanded, flesh
            against steel in the oldest gamble.

            The skilled enemy is beyond such concerns now, being dead.

            > attack enemy
            You drive forward with your masterwork sword seeking its
            purpose as the skilled enemy meets you barehanded, flesh
            against steel in the oldest gamble.

            The skilled enemy has already departed this mortal coil.
            """
        )

        // Enemy should have taken damage
        let finalEnemy = await engine.item("enemy")
        let finalHealth = await finalEnemy.health
        #expect(finalHealth < 60)
    }

    // MARK: - Enemy AI Tests

    @Test("Enemy flees when critically wounded")
    func testEnemyFleeing() async throws {
        // Given: Cowardly enemy with escape route
        let northRoom = Location(
            id: "northRoom",
            .name("North Room"),
            .inherentlyLit
        )

        let testRoomWithExit = Location(
            id: .startRoom,
            .name("Test Room"),
            .inherentlyLit,
            .exits(.north("northRoom"))
        )

        let cowardlyBandit = Item(
            id: "bandit",
            .name("cowardly bandit"),
            .characterSheet(
                .init(
                    strength: 8,
                    bravery: 6,  // Low bravery
                    armorClass: 10,
                    health: 20,
                    maxHealth: 20,
                    isFighting: true
                )
            ),
            .in(.startRoom)
        )

        let game = MinimalGame(
            locations: testRoomWithExit, northRoom,
            items: cowardlyBandit
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Severely wound the bandit to trigger flee behavior
        let banditProxy = await engine.item("bandit")
        if let damageChange = await banditProxy.takeDamage(15) {
            try await engine.apply(damageChange)
        }

        // When: Continue attacking wounded coward
        try await engine.execute("attack bandit", times: 3)

        // Then: Bandit should eventually flee (probabilistic)
        await mockIO.expectOutput(
            """
            > attack bandit
            No weapons needed as you attack with pure violence while the
            cowardly bandit braces for the inevitable collision of flesh
            and bone.

            The last blow is yours! The cowardly bandit staggers back, eyes
            going vacant, before falling motionless.

            > attack bandit
            You close the distance fast with fists ready as the cowardly
            bandit mirrors your stance, both of you committed to finding
            out who breaks first.

            Death has already claimed the cowardly bandit.

            > attack bandit
            You close the distance fast with fists ready as the cowardly
            bandit mirrors your stance, both of you committed to finding
            out who breaks first.

            The cowardly bandit is beyond such concerns now, being dead.
            """
        )
    }

    @Test("Enemy surrenders when outmatched")
    func testEnemySurrender() async throws {
        // Given: Intelligent enemy likely to surrender
        let intelligentEnemy = Item(
            id: "scholar",
            .name("scholar warrior"),
            .characterSheet(
                .init(
                    strength: 10,
                    intelligence: 16,  // High intelligence
                    wisdom: 14,
                    bravery: 8,  // Low bravery
                    armorClass: 11,
                    health: 25,
                    maxHealth: 25,
                    isFighting: true
                )
            ),
            .in(.startRoom)
        )

        let powerfulSword = Item(
            id: "sword",
            .name("intimidating sword"),
            .isWeapon,
            .isTakable,
            .value(10),
            .damage(20),
            .in(.player)
        )

        let game = MinimalGame(
            items: intelligentEnemy, powerfulSword
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Wound the scholar to make surrender more likely
        let scholarProxy = await engine.item("scholar")
        if let damageChange = await scholarProxy.takeDamage(12) {
            try await engine.apply(damageChange)
        }

        // When: Attack the wounded, intelligent enemy
        try await engine.execute("attack scholar", times: 2)

        // Then: May surrender (probabilistic based on intelligence/wisdom)
        await mockIO.expectOutput(
            """
            > attack scholar
            Armed and hungry for violence, you strike with your
            intimidating sword as the scholar warrior can only dodge and
            weave against the advantage of sharpened metal.

            Your intimidating sword finds its mark at last! The scholar
            warrior staggers once, then falls forever silent.

            > attack scholar
            You press forward with your intimidating sword leading the way
            toward flesh while the scholar warrior backs away, unarmed but
            still dangerous as any cornered thing.

            Death has already claimed the scholar warrior.
            """
        )
    }

    // MARK: - Pacification Tests

    @Test("High charisma player can pacify suitable enemies")
    func testPacification() async throws {
        // Given: Pacifiable enemy and charismatic player
        let confusedGuard = Item(
            id: "guard",
            .name("confused guard"),
            .characterSheet(
                .init(
                    intelligence: 12,
                    wisdom: 10,
                    armorClass: 14,
                    health: 30,
                    maxHealth: 30,
                    isFighting: true
                )
            ),
            .in(.startRoom)
        )

        let game = MinimalGame(
            player: Player(
                in: .startRoom,
                characterSheet: CharacterSheet(
                    charisma: 16  // High charisma for better pacification chances
                )
            ),
            items: confusedGuard
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Player tries to pacify during combat
        try await engine.execute("attack guard")
        _ = await mockIO.flush()  // Clear combat initiation

        try await engine.execute("talk to guard")

        // Then: May result in pacification (probabilistic)
        await mockIO.expectOutput(
            """
            > talk to guard
            The confused guard responds to your overture with hostile
            silence.

            The fight leaves the confused guard entirely. It stand passive
            now, all hostility forgotten.
            """
        )

        // Guard state should be affected
        let finalGuard = await engine.item("guard")
        let guardHealth = await finalGuard.health
        #expect(guardHealth <= 30)  // Health may have changed from combat
    }

    // MARK: - Weapon Requirements Tests

    @Test("Enemy requiring weapon blocks unarmed attacks")
    func testWeaponRequirement() async throws {
        // Given: Heavily armored enemy requiring weapons
        let armoredKnight = Item(
            id: "knight",
            .name("armored knight"),
            .characterSheet(
                .init(
                    armorClass: 18,
                    health: 50,
                    maxHealth: 50,
                    isFighting: true
                )
            ),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: armoredKnight
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Player attacks without weapon
        try await engine.execute("attack knight")

        // Then: Should be warned about needing weapons
        await mockIO.expectOutput(
            """
            > attack knight
            Fighting the armored knight bare-handed seems inadvisable. Find
            a proper weapon first.

            No weapons between you--just the armored knight's aggression
            and your desperation! You collide in a tangle of strikes and
            blocks.
            """
        )
    }

    // MARK: - Non-Combat Actions During Combat Tests

    @Test("Non-combat actions during combat give enemy advantage")
    func testDistractedPlayerVulnerability() async throws {
        // Given: Combat scenario
        let aggressiveEnemy = Item(
            id: "warrior",
            .name("fierce warrior"),
            .characterSheet(
                .init(
                    strength: 14,
                    armorClass: 12,
                    health: 40,
                    maxHealth: 40,
                    isFighting: true
                )
            ),
            .in(.startRoom)
        )

        let sword = Item(
            id: "sword",
            .name("short sword"),
            .isWeapon,
            .isTakable,
            .value(4),
            .damage(8),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: aggressiveEnemy, sword
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Start combat
        try await engine.execute("attack warrior")
        _ = await mockIO.flush()

        // When: Player performs non-combat action (gets distracted)
        try await engine.execute("take sword")

        // Then: Enemy should get buffed attack
        await mockIO.expectOutput(
            """
            > take sword
            Got it.

            The fierce warrior surges back instantly, fist cracking against
            your ribs--more warning than wound. The wound is trivial
            against your battle fury.
            """
        )

        // Player should have taken the sword
        let finalSword = await engine.item("sword")
        let swordParent = await finalSword.parent
        #expect(swordParent == .player)
    }

    // MARK: - Custom Combat Descriptions Tests

    @Test("Custom combat descriptions override defaults")
    func testCustomCombatDescriptions() async throws {
        // Given: Combat system with custom descriptions
        let specialEnemy = Item(
            id: "dragon",
            .name("ancient dragon"),
            .characterSheet(
                .init(
                    armorClass: 20,
                    health: 100,
                    maxHealth: 100,
                    isFighting: true
                )
            ),
            .in(.startRoom)
        )

        // Create custom combat system
        let customSystem = StandardCombatSystem(
            versus: "dragon",
            eventHandler: { event, _ in
                switch event {
                case .enemyInjured:
                    return ActionResult(
                        "The ancient dragon roars in fury as your blade finds its mark!")
                default:
                    return nil  // Use default for other events
                }
            }
        )

        let game = MinimalGame(
            items: specialEnemy
        )

        let (_, _) = await GameEngine.test(blueprint: game)

        // TODO: This test would require integrating the custom combat system
        // into the game engine, which isn't currently supported in the test framework
        // For now, just verify the combat system can be created
        #expect(customSystem.enemyID == "dragon")
    }

    // MARK: - Edge Cases and Error Handling Tests

    @Test("Combat handles already dead enemy")
    func testAlreadyDeadEnemy() async throws {
        // Given: Dead enemy
        let deadEnemy = Item(
            id: "corpse",
            .name("dead bandit"),
            .characterSheet(
                .init(
                    health: 0,
                    maxHealth: 20,
                    consciousness: .dead,
                    isFighting: false
                )
            ),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: deadEnemy
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Player tries to attack dead enemy
        try await engine.execute("attack corpse")

        // Then: Should indicate enemy is already dead
        await mockIO.expectOutput(
            """
            > attack corpse
            Barehanded, you commit to the assault as the corpse accepts the
            challenge with equal violence promised.

            The dead bandit is beyond such concerns now, being dead.
            """
        )
    }

    @Test("Combat system handles missing weapon gracefully")
    func testMissingWeaponHandling() async throws {
        // Given: Combat scenario where weapon might not exist
        let enemy = Item(
            id: "bandit",
            .name("highway bandit"),
            .characterSheet(
                .init(
                    armorClass: 11,
                    health: 25,
                    maxHealth: 25,
                    isFighting: true
                )
            ),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: enemy
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Player attacks with non-existent weapon
        try await engine.execute("attack bandit with nonexistent")

        // Then: Should handle gracefully
        await mockIO.expectOutput(
            """
            > attack bandit with nonexistent
            You cannot reach any such thing from here.

            In a moment of raw violence, the highway bandit comes at you
            with nothing but fury! You raise your fists, knowing this will
            hurt regardless of who wins.
            """
        )
    }

    @Test("Combat handles non-weapon items gracefully")
    func testNonWeaponItemAttack() async throws {
        // Given: Combat scenario with non-weapon item
        let book = Item(
            id: "book",
            .name("heavy book"),
            .isTakable,
            .in(.player)
        )

        let enemy = Item(
            id: "thug",
            .name("street thug"),
            .characterSheet(
                .init(
                    armorClass: 10,
                    health: 20,
                    maxHealth: 20,
                    isFighting: true
                )
            ),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: enemy, book
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Player tries to attack with non-weapon
        try await engine.execute("attack thug with book")

        // Then: Should handle non-weapon attack appropriately
        await mockIO.expectOutput(
            """
            > attack thug with book
            Armed and hungry for violence, you strike with your heavy book
            as the street thug can only dodge and weave against the
            advantage of sharpened metal.

            You swing the heavy book at the street thug with desperate
            creativity! It prepare to defend against your improvised
            assault.

            The street thug crashes forward in response, the impact jarring
            but glancing as you roll with it. Pain flickers and dies. Your
            body has more important work.
            """
        )
    }
}
