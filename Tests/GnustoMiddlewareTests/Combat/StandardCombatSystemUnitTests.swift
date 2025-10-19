import CustomDump
import GnustoTestSupport
import Testing

@testable import GnustoEngine
@testable import GnustoMiddleware

@Suite("Standard Combat System Unit Tests")
struct StandardCombatSystemUnitTests {

    // MARK: - Test Helpers

    /// Shared combat messenger for deterministic test results
    private let testMessenger = CombatMessenger()

    /// Creates a minimal test game with combat setup
    private func createTestGame() async -> (GameEngine, MockIOHandler) {
        let entrance = Location("entrance")
            .description("Entrance to the combat arena.")
            .north(.startRoom)
            .inherentlyLit

        let startRoom = Location(.startRoom)
            .name("Combat Arena")
            .description("A circular arena for testing combat.")
            .inherentlyLit

        let game = MinimalGame(
            player: Player(in: .startRoom),
            locations: entrance,
            startRoom,
            items: Lab.ironSword,
            Lab.nastyTroll,
            middleware: [
                CombatMiddleware(
                    combatSystems: [.nastyTroll: StandardCombatSystem(versus: .nastyTroll)]
                ),
            ]
        )

        return await GameEngine.test(blueprint: game)
    }

    func attackActionContext(for engine: GameEngine) async throws -> ActionContext {
        let command = await Command(
            verb: .attack,
            directObject: .item(Lab.nastyTroll.proxy(engine))
        )
        return ActionContext(command, engine)
    }

    func attackCombatContext(for engine: GameEngine) async throws -> CombatEventContext {
        let command = await Command(
            verb: .attack,
            directObject: .item(Lab.nastyTroll.proxy(engine))
        )
        return CombatEventContext(
            command,
            engine,
            combatMessenger: testMessenger
        )
    }

    // MARK: - processCombatTurn Tests

    @Test("processCombatTurn handles basic attack flow")
    func testProcessCombatTurnBasicAttack() async throws {
        let (engine, _) = await createTestGame()
        let combatSystem = StandardCombatSystem(
            versus: .nastyTroll,
            combatMessenger: testMessenger
        )
        let playerAction = PlayerAction.attack
        let result = try await combatSystem.processCombatTurn(
            playerAction: playerAction,
            in: attackActionContext(for: engine)
        )

        expectNoDifference(
            result.message,
            """
            Your blow with your iron sword catches the beast cleanly,
            tearing flesh and drawing crimson. The blow lands solidly, drawing blood. He
            feels the sting but remains strong.

            The grotesque monster's answer is swift and punishing -- knuckles
            meet flesh with the sound of meat hitting stone. First blood to them. The wound is real but manageable.
            """
        )
        expectNoDifference(result.changes.count, 3)
    }

    @Test("processCombatTurn handles combat ending scenarios")
    func testProcessCombatTurnCombatEnding() async throws {
        let (engine, _) = await createTestGame()
        let combatSystem = StandardCombatSystem(
            versus: .nastyTroll,
            combatMessenger: testMessenger
        )
        let result = try await combatSystem.processCombatTurn(
            playerAction: .attack,
            in: attackActionContext(for: engine)
        )

        // Should generate appropriate result for potential combat ending
        expectNoDifference(
            result.message,
            """
            Your blow with your iron sword catches the beast cleanly,
            tearing flesh and drawing crimson. The blow lands solidly, drawing blood. He
            feels the sting but remains strong.

            The grotesque monster's answer is swift and punishing -- knuckles
            meet flesh with the sound of meat hitting stone. First blood to them. The wound is real but manageable.
            """
        )
        expectNoDifference(result.changes.count, 3)
    }

    // MARK: - determineEnemyAction Tests

