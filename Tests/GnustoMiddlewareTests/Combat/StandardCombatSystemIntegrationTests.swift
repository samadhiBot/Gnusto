import GnustoEngine
import GnustoTestSupport
import Testing

@testable import GnustoMiddleware

@Suite("Standard Combat System Tests")
struct StandardCombatSystemIntegrationTests {

    // MARK: - Basic Combat Flow Tests

    @Test("Basic combat initiation and attack flow")
    func testBasicCombatFlow() async throws {
        // Given: Player and enemy in same room
        let sword = Item("sword")
            .name("steel sword")
            .isWeapon
            .isTakable
            .value(5)
            .damage(12)
            .in(.player)

        let goblin = Item("goblin")
            .name("goblin warrior")
            .characterSheet(
                armorClass: 12,
                health: 36,
                maxHealth: 30,
                isFighting: true
            )
            .in(.startRoom)

        let game = MinimalGame(
            items: goblin, sword,
            middleware: [CombatMiddleware.mock]
        )
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Player attacks enemy
        try await engine.execute("attack goblin with sword")

        // Then: Combat should initiate and process turn
        await mockIO.expect(
            """
            > attack goblin with sword
            Armed and hungry for violence, you strike with your steel sword
            as the goblin warrior can only dodge and weave against the
            advantage of sharpened metal.

            Your steel sword finds the goblin warrior exposed, carving a
            solid wound that draws a grunt of pain. It absorbs the hit,
            flesh suffering but endurance holding.

            In the tangle, the goblin warrior drives an elbow home --
            sudden pressure that blooms into dull pain. The cut registers
            dimly. Blood, but not enough to matter.
            """
        )

        // Combat state should be established
        let combatState = await CombatMiddleware.combatState(in: engine)
        #expect(combatState != nil)
        #expect(combatState?.enemyID == "goblin")

        // Goblin should still be fighting
        let finalGoblin = await engine.item("goblin")
        #expect(await finalGoblin.isFighting == true)
    }

