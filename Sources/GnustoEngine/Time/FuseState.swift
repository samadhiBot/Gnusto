import Foundation

/// Represents the runtime state of an active fuse, including both its turn countdown
/// and any custom state data that was provided when the fuse was started.
///
/// This structure allows fuses to maintain context-specific information across
/// game turns. For example, an enemy recovery fuse can store both the enemy ID and the
/// location ID where the enemy should return, preventing situations where the enemy spawns
/// in the player's current location instead of where they originally were.
public struct FuseState: Codable, Sendable, Equatable, Hashable {
    /// The number of game turns remaining until this fuse triggers.
    /// This value is decremented each turn by the game engine's timing system.
    /// If nil, the engine will use the fuse definition's initialTurns.
    public var turns: Int?

    /// Type-safe codable payload containing custom state data for this fuse instance.
    /// This can store any `Codable & Sendable` type, providing compile-time type safety
    /// and eliminating the need for string-based key lookups.
    public var payload: AnyCodableSendable?

    // MARK: - Initializers

    /// Initializes a new fuse state with a type-safe payload.
    ///
    /// - Parameters:
    ///   - turns: The number of turns until the fuse triggers (must be > 0 if provided).
    ///   - payload: Optional strongly-typed payload data for the fuse.
    /// - Throws: An error if the payload cannot be encoded to JSON.
    public init<T: Codable & Sendable>(turns: Int?, payload: T?) throws {
        if let turns = turns {
            precondition(turns > 0, "Fuse state must have a positive turn count.")
        }
        self.turns = turns
        self.payload = try payload.map(AnyCodableSendable.init)
    }

    /// Initializes a new fuse state with no payload data.
    ///
    /// - Parameters:
    ///   - turns: The number of turns until the fuse triggers (must be > 0 if provided).
    public init(turns: Int?) {
        if let turns = turns {
            precondition(turns > 0, "Fuse state must have a positive turn count.")
        }
        self.turns = turns
        self.payload = nil
    }

    /// Internal initializer that takes a payload directly without re-encoding.
    /// Used by the engine for operations like fuse repetition.
    ///
    /// - Parameters:
    ///   - turns: Number of turns until the fuse triggers (must be > 0 if provided).
    ///   - payload: The payload to use directly.
    internal init(turns: Int?, payload: AnyCodableSendable?) {
        if let turns = turns {
            precondition(turns > 0, "Fuse state must have a positive turn count.")
        }
        self.turns = turns
        self.payload = payload
    }

    // MARK: - Type-Safe Payload Access

    /// Retrieves the payload as the specified type.
    ///
    /// - Parameter type: The type to decode the payload as.
    /// - Returns: The decoded payload of the specified type, or `nil` if no payload
    ///           exists or the type doesn't match.
    public func getPayload<T: Codable & Sendable>(as type: T.Type) -> T? {
        return payload?.tryDecode(as: type)
    }

    /// Checks if the payload contains data of the specified type.
    ///
    /// - Parameter type: The type to check for.
    /// - Returns: `true` if the payload exists and can be decoded as the specified type.
    public func hasPayload<T: Codable & Sendable>(ofType type: T.Type) -> Bool {
        return getPayload(as: type) != nil
    }
}

// MARK: - Common Payload Types

extension FuseState {

    /// A structured payload for fuses that need to reference an enemy and location.
    /// This is commonly used by enemy-related fuses like wakeup and return behaviors.
    public struct EnemyLocationPayload: Codable, Sendable, Equatable, Hashable {
        public let enemyID: ItemID
        public let locationID: LocationID
        public let message: String

        public init(enemyID: ItemID, locationID: LocationID, message: String) {
            self.enemyID = enemyID
            self.locationID = locationID
            self.message = message
        }
    }

    /// A structured payload for status effect expiry fuses.
    /// Contains the affected character and the specific effect to remove.
    public struct StatusEffectPayload: Codable, Sendable, Equatable, Hashable {
        public let itemID: ItemID
        public let effect: GeneralCondition

        public init(itemID: ItemID, effect: GeneralCondition) {
            self.itemID = itemID
            self.effect = effect
        }
    }
}

// MARK: - Convenience Constructors

extension FuseState {

    /// Creates a fuse state with enemy/location payload data.
    ///
    /// - Parameters:
    ///   - turns: Number of turns until the fuse triggers (must be > 0 if provided).
    ///   - enemyID: The ID of the enemy item.
    ///   - locationID: The location ID for context.
    ///   - message: The message to display when triggered.
    /// - Throws: An error if the payload cannot be encoded.
    public static func enemyLocation(
        turns: Int?,
        enemyID: ItemID,
        locationID: LocationID,
        message: String
    ) throws -> FuseState {
        let payload = EnemyLocationPayload(
            enemyID: enemyID,
            locationID: locationID,
            message: message
        )
        return try FuseState(turns: turns, payload: payload)
    }

    /// Creates a fuse state with status effect payload data.
    ///
    /// - Parameters:
    ///   - turns: Number of turns until the fuse triggers (must be > 0 if provided).
    ///   - itemID: The ID of the affected character/item.
    ///   - effect: The status effect to remove.
    /// - Throws: An error if the payload cannot be encoded.
    public static func statusEffect(
        turns: Int?,
        itemID: ItemID,
        effect: GeneralCondition
    ) throws -> FuseState {
        let payload = StatusEffectPayload(
            itemID: itemID,
            effect: effect
        )
        return try FuseState(turns: turns, payload: payload)
    }
}
