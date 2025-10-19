import Foundation

/// Temporary combat conditions that affect fighting effectiveness.
///
/// These represent short-term states that can change during or between combats.
/// Unlike consciousness levels, these are typically temporary tactical conditions.
public enum CombatCondition: String, Codable, Sendable, Hashable, CaseIterable {
    /// Weapon has been knocked away or taken.
    ///
    /// The character must either retrieve their weapon, find a new one,
    /// or continue fighting with reduced effectiveness using improvised weapons or fists.
    case disarmed

    /// Distracted by a non-combat action or event.
    ///
    /// The character's attention is divided, making them vulnerable to attacks
    /// and less effective at defending. This condition typically applies when
    /// attempting actions like examining items or reading during combat.
    case distracted

    /// Fighting normally with no special conditions.
    case normal

    /// Lost footing or balance, easier to hit and harder to defend.
    ///
    /// Often results from powerful attacks, slippery terrain, or combat maneuvers.
    /// Reduces armor class and makes the character vulnerable to follow-up attacks.
    case offBalance

    /// Given up fighting and ceased hostilities.
    ///
    /// The character will not initiate attacks and may flee or cooperate.
    /// Combat may end or continue with the surrendered character as a non-combatant.
    case surrendered

    /// Taunting or intimidating the opponent instead of attacking.
    ///
    /// The character is engaging in psychological warfare, mocking or threatening
    /// their opponent. This can demoralize enemies but leaves the taunter open to
    /// counter-attacks.
    case taunting

    /// Hesitant and uncertain about what to do next.
    ///
    /// The character may delay actions, choose suboptimal tactics, or be more
    /// susceptible to intimidation and bluffing attempts.
    case uncertain

    /// Exposed and at a disadvantage.
    ///
    /// The character is in a compromised position, perhaps caught off-guard
    /// or in an exposed location, making them easier to hit effectively.
    case vulnerable
}

// MARK: - Combat Condition Properties

extension CombatCondition {
    /// Modifier to armor class based on combat condition.
    public var armorClassModifier: Int {
        switch self {
        case .normal: 0
        case .offBalance: -2
        case .uncertain: -1
        case .vulnerable: -3
        case .disarmed: 0  // AC not affected by weapon loss
        case .distracted: -3  // Not paying attention to defense
        case .taunting: -1  // Focused on intimidation, not defense
        case .surrendered: -5  // Not actively defending
        }
    }

    /// Modifier to attack rolls based on combat condition.
    public var attackModifier: Int {
        switch self {
        case .normal: 0
        case .offBalance: -1
        case .uncertain: -2
        case .vulnerable: 0  // Vulnerable to attacks, not bad at making them
        case .disarmed: -4  // Fighting without proper weapon
        case .distracted: -4  // Not focused on combat
        case .taunting: 0  // Can still attack after taunting
        case .surrendered: -999  // Not attacking
        }
    }

    /// Whether the character will actively participate in combat.
    public var willFight: Bool {
        switch self {
        case .surrendered: false
        case .taunting: false  // Taunting instead of fighting this turn
        default: true
        }
    }

    /// Whether this condition makes the character easier to hit.
    public var isDefensivelyImpaired: Bool {
        switch self {
        case .normal: false
        case .offBalance, .uncertain, .vulnerable, .distracted, .taunting, .surrendered: true
        case .disarmed: false
        }
    }

    /// Whether this condition makes the character less effective at attacking.
    public var isOffensivelyImpaired: Bool {
        switch self {
        case .normal: false
        case .offBalance, .uncertain, .disarmed, .distracted, .surrendered: true
        case .vulnerable, .taunting: false
        }
    }
}
