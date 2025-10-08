import Foundation

/// Represents a participant in combat, either an enemy or a player.
public enum Combatant: Sendable {
    case enemy(ItemProxy)
    case player(PlayerProxy)

    /// The combatant's character sheet containing all attributes and combat properties.
    public var characterSheet: CharacterSheet {
        get async {
            switch self {
            case .enemy(let item):
                await item.characterSheet
            case .player(let player):
                await player.characterSheet
            }
        }
    }

    /// Current health points.
    public var health: Int {
        get async {
            await characterSheet.health
        }
    }

    /// Maximum health points.
    public var maxHealth: Int {
        get async {
            await characterSheet.maxHealth
        }
    }

    /// The combatant's preferred weapon, if any.
    public var preferredWeapon: ItemProxy? {
        get async {
            switch self {
            case .enemy(let item):
                await item.preferredWeapon
            case .player(let player):
                await player.preferredWeapon
            }
        }
    }
}

extension Combatant: CustomStringConvertible {
    public var description: String {
        switch self {
        case .enemy(let enemy):
            return enemy.id.rawValue
        case .player:
            return "player"
        }
    }
}
