import Foundation
import GnustoEngine
import Logging

/// Default implementation of turn-based melee combat system with D&D-style mechanics.
///
/// This combat system provides:
/// - Turn-based melee combat with player actions and enemy reactions
/// - D&D-style d20 attack rolls and damage calculations
/// - Character attribute-based combat modifiers
/// - Dynamic enemy AI that responds to combat state
/// - Rich narrative combat descriptions
public struct StandardCombatSystem: CombatSystem {
    /// The identifier of the enemy this combat system applies to.
    public let enemyID: ItemID

    /// The combat messenger used for generating combat messages.
    public let combatMessenger: CombatMessenger

    /// Private logger for combat system messages, warnings, and errors.
    private let logger = Logger(label: "com.samadhibot.Gnusto.StandardCombatSystem")

    /// A closure that provides custom combat event handling with complete control over messages
    /// and state changes.
    public let eventHandler:
        @Sendable (CombatEvent, CombatEventContext) async throws -> ActionResult?

    /// Creates a default combat system for the specified enemy.
    ///
    /// This initializer sets up a complete turn-based combat system with D&D-style
    /// mechanics including d20 attack rolls, armor class checks, and damage calculations.
    /// The system provides intelligent enemy AI that can flee, surrender, or be pacified
    /// based on combat attributes and dice rolls.
    ///
    /// - Parameters:
    ///   - enemyID: The identifier of the enemy this system applies to
    ///   - combatMessenger: The combat messenger for generating messages
    ///   - eventHandler: Optional closure for custom combat event handling
    public init(
        versus enemyID: ItemID,
        combatMessenger: CombatMessenger = CombatMessenger(),
        eventHandler:
            @escaping @Sendable (
                CombatEvent,
                CombatEventContext
            ) async throws -> ActionResult? = { _, _ in nil }
    ) {
        self.enemyID = enemyID
        self.combatMessenger = combatMessenger
        self.eventHandler = eventHandler
    }

    /// Processes a complete turn of combat including player action and enemy reaction.
    ///
    /// - Parameters:
    ///   - playerAction: The action the player is attempting
    ///   - context: The action context for game state access
    /// - Returns: An ActionResult containing messages and state changes for the turn.
    public func processCombatTurn(
        playerAction: PlayerAction,
        in context: ActionContext
    ) async throws -> ActionResult {
        let enemy = await context.item(enemyID)

        guard await enemy.isAlive else {
            return try await ActionResult(
                context.msg.alreadyDead(enemy.withDefiniteArticle),
                CombatMiddleware.endCombat()
            )
        }

        // Check if enemy and player are still in the same location
        let playerLocationID = await context.player.location.id
        let enemyParent = await enemy.parent
        guard case .location(let enemyLocationID) = enemyParent,
            enemyLocationID == playerLocationID
        else {
            // Enemy and player are in different locations - end combat
            return try ActionResult(
                CombatMiddleware.endCombat()
            )
        }

        // Check if player can act
        let playerCanAct = await context.player.canAct
        guard playerCanAct else {
            return ActionResult("You are unconscious and cannot act.")
        }

        // Process player action (will return nil for .other commands)
        let playerCombatEvent = await playerCombatEvent(
            for: playerAction,
            against: enemy,
            in: context
        )

        // Process enemy reaction (if enemy is still alive and able)
        var enemyEvent: CombatEvent?
        if playerCombatEvent?.incapacitatesOpponent != true {
            enemyEvent = await determineEnemyAction(
                against: playerAction,
                enemy: enemy,
                in: context
            )
        }

        // Create base combat turn
        var combatTurn = CombatTurn(
            playerEvent: playerCombatEvent,
            enemyEvent: enemyEvent
        )

        // Occasionally add a random enemy taunt
        if let enemyTaunt = await selectTaunt(from: enemy, in: combatTurn, context: context) {
            combatTurn.addEvent(enemyTaunt)
        }

        // Update combat state for next round
        let updatedCombatState = await recalculateCombatState(
            after: combatTurn,
            in: context
        )

        // Generate narrative and state changes
        let result = try await generateTurnResult(combatTurn, in: context)

        // Add combat state update to the result only if combat continues
        let combinedChanges: [StateChange]
        if let updatedCombatState {
            let combatStateChange = try CombatMiddleware.setCombatState(
                to: updatedCombatState
            )
            combinedChanges = result.changes + [combatStateChange]
        } else {
            combinedChanges = result.changes
        }

        return ActionResult(
            message: result.message,
            changes: combinedChanges,
            effects: result.effects,
            executionFlow: result.executionFlow
        )
    }

    // MARK: - Combat Calculations

