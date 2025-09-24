import CustomDump
import GnustoTestSupport
import Testing

@testable import GnustoEngine

@Suite("GameEngine Combat Tests")
struct GameEngineCombatTests {

    // MARK: - Combat State Management Tests

    @Test("isInCombat returns false when no combat state exists")
    func testIsInCombatFalseWhenNoCombat() async throws {
        let game = MinimalGame()
        let (engine, _) = await GameEngine.test(blueprint: game)

        #expect(await engine.isInCombat == false)
    }

    @Test("isInCombat returns true when combat state exists")
    func testIsInCombatTrueWhenInCombat() async throws {
        let enemy = Item(
            id: "goblin",
            .name("goblin"),
            .characterSheet(.default),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: enemy
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Initiate combat
        try await engine.execute("slay the goblin")

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > slay the goblin
            You close the distance fast with fists ready as the goblin
            mirrors your stance, both of you committed to finding out who
            breaks first.

            You land a light punch that it barely feels. It notes the minor
            damage and dismisses it.

            The counterblow comes wild and desperate, the goblin hammering
            through your guard to bruise rather than break. Pain flickers
            and dies. Your body has more important work.
            """
        )

        #expect(await engine.isInCombat == true)
    }

    @Test("combatState returns nil when no combat exists")
    func testCombatStateNilWhenNoCombat() async throws {
        let game = MinimalGame()
        let (engine, _) = await GameEngine.test(blueprint: game)

        #expect(await engine.combatState == nil)
    }

    @Test("combatState returns combat state when in combat")
    func testCombatStateReturnsStateWhenInCombat() async throws {
        let enemy = Item(
            id: "orc",
            .name("orc"),
            .characterSheet(.default),
            .in(.startRoom)
        )

        let weapon = Item(
            id: "sword",
            .name("sword"),
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            items: enemy, weapon
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Initiate combat with weapon
        try await engine.execute("slay the orc with my sword")

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > slay the orc with my sword
            You press forward with your sword leading the way toward flesh
            while the orc backs away, unarmed but still dangerous as any
            cornered thing.

            You attack with the sword! The orc dodges, more puzzled than
            threatened by your choice of weapon.

            The counterblow comes wild and desperate, the orc hammering
            through your guard to bruise rather than break. Pain flickers
            and dies. Your body has more important work.
            """
        )

        let combatState = await engine.combatState
        let expected = CombatState(
            enemyID: "orc",
            roundCount: 1,
            playerWeaponID: "sword",
            combatIntensity: 0.26,
            playerFatigue: 0.18,
            enemyFatigue: 0.14
        )
        expectNoDifference(combatState, expected)
    }

    // MARK: - Enemy Attacks Tests

    @Test("enemyAttacks creates combat state and returns appropriate message")
    func testEnemyAttacksCreatesCombatState() async throws {
        let dragon = Item(
            id: "dragon",
            .name("red dragon"),
            .characterSheet(.init(isFighting: true)),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: dragon
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Enemy attacks
        try await engine.execute("look")

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > look
            --- Laboratory ---

            A laboratory in which strange experiments are being conducted.

            You can see a red dragon here.

            The red dragon attacks with pure murderous intent! You brace
            yourself for the impact, guard up, ready for the worst kind of
            fight.
            """
        )

        // Then: Combat state should be created
        let combatState = await engine.combatState
        expectNoDifference(
            combatState,
            CombatState(
                enemyID: "dragon",
                roundCount: 0,
                playerWeaponID: nil
            )
        )

        // And: Enemy should be marked as touched
        let finalDragon = await engine.item("dragon")
        #expect(await finalDragon.hasFlag(.isTouched) == true)
    }

    @Test("enemyAttacks with player weapon includes weapon in combat state")
    func testEnemyAttacksWithPlayerWeapon() async throws {
        let axe = Item(
            id: "axe",
            .name("battle axe"),
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            items: Lab.troll.fighting, axe
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Enemy attacks while player has weapon
        try await engine.execute("look")

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > look
            --- Laboratory ---

            A laboratory in which strange experiments are being conducted.

            You can see a fierce troll here.

            The fearsome beast comes at you unarmed but fearless! You level
            your battle axe at his approach--will your weapon stop such
            determination?
            """
        )

        // Then: Combat state should be created
        let combatState = await engine.combatState
        expectNoDifference(
            combatState,
            CombatState(
                enemyID: "troll",
                roundCount: 0,
                playerWeaponID: "axe"
            )
        )
    }

