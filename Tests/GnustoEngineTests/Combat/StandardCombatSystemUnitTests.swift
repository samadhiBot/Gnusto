import CustomDump
import GnustoTestSupport
import Testing

@testable import GnustoEngine

@Suite("Standard Combat System Unit Tests")
struct StandardCombatSystemUnitTests {

    // MARK: - Test Helpers

    /// Creates a minimal test game with combat setup
    private func createTestGame(randomSeed: UInt64 = 71) async -> (GameEngine, MockIOHandler) {
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
            locations: entrance, startRoom,
            items: Lab.ironSword, Lab.troll,
            combatSystems: ["troll": StandardCombatSystem(versus: "troll")],
            randomSeed: randomSeed
        )

        return await GameEngine.test(blueprint: game)
    }

    func attackContext(for engine: GameEngine) async throws -> ActionContext {
        let command = await Command(
            verb: .attack,
            directObject: .item(Lab.troll.proxy(engine))
        )
        return ActionContext(command, engine)
    }

    // MARK: - processCombatTurn Tests

    @Test("processCombatTurn handles basic attack flow")
    func testProcessCombatTurnBasicAttack() async throws {
        let (engine, _) = await createTestGame()
        let combatSystem = StandardCombatSystem(versus: "troll")
        let playerAction = PlayerAction.attack
        let result = try await combatSystem.processCombatTurn(
            playerAction: playerAction,
            in: attackContext(for: engine)
        )

        expectNoDifference(
            result.message,
            """
            Your iron sword bites deep into the beast, inflicting damage
            that shows immediately. The blow lands solidly, drawing blood. He
            feels the sting but remains strong.

            The angry beast hammers back instantly -- the blow lands solid,
            driving air from lungs and thought from mind. The blow lands solidly, drawing blood. You feel the sting but remain strong.
            """
        )
        expectNoDifference(result.changes.count, 3)
    }

    @Test("processCombatTurn handles combat ending scenarios")
    func testProcessCombatTurnCombatEnding() async throws {
        let (engine, _) = await createTestGame()
        let combatSystem = StandardCombatSystem(versus: "troll")
        let result = try await combatSystem.processCombatTurn(
            playerAction: .attack,
            in: attackContext(for: engine)
        )

        // Should generate appropriate result for potential combat ending
        expectNoDifference(
            result.message,
            """
            Your iron sword bites deep into the beast, inflicting damage
            that shows immediately. The blow lands solidly, drawing blood. He
            feels the sting but remains strong.

            The angry beast hammers back instantly -- the blow lands solid,
            driving air from lungs and thought from mind. The blow lands solidly, drawing blood. You feel the sting but remain strong.
            """
        )
        expectNoDifference(result.changes.count, 3)
    }

    // MARK: - determineEnemyAction Tests

    @Test("determineEnemyAction returns appropriate enemy response")
    func testDetermineEnemyActionBasic() async throws {
        let (engine, _) = await createTestGame()
        let combatSystem = StandardCombatSystem(versus: "troll")
        let troll = await engine.item("troll")
        let playerAction = PlayerAction.attack
        let enemyEvent = try await combatSystem.determineEnemyAction(
            against: playerAction,
            enemy: troll,
            in: attackContext(for: engine)
        )

        // Enemy should respond with some action
        if let enemyEvent {
            #expect(enemyEvent.enemy == troll)
        }
    }

    @Test("determineEnemyAction handles unconscious enemy")
    func testDetermineEnemyActionUnconsciousEnemy() async throws {
        let (engine, _) = await createTestGame()
        let troll = await engine.item("troll")

        // Make troll unconscious
        try await engine.apply(
            troll.setCharacterAttributes(consciousness: .unconscious)
        )

        let combatSystem = StandardCombatSystem(versus: "troll")
        let playerAction = PlayerAction.attack
        let enemyEvent = try await combatSystem.determineEnemyAction(
            against: playerAction,
            enemy: troll,
            in: attackContext(for: engine)
        )

        // Unconscious enemy shouldn't act
        #expect(enemyEvent == nil)
    }

    // MARK: - selectTaunt Tests

    @Test("selectTaunt generates appropriate taunt events")
    func testSelectTaunt() async throws {
        let (engine, _) = await createTestGame()
        let combatSystem = StandardCombatSystem(versus: "troll")
        let troll = await engine.item("troll")
        let tauntEvent = await combatSystem.selectTaunt(
            from: troll,
            in: CombatTurn(
                playerEvent: .enemyMissed(enemy: troll, playerWeapon: nil, enemyWeapon: nil),
                enemyEvent: .playerVulnerable(enemy: troll, enemyWeapon: nil)
            ),
            tauntRoll: 1
        )

        expectNoDifference(
            tauntEvent,
            .enemyTaunts(
                enemy: troll,
                message: """
                    The troll spits in your face, grunting "Better luck next time"
                    in a rather barbarous accent.
                    """
            )
        )
    }

    // MARK: - playerCombatEvent Tests

    @Test("playerCombatEvent handles attack action")
    func testPlayerCombatEventAttack() async throws {
        let (engine, _) = await createTestGame()
        let combatSystem = StandardCombatSystem(versus: "troll")
        let troll = await engine.item("troll")
        let sword = await engine.item("sword")
        let playerEvent = try await combatSystem.playerCombatEvent(
            for: .attack,
            against: troll,
            in: attackContext(for: engine)
        )

        expectNoDifference(
            playerEvent,
            .enemyInjured(
                enemy: troll,
                playerWeapon: sword,
                enemyWeapon: nil,
                damage: 17
            )
        )
    }

    @Test("playerCombatEvent handles flee action")
    func testPlayerCombatEventFlee() async throws {
        let (engine, _) = await createTestGame()
        let combatSystem = StandardCombatSystem(versus: "troll")
        let troll = await engine.item("troll")
        let playerEvent = try await combatSystem.playerCombatEvent(
            for: .flee(direction: .south),
            against: troll,
            in: attackContext(for: engine)
        )

        #expect(playerEvent == nil)
    }

    // MARK: - recalculateCombatState Tests

    @Test("recalculateCombatState updates state correctly")
    func testRecalculateCombatState() async throws {
        let (engine, _) = await createTestGame()
        let combatSystem = StandardCombatSystem(versus: "troll")
        let troll = await engine.item("troll")
        let sword = await engine.item("sword")
        try await engine.apply(
            engine.setCombatState(
                to: CombatState(
                    enemyID: .troll,
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
                enemy: troll,
                playerWeapon: sword,
                enemyWeapon: nil,
                damage: 5
            ),
            enemyEvent: .playerInjured(
                enemy: troll,
                enemyWeapon: nil,
                damage: 3
            )
        )

        let newState = try await combatSystem.recalculateCombatState(
            after: combatTurn,
            in: attackContext(for: engine)
        )

        expectNoDifference(
            newState,
            CombatState(
                enemyID: .troll,
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
        let combatSystem = StandardCombatSystem(versus: "troll")

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
            enemyID: .troll,
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
            context: attackContext(for: engine)
        )

        #expect(modifiers.fatigue.player == -0.22)
        #expect(modifiers.fatigue.enemy == -0.38)
        #expect(modifiers.intensity == 0.06)
    }

    // MARK: - calculateRoundDurationFatigue Tests

    @Test("calculateRoundDurationFatigue computes fatigue correctly")
    func testCalculateRoundDurationFatigue() async throws {
        let (engine, _) = await createTestGame()
        let combatSystem = StandardCombatSystem(versus: "troll")

        let playerSheet = CharacterSheet(constitution: 14)
        let enemySheet = CharacterSheet(constitution: 16)
        let currentState = CombatState(enemyID: "troll", roundCount: 5)

        let fatigue = try await combatSystem.calculateRoundDurationFatigue(
            playerSheet: playerSheet,
            enemySheet: enemySheet,
            currentState: currentState,
            context: attackContext(for: engine)
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
        let combatSystem = StandardCombatSystem(versus: "troll")
        let troll = await engine.item("troll")
        let sword = await engine.item("sword")

        let combatTurn = CombatTurn(
            playerEvent: .enemyInjured(
                enemy: troll,
                playerWeapon: sword,
                enemyWeapon: nil,
                damage: 5
            ),
            enemyEvent: .playerDodged(
                enemy: troll,
                enemyWeapon: nil
            )
        )

        let result = try await combatSystem.generateTurnResult(
            combatTurn,
            in: attackContext(for: engine)
        )

        expectNoDifference(
            result.message,
            """
            Your blow with your iron sword catches the fearsome beast cleanly,
            tearing flesh and drawing crimson. He absorbs the hit, flesh suffering
            but endurance holding.

            The terrible monster's counter whistles past as you weave aside, your body remembering how to avoid pain.
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
        let combatSystem = StandardCombatSystem(versus: "troll")
        let troll = await engine.item("troll")
        let sword = await engine.item("sword")

        let damageEvent = CombatEvent.enemyInjured(
            enemy: troll,
            playerWeapon: sword,
            enemyWeapon: nil,
            damage: 8
        )

        let result = try await combatSystem.generateEventResult(
            for: damageEvent,
            in: attackContext(for: engine)
        )

        let expected = await ActionResult(
            """
            Your blow with your iron sword catches the fearsome beast cleanly,
            tearing flesh and drawing crimson. He absorbs the hit, flesh suffering
            but endurance holding.
            """,
            troll.setCharacterAttributes(health: 43)
        )

        // Should generate damage-related state changes
        expectNoDifference(result, expected)
    }

    @Test("generateEventResult handles player knocked unconscious")
    func testGenerateEventResultKnockout() async throws {
        let (engine, mockIO) = await createTestGame()
        let combatSystem = StandardCombatSystem(versus: .troll)
        let troll = await engine.item(.troll)

        try await engine.apply(
            engine.player.move(to: "entrance"),
            troll.setCharacterAttributes(isFighting: true)
        )
        try await engine.execute("north")
        await mockIO.expectOutput(
            """
            > north
            --- Combat Arena ---

            A circular arena for testing combat.

            There is a fierce troll here.

            The fearsome beast abandons caution and lunges straight at you!
            Your iron sword suddenly feels less reassuring as the distance
            vanishes.
            """
        )

        let knockoutEvent = CombatEvent.playerUnconscious(
            enemy: troll,
            enemyWeapon: nil,
            damage: 15
        )

        let result = try await combatSystem.generateEventResult(
            for: knockoutEvent,
            in: attackContext(for: engine)
        )

        let expected = try await ActionResult(
            message: """
                The monster retaliates with precision, bare knuckles finding the spot
                where consciousness lives and evicting it.

                * * *

                Your eyes crack open to an empty scene. How long were you out? Hours? Minutes?
                The monster is nowhere to be seen -- perhaps called away by urgent matters. Whatever
                the reason, this reprieve won't last. Move now or die here.
                """,
            changes: [
                engine.player.setCharacterAttributes(health: 35),
                engine.endCombat(),
                troll.move(to: .nowhere),
            ],
            effects: [
                .startEnemyReturnFuse(
                    enemyID: .troll,
                    to: .startRoom,
                    message: """
                        The worst possible timing: the creature comes back to find you still present,
                        apparently fascinated by your surroundings rather than your survival.
                        He doesn't hesitate -- violence resumes immediately.
                        You had your chance to leave.
                        """,
                    turns: 2
                )
            ]
        )

        // Should generate damage-related state changes
        expectNoDifference(result, expected)
    }

    // MARK: - getEnemyWeapon Tests

    @Test("getEnemyWeapon finds enemy weapon")
    func testGetEnemyWeapon() async throws {
        let club = Item("club")
            .name("wooden club")
            .isWeapon
            .in(.item("troll"))

        let game = MinimalGame(
            player: Player(in: .startRoom),
            locations: Location(
                id: .startRoom,
                .name("Combat Arena"),
                .description("A circular arena for testing combat."),
                .inherentlyLit
            ),
            items: Lab.troll, club,
            combatSystems: ["troll": StandardCombatSystem(versus: "troll")],
            randomSeed: 71
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        // Set up combat state first
        try await engine.apply(
            engine.setCombatState(to: CombatState(enemyID: "troll", enemyWeaponID: "club"))
        )

        let combatSystem = StandardCombatSystem(versus: "troll")
        let weapon = await combatSystem.getEnemyWeapon(from: engine)

        #expect(weapon?.id == "club")
    }

    @Test("getEnemyWeapon returns nil when no weapon")
    func testGetEnemyWeaponNoWeapon() async throws {
        let (engine, _) = await createTestGame()
        let combatSystem = StandardCombatSystem(versus: "troll")

        let weapon = await combatSystem.getEnemyWeapon(from: engine)

        #expect(weapon == nil)
    }

    // MARK: - computeOffenseModifier Tests

    @Test("computeOffenseModifier with weapon")
    func testComputeOffenseModifierWithWeapon() async throws {
        let (engine, _) = await createTestGame()
        let combatSystem = StandardCombatSystem(versus: "troll")

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
        let combatSystem = StandardCombatSystem(versus: "troll")

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
        let combatSystem = StandardCombatSystem(versus: "troll")

        let troll = await engine.item("troll")
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
        let combatSystem = StandardCombatSystem(versus: "troll")

        let player = await engine.player
        let attacker = Combatant.player(player)
        let troll = await engine.item("troll")
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
        let combatSystem = StandardCombatSystem(versus: "troll")

        let player = await engine.player
        let attacker = Combatant.player(player)
        let troll = await engine.item("troll")
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
        let combatSystem = StandardCombatSystem(versus: "troll")

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
        let combatSystem = StandardCombatSystem(versus: "troll")

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
        let combatSystem = StandardCombatSystem(versus: "troll")

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
                CharacterSheet(
                    strength: 16,
                    constitution: 14,
                    combatCondition: .offBalance  // -2 AC, -1 attack
                )
            )
            .in("combatRoom")

        let vulnerableTroll = Item("vulnerableTroll")
            .name("vulnerable troll")
            .characterSheet(
                CharacterSheet(
                    strength: 16,
                    constitution: 14,
                    combatCondition: .vulnerable  // -3 AC, no attack penalty
                )
            )
            .in("combatRoom")

        let normalTroll = Item("normalTroll")
            .name("normal troll")
            .characterSheet(
                CharacterSheet(
                    strength: 16,
                    constitution: 14,
                    combatCondition: .normal  // No penalties
                )
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
        let combatSystem = StandardCombatSystem(versus: "troll")
        let troll = await engine.item("troll")
        let sword = await engine.item("sword")

        let hitEvent = CombatEvent.enemyInjured(
            enemy: troll,
            playerWeapon: sword,
            enemyWeapon: nil,
            damage: 6
        )

        let messenger = await engine.combatMessenger(for: "troll")

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
        let combatSystem = StandardCombatSystem(versus: "troll")
        let troll = await engine.item("troll")
        let sword = await engine.item("sword")

        let missEvent = CombatEvent.enemyMissed(
            enemy: troll,
            playerWeapon: sword,
            enemyWeapon: nil
        )

        let messenger = await engine.combatMessenger(for: "troll")

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
        let combatSystem = StandardCombatSystem(versus: "troll")
        let troll = await engine.item("troll")
        let sword = await engine.item("sword")

        let criticalEvent = CombatEvent.enemyCriticallyWounded(
            enemy: troll,
            playerWeapon: sword,
            enemyWeapon: nil,
            damage: 12
        )

        let messenger = await engine.combatMessenger(for: "troll")

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
        let combatSystem = StandardCombatSystem(versus: "troll")

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
        let combatSystem = StandardCombatSystem(versus: "troll")

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