    /// Calculates the outcome of an attack between two combatants using action-packed mechanics.
    ///
    /// This method performs a complete attack resolution including:
    /// - Rolling a d20 for the attack with improved hit chances
    /// - Adding attacker's attack bonus and weapon bonuses
    /// - Checking against defender's armor class
    /// - Handling critical hits (natural 20) and critical misses (natural 1)
    /// - Calculating substantial damage based on weapon type and attacker attributes
    /// - Determining special combat events like disarming, staggering, and vulnerability
    /// - Escalating combat intensity over time
    ///
    /// The system reduces complete misses and adds exciting special outcomes
    /// like weapon disarming, temporary stuns, and tactical advantages.
    ///
    /// - Parameters:
    ///   - attacker: The combatant making the attack (player or enemy)
    ///   - defender: The combatant being attacked (player or enemy)
    ///   - playerWeapon: Optional weapon being used, affects attack and damage bonuses
    ///   - context: Action context for accessing game engine and random number generation
    /// - Returns: A CombatEvent describing the attack outcome and any damage dealt
    /// - Throws: Errors from attribute access or combat calculations
    public func calculateAttackOutcome(
        attacker: Combatant,
        defender: Combatant,
        weapon playerWeapon: ItemProxy?,
        in context: ActionContext
    ) async -> CombatEvent {
        // Get current combat state for intensity and fatigue calculations
        let combatState = await self.combatState(from: context.engine)
        let intensity = combatState?.combatIntensity ?? 0.1
        let attackerFatigue =
            switch attacker {
            case .player: combatState?.playerFatigue ?? 0.0
            case .enemy: combatState?.enemyFatigue ?? 0.0
            }

        // Get enemy weapon if available
        let enemyWeapon = await getEnemyWeapon(from: context.engine)

        // Roll d20 for attack with dynamic combat intensity bonus
        let attackRoll = await context.engine.rollD20()
        let attackBonus = await attacker.characterSheet.attackBonus
        let weaponBonus = await playerWeapon?.value ?? 0
        let intensityBonus = Int(3.0 + (intensity * 5.0))  // 3-8 bonus based on intensity
        let fatiguePenalty = Int(attackerFatigue * 3.0)  // 0-3 penalty from fatigue

        // Attribute-driven offense/defense weighting
        let offenseModifier =
            await computeOffenseModifier(
                for: attacker,
                weapon: playerWeapon,
                intensity: intensity
            )
        let baseDefenderAC = await defender.characterSheet.effectiveArmorClass
        let defenseAdjustment = await computeDefenseAdjustment(for: defender)

        let totalAttack =
            attackRoll
            + attackBonus
            + weaponBonus
            + intensityBonus
            + offenseModifier
            - fatiguePenalty

        // Check against defender's AC with defensive adjustment
        let defenderAC = baseDefenderAC + defenseAdjustment
        let marginOfHit = max(0, totalAttack - defenderAC)

        // Critical hit on natural 20
        let isCritical = attackRoll == 20

        // Special combat events: use contextual helper
        let escalation = combatState?.escalationLevel ?? 0.1

        let marginOfHitCandidate =
            await attacker.characterSheet.attackBonus
            - (await defender.characterSheet.effectiveArmorClass)
            + weaponBonus
            + intensityBonus
            - fatiguePenalty
            + attackRoll

        let triggerSpecialEvent = await shouldTriggerSpecialEvent(
            attackRoll: attackRoll,
            marginOfHit: marginOfHitCandidate,
            escalation: escalation,
            intensity: intensity,
            attacker: await attacker.characterSheet,
            defender: await defender.characterSheet,
            engine: context.engine
        )

        let logResult =
            switch true {
            case attackRoll == 1: "Critical Miss!"
            case attackRoll == 20: "Critical Hit!"
            case totalAttack < defenderAC: "Missed!"
            default: "Hit!"
            }

        logger.info(
            """
            \n🎲 \(attacker.description.capitalizedFirst.possessive) attack roll:
            ------------------------------------
            attackRoll:      \(attackRoll)
            attackBonus:     \(attackBonus)
            weaponBonus:     \(weaponBonus)
            intensityBonus:  \(intensityBonus) (intensity: \(String(format: "%.1f", intensity)))
            fatiguePenalty:  \(fatiguePenalty) (fatigue: \(String(format: "%.1f", attackerFatigue)))
            offenseModifier: \(offenseModifier)
            defenseAdjust:   \(defenseAdjustment)
            totalAttack:     \(totalAttack)
            defenderAC:      \(defenderAC)
            escalation:      \(String(format: "%.1f", escalation))
            specialEvent:    \(triggerSpecialEvent)
            result:          \(logResult)\n
            """
        )

        // Critical miss on natural 1 - but even misses can have consequences
        if attackRoll == 1 {
            // 30% chance of special fumble effect
            if await context.engine.randomPercentage(chance: 30) {
                // Enemy fumbled and drops their weapon
                if case .enemy(let enemy) = attacker, let enemyWeapon {
                    return .enemyDisarmed(
                        CombatEventPayload(
                            enemy: enemy,
                            player: await context.engine.player,
                            playerWeapon: playerWeapon,
                            enemyWeapon: enemyWeapon
                        ),
                        wasFumble: true
                    )
                }
                // Player fumbled and drops their weapon
                if case .player = attacker,
                    case .enemy(let enemy) = defender,
                    let playerWeapon,
                    let enemyWeapon
                {
                    return .playerDisarmed(
                        CombatEventPayload(
                            enemy: enemy,
                            player: await context.engine.player,
                            playerWeapon: playerWeapon,
                            enemyWeapon: enemyWeapon
                        ),
                        wasFumble: true
                    )
                }
            }

            if case .enemy(let enemy) = attacker {
                return .playerMissed(
                    CombatEventPayload(
                        enemy: enemy,
                        player: await context.engine.player,
                        playerWeapon: nil,
                        enemyWeapon: enemyWeapon
                    )
                )
            }

            if case .enemy(let enemy) = defender {
                return .enemyMissed(
                    CombatEventPayload(
                        enemy: enemy,
                        player: nil,
                        playerWeapon: playerWeapon,
                        enemyWeapon: enemyWeapon
                    )
                )
            }
        }

        // Hit if total attack >= AC (now more likely due to intensity bonus)
        if totalAttack < defenderAC && !isCritical {
            // Even "misses" can have tactical effects
            // On miss with 20% chance, apply stagger condition alongside minimal damage
            if await context.engine.randomPercentage(chance: 20) {
                let damage = await context.engine.randomInt(in: 1...3)
                if case .enemy(let enemy) = attacker {
                    let player = await context.engine.player
                    return .playerInjured(
                        CombatEventPayload(
                            enemy: enemy,
                            player: player,
                            playerWeapon: nil,
                            enemyWeapon: enemyWeapon,
                            damage: damage,
                            damageCategory: .scratch,
                            combatCondition: .offBalance
                        )
                    )
                }
                if case .enemy(let enemy) = defender {
                    return .enemyInjured(
                        CombatEventPayload(
                            enemy: enemy,
                            player: nil,
                            playerWeapon: playerWeapon,
                            enemyWeapon: enemyWeapon,
                            damage: damage,
                            damageCategory: .scratch,
                            combatCondition: .offBalance
                        )
                    )
                }
            }

            // Standard block/dodge
            if case .enemy(let enemy) = attacker {
                let player = await context.engine.player
                return .playerDodged(
                    CombatEventPayload(
                        enemy: enemy,
                        player: player,
                        playerWeapon: nil,
                        enemyWeapon: enemyWeapon
                    )
                )
            }
            if case .enemy(let enemy) = defender {
                return .enemyBlocked(
                    CombatEventPayload(
                        enemy: enemy,
                        player: nil,
                        playerWeapon: playerWeapon,
                        enemyWeapon: enemyWeapon
                    )
                )
            }
        }

        // Track special combat condition to apply alongside damage
        var specialCondition: CombatCondition?

        if triggerSpecialEvent {
            let eventType = await context.engine.randomInt(in: 1...6)

            switch eventType {
            case 1:  // Disarm - dramatic, no damage
                if case .enemy(let enemy) = defender, let playerWeapon, let enemyWeapon {
                    return .enemyDisarmed(
                        CombatEventPayload(
                            enemy: enemy,
                            player: await context.engine.player,
                            playerWeapon: playerWeapon,
                            enemyWeapon: enemyWeapon
                        ),
                        wasFumble: false
                    )
                }
                if case .enemy(let enemy) = attacker,
                    let defenderWeapon = await defender.preferredWeapon
                {
                    return .playerDisarmed(
                        CombatEventPayload(
                            enemy: enemy,
                            player: await context.engine.player,
                            playerWeapon: defenderWeapon,
                            enemyWeapon: enemyWeapon
                        ),
                        wasFumble: false
                    )
                }
            case 2:  // Stagger - status effect, happens WITH damage
                specialCondition = .offBalance
            case 3:  // Hesitate - status effect, happens WITH damage
                specialCondition = .uncertain
            case 4:  // Vulnerable - status effect, happens WITH damage
                specialCondition = .vulnerable
            case 5:  // Unconscious - dramatic, no damage
                let defenderHealth = await defender.health
                let defenderMaxHealth = await defender.characterSheet.maxHealth
                let defenderHealthPercent = (defenderHealth * 100) / defenderMaxHealth
                if defenderHealthPercent <= 25 {
                    if case .enemy(let enemy) = defender {
                        return .enemyUnconscious(
                            CombatEventPayload(
                                enemy: enemy,
                                player: await context.engine.player,
                                playerWeapon: playerWeapon,
                                enemyWeapon: nil
                            )
                        )
                    }
                    if case .enemy(let enemy) = attacker {
                        return .playerUnconscious(
                            CombatEventPayload(
                                enemy: enemy,
                                player: await context.engine.player,
                                playerWeapon: nil,
                                enemyWeapon: enemyWeapon
                            )
                        )
                    }
                }
            default:
                break  // Fall through to damage calculation
            }
        }

        // Special conditions (stagger, hesitate, vulnerable) now happen IN ADDITION to damage
        // Continue to damage calculation and include the condition in the event payload

        // Calculate base damage with intensity and fatigue modifiers
        let weaponDamage = await playerWeapon?.weaponDamage ?? 8  // Increased from 4
        let baseDamage = await context.engine.randomInt(in: 2...weaponDamage)  // Minimum 2 damage
        let attackerBonus = await attacker.characterSheet.damageBonus
        let intensityDamageBonus = Int(intensity * 4.0)  // 0-4 bonus damage from intensity
        let fatigueDamagePenalty = Int(attackerFatigue * 2.0)  // 0-2 damage reduction from fatigue

        // Attribute-driven damage adjustments
        let damageAdjustment = await computeDamageAdjustment(
            attacker: attacker,
            defender: defender,
            weapon: playerWeapon,
            intensity: intensity,
            isCritical: false
        )

        var damage =
            baseDamage
            + attackerBonus
            + weaponBonus
            + intensityDamageBonus
            + damageAdjustment.flat
            - fatigueDamagePenalty

        // Margin-of-hit adds extra oomph on solid connects
        let marginFlatBonus = marginOfHit / 2
        if marginFlatBonus > 0 { damage += marginFlatBonus }

        var stats = ["baseDamage:   \(baseDamage) (min 2)"]
        if attackerBonus != 0 { stats.append("attackerBonus: \(attackerBonus)") }
        if weaponBonus != 0 { stats.append("weaponBonus:  \(weaponBonus)") }
        if intensityDamageBonus > 0 { stats.append("intensityBonus: +\(intensityDamageBonus)") }
        if fatigueDamagePenalty > 0 { stats.append("fatiguePenalty: -\(fatigueDamagePenalty)") }
        var totalMultiplier = damageAdjustment.multiplier
        // Strong hits scale up damage a bit more
        let marginMultiplierBonus = min(0.35, Double(marginOfHit) * 0.03)
        if marginMultiplierBonus > 0 { totalMultiplier += marginMultiplierBonus }
        if isCritical {
            let criticalMultiplier = 2.0 + intensity  // 2.0-3.0x multiplier based on intensity
            stats.append("critical:     x\(String(format: "%.1f", criticalMultiplier)) damage")
            totalMultiplier *= criticalMultiplier
        }
        if totalMultiplier != 1.0 {
            stats.append("multiplier:   x\(String(format: "%.2f", totalMultiplier))")
        }
        damage = Int(Double(damage) * totalMultiplier)

        // Apply weapon weaknesses and resistances for enemy defenders
        if case .enemy(let enemy) = defender, let playerWeapon {
            let characterSheet = await enemy.characterSheet
            // Check for weakness (bonus damage)
            if let weakness = characterSheet.weaponWeaknesses[playerWeapon.id] {
                stats.append("weakness: +\(weakness)")
                damage += weakness
            }
            // Check for resistance (reduced damage)
            if let resistance = characterSheet.weaponResistances[playerWeapon.id] {
                stats.append("resistance:  -\(resistance)")
                damage = max(1, damage - resistance)  // Always at least 1 damage on hit
            }
        }

        let defenderHealth = await defender.health
        if let weaponName = await playerWeapon?.name {
            stats.append("weapon:       \(weaponName.capitalizedFirst)")
        }

        // Categorize the outcome based on damage and defender health
        let defenderMaxHealth = await defender.characterSheet.maxHealth
        let category = DamageCategory(
            damage: damage,
            currentHealth: await defender.health,
            maxHealth: defenderMaxHealth
        )

        logger.info(
            """
            \n🎲 \(attacker.description.capitalizedFirst.possessive) damage roll:
            ------------------------------------
            \(stats.joined(separator: .linebreak))
            prev health:  \(defenderHealth)
            total damage: \(damage) (\(category))
            new health:   \(defenderHealth - damage)\n
            """
        )

        let player = await context.engine.player

        // Return appropriate event based on who is attacking
        // Now includes special combat conditions alongside damage
        return switch (attacker, defender) {
        case (.enemy(let enemy), _):
            // Enemy attacking player - no combat condition applied to player for now
            // (conditions are primarily for enemies)
            if category == .none {
                .playerDodged(
                    CombatEventPayload(
                        enemy: enemy,
                        player: player,
                        playerWeapon: nil,
                        enemyWeapon: enemyWeapon
                    )
                )
            } else {
                .playerInjured(
                    CombatEventPayload(
                        enemy: enemy,
                        player: player,
                        playerWeapon: nil,
                        enemyWeapon: enemyWeapon,
                        damage: damage,
                        damageCategory: category,
                        combatCondition: nil
                    )
                )
            }
        case (_, .enemy(let enemy)):
            // Player attacking enemy - include special condition if triggered
            if category == .none {
                .enemyBlocked(
                    CombatEventPayload(
                        enemy: enemy,
                        player: nil,
                        playerWeapon: playerWeapon,
                        enemyWeapon: enemyWeapon
                    )
                )
            } else {
                .enemyInjured(
                    CombatEventPayload(
                        enemy: enemy,
                        player: nil,
                        playerWeapon: playerWeapon,
                        enemyWeapon: enemyWeapon,
                        damage: damage,
                        damageCategory: category,
                        combatCondition: specialCondition
                    )
                )
            }
        default:
            .error(message: "Unsupported calculateAttackOutcome: \(attacker), \(defender)")
        }
    }

