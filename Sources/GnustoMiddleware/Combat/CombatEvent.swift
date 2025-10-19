import Foundation
import GnustoEngine
import Logging

// MARK: - Damage Categories

/// Categorizes damage amounts for narrative purposes based on the ratio of damage to max health.
public enum DamageCategory: Equatable, Sendable {
    // swiftlint:disable sorted_enum_cases
    /// Damage that kills or incapacitates the target (100% or more of max health).
    case fatal

    /// Severe damage that significantly impairs combat ability (50-99% of max health).
    case critical

    /// Serious damage that notably affects performance (30-49% of max health).
    case grave

    /// Noticeable damage with moderate impact (15-29% of max health).
    case moderate

    /// Minor damage with limited effect (5-14% of max health).
    case light

    /// Superficial damage with minimal impact (1-4% of max health).
    case scratch

    /// No damage dealt (0 damage).
    case none
    // swiftlint:enable sorted_enum_cases

    /// Creates a damage category from damage amount and target's max health.
    ///
    /// - Parameters:
    ///   - damage: Amount of damage dealt
    ///   - currentHealth: Target's current health before damage
    ///   - maxHealth: Target's maximum health
    public init(damage: Int, currentHealth: Int, maxHealth: Int) {
        guard maxHealth > 0 else {
            self = damage > 0 ? .fatal : .none
            return
        }

        // Fatal if damage kills the target
        if damage >= currentHealth {
            self = .fatal
            return
        }

        // Calculate percentage of max health
        let damagePercent = (damage * 100) / maxHealth

        switch damagePercent {
        case 50...: self = .critical
        case 30..<50: self = .grave
        case 15..<30: self = .moderate
        case 5..<15: self = .light
        case 1..<5: self = .scratch
        default: self = .none
        }
    }
}

// MARK: - Combat Event Payload

/// Common payload for combat events containing shared combat context.
///
/// This structure consolidates the data commonly needed across combat events,
/// reducing redundancy and making it easier to pass damage, conditions, and
/// combat participants through the system.
public struct CombatEventPayload: Equatable, Sendable {
    /// The enemy involved in the combat event.
    public let enemy: ItemProxy

    /// The player proxy, if needed for the event.
    public let player: PlayerProxy?

    /// The weapon the player is using, if any.
    public let playerWeapon: ItemProxy?

    /// The weapon the enemy is using, if any.
    public let enemyWeapon: ItemProxy?

    /// Amount of damage dealt in this event.
    public let damage: Int

    /// Category of damage for narrative purposes.
    public let damageCategory: DamageCategory

    /// Optional combat condition applied by this event.
    public let combatCondition: CombatCondition?

    /// Creates a combat event payload.
    public init(
        enemy: ItemProxy,
        player: PlayerProxy? = nil,
        playerWeapon: ItemProxy? = nil,
        enemyWeapon: ItemProxy? = nil,
        damage: Int = 0,
        damageCategory: DamageCategory = .none,
        combatCondition: CombatCondition? = nil
    ) {
        self.enemy = enemy
        self.player = player
        self.playerWeapon = playerWeapon
        self.enemyWeapon = enemyWeapon
        self.damage = damage
        self.damageCategory = damageCategory
        self.combatCondition = combatCondition
    }
}

// MARK: - Combat Event

/// Represents specific combat events with detailed outcome information.
///
/// Each event captures both what happened mechanically (damage, status changes)
/// and provides context for generating appropriate narrative messages.
public enum CombatEvent: Equatable, Sendable {
    /// Combat is interrupted by external event.
    case combatInterrupted(reason: String)

    /// An enemy attacks the player.
    case enemyAttacks(CombatEventPayload)

    /// Player's attack is blocked, dodged, or made ineffective by armor.
    case enemyBlocked(CombatEventPayload)

    /// Enemy drop their weapon, either disarmed by the player, or by fumbling on a critical miss
    /// and dropping their weapon.
    case enemyDisarmed(CombatEventPayload, wasFumble: Bool)

    /// Enemy flees from combat.
    case enemyFlees(CombatEventPayload, direction: Direction?, destination: LocationID?)

    /// Player injures the enemy.
    ///
    /// This consolidated event replaces enemyCriticallyWounded, enemyGravelyInjured,
    /// enemyInjured, enemyLightlyInjured, enemyGrazed, and enemySlain.
    /// Use the payload's damageCategory to determine severity.
    case enemyInjured(CombatEventPayload)

