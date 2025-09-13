import Foundation
import Logging

/// Represents specific combat events with detailed outcome information.
///
/// Each event captures both what happened mechanically (damage, status changes)
/// and provides context for generating appropriate narrative messages.
public enum CombatEvent: Equatable, Sendable {
    // MARK: - Combat Initiation

    /// An enemy attacks the player.
    case enemyAttacks(
        enemy: ItemProxy,
        playerWeapon: ItemProxy?,
        enemyWeapon: ItemProxy?
    )

    /// The player attacks an enemy.
    case playerAttacks(
        enemy: ItemProxy,
        playerWeapon: ItemProxy?,
        enemyWeapon: ItemProxy?
    )

    // MARK: - Player Attack Outcomes

    /// Player kills the enemy outright.
    case enemySlain(
        enemy: ItemProxy,
        playerWeapon: ItemProxy?,
        enemyWeapon: ItemProxy?,
        damage: Int
    )

    /// Player knocks enemy unconscious.
    case enemyUnconscious(
        enemy: ItemProxy,
        playerWeapon: ItemProxy?,
        enemyWeapon: ItemProxy?
    )

    /// Enemy drop their weapon, either disarmed by the player, or by fumbling on a critical miss
    /// and dropping their weapon.
    case enemyDisarmed(
        enemy: ItemProxy,
        playerWeapon: ItemProxy?,
        enemyWeapon: ItemProxy,
        wasFumble: Bool
    )

    /// Player's attack causes enemy to stagger, reducing their combat effectiveness.
    case enemyStaggers(
        enemy: ItemProxy,
        playerWeapon: ItemProxy?,
        enemyWeapon: ItemProxy?
    )

    /// Player's attack causes enemy to hesitate, creating an opening for follow-up actions.
    case enemyHesitates(
        enemy: ItemProxy,
        playerWeapon: ItemProxy?,
        enemyWeapon: ItemProxy?
    )

    /// Player's attack leaves enemy vulnerable to subsequent attacks.
    case enemyVulnerable(
        enemy: ItemProxy,
        playerWeapon: ItemProxy?,
        enemyWeapon: ItemProxy?
    )

    /// Player deals critical damage to enemy.
    case enemyCriticallyWounded(
        enemy: ItemProxy,
        playerWeapon: ItemProxy?,
        enemyWeapon: ItemProxy?,
        damage: Int
    )

    /// Player deals significant damage to enemy.
    case enemyGravelyInjured(
        enemy: ItemProxy,
        playerWeapon: ItemProxy?,
        enemyWeapon: ItemProxy?,
        damage: Int
    )

    /// Player deals moderate damage to enemy.
    case enemyInjured(
        enemy: ItemProxy,
        playerWeapon: ItemProxy?,
        enemyWeapon: ItemProxy?,
        damage: Int
    )

    /// Player deals light damage to enemy.
    case enemyLightlyInjured(
        enemy: ItemProxy,
        playerWeapon: ItemProxy?,
        enemyWeapon: ItemProxy?,
        damage: Int
    )

    /// Player barely damages enemy.
    case enemyGrazed(
        enemy: ItemProxy,
        playerWeapon: ItemProxy?,
        enemyWeapon: ItemProxy?,
        damage: Int
    )

    /// Player's attack is a critical miss.
    case enemyMissed(
        enemy: ItemProxy,
        playerWeapon: ItemProxy?,
        enemyWeapon: ItemProxy?
    )

    /// Player's attack is blocked, dodged, or made ineffective by armor.
    case enemyBlocked(
        enemy: ItemProxy,
        playerWeapon: ItemProxy?,
        enemyWeapon: ItemProxy?
    )

    // MARK: - Enemy Attack Outcomes

    /// Enemy kills the player.
    case playerSlain(
        enemy: ItemProxy,
        enemyWeapon: ItemProxy?,
        damage: Int
    )

    /// Enemy knocks player unconscious.
    case playerUnconscious(
        enemy: ItemProxy,
        enemyWeapon: ItemProxy?,
        damage: Int
    )

    /// Player drop their weapon, either disarmed by the enemy, or by fumbling on a critical miss
    /// and dropping their weapon.
    case playerDisarmed(
        enemy: ItemProxy,
        playerWeapon: ItemProxy,
        enemyWeapon: ItemProxy?,
        wasFumble: Bool
    )

    /// Enemy's attack causes player to stagger, reducing their combat effectiveness.
    case playerStaggers(
        enemy: ItemProxy,
        enemyWeapon: ItemProxy?
    )

    /// Enemy's attack causes player to hesitate, creating an opening for follow-up actions.
    case playerHesitates(
        enemy: ItemProxy,
        enemyWeapon: ItemProxy?
    )

    /// Enemy's attack leaves player vulnerable to subsequent attacks.
    case playerVulnerable(
        enemy: ItemProxy,
        enemyWeapon: ItemProxy?
    )

    /// Enemy deals critical damage to player.
    case playerCriticallyWounded(
        enemy: ItemProxy,
        enemyWeapon: ItemProxy?,
        damage: Int
    )

    /// Enemy deals significant damage to player.
    case playerGravelyInjured(
        enemy: ItemProxy,
        enemyWeapon: ItemProxy?,
        damage: Int
    )

    /// Enemy deals moderate damage to player.
    case playerInjured(
        enemy: ItemProxy,
        enemyWeapon: ItemProxy?,
        damage: Int
    )

    /// Enemy deals light damage to player.
    case playerLightlyInjured(
        enemy: ItemProxy,
        enemyWeapon: ItemProxy?,
        damage: Int
    )

    /// Enemy barely damages player.
    case playerGrazed(
        enemy: ItemProxy,
        enemyWeapon: ItemProxy?,
        damage: Int
    )