    /// Determines the enemy's reaction to a player action using intelligent AI.
    ///
    /// This method implements sophisticated enemy AI that considers multiple factors:
    /// - Current health percentage for flee decisions
    /// - Intelligence and wisdom for surrender decisions
    /// - Charisma checks for pacification attempts
    /// - Combat attributes like flee thresholds and custom taunts
    ///
    /// The AI makes contextual decisions based on the player's action:
    /// - Attacks trigger counter-attacks or defensive actions
    /// - Talk actions may lead to pacification if the enemy allows it
    /// - Low health may cause fleeing or surrender based on enemy attributes
    /// - Non-combat actions may trigger taunts instead of attacks
    ///
    /// - Parameters:
    ///   - playerAction: The action the player just took
    ///   - enemy: The enemy proxy for accessing combat attributes
    ///   - context: Action context for dice rolls and game state access
    /// - Returns: A CombatEvent representing the enemy's action, or nil if no action taken
    /// - Throws: Errors from attribute access or combat calculations
    public func determineEnemyAction(
        against playerAction: PlayerAction,
        enemy: ItemProxy,
        in context: ActionContext
    ) async -> CombatEvent? {
        guard await enemy.isAwake else { return nil }

        let characterSheet = await enemy.characterSheet

        // Calculate current health percentage and get combat state
        let healthPercent = 100 * characterSheet.health / characterSheet.maxHealth
        let combatState = await self.combatState(from: context.engine)
        let enemyFatigue = combatState?.enemyFatigue ?? 0.0
        let intensity = combatState?.combatIntensity ?? 0.1

        // Check for fleeing based on combat attributes, health, and fatigue
        let fleeChance = characterSheet.fleeThreshold + Int(enemyFatigue * 30.0)  // Fatigue increases flee chance
        if healthPercent <= characterSheet.fleeHealthPercent || enemyFatigue > 0.8 {
            if await context.engine.randomPercentage(chance: fleeChance) {
                // Determine flee destination (simple implementation)
                let currentLocation = await context.player.location
                let validExits = await currentLocation.exits.filter {
                    $0.destinationID != nil && $0.blockedMessage == nil
                }
                if let flightExit = await context.engine.randomElement(in: validExits) {
                    let enemyWeapon = await getEnemyWeapon(from: context.engine)
                    let playerWeapon = await context.player.preferredWeapon
                    return .enemyFlees(
                        CombatEventPayload(
                            enemy: enemy,
                            player: await context.engine.player,
                            playerWeapon: playerWeapon,
                            enemyWeapon: enemyWeapon
                        ),
                        direction: flightExit.direction,
                        destination: flightExit.destinationID
                    )
                }
            }
        }

        // Smart enemies might surrender when outmatched, especially when fatigued
        let surrenderThreshold = enemyFatigue > 0.5 ? 35 : 25  // Higher threshold when fatigued
        if healthPercent <= surrenderThreshold && characterSheet.intelligence > 14 {
            let roll = await context.engine.rollD20()
            let fatigueBonus = Int(enemyFatigue * 5.0)  // Fatigue makes surrender more likely
            if roll + characterSheet.wisdomModifier + fatigueBonus > 15 {
                let enemyWeapon = await getEnemyWeapon(from: context.engine)
                let playerWeapon = await context.player.preferredWeapon
                return .enemySurrenders(
                    CombatEventPayload(
                        enemy: enemy,
                        player: await context.engine.player,
                        playerWeapon: playerWeapon,
                        enemyWeapon: enemyWeapon
                    )
                )
            }
        }

        // Handle pacification attempts
        if case .talk = playerAction, characterSheet.canBePacified == true {
            let roll = await context.engine.rollD20()
            let playerCharisma = await context.player.characterSheet.charismaModifier
            if roll + playerCharisma >= characterSheet.pacifyDC {
                let enemyWeapon = await getEnemyWeapon(from: context.engine)
                let playerWeapon = await context.player.preferredWeapon
                return .enemyPacified(
                    CombatEventPayload(
                        enemy: enemy,
                        player: await context.engine.player,
                        playerWeapon: playerWeapon,
                        enemyWeapon: enemyWeapon
                    )
                )
            }
        }

        // For non-attack actions, enemy gets advantage and always attacks (player is distracted)
        guard case .attack = playerAction else {
            // Player is distracted - enemy gets buffed attack with advantage
            // Roll twice and take the better result
            let roll1 = await context.engine.rollD20()
            let roll2 = await context.engine.rollD20()
            let bestRoll = max(roll1, roll2)

            // Calculate attack with advantage, considering enemy fatigue
            let attackBonus = await enemy.characterSheet.attackBonus
            let opportunityBonus = 7 - Int(enemyFatigue * 3.0)  // Reduced bonus if enemy is tired
            let totalAttack = bestRoll + attackBonus + opportunityBonus

            // Check against player's AC
            let playerAC = await context.player.characterSheet.armorClass

            // Critical hit on natural 20
            let isCritical = bestRoll == 20

            // Get enemy weapon for this opportunity attack
            let enemyWeapon = await getEnemyWeapon(from: context.engine)

            // Critical miss on natural 1 (both rolls must be 1)
            if roll1 == 1 && roll2 == 1 {
                return .playerDodged(
                    CombatEventPayload(
                        enemy: enemy,
                        player: await context.engine.player,
                        playerWeapon: nil,
                        enemyWeapon: enemyWeapon
                    )
                )
            }

            // Check for devastating opportunity attack on distracted player
            if bestRoll >= 15 || isCritical {
                let opportunityRoll = await context.engine.rollD20()
                if opportunityRoll >= 14 {
                    // Special opportunity attacks on distracted opponents
                    let condition: CombatCondition =
                        switch opportunityRoll {
                        case 20: .vulnerable
                        case 18...19: .offBalance
                        default: .uncertain
                        }

                    return .playerInjured(
                        CombatEventPayload(
                            enemy: enemy,
                            player: await context.engine.player,
                            playerWeapon: nil,
                            enemyWeapon: enemyWeapon,
                            damage: 0,
                            damageCategory: .none,
                            combatCondition: condition
                        )
                    )
                }
            }

            guard totalAttack >= playerAC || isCritical else {
                return .playerDodged(
                    CombatEventPayload(
                        enemy: enemy,
                        player: await context.engine.player,
                        playerWeapon: nil,
                        enemyWeapon: enemyWeapon
                    )
                )
            }

            // Calculate damage with bonus for distracted player and intensity
            var damage = await context.engine.randomInt(in: 3...12)  // Higher base damage when distracted
            damage += await enemy.characterSheet.damageBonus
            damage += 5 - Int(enemyFatigue * 2.0)  // Reduced bonus if enemy is fatigued
            damage += Int(intensity * 3.0)  // Intensity bonus for opportunity attacks
            if isCritical {
                let critMultiplier = 2.5 + (intensity * 0.5)  // Up to 3.0x with high intensity
                damage = Int(Double(damage) * critMultiplier)
            }

            // Categorize the outcome
            let playerMaxHealth = await context.player.characterSheet.maxHealth
            let category = DamageCategory(
                damage: damage,
                currentHealth: await context.player.health,
                maxHealth: playerMaxHealth
            )

            let player = await context.player

            return if category == .none {
                .playerDodged(
                    CombatEventPayload(
                        enemy: enemy,
                        player: player,
                        playerWeapon: nil,
                        enemyWeapon: enemyWeapon
                    )
                )
            } else {
                .playerInjured(
                    CombatEventPayload(
                        enemy: enemy,
                        player: player,
                        playerWeapon: nil,
                        enemyWeapon: enemyWeapon,
                        damage: damage,
                        damageCategory: category,
                        combatCondition: nil
                    )
                )
            }
        }

        // Counter-attack
        return await calculateAttackOutcome(
            attacker: .enemy(enemy),
            defender: .player(context.player),
            weapon: nil,  // Enemy weapons handled internally
            in: context
        )
    }