    @Test("determineEnemyAction returns appropriate enemy response")
    func testDetermineEnemyActionBasic() async throws {
        let (engine, _) = await createTestGame()
        let combatSystem = StandardCombatSystem(
            versus: .nastyTroll,
            combatMessenger: testMessenger
        )
        let troll = await engine.item(.nastyTroll)
        let playerAction = PlayerAction.attack
        let enemyEvent = try await combatSystem.determineEnemyAction(
            against: playerAction,
            enemy: troll,
            in: attackActionContext(for: engine)
        )

        // Enemy should respond with some action
        if let enemyEvent {
            #expect(enemyEvent.enemy == troll)
        }
    }

    @Test("determineEnemyAction handles unconscious enemy")
    func testDetermineEnemyActionUnconsciousEnemy() async throws {
        let (engine, _) = await createTestGame()
        let troll = await engine.item(.nastyTroll)

        // Make troll unconscious
        try await engine.apply(
            troll.setCharacterAttributes(consciousness: .unconscious)
        )

        let combatSystem = StandardCombatSystem(
            versus: .nastyTroll,
            combatMessenger: testMessenger
        )
        let playerAction = PlayerAction.attack
        let enemyEvent = try await combatSystem.determineEnemyAction(
            against: playerAction,
            enemy: troll,
            in: attackActionContext(for: engine)
        )

        // Unconscious enemy shouldn't act
        #expect(enemyEvent == nil)
    }

    // MARK: - selectTaunt Tests

    @Test("selectTaunt generates appropriate taunt events")
    func testSelectTaunt() async throws {
        let (engine, _) = await createTestGame()
        let combatSystem = StandardCombatSystem(
            versus: .nastyTroll,
            combatMessenger: testMessenger
        )
        let troll = await engine.item(.nastyTroll)
        let tauntEvent = await combatSystem.selectTaunt(
            from: troll,
            in: CombatTurn(
                playerEvent: .enemyMissed(
                    CombatEventPayload(
                        enemy: troll,
                        player: await engine.player,
                        playerWeapon: nil,
                        enemyWeapon: nil
                    )
                ),
                enemyEvent: .playerInjured(
                    CombatEventPayload(
                        enemy: troll,
                        player: await engine.player,
                        playerWeapon: nil,
                        enemyWeapon: nil,
                        damage: 0,
                        damageCategory: .none,
                        combatCondition: .vulnerable
                    )
                )
            ),
            context: ActionContext(Command(verb: .attack), engine),
            tauntRoll: 1
        )

        // Verify that a taunt event is generated
        #expect(tauntEvent != nil)
        if case .enemyAttacks(let payload) = tauntEvent {
            #expect(payload.combatCondition == .taunting)
        }
    }

    // MARK: - playerCombatEvent Tests

    @Test("playerCombatEvent handles attack action")
    func testPlayerCombatEventAttack() async throws {
        let (engine, _) = await createTestGame()
        let combatSystem = StandardCombatSystem(
            versus: .nastyTroll,
            combatMessenger: testMessenger
        )
        let troll = await engine.item(.nastyTroll)
        let playerEvent = try await combatSystem.playerCombatEvent(
            for: .attack,
            against: troll,
            in: attackActionContext(for: engine)
        )

        // Verify event is enemyInjured with correct damage
        if case .enemyInjured(let payload) = playerEvent {
            #expect(payload.enemy.id == troll.id)
            #expect(payload.damage == 17)
        } else {
            Issue.record("Expected enemyInjured event")
        }
    }

    @Test("playerCombatEvent handles flee action")
    func testPlayerCombatEventFlee() async throws {
        let (engine, _) = await createTestGame()
        let combatSystem = StandardCombatSystem(
            versus: .nastyTroll,
            combatMessenger: testMessenger
        )
        let troll = await engine.item(.nastyTroll)
        let playerEvent = try await combatSystem.playerCombatEvent(
            for: .flee(direction: .south),
            against: troll,
            in: attackActionContext(for: engine)
        )

        #expect(playerEvent == nil)
    }

    // MARK: - recalculateCombatState Tests

