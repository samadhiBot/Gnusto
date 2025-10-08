import Foundation

/// Types of actions the player can take during combat.
public enum PlayerAction: Equatable, Sendable {
    /// Standard weapon or unarmed attack.
    case attack

    /// Defensive stance to reduce incoming damage.
    case defend

    /// Attempt to flee from combat.
    case flee(direction: Direction?)

    /// Any other action taken during combat.
    case other

    /// Cast a spell or use a special ability.
    case special(ability: String)

    /// Attempt to communicate with the enemy.
    case talk(topic: ProxyReference?)

    /// Use an item during combat.
    case useItem(item: ItemProxy)
}