    /// Selects an appropriate taunt from the enemy's custom taunts or default options.
    ///
    /// This method first checks if the enemy has custom taunts defined in their combat
    /// attributes. If custom taunts are available, one is randomly selected. Otherwise,
    /// it falls back to generating a default taunt based on the enemy's characteristics.
    ///
    /// - Returns: A taunt message string to display to the player
    func selectTaunt(
        from enemy: ItemProxy,
        in combatTurn: CombatTurn,
        context: ActionContext,
        tauntRoll: Int = 13
    ) async -> CombatEvent? {
        let engine = context.engine
        guard await engine.rollD20(isAtLeast: tauntRoll) else {
            return nil
        }
        let enemyTauntChance = combatTurn.enemyEvent?.chanceToProvokeEnemyTaunt ?? 0
        let playerTauntChance = combatTurn.playerEvent?.chanceToProvokeEnemyTaunt ?? 0
        if await engine.randomDouble() < max(enemyTauntChance, playerTauntChance) {
            // Enemy taunts by applying taunting condition instead of attacking
            let enemyWeapon = await self.getEnemyWeapon(from: engine)
            let playerWeapon = await context.player.preferredWeapon
            return .enemyAttacks(
                CombatEventPayload(
                    enemy: enemy,
                    player: await engine.player,
                    playerWeapon: playerWeapon,
                    enemyWeapon: enemyWeapon,
                    damage: 0,
                    damageCategory: .none,
                    combatCondition: Optional.some(.taunting)
                )
            )
        }
        return nil
    }

    // MARK: - Player Action Processing