    // MARK: - Player Attacks Tests

    @Test("playerAttacks creates combat state and returns appropriate message")
    func testPlayerAttacksCreatesCombatState() async throws {
        let skeleton = Item(
            id: "skeleton",
            .name("skeleton warrior"),
            .characterSheet(.default),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: skeleton
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Player attacks
        try await engine.execute("attack the skeleton warrior")

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > attack the skeleton warrior
            You close the distance fast with fists ready as the skeleton
            warrior mirrors your stance, both of you committed to finding
            out who breaks first.

            You land a light punch that it barely feels. It notes the minor
            damage and dismisses it.

            The counterblow comes wild and desperate, the skeleton warrior
            hammering through your guard to bruise rather than break. Pain
            flickers and dies. Your body has more important work.
            """
        )

        // Then: Combat state should be created
        let combatState = await engine.combatState
        let expectedSkeleton = CombatState(
            enemyID: "skeleton",
            roundCount: 1,
            playerWeaponID: nil,
            combatIntensity: 0.33999999999999997,
            playerFatigue: 0.18,
            enemyFatigue: 0.18
        )
        expectNoDifference(combatState, expectedSkeleton)

        // And: Enemy should be marked as touched
        let finalSkeleton = await engine.item("skeleton")
        #expect(await finalSkeleton.hasFlag(.isTouched) == true)
    }

    @Test("playerAttacks with weapon includes weapon in combat state")
    func testPlayerAttacksWithWeapon() async throws {
        let zombie = Item(
            id: "zombie",
            .name("shambling zombie"),
            .characterSheet(.default),
            .in(.startRoom)
        )

        let mace = Item(
            id: "mace",
            .name("iron mace"),
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            items: zombie, mace
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Player attacks with weapon
        try await engine.execute("slay the shambling zombie")

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > slay the shambling zombie
            You press forward with your iron mace leading the way toward
            flesh while the shambling zombie backs away, unarmed but still
            dangerous as any cornered thing.

            You attack with the iron mace! The shambling zombie dodges,
            more puzzled than threatened by your choice of weapon.

            The counterblow comes wild and desperate, the shambling zombie
            hammering through your guard to bruise rather than break. Pain
            flickers and dies. Your body has more important work.
            """
        )

        // Then: Combat state should be created
        let combatState = await engine.combatState
        let expectedZombie = CombatState(
            enemyID: "zombie",
            roundCount: 1,
            playerWeaponID: "mace",
            combatIntensity: 0.26,
            playerFatigue: 0.18,
            enemyFatigue: 0.14
        )
        expectNoDifference(combatState, expectedZombie)
    }

    // MARK: - Get Combat Result Tests