    /// Player's attack is a critical miss.
    case enemyMissed(CombatEventPayload)

    /// Enemy is pacified and stops fighting.
    case enemyPacified(CombatEventPayload)

    /// Enemy surrenders.
    case enemySurrenders(CombatEventPayload)

    /// Player knocks enemy unconscious.
    case enemyUnconscious(CombatEventPayload)

    /// Error processing combat event outcome.
    case error(message: String)

    /// Player attempts to attack with non-weapon item.
    case nonWeaponAttack(CombatEventPayload)

    /// Player attacks an enemy.
    case playerAttacks(CombatEventPayload)

    /// Player drop their weapon, either disarmed by the enemy, or by fumbling on a critical miss
    /// and dropping their weapon.
    case playerDisarmed(CombatEventPayload, wasFumble: Bool)

    /// Enemy's attack is blocked, dodged, or made ineffective by armor.
    case playerDodged(CombatEventPayload)

    /// Enemy injures the player.
    ///
    /// This consolidated event replaces playerCriticallyWounded, playerGravelyInjured,
    /// playerInjured, playerLightlyInjured, playerGrazed, and playerSlain.
    /// Use the payload's damageCategory to determine severity.
    case playerInjured(CombatEventPayload)

    /// Enemy's attack is a critical miss.
    case playerMissed(CombatEventPayload)

    /// Enemy knocks player unconscious.
    case playerUnconscious(CombatEventPayload)

    /// Stalemate - neither side can harm the other.
    case stalemate(CombatEventPayload)

    /// Player attempts to attack without required weapon.
    case unarmedAttackDenied(CombatEventPayload)
}

// MARK: - Helpers

extension CombatEvent {
    /// Extracts the enemy proxy from any combat event.
    ///
    /// - Returns: The enemy involved in the combat event, or `nil` for non-enemy events.
    public var enemy: ItemProxy? {
        switch self {
        case .enemyInjured(let payload),
            .playerInjured(let payload),
            .enemyAttacks(let payload),
            .playerAttacks(let payload),
            .enemyBlocked(let payload),
            .enemyMissed(let payload),
            .playerDodged(let payload),
            .playerMissed(let payload),
            .enemyDisarmed(let payload, _),
            .enemyFlees(let payload, _, _),
            .enemyPacified(let payload),
            .enemySurrenders(let payload),
            .enemyUnconscious(let payload),
            .nonWeaponAttack(let payload),
            .playerDisarmed(let payload, _),
            .playerUnconscious(let payload),
            .stalemate(let payload),
            .unarmedAttackDenied(let payload):
            payload.enemy
        case .combatInterrupted, .error:
            nil
        }
    }

    /// Whether an event incapacitates the opponent and prevents counter-attacks.
    ///
    /// - Returns: `true` if the event prevents the opponent from attacking back.
    public var incapacitatesOpponent: Bool {
        switch self {
        case .enemyInjured(let payload):
            payload.damageCategory == .fatal
        case .enemyUnconscious, .enemyFlees, .enemySurrenders:
            true
        default:
            false
        }
    }

    /// Chance that a combat event will provoke an enemy taunt, relative to other events.
    ///
    /// - Returns: A value from 0.0 to 1.0 representing the likelihood of provoking a taunt.
    public var chanceToProvokeEnemyTaunt: Double {
        switch self {
        case .enemyInjured(let payload):
            switch payload.damageCategory {
            case .scratch: 0.3
            default: 0
            }
        case .enemyMissed, .enemyBlocked: 0.6
        case .playerInjured(let payload):
            switch payload.damageCategory {
            case .fatal: 0.9
            case .critical: 0.7
            case .grave: 0.6
            case .moderate: 0.5
            case .light: 0.4
            case .scratch, .none: 0.3
            }
        case .playerUnconscious: 0.8
        case .playerDisarmed: 0.7
        default: 0
        }
    }
}

// MARK: - CombatEvent array helpers

extension Array where Element == CombatEvent {
    /// Returns `true` if any event in the array leaves the player unconscious.
    ///
    /// This computed property checks whether the combat events resulted in the player
    /// being knocked unconscious, which would end combat and require special handling.
    ///
    /// - Returns: `true` if any event is `.playerUnconscious`, `false` otherwise.
    public var leavesPlayerUnconscious: Bool {
        contains {
            if case .playerUnconscious = $0 { true } else { false }
        }
    }
}