    /// Processes a player's action during combat and returns the resulting combat event.
    ///
    /// This method validates player actions against enemy combat attributes and calculates
    /// the appropriate combat outcome. It handles different action types including attacks,
    /// talking attempts, and other combat maneuvers.
    ///
    /// - Parameters:
    ///   - playerAction: The player action to process (attack, talk, defend, etc.)
    ///   - enemy: The enemy proxy for accessing enemy combat attributes
    ///   - context: The action context providing access to game engine and messaging
    /// - Returns: A CombatEvent representing the outcome of the player's action, or nil if no event occurs
    /// - Throws: Any errors from combat calculations or attribute access
    func playerCombatEvent(
        for playerAction: PlayerAction,
        against enemy: ItemProxy,
        in context: ActionContext
    ) async -> CombatEvent? {
        let characterSheet = await enemy.characterSheet

        // If player cannot act (unconscious/asleep/coma), interrupt combat with narrative only
        if await context.player.canAct == false {
            return .combatInterrupted(
                reason: context.msg.youCannotAct()
            )
        }

        switch playerAction {
        case .attack:
            let weapon =
                if let specified = context.command.indirectObject?.itemProxy {
                    specified
                } else {
                    await context.player.preferredWeapon
                }

            // Check for weapon requirements
            if characterSheet.requiresWeapon == true && weapon == nil {
                let enemyWeapon = await getEnemyWeapon(from: context.engine)
                return .unarmedAttackDenied(
                    CombatEventPayload(
                        enemy: enemy,
                        player: await context.engine.player,
                        playerWeapon: nil,
                        enemyWeapon: enemyWeapon
                    )
                )
            }

            // Check if item is actually a weapon
            if let weapon, await !weapon.isWeapon {
                let enemyWeapon = await getEnemyWeapon(from: context.engine)
                return .nonWeaponAttack(
                    CombatEventPayload(
                        enemy: enemy,
                        player: await context.engine.player,
                        playerWeapon: weapon,
                        enemyWeapon: enemyWeapon
                    )
                )
            }

            // Calculate attack outcome
            return await calculateAttackOutcome(
                attacker: .player(context.player),
                defender: .enemy(enemy),
                weapon: weapon,
                in: context
            )

        case .talk(let topic):
            // Talking during combat might have special effects
            guard characterSheet.canBePacified == true && topic != nil else {
                return nil
            }
            let roll = await context.engine.rollD20()
            /*
             TODO: We should also factor in enemy intelligence/wisdom and percentage current health
             */
            let charismaCheck = await context.player.characterSheet.charismaModifier + roll
            let enemyWeapon = await getEnemyWeapon(from: context.engine)
            let playerWeapon = await context.player.preferredWeapon
            return if charismaCheck >= characterSheet.pacifyDC {
                .enemyPacified(
                    CombatEventPayload(
                        enemy: enemy,
                        player: await context.engine.player,
                        playerWeapon: playerWeapon,
                        enemyWeapon: enemyWeapon
                    )
                )
            } else {
                nil
            }

        case .defend:
            // Player is defending - might reduce incoming damage
            // TODO: Enemy gets to attack, but their hit and damage rolls should be nerfed
            return nil

        case .flee:
            // Player is trying to flee combat
            /*
             TODO: Here there should be a roll of the dice...
             with dexterity modifier and maybe wisdom/intelligence versus same enemy
             attributes. If they succeed, they run back the way they just came from, which
             maybe we could pull from the gameState changeHistory? Ideally the enemy
             should get one last chance to clobber the player as they turn their back and go.
             If they fail the roll, the enemy should get a buff since the player is distracted.
             */
            return nil

        case .useItem:
            // Player is using an item in combat
            // TODO: To be handled by game-specific extensions?
            return nil

        case .special:
            // Game-specific special actions
            // TODO: To be handled by game-specific extensions?
            return nil

        case .other:
            // Non-combat action during combat - player is distracted
            // The action handler message has already been added to the message queue
            // Return nil - no combat-specific player event
            // The enemy will get a buffed attack in determineEnemyAction
            return nil
        }
    }

    // MARK: - Combat State Management

    /// Updates the combat state after a turn, adjusting intensity, fatigue, and other factors.
    ///
    /// This method analyzes the combat events that occurred and updates the combat state
    /// accordingly, including:
    /// - Increasing intensity based on damage dealt and special events
    /// - Adding fatigue from prolonged combat and exertion
    /// - Updating weapon states if disarmament occurred
    /// - Applying special modifiers from combat events
    /// - Factoring in character attributes like constitution, strength, armor weight, and morale
    ///
    /// - Parameters:
    ///   - turn: The combat turn that just completed
    ///   - context: The action context for accessing game state
    /// - Returns: Updated CombatState for the next round, or nil if combat should end
    /// - Throws: Errors from combat state calculation
    func recalculateCombatState(
        after turn: CombatTurn,
        in context: ActionContext
    ) async -> CombatState? {
        guard let currentState = await combatState(from: context.engine) else {
            // Create initial combat state if none exists
            return CombatState(
                enemyID: enemyID,
                playerWeaponID: await context.player.preferredWeapon?.id,
                enemyWeaponID: await context.item(enemyID).preferredWeapon?.id
            )
        }

        // Check for combat-ending events
        let combatShouldEnd = turn.allEvents.contains { (event: CombatEvent) in
            switch event {
            case .enemyInjured(let payload):
                payload.damageCategory == .fatal
            case .playerInjured(let payload):
                payload.damageCategory == .fatal
            case .enemyFlees, .enemySurrenders, .enemyPacified, .playerUnconscious:
                true
            default:
                false
            }
        }

        guard !combatShouldEnd else {
            return nil  // Combat ends
        }

        // Get character sheets for attribute-based calculations
        let playerSheet = await context.player.characterSheet
        let enemySheet = await context.item(enemyID).characterSheet

        // Calculate attribute-based base fatigue and intensity modifiers
        let (baseFatigueModifiers, baseIntensityModifier) =
            await calculateAttributeBasedModifiers(
                playerSheet: playerSheet,
                enemySheet: enemySheet,
                currentState: currentState,
                context: context
            )

        // Start with base values influenced by character attributes
        var intensityDelta = 0.08 + baseIntensityModifier  // Increased from 0.05
        var playerFatigueDelta = 0.06 + baseFatigueModifiers.player  // Increased from 0.03
        var enemyFatigueDelta = 0.06 + baseFatigueModifiers.enemy  // Increased from 0.03

        var newPlayerWeapon = currentState.playerWeaponID
        var newEnemyWeapon = currentState.enemyWeaponID

        // Analyze events for intensity and fatigue modifiers
        for event in turn.allEvents {
            switch event {
            case .enemyInjured(let payload):
                // Apply intensity and fatigue based on damage category
                switch payload.damageCategory {
                case .fatal:
                    intensityDelta += 0.25  // Fatal blow - maximum intensity
                    enemyFatigueDelta += 0.10
                case .critical:
                    intensityDelta += 0.20  // Increased from 0.15 - Critical wounds spike intensity
                    enemyFatigueDelta += 0.08  // Increased from 0.05
                case .grave:
                    intensityDelta += 0.15  // Increased from 0.10
                    enemyFatigueDelta += 0.06  // Increased from 0.04
                case .moderate:
                    intensityDelta += 0.08  // Increased from 0.05
                    enemyFatigueDelta += 0.04  // Increased from 0.02
                case .light, .scratch:
                    intensityDelta += 0.08  // Increased from 0.05
                    enemyFatigueDelta += 0.04  // Increased from 0.02
                case .none:
                    break
                }

                // Apply additional fatigue if combat condition was inflicted
                if payload.combatCondition != nil {
                    enemyFatigueDelta += 0.05  // Special conditions add fatigue
                }

            case .playerInjured(let payload):
                // Apply intensity and fatigue based on damage category
                switch payload.damageCategory {
                case .fatal:
                    intensityDelta += 0.25  // Fatal blow - maximum intensity
                    playerFatigueDelta += 0.10
                case .critical:
                    intensityDelta += 0.20  // Increased from 0.15 - Critical wounds spike intensity
                    playerFatigueDelta += 0.08  // Increased from 0.05
                case .grave:
                    intensityDelta += 0.15  // Increased from 0.10
                    playerFatigueDelta += 0.06  // Increased from 0.04
                case .moderate:
                    intensityDelta += 0.08  // Increased from 0.05
                    playerFatigueDelta += 0.04  // Increased from 0.02
                case .light, .scratch:
                    intensityDelta += 0.08  // Increased from 0.05
                    playerFatigueDelta += 0.04  // Increased from 0.02
                case .none:
                    break
                }

                // Apply additional fatigue if combat condition was inflicted
                if payload.combatCondition != nil {
                    playerFatigueDelta += 0.05  // Special conditions add fatigue
                }

            case .enemyDisarmed:
                newEnemyWeapon = nil
                intensityDelta += 0.25  // Increased from 0.20 - Disarmament is dramatic
                enemyFatigueDelta += 0.05  // Disarming is exhausting

            case .playerDisarmed:
                newPlayerWeapon = nil
                intensityDelta += 0.25  // Increased from 0.20
                playerFatigueDelta += 0.05  // Disarming is exhausting

            case .enemyMissed, .enemyBlocked:
                intensityDelta -= 0.03  // Slightly increased penalty from -0.02

            case .playerMissed, .playerDodged:
                intensityDelta -= 0.03  // Slightly increased penalty from -0.02

            default:
                break
            }
        }

        // Apply high-intensity combat effects with attribute consideration
        if currentState.isHighIntensity {
            intensityDelta += 0.08  // Increased from 0.05 - Intensity builds on itself
            playerFatigueDelta += 0.04  // Increased from 0.02
            enemyFatigueDelta += 0.04
        }

        // Apply round duration fatigue based on constitution and armor
        let roundDurationFatigue = await calculateRoundDurationFatigue(
            playerSheet: playerSheet,
            enemySheet: enemySheet,
            currentState: currentState,
            context: context
        )
        playerFatigueDelta += roundDurationFatigue.player
        enemyFatigueDelta += roundDurationFatigue.enemy

        return currentState.nextRound(
            intensityDelta: intensityDelta,
            playerFatigueDelta: playerFatigueDelta,
            enemyFatigueDelta: enemyFatigueDelta,
            newPlayerWeapon: newPlayerWeapon,
            newEnemyWeapon: newEnemyWeapon
        )
    }