    @Test("getCombatResult uses default StandardCombatSystem when none specified")
    func testGetCombatResultUsesDefaultCombatSystem() async throws {
        let goblin = Item(
            id: "goblin",
            .name("goblin"),
            .characterSheet(.default),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: goblin
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Initiate combat
        try await engine.execute("kill the goblin")

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > kill the goblin
            You close the distance fast with fists ready as the goblin
            mirrors your stance, both of you committed to finding out who
            breaks first.

            You land a light punch that it barely feels. It notes the minor
            damage and dismisses it.

            The counterblow comes wild and desperate, the goblin hammering
            through your guard to bruise rather than break. Pain flickers
            and dies. Your body has more important work.
            """
        )
    }

    // MARK: - Get Player Action Tests

    @Test("getPlayerAction converts attack intents to attack action")
    func testGetPlayerActionAttackIntents() async throws {
        let game = MinimalGame()
        let (engine, _) = await GameEngine.test(blueprint: game)

        let combatState = CombatState(enemyID: "enemy", roundCount: 1)

        let attackVerbs: [Verb] = [.attack, .burn, .cut, .eat]

        for verb in attackVerbs {
            let command = Command(verb: verb)
            let action = await engine.getPlayerAction(
                for: command,
                in: combatState
            )
            #expect(action == .attack)
        }
    }

    @Test("getPlayerAction converts ask/tell intents to talk action")
    func testGetPlayerActionTalkIntents() async throws {
        let game = MinimalGame()
        let (engine, _) = await GameEngine.test(blueprint: game)

        let combatState = CombatState(enemyID: "enemy", roundCount: 1)

        // Test ask without topic
        let command = Command(verb: .ask)
        let askAction = await engine.getPlayerAction(for: command, in: combatState)
        if case .talk(let topic) = askAction {
            #expect(topic == nil)
        } else {
            #expect(Bool(false), "Ask should map to .talk action")
        }

        // Test tell - since we can't easily create indirectObject, test basic tell
        let tellCommand = Command(verb: .tell)
        let tellAction = await engine.getPlayerAction(for: tellCommand, in: combatState)
        if case .talk(let topic) = tellAction {
            #expect(topic == nil)
        } else {
            #expect(Bool(false), "Tell should map to .talk action")
        }
    }

    @Test("getPlayerAction converts move intent to flee action")
    func testGetPlayerActionMoveIntent() async throws {
        let game = MinimalGame()
        let (engine, _) = await GameEngine.test(blueprint: game)

        let combatState = CombatState(enemyID: "enemy", roundCount: 1)

        let moveCommand = Command(verb: .move, direction: .north)
        let action = await engine.getPlayerAction(for: moveCommand, in: combatState)

        if case .flee(let direction) = action {
            #expect(direction == .north)
        } else {
            #expect(Bool(false), "Move should map to .flee action")
        }
    }

    //    @Test("getPlayerAction converts defend intent to defend action")
    //    func testGetPlayerActionDefendIntent() async throws {
    //        let game = MinimalGame()
    //        let (engine, _) = await GameEngine.test(blueprint: game)
    //
    //        let combatState = CombatState(enemyID: "enemy", roundCount: 1)
    //
    //        let defendCommand = Command(verb: .block)  // Using block as defensive verb
    //        let action = await engine.getPlayerAction(for: defendCommand, in: combatState)
    //        switch action {
    //        case .defend:
    //            // Expected case
    //            break
    //        default:
    //            #expect(Bool(false), "Block command should map to .defend action but got \(action)")
    //        }
    //    }

    @Test("getPlayerAction converts give intent with item to useItem action")
    func testGetPlayerActionGiveIntentWithItem() async throws {
        let potion = Item(
            id: "potion",
            .name("health potion"),
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            items: potion
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        let combatState = CombatState(enemyID: "enemy", roundCount: 1)
        let potionProxy = await engine.item("potion")

        let giveCommand = Command(verb: .give, directObject: .item(potionProxy))
        let action = await engine.getPlayerAction(for: giveCommand, in: combatState)

        if case .useItem(let item) = action {
            #expect(item.id == "potion")
        } else {
            #expect(Bool(false), "Give with item should map to .useItem action")
        }
    }

    @Test("getPlayerAction defaults to other action for unrecognized intents")
    func testGetPlayerActionDefaultsToOther() async throws {
        let game = MinimalGame()
        let (engine, _) = await GameEngine.test(blueprint: game)

        let combatState = CombatState(enemyID: "enemy", roundCount: 1)

        let unknownCommand = Command(verb: .look)
        let action = await engine.getPlayerAction(for: unknownCommand, in: combatState)
        switch action {
        case .other:
            // Expected case
            break
        default:
            #expect(Bool(false), "Look command should map to .other action but got \(action)")
        }
    }

    // MARK: - Should End Combat Tests

    @Test("shouldEndCombat returns true when enemy is dead")
    func testShouldEndCombatWhenEnemyIsDead() async throws {
        let deadEnemy = Item(
            id: "deadEnemy",
            .name("dead enemy"),
            .characterSheet(.init(consciousness: .dead)),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: deadEnemy
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        let enemyProxy = await engine.item("deadEnemy")
        let shouldEnd = await engine.shouldEndCombat(enemy: enemyProxy)
        #expect(shouldEnd == true)
    }

    @Test("shouldEndCombat returns true when enemy is unconscious")
    func testShouldEndCombatWhenEnemyIsUnconscious() async throws {
        let unconsciousEnemy = Item(
            id: "unconsciousEnemy",
            .name("unconscious enemy"),
            .characterSheet(.init(consciousness: .unconscious)),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: unconsciousEnemy
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        let enemyProxy = await engine.item("unconsciousEnemy")
        let shouldEnd = await engine.shouldEndCombat(enemy: enemyProxy)
        #expect(shouldEnd == true)
    }

    @Test("shouldEndCombat returns true when player is dead")
    func testShouldEndCombatWhenPlayerIsDead() async throws {
        let enemy = Item(
            id: "enemy",
            .name("enemy"),
            .characterSheet(.default),
            .in(.startRoom)
        )

        let game = MinimalGame(items: enemy)
        let (engine, _) = await GameEngine.test(blueprint: game)

        // Set player as dead
        try await engine.apply(
            engine.player.setHealth(to: 0)
        )

        let enemyProxy = await engine.item("enemy")
        let shouldEnd = await engine.shouldEndCombat(enemy: enemyProxy)
        #expect(shouldEnd == true)
    }

    @Test("shouldEndCombat returns true when player health is zero or below")
    func testShouldEndCombatWhenPlayerHealthZero() async throws {
        let enemy = Item(
            id: "enemy",
            .name("enemy"),
            .characterSheet(.default),
            .in(.startRoom)
        )

        let deadPlayer = Player(
            in: .startRoom,
            characterSheet: .init(health: 0)
        )

        let game = MinimalGame(
            player: deadPlayer,
            items: enemy
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        let enemyProxy = await engine.item("enemy")
        let shouldEnd = await engine.shouldEndCombat(enemy: enemyProxy)
        #expect(shouldEnd == true)
    }

    @Test("shouldEndCombat returns true when enemy health is zero or below")
    func testShouldEndCombatWhenEnemyHealthZero() async throws {
        let weakEnemy = Item(
            id: "weakEnemy",
            .name("weak enemy"),
            .characterSheet(.init(health: 0)),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: weakEnemy
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        let enemyProxy = await engine.item("weakEnemy")
        let shouldEnd = await engine.shouldEndCombat(enemy: enemyProxy)
        #expect(shouldEnd == true)
    }

    @Test("shouldEndCombat returns false when combat should continue")
    func testShouldEndCombatReturnsFalseWhenCombatContinues() async throws {
        let healthyEnemy = Item(
            id: "healthyEnemy",
            .name("healthy enemy"),
            .characterSheet(.init(health: 100)),
            .in(.startRoom)
        )

        let healthyPlayer = Player(
            in: .startRoom,
            characterSheet: .init(health: 100)
        )

        let game = MinimalGame(
            player: healthyPlayer,
            items: healthyEnemy
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        let enemyProxy = await engine.item("healthyEnemy")
        let shouldEnd = await engine.shouldEndCombat(enemy: enemyProxy)
        #expect(shouldEnd == false)
    }

    // MARK: - Integration Tests

    @Test("complete combat flow from initiation to resolution")
    func testCompleteCombatFlow() async throws {
        let rat = Item(
            id: "rat",
            .name("giant rat"),
            .characterSheet(
                .init(health: 10)
            ),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: rat
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Initiate combat
        try await engine.execute("kill the rat")

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > kill the rat
            You close the distance fast with fists ready as the giant rat
            mirrors your stance, both of you committed to finding out who
            breaks first.

            You land a light punch that it barely feels. It notes the minor
            damage and dismisses it.

            The giant rat retaliates with violence but you're already
            elsewhere when the blow arrives.
            """
        )

        // 2. Process combat turn that ends combat
        let command = Command(verb: .attack)
        let combatResult = try await engine.getCombatResult(for: command)

        // Process the result to apply state changes
        try await engine.processActionResult(combatResult)

        // 3. Combat should now be ended
        #expect(await engine.isInCombat == false)
        #expect(await engine.combatState == nil)
    }

