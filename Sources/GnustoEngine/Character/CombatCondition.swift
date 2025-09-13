import Foundation

/// Temporary combat conditions that affect fighting effectiveness.
///
/// These represent short-term states that can change during or between combats.
/// Unlike consciousness levels, these are typically temporary tactical conditions.
public enum CombatCondition: String, Codable, Sendable, Hashable, CaseIterable {
    /// Fighting normally with no special conditions.
    case normal

    /// Lost footing or balance, easier to hit and harder to defend.
    ///
    /// Often results from powerful attacks, slippery terrain, or combat maneuvers.
    /// Reduces armor class and makes the character vulnerable to follow-up attacks.
    case offBalance

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

    /// Weapon has been knocked away or taken.
    ///
    /// The character must either retrieve their weapon, find a new one,
    /// or continue fighting with reduced effectiveness using improvised weapons or fists.
    case disarmed

    /// Given up fighting and ceased hostilities.
    ///
    /// The character will not initiate attacks and may flee or cooperate.
    /// Combat may end or continue with the surrendered character as a non-combatant.
    case surrendered
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
        case .surrendered: -999  // Not attacking
        }
    }

    /// Whether the character will actively participate in combat.
    public var willFight: Bool {
        self != .surrendered
    }

    /// Whether this condition makes the character easier to hit.
    public var isDefensivelyImpaired: Bool {
        switch self {
        case .normal: false
        case .offBalance, .uncertain, .vulnerable, .surrendered: true
        case .disarmed: false
        }
    }

    /// Whether this condition makes the character less effective at attacking.
    public var isOffensivelyImpaired: Bool {
        switch self {
        case .normal: false
        case .offBalance, .uncertain, .disarmed, .surrendered: true
        case .vulnerable: false
        }
    }
}