    /// Calculates base fatigue and intensity modifiers based on character attributes.
    ///
    /// This method considers:
    /// - Constitution for fatigue resistance
    /// - Strength for endurance in combat
    /// - Armor weight and encumbrance
    /// - Morale and bravery for intensity
    /// - Current health state
    ///
    /// - Parameters:
    ///   - playerSheet: The player's character sheet
    ///   - enemySheet: The enemy's character sheet
    ///   - currentState: Current combat state for context
    ///   - context: Action context for accessing equipment
    /// - Returns: Base modifiers for fatigue (player, enemy) and intensity
    func calculateAttributeBasedModifiers(
        playerSheet: CharacterSheet,
        enemySheet: CharacterSheet,
        currentState: CombatState,
        context: ActionContext
    ) async -> (fatigue: (player: Double, enemy: Double), intensity: Double) {

        // Player fatigue modifiers
        var playerFatigueMod = 0.0

        // Constitution affects fatigue resistance (negative modifier reduces fatigue gain)
        playerFatigueMod -= Double(playerSheet.constitutionModifier) * 0.06  // -4 to +4 becomes -0.24 to +0.24

        // Strength affects combat endurance
        if playerSheet.strengthModifier < 0 {
            playerFatigueMod += Double(abs(playerSheet.strengthModifier)) * 0.08  // Weak characters tire faster
        } else {
            playerFatigueMod -= Double(playerSheet.strengthModifier) * 0.05  // Strong characters tire slower
        }

        // Armor weight increases fatigue
        let playerAC = playerSheet.armorClass
        if playerAC > 12 {  // Heavy armor
            playerFatigueMod += Double(playerAC - 12) * 0.04  // Each AC above 12 adds fatigue
        }

        // Health state affects fatigue accumulation
        let playerHealthPercent = playerSheet.healthPercent
        if playerHealthPercent < 50 {
            playerFatigueMod += Double(50 - playerHealthPercent) * 0.004  // Wounded fighters tire faster
        }

        // Morale affects endurance
        playerFatigueMod -= Double(playerSheet.moraleModifier) * 0.025  // High morale reduces fatigue

        // Enemy fatigue modifiers (similar calculations)
        var enemyFatigueMod = 0.0
        enemyFatigueMod -= Double(enemySheet.constitutionModifier) * 0.06

        if enemySheet.strengthModifier < 0 {
            enemyFatigueMod += Double(abs(enemySheet.strengthModifier)) * 0.08
        } else {
            enemyFatigueMod -= Double(enemySheet.strengthModifier) * 0.05
        }

        let enemyAC = enemySheet.armorClass
        if enemyAC > 12 {
            enemyFatigueMod += Double(enemyAC - 12) * 0.04
        }

        let enemyHealthPercent = enemySheet.healthPercent
        if enemyHealthPercent < 50 {
            enemyFatigueMod += Double(50 - enemyHealthPercent) * 0.004
        }

        enemyFatigueMod -= Double(enemySheet.moraleModifier) * 0.025

        // Intensity modifier based on combined attributes
        var intensityMod = 0.0

        // Higher bravery and lower wisdom lead to more intense combat
        intensityMod += Double(playerSheet.braveryModifier + enemySheet.braveryModifier) * 0.06

        // Wisdom tempers intensity
        intensityMod -= Double(playerSheet.wisdomModifier + enemySheet.wisdomModifier) * 0.03

        // Low health combats are more desperate and intense
        let avgHealthPercent = (playerHealthPercent + enemyHealthPercent) / 2
        if avgHealthPercent < 60 {
            intensityMod += Double(60 - avgHealthPercent) * 0.005
        }

        return (
            fatigue: (player: playerFatigueMod, enemy: enemyFatigueMod), intensity: intensityMod
        )
    }

    /// Calculates additional fatigue from round duration based on constitution and equipment.
    ///
    /// This represents the ongoing strain of maintaining combat readiness, affected by:
    /// - Constitution for basic endurance
    /// - Armor weight and encumbrance
    /// - Weapon weight and handling requirements
    /// - Current fatigue level (compounding effect)
    ///
    /// - Parameters:
    ///   - playerSheet: The player's character sheet
    ///   - enemySheet: The enemy's character sheet
    ///   - currentState: Current combat state for fatigue levels
    ///   - context: Action context for equipment access
    /// - Returns: Additional fatigue for both combatants
    func calculateRoundDurationFatigue(
        playerSheet: CharacterSheet,
        enemySheet: CharacterSheet,
        currentState: CombatState,
        context: ActionContext
    ) async -> (player: Double, enemy: Double) {

        // Base round fatigue - everyone gets a little tired each round
        var playerRoundFatigue = 0.08  // Base fatigue per round (increased for 5-round combat)
        var enemyRoundFatigue = 0.08

        // Constitution reduces round fatigue
        playerRoundFatigue -= Double(playerSheet.constitutionModifier) * 0.015
        enemyRoundFatigue -= Double(enemySheet.constitutionModifier) * 0.015

        // Heavy weapons are more tiring to wield
        if let playerWeapon = await currentState.playerWeapon(with: context.engine) {
            let weaponDamage = await playerWeapon.weaponDamage
            if weaponDamage > 8 {  // Heavy weapons
                playerRoundFatigue += Double(weaponDamage - 8) * 0.01
            }
        }

        if let enemyWeapon = await currentState.enemyWeapon(with: context.engine) {
            let weaponDamage = await enemyWeapon.weaponDamage
            if weaponDamage > 8 {
                enemyRoundFatigue += Double(weaponDamage - 8) * 0.01
            }
        }

        // Fatigue compounds - tired fighters get more tired faster
        let playerCurrentFatigue = currentState.playerFatigue
        let enemyCurrentFatigue = currentState.enemyFatigue

        if playerCurrentFatigue > 0.3 {
            playerRoundFatigue += playerCurrentFatigue * 0.1  // Compounding fatigue effect
        }

        if enemyCurrentFatigue > 0.3 {
            enemyRoundFatigue += enemyCurrentFatigue * 0.1
        }

        // Clamp to reasonable ranges for faster combat
        playerRoundFatigue = max(0.03, min(0.2, playerRoundFatigue))
        enemyRoundFatigue = max(0.03, min(0.2, enemyRoundFatigue))

        return (player: playerRoundFatigue, enemy: enemyRoundFatigue)
    }

    // MARK: - Turn Result Generation

    /// Generates the complete result for a combat turn including all events and state changes.
    ///
    /// This method processes all combat events that occurred during a turn, generating
    /// appropriate narrative descriptions and game state changes for each event.
    /// It combines custom descriptions (if provided) with default combat messages
    /// to create a cohesive combat narrative.
    ///
    /// - Parameters:
    ///   - turn: The complete combat turn containing all events
    ///   - messages: A queue of messages to display before the combat descriptions.
    ///   - context: Action context for accessing messaging and game state
    /// - Returns: An ActionResult with combined messages and state changes
    /// - Throws: Errors from message generation or state change creation
    /// - Returns: A merged ActionResult containing all event outcomes.
    func generateTurnResult(
        _ turn: CombatTurn,
        in context: ActionContext
    ) async throws -> ActionResult {
        // Create combat event context for event generation
        let combatContext = CombatEventContext(
            from: context,
            combatMessenger: combatMessenger
        )

        return try await turn.allEvents.asyncMap {
            try await generateEventResult(for: $0, in: combatContext)
        }
        .merged()
    }