    /// Enemy's attack is a critical miss.
    case playerMissed(
        enemy: ItemProxy,
        enemyWeapon: ItemProxy?
    )

    /// Enemy's attack is blocked, dodged, or made ineffective by armor.
    case playerDodged(
        enemy: ItemProxy,
        enemyWeapon: ItemProxy?
    )

    // MARK: - Special Outcomes

    /// Enemy flees from combat.
    case enemyFlees(
        enemy: ItemProxy,
        enemyWeapon: ItemProxy?,
        direction: Direction?,
        destination: LocationID?
    )

    /// Enemy is pacified and stops fighting.
    case enemyPacified(
        enemy: ItemProxy,
        enemyWeapon: ItemProxy?
    )

    /// Enemy surrenders.
    case enemySurrenders(
        enemy: ItemProxy,
        enemyWeapon: ItemProxy?
    )

    /// Enemy taunts or intimidates instead of attacking.
    case enemyTaunts(
        enemy: ItemProxy,
        message: String
    )

    /// Enemy performs a special ability or action.
    case enemySpecialAction(
        enemy: ItemProxy,
        enemyWeapon: ItemProxy?,
        message: String
    )

    /// Player attempts to attack without required weapon.
    case unarmedAttackDenied(
        enemy: ItemProxy,
        enemyWeapon: ItemProxy?
    )

    /// Player attempts to attack with non-weapon item.
    case nonWeaponAttack(
        enemy: ItemProxy,
        enemyWeapon: ItemProxy?,
        item: ItemProxy
    )

    /// Player is distracted by non-combat action, allowing enemy free attack.
    case playerDistracted(
        enemy: ItemProxy,
        enemyWeapon: ItemProxy?,
        command: Command
    )

    /// Combat is interrupted by external event.
    case combatInterrupted(reason: String)

    /// Stalemate - neither side can harm the other.
    case stalemate(
        enemy: ItemProxy,
        enemyWeapon: ItemProxy?
    )

    /// Error processing combat event outcome.
    case error(message: String)
}

// MARK: - Damage Categories

extension CombatEvent {
    /// Categorizes damage amounts for narrative purposes.
    public enum DamageCategory {
        case fatal  // 100+ or kills
        case critical  // 50-99
        case grave  // 30-49
        case moderate  // 15-29
        case light  // 5-14
        case scratch  // 1-4
        case none  // 0

        /// Creates a damage category from a numeric value.
        public init(damage: Int, currentHealth: Int) {
            if damage >= currentHealth {
                self = .fatal
            } else {
                switch damage {
                case 50...: self = .critical
                case 30...49: self = .grave
                case 15...29: self = .moderate
                case 5...14: self = .light
                case 1...4: self = .scratch
                default: self = .none
                }
            }
        }
    }
}

// MARK: - Helpers

extension CombatEvent {
    /// Extracts the enemy proxy from any combat event.
    ///
    /// - Returns: The enemy involved in the combat event, or `nil` for non-enemy events.
    public var enemy: ItemProxy? {
        switch self {
        case .enemyAttacks(let enemy, _, _),
            .enemyBlocked(let enemy, _, _),
            .enemyCriticallyWounded(let enemy, _, _, _),
            .enemyDisarmed(let enemy, _, _, _),
            .enemyFlees(let enemy, _, _, _),
            .enemyGravelyInjured(let enemy, _, _, _),
            .enemyGrazed(let enemy, _, _, _),
            .enemyHesitates(let enemy, _, _),
            .enemyInjured(let enemy, _, _, _),
            .enemyLightlyInjured(let enemy, _, _, _),
            .enemyMissed(let enemy, _, _),
            .enemyPacified(let enemy, _),
            .enemySlain(let enemy, _, _, _),
            .enemySpecialAction(let enemy, _, _),
            .enemyStaggers(let enemy, _, _),
            .enemySurrenders(let enemy, _),
            .enemyTaunts(let enemy, _),
            .enemyUnconscious(let enemy, _, _),
            .enemyVulnerable(let enemy, _, _),
            .nonWeaponAttack(let enemy, _, _),
            .playerAttacks(let enemy, _, _),
            .playerCriticallyWounded(let enemy, _, _),
            .playerDisarmed(let enemy, _, _, _),
            .playerDistracted(let enemy, _, _),
            .playerDodged(let enemy, _),
            .playerGravelyInjured(let enemy, _, _),
            .playerGrazed(let enemy, _, _),
            .playerHesitates(let enemy, _),
            .playerInjured(let enemy, _, _),
            .playerLightlyInjured(let enemy, _, _),
            .playerMissed(let enemy, _),
            .playerSlain(let enemy, _, _),
            .playerStaggers(let enemy, _),
            .playerUnconscious(let enemy, _, _),
            .playerVulnerable(let enemy, _),
            .stalemate(let enemy, _),
            .unarmedAttackDenied(let enemy, _):
            enemy
        case .combatInterrupted, .error:
            nil
        }
    }

    /// Whether an event incapacitates the opponent and prevents counter-attacks.
    ///
    /// - Returns: `true` if the event prevents the opponent from attacking back.
    public var incapacitatesOpponent: Bool {
        switch self {
        case .enemySlain, .enemyUnconscious, .enemyFlees, .enemySurrenders:
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
        case .enemyGrazed: 0.3
        case .enemyMissed: 0.7
        case .enemyBlocked: 0.5
        case .playerSlain: 0.9
        case .playerUnconscious: 0.8
        case .playerCriticallyWounded,
            .playerDisarmed,
            .playerVulnerable:
            0.7
        case .playerGravelyInjured,
            .playerStaggers,
            .playerHesitates:
            0.6
        case .playerInjured: 0.5
        case .playerLightlyInjured: 0.4
        case .playerDistracted: 0.3
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
