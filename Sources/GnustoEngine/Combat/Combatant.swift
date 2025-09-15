import Foundation

/// Represents a participant in combat, either an enemy or a player.
public enum Combatant: Sendable {
    case enemy(ItemProxy)
    case player(PlayerProxy)

    /// The combatant's character sheet containing all attributes and combat properties.
    public var characterSheet: CharacterSheet {
        get async throws {
            switch self {
            case .enemy(let item):
                try await item.characterSheet
            case .player(let player):
                await player.characterSheet
            }
        }
    }

    /// Current health points.
    public var health: Int {
        get async throws {
            try await characterSheet.health
        }
    }

    /// Maximum health points.
    public var maxHealth: Int {
        get async throws {
            try await characterSheet.maxHealth
        }
    }

    /// The combatant's preferred weapon, if any.
    public var preferredWeapon: ItemProxy? {
        get async throws {
            switch self {
            case .enemy(let item):
                try await item.preferredWeapon
            case .player(let player):
                try await player.preferredWeapon
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