    @Test("recalculateCombatState updates state correctly")
    func testRecalculateCombatState() async throws {
        let (engine, _) = await createTestGame()
        let combatSystem = StandardCombatSystem(
            versus: .nastyTroll,
            combatMessenger: testMessenger
        )
        let troll = await engine.item(.nastyTroll)
        let sword = await engine.item("sword")
        try await engine.apply(
            CombatMiddleware.setCombatState(
                to: CombatState(
                    enemyID: .nastyTroll,
                    roundCount: 1,
                    playerWeaponID: "sword",
                    combatIntensity: 0.36,
                    playerFatigue: 0.115,
                    enemyFatigue: 0.082
                )
            )
        )

        let combatTurn = CombatTurn(
            playerEvent: .enemyInjured(
                CombatEventPayload(
                    enemy: troll,
                    player: await engine.player,
                    playerWeapon: sword,
                    enemyWeapon: nil,
                    damage: 5,
                    damageCategory: .light
                )
            ),
            enemyEvent: .playerInjured(
                CombatEventPayload(
                    enemy: troll,
                    player: await engine.player,
                    playerWeapon: nil,
                    enemyWeapon: nil,
                    damage: 3,
                    damageCategory: .scratch
                )
            )
        )

        let newState = try await combatSystem.recalculateCombatState(
            after: combatTurn,
            in: attackActionContext(for: engine)
        )

        expectNoDifference(
            newState,
            CombatState(
                enemyID: .nastyTroll,
                roundCount: 2,
                playerWeaponID: "sword",
                combatIntensity: 0.72,
                playerFatigue: 0.305,
                enemyFatigue: 0.06200000000000001
            )
        )
    }

    // MARK: - calculateAttributeBasedModifiers Tests

    @Test("calculateAttributeBasedModifiers returns appropriate values")
    func testCalculateAttributeBasedModifiers() async throws {
        let (engine, _) = await createTestGame()
        let combatSystem = StandardCombatSystem(
            versus: .nastyTroll,
            combatMessenger: testMessenger
        )

        let playerSheet = CharacterSheet(
            strength: 15,
            dexterity: 12,
            constitution: 14,
            wisdom: 10
        )

        let enemySheet = CharacterSheet(
            strength: 18,
            dexterity: 8,
            constitution: 16,
            wisdom: 6
        )

        let currentState = CombatState(
            enemyID: .nastyTroll,
            roundCount: 2,
            playerWeaponID: "sword",
            combatIntensity: 0.7,
            playerFatigue: 0.3,
            enemyFatigue: 0.3
        )

        let modifiers = try await combatSystem.calculateAttributeBasedModifiers(
            playerSheet: playerSheet,
            enemySheet: enemySheet,
            currentState: currentState,
            context: attackActionContext(for: engine)
        )

        #expect(modifiers.fatigue.player == -0.22)
        #expect(modifiers.fatigue.enemy == -0.38)
        #expect(modifiers.intensity == 0.06)
    }

    // MARK: - calculateRoundDurationFatigue Tests

    @Test("calculateRoundDurationFatigue computes fatigue correctly")
    func testCalculateRoundDurationFatigue() async throws {
        let (engine, _) = await createTestGame()
        let combatSystem = StandardCombatSystem(
            versus: .nastyTroll,
            combatMessenger: testMessenger
        )

        let playerSheet = CharacterSheet(constitution: 14)
        let enemySheet = CharacterSheet(constitution: 16)
        let currentState = CombatState(enemyID: .nastyTroll, roundCount: 5)

        let fatigue = try await combatSystem.calculateRoundDurationFatigue(
            playerSheet: playerSheet,
            enemySheet: enemySheet,
            currentState: currentState,
            context: attackActionContext(for: engine)
        )

        #expect(fatigue.player == 0.05)
        #expect(fatigue.enemy == 0.035)

        // Enemy has less fatigue due to higher constitution
        #expect(fatigue.enemy < fatigue.player)
    }

    // MARK: - generateTurnResult Tests

