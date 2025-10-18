import CustomDump
import GnustoTestSupport
import Testing

@testable import GnustoEngine
@testable import GnustoMiddleware

@Suite("GameEngine Combat Tests")
struct GameEngineCombatTests {

    // MARK: - Combat State Management Tests

    @Test("isInCombat returns false when no combat state exists")
    func testIsInCombatFalseWhenNoCombat() async throws {
        let game = MinimalGame(
            middleware: [CombatMiddleware.mock]
        )
        let (engine, _) = await GameEngine.test(blueprint: game)

        #expect(await CombatMiddleware.isInCombat(in: engine) == false)
    }

    @Test("isInCombat returns true when combat state exists")
    func testIsInCombatTrueWhenInCombat() async throws {
        let enemy = Item("goblin")
            .name("goblin")
            .characterSheet(.default)
            .in(.startRoom)

        let game = MinimalGame(
            items: enemy,
            middleware: [CombatMiddleware.mock]
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Initiate combat
        try await engine.execute("slay the goblin")

        await mockIO.expect(
            """
            > slay the goblin
            No weapons needed as you attack with pure violence while the
            goblin braces for the inevitable collision of flesh and bone.

            Your strike grazes the goblin, more push than punch. It
            registers the wound with annoyance.

            In the tangle, the goblin drives an elbow home -- sudden
            pressure that blooms into dull pain. The cut registers dimly.
            Blood, but not enough to matter.
            """
        )

        #expect(await CombatMiddleware.isInCombat(in: engine) == true)
    }

    @Test("combatState returns nil when no combat exists")
    func testCombatStateNilWhenNoCombat() async throws {
        let game = MinimalGame()
        let (engine, _) = await GameEngine.test(blueprint: game)

        #expect(await CombatMiddleware.combatState(in: engine) == nil)
    }

    @Test("combatState returns combat state when in combat")
    func testCombatStateReturnsStateWhenInCombat() async throws {
        let enemy = Item("orc")
            .name("orc")
            .characterSheet(.default)
            .in(.startRoom)

        let weapon = Item("sword")
            .name("sword")
            .isTakable
            .in(.player)

        let game = MinimalGame(
            items: enemy, weapon,
            middleware: [CombatMiddleware.mock]
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Initiate combat with weapon
        try await engine.execute("slay the orc with my sword")

        await mockIO.expect(
            """
            > slay the orc with my sword
            Armed and hungry for violence, you strike with your sword as
            the orc can only dodge and weave against the advantage of
            sharpened metal.

            Brandishing the sword, you advance on the orc! It's
            unconventional, but might just work.

            The orc answers with raw violence, a clubbing strike that finds
            you but lacks the angle to truly hurt. Pain flickers and dies.
            Your body has more important work.
            """
        )

        let combatState = await CombatMiddleware.combatState(in: engine)
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
        let dragon = Item("dragon")
            .name("red dragon")
            .characterSheet(.init(isFighting: true))
            .in(.startRoom)

        let game = MinimalGame(
            items: dragon,
            middleware: [CombatMiddleware.mock]
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Enemy attacks
        try await engine.execute("look")

        await mockIO.expect(
            """
            > look
            --- Laboratory ---

            A laboratory in which strange experiments are being conducted.

            There is a red dragon here.

            In a moment of raw violence, the red dragon comes at you with
            nothing but fury! You raise your fists, knowing this will hurt
            regardless of who wins.
            """
        )

        // Then: Combat state should be created
        let combatState = await CombatMiddleware.combatState(in: engine)
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
        let axe = Item("axe")
            .name("battle axe")
            .isTakable
            .in(.player)

        let game = MinimalGame(
            items: Lab.nastyTroll.fighting, axe,
            middleware: [CombatMiddleware.mock]
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Enemy attacks while player has weapon
        try await engine.execute("look")

        await mockIO.expect(
            """
            > look
            --- Laboratory ---

            A laboratory in which strange experiments are being conducted.

            There is a nasty troll here.

            Despite having no weapon, the fearsome beast charges with
            terrifying resolve! You grip your battle axe tighter, knowing
            you'd better use this advantage.
            """
        )

        // Then: Combat state should be created
        let combatState = await CombatMiddleware.combatState(in: engine)
        expectNoDifference(
            combatState,
            CombatState(
                enemyID: .nastyTroll,
                roundCount: 0,
                playerWeaponID: "axe"
            )
        )
    }

    // MARK: - Player Attacks Tests

    @Test("playerAttacks creates combat state and returns appropriate message")
    func testPlayerAttacksCreatesCombatState() async throws {
        let skeleton = Item("skeleton")
            .name("skeleton warrior")
            .characterSheet(.default)
            .in(.startRoom)

        let game = MinimalGame(
            items: skeleton,
            middleware: [CombatMiddleware.mock]
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Player attacks
        try await engine.execute("attack the skeleton warrior")

        await mockIO.expect(
            """
            > attack the skeleton warrior
            No weapons needed as you attack with pure violence while the
            skeleton warrior braces for the inevitable collision of flesh
            and bone.

            Your strike grazes the skeleton warrior, more push than punch.
            It registers the wound with annoyance.

            In the tangle, the skeleton warrior drives an elbow home --
            sudden pressure that blooms into dull pain. The cut registers
            dimly. Blood, but not enough to matter.
            """
        )

        // Then: Combat state should be created
        let combatState = await CombatMiddleware.combatState(in: engine)
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
        let zombie = Item("zombie")
            .name("shambling zombie")
            .characterSheet(.default)
            .in(.startRoom)

        let mace = Item("mace")
            .name("iron mace")
            .isTakable
            .in(.player)

        let game = MinimalGame(
            items: zombie, mace,
            middleware: [CombatMiddleware.mock]
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Player attacks with weapon
        try await engine.execute("slay the shambling zombie")

        await mockIO.expect(
            """
            > slay the shambling zombie
            Armed and hungry for violence, you strike with your iron mace
            as the shambling zombie can only dodge and weave against the
            advantage of sharpened metal.

            Brandishing the iron mace, you advance on the shambling zombie!
            It's unconventional, but might just work.

            The shambling zombie answers with raw violence, a clubbing
            strike that finds you but lacks the angle to truly hurt. Pain
            flickers and dies. Your body has more important work.
            """
        )

        // Then: Combat state should be created
        let combatState = await CombatMiddleware.combatState(in: engine)
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
        let goblin = Item("goblin")
            .name("goblin")
            .characterSheet(.default)
            .in(.startRoom)

        let game = MinimalGame(
            items: goblin,
            middleware: [CombatMiddleware.mock]
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Initiate combat
        try await engine.execute("kill the goblin")

        await mockIO.expect(
            """
            > kill the goblin
            No weapons needed as you attack with pure violence while the
            goblin braces for the inevitable collision of flesh and bone.

            Your strike grazes the goblin, more push than punch. It
            registers the wound with annoyance.

            In the tangle, the goblin drives an elbow home -- sudden
            pressure that blooms into dull pain. The cut registers dimly.
            Blood, but not enough to matter.
            """
        )
    }
    // MARK: - Should End Combat Tests

    @Test("shouldEndCombat returns true when enemy is dead")
    func testShouldEndCombatWhenEnemyIsDead() async throws {
        let deadEnemy = Item("deadEnemy")
            .name("dead enemy")
            .characterSheet(.init(consciousness: .dead))
            .in(.startRoom)

        let game = MinimalGame(
            items: deadEnemy,
            middleware: [CombatMiddleware.mock]
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        let enemyProxy = await engine.item("deadEnemy")
        let shouldEnd = await CombatMiddleware.shouldEndCombat(enemy: enemyProxy, engine: engine)
        #expect(shouldEnd == true)
    }

    @Test("shouldEndCombat returns true when enemy is unconscious")
    func testShouldEndCombatWhenEnemyIsUnconscious() async throws {
        let unconsciousEnemy = Item("unconsciousEnemy")
            .name("unconscious enemy")
            .characterSheet(.init(consciousness: .unconscious))
            .in(.startRoom)

        let game = MinimalGame(
            items: unconsciousEnemy,
            middleware: [CombatMiddleware.mock]
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        let enemyProxy = await engine.item("unconsciousEnemy")
        let shouldEnd = await CombatMiddleware.shouldEndCombat(enemy: enemyProxy, engine: engine)
        #expect(shouldEnd == true)
    }

    @Test("shouldEndCombat returns true when player is dead")
    func testShouldEndCombatWhenPlayerIsDead() async throws {
        let enemy = Item("enemy")
            .name("enemy")
            .characterSheet(.default)
            .in(.startRoom)

        let game = MinimalGame(
            items: enemy,
            middleware: [CombatMiddleware.mock]
        )
        let (engine, _) = await GameEngine.test(blueprint: game)

        // Set player as dead
        try await engine.apply(
            engine.player.setHealth(to: 0)
        )

        let enemyProxy = await engine.item("enemy")
        let shouldEnd = await CombatMiddleware.shouldEndCombat(enemy: enemyProxy, engine: engine)
        #expect(shouldEnd == true)
    }

    @Test("shouldEndCombat returns true when player health is zero or below")
    func testShouldEndCombatWhenPlayerHealthZero() async throws {
        let enemy = Item("enemy")
            .name("enemy")
            .characterSheet(.default)
            .in(.startRoom)

        let deadPlayer = Player(
            in: .startRoom,
            characterSheet: .init(health: 0)
        )

        let game = MinimalGame(
            player: deadPlayer,
            items: enemy,
            middleware: [CombatMiddleware.mock]
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        let enemyProxy = await engine.item("enemy")
        let shouldEnd = await CombatMiddleware.shouldEndCombat(enemy: enemyProxy, engine: engine)
        #expect(shouldEnd == true)
    }

    @Test("shouldEndCombat returns true when enemy health is zero or below")
    func testShouldEndCombatWhenEnemyHealthZero() async throws {
        let weakEnemy = Item("weakEnemy")
            .name("weak enemy")
            .characterSheet(.init(health: 0))
            .in(.startRoom)

        let game = MinimalGame(
            items: weakEnemy,
            middleware: [CombatMiddleware.mock]
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        let enemyProxy = await engine.item("weakEnemy")
        let shouldEnd = await CombatMiddleware.shouldEndCombat(enemy: enemyProxy, engine: engine)
        #expect(shouldEnd == true)
    }

    @Test("shouldEndCombat returns false when combat should continue")
    func testShouldEndCombatReturnsFalseWhenCombatContinues() async throws {
        let healthyEnemy = Item("healthyEnemy")
            .name("healthy enemy")
            .characterSheet(.init(health: 100))
            .in(.startRoom)

        let healthyPlayer = Player(
            in: .startRoom,
            characterSheet: .init(health: 100)
        )

        let game = MinimalGame(
            player: healthyPlayer,
            items: healthyEnemy,
            middleware: [CombatMiddleware.mock]
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        let enemyProxy = await engine.item("healthyEnemy")
        let shouldEnd = await CombatMiddleware.shouldEndCombat(enemy: enemyProxy, engine: engine)
        #expect(shouldEnd == false)
    }

    // MARK: - Integration Tests

    @Test("complete combat flow from initiation to resolution")
    func testCompleteCombatFlow() async throws {
        let rat = Item("rat")
            .name("giant rat")
            .characterSheet(
                health: 12
            )
            .in(.startRoom)

        let game = MinimalGame(
            items: rat,
            middleware: [CombatMiddleware.mock]
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Initiate combat
        try await engine.execute("kill the rat")

        await mockIO.expect(
            """
            > kill the rat
            No weapons needed as you attack with pure violence while the
            giant rat braces for the inevitable collision of flesh and
            bone.

            Your bare hands deliver death! The giant rat crumples without
            ceremony, the fight conclusively ended.
            """
        )

        #expect(await engine.item("rat").health == 0)
        #expect(await engine.item("rat").isDead)

        // Then: Combat should now be ended
        #expect(await CombatMiddleware.isInCombat(in: engine) == false)
        #expect(await CombatMiddleware.combatState(in: engine) == nil)
    }

    @Test("combat state persists across multiple turns")
    func testCombatStatePersistsAcrossTurns() async throws {
        let ogre = Item("ogre")
            .name("fierce ogre")
            .characterSheet(.init(health: 100))
            .in(.startRoom)

        let club = Item("club")
            .name("wooden club")
            .isTakable
            .in(.player)

        let game = MinimalGame(
            items: ogre, club,
            middleware: [CombatMiddleware.mock]
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Initiate combat
        try await engine.execute("attack the ogre")

        await mockIO.expect(
            """
            > attack the ogre
            Armed and hungry for violence, you strike with your wooden club
            as the fierce ogre can only dodge and weave against the
            advantage of sharpened metal.

            Brandishing the wooden club, you advance on the fierce ogre!
            It's unconventional, but might just work.

            The fierce ogre answers with raw violence, a clubbing strike
            that finds you but lacks the angle to truly hurt. Pain flickers
            and dies. Your body has more important work.
            """
        )

        let initialCombatState = await CombatMiddleware.combatState(in: engine)
        #expect(initialCombatState?.enemyID == "ogre")
        #expect(initialCombatState?.playerWeaponID == "club")

        // Process multiple combat turns
        for _ in 1...3 {
            try await engine.execute("attack")

            // Combat state should persist
            #expect(await CombatMiddleware.isInCombat(in: engine) == true)
            let currentState = await CombatMiddleware.combatState(in: engine)
            #expect(currentState?.enemyID == "ogre")
            #expect(currentState?.playerWeaponID == "club")
        }
    }

    @Test("combat with multiple weapons and enemies")
    func testCombatWithMultipleWeaponsAndEnemies() async throws {
        let wolf = Item("wolf")
            .name("dire wolf")
            .characterSheet(.default)
            .in(.startRoom)

        let bear = Item("bear")
            .name("brown bear")
            .characterSheet(.default)
            .in(.startRoom)

        let sword = Item("sword")
            .name("steel sword")
            .isWeapon
            .isTakable
            .in(.player)

        let bow = Item("bow")
            .name("longbow")
            .isTakable
            .in(.player)

        let game = MinimalGame(
            items: wolf, bear, sword, bow,
            middleware: [CombatMiddleware.mock]
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Enemy attacks
        try await engine.execute(
            "slay the wolf with the sword",
            "kill the bear",
            "kill the bear with the bow",
        )

        await mockIO.expect(
            """
            > slay the wolf with the sword
            Armed and hungry for violence, you strike with your steel sword
            as the dire wolf can only dodge and weave against the advantage
            of sharpened metal.

            Your steel sword finds the dire wolf exposed, carving a solid
            wound that draws a grunt of pain. It absorbs the hit, flesh
            suffering but endurance holding.

            In the tangle, the dire wolf drives an elbow home -- sudden
            pressure that blooms into dull pain. The cut registers dimly.
            Blood, but not enough to matter.

            > kill the bear
            Your steel sword finds the dire wolf exposed, carving a solid
            wound that draws a grunt of pain. It absorbs the hit, flesh
            suffering but endurance holding.

            In the tangle, the dire wolf drives an elbow home -- sudden
            pressure that blooms into dull pain. You feel it connect,
            adding to the bruises but not breaking your rhythm.

            > kill the bear with the bow
            Brandishing the longbow, you advance on the dire wolf! It's
            unconventional, but might just work.

            The counterblow comes wild and desperate, the dire wolf
            hammering through your guard to bruise rather than break. You
            feel the hit, another note in the symphony of damage.
            """
        )
    }
}