    @Test("combat state persists across multiple turns")
    func testCombatStatePersistsAcrossTurns() async throws {
        let ogre = Item(
            id: "ogre",
            .name("fierce ogre"),
            .characterSheet(.init(health: 100)),
            .in(.startRoom)
        )

        let club = Item(
            id: "club",
            .name("wooden club"),
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            items: ogre, club
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Initiate combat
        try await engine.execute("attack the ogre")

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > attack the ogre
            You press forward with your wooden club leading the way toward
            flesh while the fierce ogre backs away, unarmed but still
            dangerous as any cornered thing.

            You attack with the wooden club! The fierce ogre dodges, more
            puzzled than threatened by your choice of weapon.

            The counterblow comes wild and desperate, the fierce ogre
            hammering through your guard to bruise rather than break. Pain
            flickers and dies. Your body has more important work.
            """
        )

        let initialCombatState = await engine.combatState
        #expect(initialCombatState?.enemyID == "ogre")
        #expect(initialCombatState?.playerWeaponID == "club")

        // Process multiple combat turns
        for _ in 1...3 {
            let command = Command(verb: .attack)
            _ = try await engine.getCombatResult(for: command)

            // Combat state should persist
            #expect(await engine.isInCombat == true)
            let currentState = await engine.combatState
            #expect(currentState?.enemyID == "ogre")
            #expect(currentState?.playerWeaponID == "club")
        }
    }

    @Test("combat with multiple weapons and enemies")
    func testCombatWithMultipleWeaponsAndEnemies() async throws {
        let wolf = Item(
            id: "wolf",
            .name("dire wolf"),
            .characterSheet(.default),
            .in(.startRoom)
        )

        let bear = Item(
            id: "bear",
            .name("brown bear"),
            .characterSheet(.default),
            .in(.startRoom)
        )

        let sword = Item(
            id: "sword",
            .name("steel sword"),
            .isWeapon,
            .isTakable,
            .in(.player)
        )

        let bow = Item(
            id: "bow",
            .name("longbow"),
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            items: wolf, bear, sword, bow
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Enemy attacks
        try await engine.execute(
            "slay the wolf with the sword",
            "kill the bear",
            "kill the bear with the bow",
        )

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > slay the wolf with the sword
            You press forward with your steel sword leading the way toward
            flesh while the dire wolf backs away, unarmed but still
            dangerous as any cornered thing.

            You nick the dire wolf with your steel sword, the weapon barely
            breaking skin. It notes the minor damage and dismisses it.

            The dire wolf retaliates with violence but you're already
            elsewhere when the blow arrives.

            > kill the bear
            You and the dire wolf are already exchanging blows!

            You nick the dire wolf with your steel sword, the weapon barely
            breaking skin. It notes the minor damage and dismisses it.

            The dire wolf strikes back hard but you duck away, the punch
            finding only the ghost of where you were.

            > kill the bear with the bow
            You're already locked in combat with the dire wolf!

            You attack with the longbow! The dire wolf dodges, more puzzled
            than threatened by your choice of weapon.

            The dire wolf retaliates with expert technique, disarming you
            barehanded and sending your steel sword clattering away.
            """
        )
    }
}
