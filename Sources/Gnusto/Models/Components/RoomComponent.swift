import Foundation

/// Defines a room in the game world.
public struct RoomComponent: Component {
    public static let type: ComponentType = .room

    /// Whether this room is naturally lit
    public var isLit: Bool

    /// Exits leading from this room
    public var exits: [Direction: Exit]

    /// Custom description to show when the room is dark
    private var _darkDescription: String?

    /// Creates a new room component
    /// - Parameters:
    ///   - isLit: Whether this room is naturally lit (default: true)
    ///   - darkDescription: Custom description to show when the room is dark (default: nil)
    ///   - exits: Initial exits for this room (default: empty)
    public init(
        isLit: Bool = true,
        darkDescription: String? = nil,
        exits: [Direction: Exit] = [:]
    ) {
        self.isLit = isLit
        self._darkDescription = darkDescription
        self.exits = exits
    }

    /// Get default darkness description if none is specified
    public var darkDescription: String {
        _darkDescription ?? "It is pitch black. You are likely to be eaten by a grue."
    }
    
    /// Get a direct mapping of directions to room IDs for exits that are unconditionally available
    public var directExits: [Direction: Object.ID] {
        exits.compactMapValues { exit in
            if case .direct(let roomID) = exit {
                return roomID
            }
            return nil
        }
    }

    /// Adds a direct exit to the room
    /// - Parameters:
    ///   - direction: The direction of the exit
    ///   - destination: The destination room ID
    public mutating func addExit(
        direction: Direction,
        to destination: Object.ID
    ) {
        exits[direction] = .direct(destination)
    }

    /// Adds a conditional exit to the room
    /// - Parameters:
    ///   - direction: The direction of the exit
    ///   - conditionalExit: The conditional exit configuration
    public mutating func addExit(
        direction: Direction,
        conditional conditionalExit: ConditionalExit
    ) {
        exits[direction] = .conditional(conditionalExit)
    }

    /// Check if an exit is available in the current world state
    /// - Parameters:
    ///   - direction: The direction to check
    ///   - world: The current game world
    /// - Returns: The destination room ID if the exit is available, nil otherwise
    public func availableExit(
        direction: Direction,
        in world: World
    ) -> Object.ID? {
        guard let exit = exits[direction] else {
            return nil
        }
        return exit.destination(in: world)
    }

    /// Get a message explaining why an exit is blocked, if applicable
    /// - Parameters:
    ///   - direction: The direction to check
    ///   - world: The current game world
    /// - Returns: A message if the exit is conditionally blocked, nil otherwise
    public func blockedExitMessage(
        direction: Direction,
        in world: World
    ) -> String? {
        guard let exit = exits[direction] else {
            return nil
        }
        return exit.blockedMessage(in: world)
    }
}
