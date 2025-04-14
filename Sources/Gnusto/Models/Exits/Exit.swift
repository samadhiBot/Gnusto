import Foundation

/// An exit that can be either a direct destination or a conditional exit
public enum Exit: Sendable {
    /// A direct exit to another room
    case direct(Object.ID)

    /// A conditional exit that depends on game state
    case conditional(ConditionalExit)

    /// Create a direct exit to a destination
    /// - Parameter destination: The destination room ID
    /// - Returns: A direct exit
    public static func to(_ destination: Object.ID) -> Exit {
        .direct(destination)
    }

    /// Create a conditional exit
    /// - Parameter conditionalExit: The conditional exit configuration
    /// - Returns: A conditional exit
    public static func when(_ conditionalExit: ConditionalExit) -> Exit {
        .conditional(conditionalExit)
    }

    /// The destination room ID, if available in the current world state
    /// - Parameter world: The current game world
    /// - Returns: The destination room ID if the exit is available, nil otherwise
    public func destination(in world: World) -> Object.ID? {
        switch self {
        case .direct(let roomID):
            return roomID
        case .conditional(let conditionalExit):
            return conditionalExit.condition(world) ? conditionalExit.destination : nil
        }
    }

    /// If this is a conditional exit that is blocked, returns the blocked message
    /// - Parameter world: The current game world
    /// - Returns: The blocked message if available and exit is blocked, nil otherwise
    public func blockedMessage(in world: World) -> String? {
        switch self {
        case .direct:
            return nil
        case .conditional(let conditionalExit):
            return conditionalExit.condition(world) ? nil : conditionalExit.blockedMessage
        }
    }
}

// MARK: - Conformances

extension Exit: Equatable {
    // This equality check is for testing purposes only
    public static func == (lhs: Exit, rhs: Exit) -> Bool {
        switch (lhs, rhs) {
        case (.direct(let lhsID), .direct(let rhsID)): lhsID == rhsID
        case (.conditional(let lhsExit), .conditional(let rhsExit)): lhsExit == rhsExit
        case (.direct, .conditional), (.conditional, .direct): false
        }
    }
}
