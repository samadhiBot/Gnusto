import Foundation

/// Represents an exit that is conditionally available based on game state.
public struct ConditionalExit: Sendable {
    /// The destination room ID if the exit is available
    public let destination: Object.ID

    /// A closure that determines if the exit is available based on world state
    public let condition: @Sendable (World) -> Bool

    /// Optional message to display when the exit is unavailable
    public let blockedMessage: String?

    /// Creates a new conditional exit
    /// - Parameters:
    ///   - destination: The destination room ID
    ///   - condition: A closure that returns true if the exit is available
    ///   - blockedMessage: Optional message to show when exit is blocked
    public init(
        to destination: Object.ID,
        when condition: @escaping @Sendable (World) -> Bool,
        blockedMessage: String? = nil
    ) {
        self.destination = destination
        self.condition = condition
        self.blockedMessage = blockedMessage
    }

    /// Creates a conditional exit that requires the player to have a specific object
    /// - Parameters:
    ///   - destination: The destination room ID
    ///   - requiredObject: The object ID the player must have
    ///   - blockedMessage: Optional message to show when exit is blocked
    /// - Returns: A conditional exit that checks if the player has the object
    public static func requiresObject(
        to destination: Object.ID,
        object requiredObject: Object.ID,
        blockedMessage: String? = nil
    ) -> ConditionalExit {
        ConditionalExit(
            to: destination,
            when: {
                $0.find(in: $0.player.id).contains { $0.id == requiredObject }
            },
            blockedMessage: blockedMessage
        )
    }

    /// Creates a conditional exit that requires an object to have a specific flag state
    /// - Parameters:
    ///   - destination: The destination room ID
    ///   - object: The object ID to check
    ///   - flag: The flag that must be set
    ///   - value: Whether the flag should be present (true) or absent (false)
    ///   - blockedMessage: Optional message to show when exit is blocked
    /// - Returns: A conditional exit that checks the flag state
    public static func requiresFlag(
        to destination: Object.ID,
        object: Object.ID,
        flag: Flag,
        value: Bool = true,
        blockedMessage: String? = nil
    ) -> ConditionalExit {
        ConditionalExit(
            to: destination,
            when: { world in
                guard let obj = world.find(object),
                      let objComponent = obj.find(ObjectComponent.self) else {
                    return false
                }
                return objComponent.flags.contains(flag) == value
            },
            blockedMessage: blockedMessage
        )
    }
}

// MARK: - Conformances

extension ConditionalExit: Equatable {
    // This equality check is for testing purposes only
    public static func == (lhs: ConditionalExit, rhs: ConditionalExit) -> Bool {
        // Note: We cannot compare the condition closures
        lhs.destination == rhs.destination &&
        lhs.blockedMessage == rhs.blockedMessage
    }
}