    @Test("generateTurnResult creates appropriate action result")
    func testGenerateTurnResult() async throws {
        let (engine, _) = await createTestGame()
        let combatSystem = StandardCombatSystem(
            versus: .nastyTroll,
            combatMessenger: testMessenger
        )
        let troll = await engine.item(.nastyTroll)
        let sword = await engine.item("sword")

        let combatTurn = CombatTurn(
            playerEvent: .enemyInjured(
                CombatEventPayload(
                    enemy: troll,
                    player: await engine.player,
                    playerWeapon: sword,
                    enemyWeapon: nil,
                    damage: 5,
                    damageCategory: .light
                )
            ),
            enemyEvent: .playerDodged(
                CombatEventPayload(
                    enemy: troll,
                    player: await engine.player,
                    playerWeapon: nil,
                    enemyWeapon: nil
                )
            )
        )

        let result = try await combatSystem.generateTurnResult(
            combatTurn,
            in: attackActionContext(for: engine)
        )

        expectNoDifference(
            result.message,
            """
            Your blow with your iron sword catches the fearsome beast cleanly,
            tearing flesh and drawing crimson. The blow lands solidly, drawing blood. He
            feels the sting but remains strong.

            The fearsome beast strikes back hard but you duck away, the punch finding only the ghost of where you were.
            """
        )
        #expect(
            result.changes == [await troll.setCharacterAttributes(health: 46)]
        )
    }

    // MARK: - generateEventResult Tests

    @Test("generateEventResult creates damage state changes")
    func testGenerateEventResultDamage() async throws {
        let (engine, _) = await createTestGame()
        let combatSystem = StandardCombatSystem(
            versus: .nastyTroll,
            combatMessenger: testMessenger
        )
        let troll = await engine.item(.nastyTroll)
        let sword = await engine.item("sword")

        let damageEvent = CombatEvent.enemyInjured(
            CombatEventPayload(
                enemy: troll,
                player: await engine.player,
                playerWeapon: sword,
                enemyWeapon: nil,
                damage: 8,
                damageCategory: .light
            )
        )

        let result = try await combatSystem.generateEventResult(
            for: damageEvent,
            in: attackCombatContext(for: engine)
        )

        let expected = await ActionResult(
            """
            Your blow with your iron sword catches the fearsome beast cleanly,
            tearing flesh and drawing crimson. The blow lands solidly, drawing blood. He
            feels the sting but remains strong.
            """,
            troll.setCharacterAttributes(health: 43)
        )

        // Should generate damage-related state changes
        expectNoDifference(result, expected)
    }

    @Test("generateEventResult handles player knocked unconscious")
    func testGenerateEventResultKnockout() async throws {
        let (engine, mockIO) = await createTestGame()
        let combatSystem = StandardCombatSystem(
            versus: .nastyTroll,
            combatMessenger: testMessenger
        )
        let troll = await engine.item(.nastyTroll)

        try await engine.apply(
            engine.player.move(to: "entrance"),
            troll.setCharacterAttributes(isFighting: true)
        )
        try await engine.execute("north")
        await mockIO.expect(
            """
            > north
            --- Combat Arena ---

            A circular arena for testing combat.

            There is a nasty troll here.

            Despite having no weapon, the fearsome beast charges with
            terrifying resolve! You grip your iron sword tighter, knowing
            you'd better use this advantage.
            """
        )

        let knockoutEvent = CombatEvent.playerUnconscious(
            CombatEventPayload(
                enemy: troll,
                player: await engine.player,
                playerWeapon: nil,
                enemyWeapon: nil,
                damage: 15,
                damageCategory: .moderate
            )
        )

        let result = try await combatSystem.generateEventResult(
            for: knockoutEvent,
            in: attackCombatContext(for: engine)
        )

        // Should have a message (exact text is random)
        #expect(result.message != nil)

        // Should generate correct state changes
        #expect(result.changes.count == 3)

        // Check player health change
        guard case .setPlayerAttributes(let attrs) = result.changes[0] else {
            Issue.record("Expected setPlayerAttributes for player")
            return
        }
        #expect(attrs.health == 35)
        #expect(attrs.consciousness == .unconscious)

        // Check combat state cleared
        guard case .clearGlobalState(let id) = result.changes[1] else {
            Issue.record("Expected clearGlobalState")
            return
        }
        #expect(id == .combatMiddlewareState)

        // Check enemy removed
        guard case .moveItem(let itemID, let parent) = result.changes[2] else {
            Issue.record("Expected moveItem for enemy")
            return
        }
        #expect(itemID == .nastyTroll)
        #expect(parent == .nowhere)

        // Check fuse effect
        #expect(result.effects.count == 1)
        guard case .startFuse = result.effects[0].type else {
            Issue.record("Expected startFuse effect")
            return
        }
    }

    // MARK: - getEnemyWeapon Tests

    @Test("getEnemyWeapon finds enemy weapon")
    func testGetEnemyWeapon() async throws {
        let club = Item("club")
            .name("wooden club")
            .isWeapon
            .in(.item(.nastyTroll))

        let game = MinimalGame(
            player: Player(in: .startRoom),
            locations: Location(
                id: .startRoom,
                .name("Combat Arena"),
                .description("A circular arena for testing combat."),
                .inherentlyLit
            ),
            items: Lab.nastyTroll,
            club,
            middleware: [
                CombatMiddleware(
                    combatSystems: [.nastyTroll: StandardCombatSystem(versus: .nastyTroll)]
                ),
            ]
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        // Set up combat state first
        try await engine.apply(
            CombatMiddleware.setCombatState(
                to: CombatState(enemyID: .nastyTroll, enemyWeaponID: "club")
            )
        )

        let combatSystem = StandardCombatSystem(
            versus: .nastyTroll,
            combatMessenger: testMessenger
        )
        let weapon = await combatSystem.getEnemyWeapon(from: engine)

        #expect(weapon?.id == "club")
    }

    @Test("getEnemyWeapon returns nil when no weapon")
    func testGetEnemyWeaponNoWeapon() async throws {
        let (engine, _) = await createTestGame()
        let combatSystem = StandardCombatSystem(
            versus: .nastyTroll,
            combatMessenger: testMessenger
        )

        let weapon = await combatSystem.getEnemyWeapon(from: engine)

        #expect(weapon == nil)
    }

    // MARK: - computeOffenseModifier Tests

    @Test("computeOffenseModifier with weapon")
    func testComputeOffenseModifierWithWeapon() async throws {
        let (engine, _) = await createTestGame()
        let combatSystem = StandardCombatSystem(
            versus: .nastyTroll,
            combatMessenger: testMessenger
        )

        let player = await engine.player
        let attacker = Combatant.player(player)
        let weapon = await engine.item("sword")
        let intensity = 1.0

        let modifier = await combatSystem.computeOffenseModifier(
            for: attacker,
            weapon: weapon,
            intensity: intensity
        )

        #expect(modifier >= -10)  // Reasonable range for modifiers
    }

    @Test("computeOffenseModifier without weapon")
    func testComputeOffenseModifierWithoutWeapon() async throws {
        let (engine, _) = await createTestGame()
        let combatSystem = StandardCombatSystem(
            versus: .nastyTroll,
            combatMessenger: testMessenger
        )

        let player = await engine.player
        let attacker = Combatant.player(player)
        let intensity = 1.0

        let modifier = await combatSystem.computeOffenseModifier(
            for: attacker,
            weapon: nil,
            intensity: intensity
        )

        #expect(modifier >= -10)  // Should still return valid modifier
    }

    // MARK: - computeDefenseAdjustment Tests

    @Test("computeDefenseAdjustment returns valid adjustment")
    func testComputeDefenseAdjustment() async throws {
        let (engine, _) = await createTestGame()
        let combatSystem = StandardCombatSystem(
            versus: .nastyTroll,
            combatMessenger: testMessenger
        )

        let troll = await engine.item(.nastyTroll)
        let defender = Combatant.enemy(troll)

        let adjustment = await combatSystem.computeDefenseAdjustment(
            for: defender
        )

        #expect(adjustment >= -10)  // Should return reasonable adjustment range
    }

    // MARK: - computeDamageAdjustment Tests

    @Test("computeDamageAdjustment with critical hit")
    func testComputeDamageAdjustmentCritical() async throws {
        let (engine, _) = await createTestGame()
        let combatSystem = StandardCombatSystem(
            versus: .nastyTroll,
            combatMessenger: testMessenger
        )

        let player = await engine.player
        let attacker = Combatant.player(player)
        let troll = await engine.item(.nastyTroll)
        let defender = Combatant.enemy(troll)
        let weapon = await engine.item("sword")
        let intensity = 1.5

        let adjustment = await combatSystem.computeDamageAdjustment(
            attacker: attacker,
            defender: defender,
            weapon: weapon,
            intensity: intensity,
            isCritical: true
        )

        #expect(adjustment.flat >= -10)
        #expect(adjustment.multiplier >= 0.5)  // Should be reasonable multiplier
    }

    @Test("computeDamageAdjustment normal hit")
    func testComputeDamageAdjustmentNormal() async throws {
        let (engine, _) = await createTestGame()
        let combatSystem = StandardCombatSystem(
            versus: .nastyTroll,
            combatMessenger: testMessenger
        )

        let player = await engine.player
        let attacker = Combatant.player(player)
        let troll = await engine.item(.nastyTroll)
        let defender = Combatant.enemy(troll)
        let weapon = await engine.item("sword")
        let intensity = 1.0

        let adjustment = await combatSystem.computeDamageAdjustment(
            attacker: attacker,
            defender: defender,
            weapon: weapon,
            intensity: intensity,
            isCritical: false
        )

        #expect(adjustment.flat >= -10)
        #expect(adjustment.multiplier >= 0.0)
    }

    // MARK: - shouldTriggerSpecialEvent Tests

    @Test("shouldTriggerSpecialEvent with natural 20 always triggers")
    func testShouldTriggerSpecialEventNatural20() async throws {
        let (engine, _) = await createTestGame()
        let combatSystem = StandardCombatSystem(
            versus: .nastyTroll,
            combatMessenger: testMessenger
        )

        let shouldTrigger = await combatSystem.shouldTriggerSpecialEvent(
            attackRoll: 20,
            marginOfHit: 1,
            escalation: 0.1,
            intensity: 0.1,
            attacker: CharacterSheet(strength: 10),
            defender: CharacterSheet(constitution: 10),
            engine: engine
        )

        #expect(shouldTrigger == true)
    }

    @Test("shouldTriggerSpecialEvent is rare with low values")
    func testShouldTriggerSpecialEventRarity() async throws {
        let (engine, _) = await createTestGame()
        let combatSystem = StandardCombatSystem(
            versus: .nastyTroll,
            combatMessenger: testMessenger
        )

        // Test multiple times to ensure special events are truly rare
        var triggerCount = 0
        let testIterations = 50

        for _ in 0..<testIterations {
            let shouldTrigger = await combatSystem.shouldTriggerSpecialEvent(
                attackRoll: 15,  // Good roll but not crit
                marginOfHit: 3,
                escalation: 0.5,
                intensity: 0.5,
                attacker: CharacterSheet(strength: 12),
                defender: CharacterSheet(constitution: 12),
                engine: engine
            )
            if shouldTrigger {
                triggerCount += 1
            }
        }

        // Special events should be RARE - expect less than 30% trigger rate
        let triggerRate = Double(triggerCount) / Double(testIterations)
        #expect(triggerRate < 0.3, "Special events should be rare, got \(triggerRate) trigger rate")
    }

    @Test("shouldTriggerSpecialEvent increases with escalation")
    func testShouldTriggerSpecialEventEscalation() async throws {
        let (engine, _) = await createTestGame()
        let combatSystem = StandardCombatSystem(
            versus: .nastyTroll,
            combatMessenger: testMessenger
        )

        var lowEscalationTriggers = 0
        var highEscalationTriggers = 0
        let testIterations = 30

        for _ in 0..<testIterations {
            // Low escalation test
            let lowTrigger = await combatSystem.shouldTriggerSpecialEvent(
                attackRoll: 16,
                marginOfHit: 5,
                escalation: 0.2,
                intensity: 0.8,
                attacker: CharacterSheet(strength: 14),
                defender: CharacterSheet(constitution: 12),
                engine: engine
            )
            if lowTrigger { lowEscalationTriggers += 1 }

            // High escalation test
            let highTrigger = await combatSystem.shouldTriggerSpecialEvent(
                attackRoll: 16,
                marginOfHit: 5,
                escalation: 2.5,
                intensity: 0.8,
                attacker: CharacterSheet(strength: 14),
                defender: CharacterSheet(constitution: 12),
                engine: engine
            )
            if highTrigger { highEscalationTriggers += 1 }
        }

        // High escalation should trigger more often than low escalation
        #expect(
            highEscalationTriggers >= lowEscalationTriggers,
            "High escalation should trigger more special events than low escalation")
    }

    @Test("Combat conditions affect subsequent attacks")
    func testCombatConditionsAffectAttacks() async throws {
        // Given: A combat scenario with staggered enemy
        let staggeredTroll = Item("staggeredTroll")
            .name("staggered troll")
            .characterSheet(
                strength: 16,
                constitution: 14,
                combatCondition: .offBalance  // -2 AC, -1 attack
            )
            .in("combatRoom")

        let vulnerableTroll = Item("vulnerableTroll")
            .name("vulnerable troll")
            .characterSheet(
                strength: 16,
                constitution: 14,
                combatCondition: .vulnerable  // -3 AC, no attack penalty
            )
            .in("combatRoom")

        let normalTroll = Item("normalTroll")
            .name("normal troll")
            .characterSheet(
                strength: 16,
                constitution: 14,
                combatCondition: .normal  // No penalties
            )
            .in("combatRoom")

        let player = Player(
            in: "combatRoom",
            characterSheet: CharacterSheet(strength: 14, dexterity: 12)
        )

        let testRoom = Location("combatRoom")
            .name("Combat Room")
            .inherentlyLit

        let game = MinimalGame(
            player: player,
            locations: testRoom,
            items: staggeredTroll, vulnerableTroll, normalTroll
        )

        let (engine, _) = await GameEngine.test(blueprint: game)
        let combatSystem = StandardCombatSystem(versus: "staggeredTroll")

        // When: Computing offense modifiers for each enemy
        let staggeredProxy = await engine.item("staggeredTroll")
        let vulnerableProxy = await engine.item("vulnerableTroll")
        let normalProxy = await engine.item("normalTroll")

        let staggeredOffense = await combatSystem.computeOffenseModifier(
            for: .enemy(staggeredProxy),
            weapon: nil,
            intensity: 0.5
        )

        let vulnerableOffense = await combatSystem.computeOffenseModifier(
            for: .enemy(vulnerableProxy),
            weapon: nil,
            intensity: 0.5
        )

        let normalOffense = await combatSystem.computeOffenseModifier(
            for: .enemy(normalProxy),
            weapon: nil,
            intensity: 0.5
        )

        // Then: Combat conditions should affect combat effectiveness
        #expect(staggeredOffense < normalOffense, "Staggered enemy should have reduced offense")
        #expect(vulnerableOffense == normalOffense, "Vulnerable doesn't affect offense")

        // Defense adjustments don't include combat condition modifiers (they're in effectiveArmorClass)
        // but we can verify the effectiveArmorClass includes the penalties
        let staggeredAC = await staggeredProxy.characterSheet.effectiveArmorClass
        let vulnerableAC = await vulnerableProxy.characterSheet.effectiveArmorClass
        let normalAC = await normalProxy.characterSheet.effectiveArmorClass

        #expect(staggeredAC == normalAC - 2, "Staggered enemy should have -2 AC")
        #expect(vulnerableAC == normalAC - 3, "Vulnerable enemy should have -3 AC")
    }

    // MARK: - defaultCombatDescription Tests

    @Test("defaultCombatDescription generates appropriate descriptions")
    func testDefaultCombatDescription() async throws {
        let (engine, _) = await createTestGame()
        let combatSystem = StandardCombatSystem(
            versus: .nastyTroll,
            combatMessenger: testMessenger
        )
        let troll = await engine.item(.nastyTroll)
        let sword = await engine.item("sword")

        let messenger = testMessenger
        let hitEvent = CombatEvent.enemyInjured(
            CombatEventPayload(
                enemy: troll,
                player: await engine.player,
                playerWeapon: sword,
                enemyWeapon: nil,
                damage: 6,
                damageCategory: .moderate
            )
        )

        let description = await combatSystem.defaultCombatDescription(
            of: hitEvent,
            via: messenger
        )

        #expect(!description.isEmpty)
        #expect(
            description.contains("hit") || description.contains("strike")
                || description.contains("damage") || description.contains("sword"))
    }

    @Test("defaultCombatDescription handles miss events")
    func testDefaultCombatDescriptionMiss() async throws {
        let (engine, _) = await createTestGame()
        let combatSystem = StandardCombatSystem(
            versus: .nastyTroll,
            combatMessenger: testMessenger
        )
        let troll = await engine.item(.nastyTroll)
        let sword = await engine.item("sword")

        let messenger = testMessenger
        let missEvent = CombatEvent.enemyMissed(
            CombatEventPayload(
                enemy: troll,
                player: await engine.player,
                playerWeapon: sword,
                enemyWeapon: nil
            )
        )

        let description = await combatSystem.defaultCombatDescription(
            of: missEvent,
            via: messenger
        )

        #expect(!description.isEmpty)
        #expect(
            description.contains("miss") || description.contains("dodge")
                || description.contains("avoid") || description.contains("swing"))
    }

    @Test("defaultCombatDescription handles critical hits")
    func testDefaultCombatDescriptionCritical() async throws {
        let (engine, _) = await createTestGame()
        let combatSystem = StandardCombatSystem(
            versus: .nastyTroll,
            combatMessenger: testMessenger
        )
        let troll = await engine.item(.nastyTroll)
        let sword = await engine.item("sword")

        let criticalEvent = CombatEvent.enemyInjured(
            CombatEventPayload(
                enemy: troll,
                player: await engine.player,
                playerWeapon: sword,
                enemyWeapon: nil,
                damage: 12,
                damageCategory: .critical
            )
        )

        let messenger = testMessenger

        let description = await combatSystem.defaultCombatDescription(
            of: criticalEvent,
            via: messenger
        )

        #expect(!description.isEmpty)
        #expect(
            description.contains("critical") || description.contains("devastating")
                || description.contains("powerful") || description.contains("wound"))
    }

    // MARK: - Edge Case Tests

    @Test("functions handle nil parameters gracefully")
    func testNilParameterHandling() async throws {
        let (engine, _) = await createTestGame()
        let combatSystem = StandardCombatSystem(
            versus: .nastyTroll,
            combatMessenger: testMessenger
        )

        let player = await engine.player

        // Test computeOffenseModifier with nil weapon
        let modifier = await combatSystem.computeOffenseModifier(
            for: .player(player),
            weapon: nil,
            intensity: 1.0
        )
        #expect(modifier >= -10)

        // Test getEnemyWeapon when no weapon exists
        let weapon = await combatSystem.getEnemyWeapon(from: engine)
        #expect(weapon == nil)
    }

    @Test("functions handle extreme values")
    func testExtremeValues() async throws {
        let (engine, _) = await createTestGame()
        let combatSystem = StandardCombatSystem(
            versus: .nastyTroll,
            combatMessenger: testMessenger
        )

        let player = await engine.player

        // Test with very high intensity
        let highIntensityModifier = await combatSystem.computeOffenseModifier(
            for: .player(player),
            weapon: nil,
            intensity: 10.0
        )
        #expect(highIntensityModifier >= -20)

        // Test with zero intensity
        let zeroIntensityModifier = await combatSystem.computeOffenseModifier(
            for: .player(player),
            weapon: nil,
            intensity: 0.0
        )
        #expect(zeroIntensityModifier >= -20)
    }
}