    /// Generates appropriate state changes for a combat event.
    ///
    /// This method translates combat events into concrete game state modifications
    /// such as damage application, status flag changes, and location movements.
    /// Different event types trigger different combinations of state changes:
    /// - Damage events modify health and set combat flags
    /// - Death events set death flags and clear combat status
    /// - Flee events move enemies and clear combat status
    /// - Pacification events clear combat flags without harm
    ///
    /// - Parameters:
    ///   - event: The combat event to process
    ///   - context: Action context for accessing game engine
    /// - Returns: An array of state changes to apply to the game
    /// - Throws: Errors from state change creation or attribute access
    func generateEventResult(
        for event: CombatEvent,
        in context: CombatEventContext
    ) async throws -> ActionResult {
        // Check for custom event handling first
        if let customResult = try await eventHandler(event, context) {
            // Handle different execution flows
            switch customResult.executionFlow {
            case .override:
                // Override default behavior entirely - use only custom result
                return customResult

            case .append:
                // Append custom content after default content
                let defaultResult = try await generateDefaultEventResult(
                    for: event, in: context)
                let combinedMessage: String? = {
                    switch (defaultResult.message, customResult.message) {
                    case (let defaultMsg?, let customMsg?):
                        return "\(defaultMsg)\n\n\(customMsg)"
                    case (let defaultMsg?, nil):
                        return defaultMsg
                    case (nil, let customMsg?):
                        return customMsg
                    case (nil, nil):
                        return nil
                    }
                }()
                return ActionResult(
                    message: combinedMessage,
                    changes: defaultResult.changes + customResult.changes,
                    effects: defaultResult.effects + customResult.effects,
                    executionFlow: .override
                )

            case .prepend:
                // Prepend custom content before default content
                let defaultResult = try await generateDefaultEventResult(
                    for: event, in: context)
                let combinedMessage: String? = {
                    switch (customResult.message, defaultResult.message) {
                    case (let customMsg?, let defaultMsg?):
                        return "\(customMsg)\n\n\(defaultMsg)"
                    case (let customMsg?, nil):
                        return customMsg
                    case (nil, let defaultMsg?):
                        return defaultMsg
                    case (nil, nil):
                        return nil
                    }
                }()
                return ActionResult(
                    message: combinedMessage,
                    changes: customResult.changes + defaultResult.changes,
                    effects: customResult.effects + defaultResult.effects,
                    executionFlow: .override
                )

            case .yield:
                // Apply custom changes/effects but yield to default processing
                let defaultResult = try await generateDefaultEventResult(for: event, in: context)
                // Custom message takes full precedence when provided
                let finalMessage = customResult.message ?? defaultResult.message
                return ActionResult(
                    message: finalMessage,
                    changes: customResult.changes + defaultResult.changes,
                    effects: customResult.effects + defaultResult.effects,
                    executionFlow: .override
                )
            }
        }

        // No custom handling - use default
        return try await generateDefaultEventResult(for: event, in: context)
    }

    // MARK: - Helper Methods

    /// Gets the current combat state from the game engine.
    private func combatState(from engine: GameEngine) async -> CombatState? {
        await engine.gameState.globalState[.combatMiddlewareState]?.toCodable(as: CombatState.self)
    }

    /// Generates the default combat event result with standard messaging and changes.
    func generateDefaultEventResult(
        for event: CombatEvent,
        in context: CombatEventContext
    ) async throws -> ActionResult {
        let combatMsg = context.combatMsg
        let description = await defaultCombatDescription(of: event, via: combatMsg)

        switch event {

        // Combat initiation

        case .enemyAttacks, .playerAttacks:
            // These initiation events don't require state changes
            // The subsequent combat events handle damage and conditions
            return ActionResult(description)

        // Enemy damage events

        case .enemyInjured(let payload):
            let enemy = payload.enemy
            let damage = payload.damage

            // Handle fatal damage
            if payload.damageCategory == .fatal {
                return try await ActionResult(
                    description,
                    enemy.takeDamage(damage),
                    CombatMiddleware.endCombat(),
                    enemy.setCharacterAttributes(
                        health: 0,
                        consciousness: .dead,
                        isFighting: false
                    )
                )
            }

            // Apply damage and optional combat condition
            if let condition = payload.combatCondition {
                return await ActionResult(
                    description,
                    enemy.takeDamage(damage),
                    enemy.setCharacterAttributes(combatCondition: condition)
                )
            }

            return await ActionResult(
                description,
                enemy.takeDamage(damage)
            )

        case .enemyUnconscious(let payload):
            return try await ActionResult(
                message: description,
                changes: [
                    payload.enemy.setCharacterAttributes(consciousness: .unconscious),
                    CombatMiddleware.endCombat(),
                ],
                effects: [
                    .startEnemyWakeUpFuse(
                        enemyID: payload.enemy.id,
                        locationID: await context.player.location.id,
                        message: combatMsg.enemyWakes(enemy: payload.enemy),
                        turns: context.engine.randomInt(in: 3...6)
                    ),
                ]
            )

        case .enemyMissed, .enemyBlocked, .playerMissed, .playerDodged:
            return ActionResult(description)

        // Player damage events

        case .playerInjured(let payload):
            let enemy = payload.enemy
            let damage = payload.damage

            // Handle fatal damage
            if payload.damageCategory == .fatal {
                return try await ActionResult(
                    description,
                    context.player.takeDamage(damage),
                    context.player.setCharacterAttributes(
                        health: 0,
                        consciousness: .dead,
                        isFighting: false
                    ),
                    enemy.setCharacterAttributes(isFighting: false),
                    CombatMiddleware.endCombat()
                )
            }

            // Apply damage and optional combat condition
            if let condition = payload.combatCondition {
                return await ActionResult(
                    description,
                    context.player.takeDamage(damage),
                    context.player.setCharacterAttributes(combatCondition: condition)
                )
            }

            return await ActionResult(
                description,
                context.player.takeDamage(damage)
            )

        case .playerUnconscious(let payload):
            return try await ActionResult(
                message: description,
                changes: [
                    context.player.setCharacterAttributes(consciousness: .unconscious),
                    context.player.takeDamage(payload.damage),
                    CombatMiddleware.endCombat(),
                    payload.enemy.remove(),
                ],
                effects: [
                    .startEnemyReturnFuse(
                        enemyID: payload.enemy.id,
                        to: await context.player.location.id,
                        message: combatMsg.enemyReturns(enemy: payload.enemy),
                        turns: context.engine.randomInt(in: 2...4)
                    ),
                ]
            )

        // Special outcomes

        case .enemyDisarmed(let payload, _):
            return await ActionResult(
                description,
                payload.enemy.setCharacterAttributes(combatCondition: .disarmed),
                payload.enemyWeapon?.move(to: context.player.location.id)
            )

        case .enemyFlees(let payload, _, let destination):
            if let destination {
                return try ActionResult(
                    description,
                    CombatMiddleware.endCombat(),
                    payload.enemy.move(to: destination)
                )
            } else {
                return ActionResult(description)
            }

        case .enemyPacified(let payload):
            return try await ActionResult(
                description,
                CombatMiddleware.endCombat(),
                payload.enemy.setCharacterAttributes(isFighting: false)
            )

        case .enemySurrenders(let payload):
            return try await ActionResult(
                description,
                CombatMiddleware.endCombat(),
                payload.enemy.setCharacterAttributes(
                    combatCondition: .surrendered,
                    isFighting: false
                )
            )

        case .playerDisarmed(let payload, _):
            let playerLocation = await context.player.location
            return await ActionResult(
                description,
                context.player.setCharacterAttributes(combatCondition: .disarmed),
                payload.playerWeapon?.move(to: playerLocation.id)
            )

        case .unarmedAttackDenied, .nonWeaponAttack, .combatInterrupted,
            .stalemate, .error:
            // These prevent combat, no state changes
            return ActionResult(description)
        }
    }