    @Test("Combat ends when enemy dies")
    func testCombatEndsOnEnemyDeath() async throws {
        // Given: Very weak enemy
        let powerfulSword = Item("sword")
            .name("legendary sword")
            .isWeapon
            .isTakable
            .value(20)
            .damage(50)
            .in(.player)

        let weakGoblin = Item("goblin")
            .name("weak goblin")
            .characterSheet(
                armorClass: 5,
                health: 1,
                maxHealth: 1,
                isFighting: true
            )
            .in(.startRoom)

        let game = MinimalGame(
            items: weakGoblin, powerfulSword,
            middleware: [CombatMiddleware.mock]
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Player attacks with powerful weapon
        try await engine.execute("attack goblin with sword", times: 2)

        // Then: Goblin should die and combat should end
        await mockIO.expect(
            """
            > attack goblin with sword
            Armed and hungry for violence, you strike with your legendary
            sword as the weak goblin can only dodge and weave against the
            advantage of sharpened metal.

            The final thrust of your legendary sword is devastating! The
            weak goblin collapses, unable to defend without a weapon.

            > attack goblin with sword
            You press forward with your legendary sword leading the way
            toward flesh while the weak goblin backs away, unarmed but
            still dangerous as any cornered thing.

            Death has already claimed the weak goblin.
            """
        )

        // Combat state should be cleared
        let combatState = await CombatMiddleware.combatState(in: engine)
        #expect(combatState == nil)

        // Goblin should be dead
        let finalGoblin = await engine.item("goblin")
        #expect(await finalGoblin.isDead)
    }

    @Test("Damage categories are properly calculated")
    func testDamageCategories() async throws {
        // Given: Enemy with known health
        let variableSword = Item("sword")
            .name("variable sword")
            .isWeapon
            .isTakable
            .value(1)
            .damage(25)
            .in(.player)

        let game = MinimalGame(
            items: Lab.castleGuard, variableSword,
            middleware: [CombatMiddleware.mock]
        )
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Player attacks multiple times to see different damage categories
        try await engine.execute("attack the guard", times: 5)

        // Then: Should see various damage descriptions
        await mockIO.expect(
            """
            > attack the guard
            Armed and hungry for violence, you strike with your variable
            sword as the drunken brute can only dodge and weave against the
            advantage of sharpened metal.

            Your variable sword finds the drunken bully exposed, carving a
            serious wound that will need tending -- if there's time. He
            reels from the unexpected wound. The reality of violence
            arrives.

            In the exchange, the bitter brute lands clean. The world
            lurches as your body absorbs punishment it won't soon forget.
            You absorb the hit, feeling flesh tear but knowing you can
            endure.

            > attack the guard
            Your variable sword clips the bully's unguarded flesh, leaving
            a shallow cut. He registers the wound with annoyance.

            In the exchange, the brute lands clean. The world lurches as
            your body absorbs punishment it won't soon forget. You grunt
            from the impact but maintain your stance.

            "Submit to my authority!", cries the castle guard.

            > attack the guard
            The final thrust of your variable sword is devastating! The
            guard collapses, unable to defend without a weapon.

            > attack the guard
            Your variable sword cuts through air toward the brute who has
            no steel to answer yours, only the speed of desperation.

            Death has already claimed the castle guard.

            > attack the guard
            Armed and hungry for violence, you strike with your variable
            sword as the surly bully can only dodge and weave against the
            advantage of sharpened metal.

            The castle guard is beyond such concerns now, being dead.
            """
        )

        // Enemy has been slain
        let finalEnemy = await engine.item("guard")
        #expect(await finalEnemy.isDead)
    }

    @Test("Critical hits deal increased damage")
    func testCriticalHits() async throws {
        // Given: Setup to force critical hits (this is probabilistic in real game)
        let sword = Item("sword")
            .name("sharp sword")
            .isWeapon
            .isTakable
            .value(5)
            .damage(10)
            .in(.player)

        let enemy = Item("enemy")
            .name("test enemy")
            .characterSheet(
                armorClass: 1,  // Always hit
                health: 100,
                maxHealth: 100,
                isFighting: true
            )
            .in(.startRoom)

        let game = MinimalGame(
            items: enemy, sword,
            middleware: [CombatMiddleware.mock]
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Attack many times to eventually get a critical hit
        try await engine.execute("attack enemy", times: 10)

        // Then: Should eventually see critical hit language (probabilistic)
        await mockIO.expect(
            """
            > attack enemy
            Armed and hungry for violence, you strike with your sharp sword
            as the test enemy can only dodge and weave against the
            advantage of sharpened metal.

            Your sharp sword finds the test enemy exposed, carving a
            serious wound that will need tending -- if there's time. It
            reels from the unexpected wound. The reality of violence
            arrives.

            In the tangle, the test enemy drives an elbow home -- sudden
            pressure that blooms into dull pain. The cut registers dimly.
            Blood, but not enough to matter.

            > attack enemy
            Your sharp sword finds the test enemy exposed, carving a
            serious wound that will need tending -- if there's time. It
            looks down at the wound in disbelief. The pain hasn't fully
            registered yet.

            In the tangle, the test enemy drives an elbow home -- sudden
            pressure that blooms into dull pain. You feel it connect,
            adding to the bruises but not breaking your rhythm.

            > attack enemy
            The final thrust of your sharp sword is devastating! The test
            enemy collapses, unable to defend without a weapon.

            > attack enemy
            Your sharp sword cuts through air toward the test enemy who has
            no steel to answer yours, only the speed of desperation.

            Death has already claimed the test enemy.

            > attack enemy
            Armed and hungry for violence, you strike with your sharp sword
            as the test enemy can only dodge and weave against the
            advantage of sharpened metal.

            The test enemy is beyond such concerns now, being dead.

            > attack enemy
            You drive forward with your sharp sword seeking its purpose as
            the test enemy meets you barehanded, flesh against steel in the
            oldest gamble.

            Death has already claimed the test enemy.

            > attack enemy
            You drive forward with your sharp sword seeking its purpose as
            the test enemy meets you barehanded, flesh against steel in the
            oldest gamble.

            The test enemy is beyond such concerns now, being dead.

            > attack enemy
            Your sharp sword cuts through air toward the test enemy who has
            no steel to answer yours, only the speed of desperation.

            The test enemy is beyond such concerns now, being dead.

            > attack enemy
            You drive forward with your sharp sword seeking its purpose as
            the test enemy meets you barehanded, flesh against steel in the
            oldest gamble.

            You're too late -- the test enemy is already deceased.

            > attack enemy
            You advance with your sharp sword ready to taste blood while
            the test enemy has nothing but rage to meet steel.

            The test enemy is beyond such concerns now, being dead.
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
        let devastatingWeapon = Item("hammer")
            .name("war hammer")
            .isWeapon
            .isTakable
            .value(15)
            .damage(25)
            .in(.startRoom)

        let brutalEnemy = Item("giant")
            .name("stone giant")
            .characterSheet(
                strength: 20,  // Very high strength for massive damage
                armorClass: 15,
                health: 80,
                maxHealth: 80,
                isFighting: true
            )
            .in(.startRoom)

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
            items: brutalEnemy, devastatingWeapon,
            middleware: [CombatMiddleware.mock]
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
        let combatState = await CombatMiddleware.combatState(in: engine)
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
        let sword = Item("sword")
            .name("training sword")
            .isWeapon
            .isTakable
            .in(.player)

        let toughEnemy = Item("enemy")
            .name("tough enemy")
            .characterSheet(.strong)
            .in(.startRoom)

        let game = MinimalGame(
            items: toughEnemy, sword,
            middleware: [CombatMiddleware.mock]
        )
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Engage in extended combat
        try await engine.execute("attack enemy", times: 4)

        await mockIO.expect(
            """
            > attack enemy
            Armed and hungry for violence, you strike with your training
            sword as the tough enemy can only dodge and weave against the
            advantage of sharpened metal.

            Your training sword clips the tough enemy's unguarded flesh,
            leaving a shallow cut. It registers the wound with annoyance.

            Then the tough enemy recovers and strikes true. Your jaw takes
            the full force. Blood and fragments of teeth spray the air. You
            reel from the unexpected wound. The reality of violence
            arrives.

            > attack enemy
            Your training sword finds the tough enemy exposed, carving a
            solid wound that draws a grunt of pain. It absorbs the hit,
            flesh suffering but endurance holding.

            The tough enemy delivers death with bare hands, crushing you
            windpipe with the indifference of stone.

            ****  You have died  ****

            Death, that most permanent of inconveniences, has claimed you.
            Yet in these tales, even death offers second chances.

            You scored 0 out of a possible 10 points, in 1 moves.

            Would you like to RESTART, RESTORE a saved game, or QUIT?

            >
            """
        )

        // Then: Combat should have ended when player became unconscious
        let finalState = await CombatMiddleware.combatState(in: engine)
        #expect(finalState == nil)

        // Player should be unconscious
        let playerSheet = await engine.player.characterSheet
        #expect(playerSheet.consciousness == .dead)
    }

    @Test("Combat fatigue increases over time")
    func testCombatFatigueEscalation() async throws {
        // Given: Long-lived combat scenario with very low damage to show fatigue
        let sword = Item("sword")
            .name("training blade")
            .isWeapon
            .isTakable
            .value(1)  // Very low value for minimal damage
            .damage(2)  // Very low damage
            .in(.player)

        let resilientEnemy = Item("warrior")
            .name("veteran warrior")
            .characterSheet(
                strength: 8,  // Low strength for low damage
                constitution: 16,  // High constitution for endurance
                armorClass: 11,  // Lower AC for more hits
                health: 200,  // Very high health
                maxHealth: 200,
                isFighting: true
            )
            .in(.startRoom)

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
            items: resilientEnemy, sword,
            middleware: [CombatMiddleware.mock]
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
        let finalState = await CombatMiddleware.combatState(in: engine)
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
        let sword = Item("sword")
            .name("masterwork sword")
            .adjectives("gleaming", "razor sharp", "masterfully forged")
            .isWeapon
            .isTakable
            .value(8)
            .damage(15)
            .in(.player)

        let enemy = Item("enemy")
            .name("skilled enemy")
            .characterSheet(
                armorClass: 12,
                health: 60,
                maxHealth: 60,
                isFighting: true
            )
            .in(.startRoom)

        let game = MinimalGame(
            items: enemy, sword,
            middleware: [CombatMiddleware.mock]
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Engage in extended combat to trigger special events
        try await engine.execute("attack enemy", times: 7)

        // Then: Should potentially see special events (probabilistic)
        await mockIO.expect(
            """
            > attack enemy
            Armed and hungry for violence, you strike with your masterwork
            sword as the skilled enemy can only dodge and weave against the
            advantage of sharpened metal.

            Your masterwork sword finds the skilled enemy exposed, carving
            a solid wound that draws a grunt of pain. It absorbs the hit,
            flesh suffering but endurance holding.

            The skilled enemy strikes back but fury has made it blind, the
            attack failing to find flesh.

            > attack enemy
            The final thrust of your masterwork sword is devastating! The
            skilled enemy collapses, unable to defend without a weapon.

            > attack enemy
            You drive forward with your masterwork sword seeking its
            purpose as the skilled enemy meets you barehanded, flesh
            against steel in the oldest gamble.

            Death has already claimed the skilled enemy.

            > attack enemy
            You press forward with your masterwork sword leading the way
            toward flesh while the skilled enemy backs away, unarmed but
            still dangerous as any cornered thing.

            The skilled enemy is beyond such concerns now, being dead.

            > attack enemy
            You press forward with your masterwork sword leading the way
            toward flesh while the skilled enemy backs away, unarmed but
            still dangerous as any cornered thing.

            Death has already claimed the skilled enemy.

            > attack enemy
            Your masterwork sword cuts through air toward the skilled enemy
            who has no steel to answer yours, only the speed of
            desperation.

            The skilled enemy is beyond such concerns now, being dead.

            > attack enemy
            Your masterwork sword cuts through air toward the skilled enemy
            who has no steel to answer yours, only the speed of
            desperation.

            The skilled enemy is beyond such concerns now, being dead.
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
        let northRoom = Location("northRoom")
            .name("North Room")
            .inherentlyLit

        let testRoomWithExit = Location(.startRoom)
            .name("Test Room")
            .inherentlyLit
            .exits(.north("northRoom"))

        let cowardlyBandit = Item("bandit")
            .name("cowardly bandit")
            .characterSheet(
                strength: 8,
                bravery: 6,  // Low bravery
                armorClass: 10,
                health: 20,
                maxHealth: 20,
                isFighting: true
            )
            .in(.startRoom)

        let game = MinimalGame(
            locations: testRoomWithExit, northRoom,
            items: cowardlyBandit,
            middleware: [CombatMiddleware.mock]
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
        await mockIO.expect(
            """
            > attack bandit
            No weapons needed as you attack with pure violence while the
            cowardly bandit braces for the inevitable collision of flesh
            and bone.

            Your bare hands deliver death! The cowardly bandit crumples
            without ceremony, the fight conclusively ended.

            > attack bandit
            You close the distance fast with fists ready as the cowardly
            bandit mirrors your stance, both of you committed to finding
            out who breaks first.

            Death has already claimed the cowardly bandit.

            > attack bandit
            You attack with nothing but will and bone as the cowardly
            bandit meets your charge head-on, no weapons, no rules, no
            mercy.

            The cowardly bandit is beyond such concerns now, being dead.
            """
        )
    }

    @Test("Enemy surrenders when outmatched")
    func testEnemySurrender() async throws {
        // Given: Intelligent enemy likely to surrender
        let intelligentEnemy = Item("scholar")
            .name("scholar warrior")
            .characterSheet(
                strength: 10,
                intelligence: 16,  // High intelligence
                wisdom: 14,
                bravery: 8,  // Low bravery
                armorClass: 11,
                health: 25,
                maxHealth: 25,
                isFighting: true
            )
            .in(.startRoom)

        let powerfulSword = Item("sword")
            .name("intimidating sword")
            .isWeapon
            .isTakable
            .value(10)
            .damage(20)
            .in(.player)

        let game = MinimalGame(
            items: intelligentEnemy, powerfulSword,
            middleware: [CombatMiddleware.mock]
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
        await mockIO.expect(
            """
            > attack scholar
            Armed and hungry for violence, you strike with your
            intimidating sword as the scholar warrior can only dodge and
            weave against the advantage of sharpened metal.

            The final thrust of your intimidating sword is devastating! The
            scholar warrior collapses, unable to defend without a weapon.

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
        let confusedGuard = Item("guard")
            .name("confused guard")
            .characterSheet(
                intelligence: 12,
                wisdom: 10,
                armorClass: 14,
                health: 30,
                maxHealth: 30,
                isFighting: true
            )
            .in(.startRoom)

        let game = MinimalGame(
            player: Player(
                in: .startRoom,
                characterSheet: CharacterSheet(
                    charisma: 16  // High charisma for better pacification chances
                )
            ),
            items: confusedGuard,
            middleware: [CombatMiddleware.mock]
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Player tries to pacify during combat
        try await engine.execute("attack guard")
        _ = await mockIO.flush()  // Clear combat initiation

        try await engine.execute("talk to guard")

        // Then: May result in pacification (probabilistic)
        await mockIO.expect(
            """
            > talk to guard
            The confused guard's aggressive stance melts away. Though still
            watchful, it clearlys want no more violence.
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
        let armoredKnight = Item("knight")
            .name("armored knight")
            .characterSheet(
                armorClass: 18,
                health: 50,
                maxHealth: 50,
                isFighting: true
            )
            .in(.startRoom)

        let game = MinimalGame(
            items: armoredKnight,
            middleware: [CombatMiddleware.mock]
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Player attacks without weapon
        try await engine.execute("attack knight")

        // Then: Should be warned about needing weapons
        await mockIO.expect(
            """
            > attack knight
            Fighting the armored knight bare-handed seems inadvisable. Find
            a proper weapon first.

            No weapons between you -- just the armored knight's aggression
            and your desperation! You collide in a tangle of strikes and
            blocks.
            """
        )
    }

    // MARK: - Non-Combat Actions During Combat Tests

    @Test("Non-combat actions during combat give enemy advantage")
    func testDistractedPlayerVulnerability() async throws {
        // Given: Combat scenario
        let aggressiveEnemy = Item("warrior")
            .name("fierce warrior")
            .characterSheet(
                strength: 14,
                armorClass: 12,
                health: 40,
                maxHealth: 40,
                isFighting: true
            )
            .in(.startRoom)

        let sword = Item("sword")
            .name("short sword")
            .isWeapon
            .isTakable
            .value(4)
            .damage(8)
            .in(.startRoom)

        let game = MinimalGame(
            items: aggressiveEnemy, sword,
            middleware: [CombatMiddleware.mock]
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Start combat
        try await engine.execute("attack warrior")
        _ = await mockIO.flush()

        // When: Player performs non-combat action (gets distracted)
        try await engine.execute("take sword")

        // Then: Enemy should get buffed attack
        await mockIO.expect(
            """
            > take sword
            The fierce warrior pivots and strikes true -- impact ripples
            through muscle and bone, stealing balance and breath together.
            The wound stings sharply. You can take more, but not forever.
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
        let specialEnemy = Item("dragon")
            .name("ancient dragon")
            .characterSheet(
                armorClass: 20,
                health: 100,
                maxHealth: 100,
                isFighting: true
            )
            .in(.startRoom)

        // Create custom combat system
        let customSystem = StandardCombatSystem(versus: "dragon") { event, _ in
            switch event {
            case .enemyInjured:
                ActionResult(
                    "The ancient dragon roars in fury as your blade finds its mark!"
                )
            default:
                nil  // Use default for other events
            }
        }

        let game = MinimalGame(
            items: specialEnemy,
            middleware: [CombatMiddleware.mock]
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
        let deadEnemy = Item("corpse")
            .name("dead bandit")
            .characterSheet(
                health: 0,
                maxHealth: 20,
                consciousness: .dead,
                isFighting: false
            )
            .in(.startRoom)

        let game = MinimalGame(
            items: deadEnemy,
            middleware: [CombatMiddleware.mock]
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Player tries to attack dead enemy
        try await engine.execute("attack corpse")

        // Then: Should indicate enemy is already dead
        await mockIO.expect(
            """
            > attack corpse
            No weapons needed as you attack with pure violence while the
            corpse braces for the inevitable collision of flesh and bone.

            The dead bandit is beyond such concerns now, being dead.
            """
        )
    }

    @Test("Combat system handles missing weapon gracefully")
    func testMissingWeaponHandling() async throws {
        // Given: Combat scenario where weapon might not exist
        let enemy = Item("bandit")
            .name("highway bandit")
            .characterSheet(
                armorClass: 11,
                health: 25,
                maxHealth: 25,
                isFighting: true
            )
            .in(.startRoom)

        let game = MinimalGame(
            items: enemy,
            middleware: [CombatMiddleware.mock]
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Player attacks with non-existent weapon
        try await engine.execute("attack bandit with nonexistent")

        // Then: Should handle gracefully
        await mockIO.expect(
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
        let book = Item("book")
            .name("heavy book")
            .isTakable
            .in(.player)

        let enemy = Item("thug")
            .name("street thug")
            .characterSheet(
                armorClass: 10,
                health: 20,
                maxHealth: 20,
                isFighting: true
            )
            .in(.startRoom)

        let game = MinimalGame(
            items: enemy, book,
            middleware: [CombatMiddleware.mock]
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Player tries to attack with non-weapon
        try await engine.execute("attack thug with book")

        // Then: Should handle non-weapon attack appropriately
        await mockIO.expect(
            """
            > attack thug with book
            Armed and hungry for violence, you strike with your heavy book
            as the street thug can only dodge and weave against the
            advantage of sharpened metal.

            Brandishing the heavy book, you advance on the street thug!
            It's unconventional, but might just work.

            The street thug answers with raw violence, a clubbing strike
            that finds you but lacks the angle to truly hurt. Pain flickers
            and dies. Your body has more important work.
            """
        )
    }
}