    // MARK: - Helper Functions

    /// Retrieves the enemy's weapon from the current combat state.
    ///
    /// - Parameter engine: The game engine to access combat state and create proxies
    /// - Returns: The enemy's weapon as an ItemProxy, or nil if no weapon or no combat
    func getEnemyWeapon(from engine: GameEngine) async -> ItemProxy? {
        guard let combatState = await self.combatState(from: engine) else { return nil }
        return await combatState.enemyWeapon(with: engine)
    }

    // MARK: - Weighting Helpers

    /// Computes an additional offense modifier based on nuanced character attributes.
    ///
    /// This is intentionally modest in magnitude and complements `attackBonus` rather than replacing it.
    /// It accounts for current health, perception, luck, morale, bravery, accuracy, consciousness,
    /// and general condition. Values are clamped to a conservative range to avoid wild swings.
    func computeOffenseModifier(
        for attacker: Combatant,
        weapon: ItemProxy?,
        intensity: Double
    ) async -> Int {
        let sheet = await attacker.characterSheet

        var modifier = 0

        // Core precision contributions beyond base attackBonus
        modifier += sheet.dexterityModifier  // aiming/hand-eye
        modifier += sheet.accuracyModifier / 2  // weapon discipline
        modifier += sheet.perceptionModifier / 2  // situational awareness
        modifier += sheet.luckModifier / 3  // streaks of fortune

        // Fighting spirit and poise
        modifier += sheet.moraleModifier / 2
        modifier += sheet.braveryModifier / 3

        // Health state impact (helps when healthy, hinders when wounded)
        let healthSwing = (sheet.healthPercent - 50) / 25  // ~[-2, +2]
        modifier += healthSwing

        // Consciousness and general condition effects
        if sheet.consciousness == .drowsy { modifier += -1 }
        if !sheet.consciousness.canAct { modifier += -3 }  // should rarely apply if allowed to attack
        modifier += sheet.generalCondition.abilityCheckModifier / 2

        // Slight benefit when properly armed (without inspecting weapon style)
        if weapon != nil { modifier += 1 }

        // Combat condition effects on offense
        modifier += sheet.combatCondition.attackModifier

        // Intensity can sharpen focus a bit
        modifier += Int(intensity * 2.0)  // 0..2

        // Clamp to stable band
        return max(-6, min(6, modifier))
    }

    /// Computes a defensive adjustment to be applied on top of effectiveArmorClass.
    ///
    /// Avoids double-counting `CombatCondition.armorClassModifier` (already in `effectiveArmorClass`).
    /// Considers perception, luck, bravery, morale, health, consciousness, and general condition.
    func computeDefenseAdjustment(
        for defender: Combatant
    ) async -> Int {
        let sheet = await defender.characterSheet

        var adjustment = 0

        // Evasion and vigilance beyond base AC
        adjustment += sheet.perceptionModifier  // read the fight better
        adjustment += sheet.luckModifier / 2  // fortunate glances/near-misses
        adjustment += sheet.braveryModifier / 2  // steady under pressure
        adjustment += sheet.moraleModifier / 2  // holds the line

        // Health and awareness
        let healthSwing = (sheet.healthPercent - 50) / 20  // ~[-2, +2]
        adjustment += healthSwing

        // Consciousness levels
        switch sheet.consciousness {
        case .alert: break
        case .drowsy: adjustment += -1
        case .asleep, .unconscious, .coma: adjustment += -5
        case .dead: adjustment += -10
        }

        // General long-term conditions (blessed/cursed/etc.)
        adjustment += sheet.generalCondition.abilityCheckModifier

        // Clamp to stable band so base AC remains primary
        return max(-6, min(6, adjustment))
    }

    /// Computes damage adjustments as a flat bonus and a multiplier.
    ///
    /// - Flat bonus reflects raw power and technique (strength, dexterity, level, morale,
    ///   bravery, luck, health).
    /// - Multiplier reflects tactical advantage and state (intimidation vs bravery, conditions,
    ///   intensity, target health).
    func computeDamageAdjustment(
        attacker: Combatant,
        defender: Combatant,
        weapon: ItemProxy?,
        intensity: Double,
        isCritical: Bool
    ) async -> (flat: Int, multiplier: Double) {
        let atk = await attacker.characterSheet
        let def = await defender.characterSheet

        // Flat component
        var flat = 0
        flat += atk.strengthModifier  // primary source of physical damage
        flat += atk.dexterityModifier / 2  // placement and finesse
        flat += atk.level / 3  // training scales slowly
        flat += atk.moraleModifier / 2  // fighting spirit
        flat += atk.braveryModifier / 2  // commitment to press the attack
        flat += atk.luckModifier / 3  // lucky strikes
        flat += (atk.healthPercent - 50) / 20  // ~[-2, +2] based on stamina

        if weapon != nil { flat += 1 }  // modest benefit for being armed

        // Multiplier component (starts neutral)
        var mult: Double = 1.0

        // Tactical advantage: intimidation vs composure
        let intimidationEdge = atk.intimidationModifier - def.braveryModifier
        if intimidationEdge > 0 { mult += Double(intimidationEdge) * 0.03 }  // up to ~+0.3 at large edges

        // Defender vulnerability or impairment
        if def.combatCondition.isDefensivelyImpaired { mult += 0.10 }
        if atk.combatCondition.isOffensivelyImpaired { mult -= 0.10 }

        // General conditions
        mult += Double(atk.generalCondition.abilityCheckModifier) * 0.02
        mult -= Double(def.generalCondition.abilityCheckModifier) * 0.02  // blessed targets dampen damage

        // Intensity adds ferocity
        mult += min(0.15, intensity * 0.10)

        // Attacker awareness and target weakness by health state
        if atk.consciousness == .drowsy { mult -= 0.05 }
        if !atk.consciousness.canAct { mult -= 0.15 }
        let defWeakness = max(0, 60 - def.healthPercent)  // stronger effect when below 60%
        mult += Double(defWeakness) * 0.002  // up to +0.12 at 0% health

        // Clamp to reasonable band; criticals are applied outside via caller
        mult = max(0.5, min(1.75, mult))

        return (flat: flat, multiplier: mult)
    }

    /// Determines whether a special event should trigger based on combat context.
    ///
    /// Factors include: natural roll, margin of hit, escalation, intensity, attacker and defender
    /// luck, and defender current health percent. The threshold is conservative so specials remain
    /// exciting.
    func shouldTriggerSpecialEvent(  // swiftlint:disable:this function_parameter_count
        attackRoll: Int,
        marginOfHit: Int,
        escalation: Double,
        intensity: Double,
        attacker: CharacterSheet?,
        defender: CharacterSheet?,
        engine: GameEngine
    ) async -> Bool {
        if attackRoll == 20 { return true }

        // Base threshold starts very high to keep special events RARE
        var threshold: Double = 25.0
        threshold -= escalation * 3.0  // 0..3 easier with escalation
        threshold -= intensity * 1.5  // 0..1.5 easier with intensity
        threshold -= Double(max(0, marginOfHit)) * 0.3  // strong hits slightly more likely

        // Luck influences
        if let attacker { threshold -= Double(attacker.luckModifier) * 0.2 }
        if let defender { threshold += Double(defender.luckModifier) * 0.1 }

        // Very low defender health makes dramatic outcomes more likely
        if let defender, defender.healthPercent <= 15 { threshold -= 1.5 }  // Only at very low health

        // Clamp threshold to maintain rarity - most special events require 18+ on d20
        threshold = max(15.0, min(25.0, threshold))

        let roll = await engine.rollD20()
        return Double(roll) >= threshold
    }
}
