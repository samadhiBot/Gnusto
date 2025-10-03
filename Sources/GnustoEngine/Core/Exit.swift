import CustomDump
import Foundation

/// Represents a one-way connection from one `Location` to another in a specific `Direction`.
///
/// `Exit` objects are stored in a `Location`'s `exits` property, declaring a `Direction`
/// (e.g., `.north`, `.east`) and the path in that direction. An exit can be a simple passage
/// or can be associated with a door (`doorID`) that might be open, closed, or locked, all
/// affecting traversal. If `destinationID` is `nil`, the exit is permanently blocked.
public struct Exit: Codable, Hashable, Sendable {
    /// The cardinal or other direction to move toward or through the exit.
    public let direction: Direction

    /// The `LocationID` of the location this exit leads to, or `nil` if the exit is permanently
    /// blocked.
    ///
    /// When `nil`, this represents an exit that doesn't actually lead anywhere (e.g., repeatedly
    /// going north in Zork's forest). Such exits should typically display either the custom
    /// `blockedMessage` or a default "You can't go that way" message.
    public let destinationID: LocationID?

    /// An optional custom message to be displayed if the player attempts to use this exit
    /// but is prevented from doing so.
    ///
    /// Examples of blockages include when an associated door is closed and locked, or some
    /// other game condition blocks passage. If `nil`, the engine displays a default message.
    public let blockedMessage: String?

    /// An optional `ItemID` that identifies an `Item` acting as a door or barrier for this exit.
    ///
    /// If `doorID` is set, the state of the corresponding `Item` (e.g., whether it's open,
    /// closed, locked) will typically determine if the player can pass through this exit.
    /// The `GoActionHandler` often uses this to check door states.
    public let doorID: ItemID?

    // MARK: - Cardinal Directions

    /// Creates an exit leading north to the specified location.
    /// - Parameters:
    ///   - locationID: The destination location ID.
    ///   - itemID: Optional door or barrier item ID that controls access.
    ///   - blocked: Optional custom message shown when the exit is blocked.
    /// - Returns: An `Exit` configured for northward movement.
    public static func north(
        _ locationID: LocationID,
        via itemID: ItemID? = nil,
        blocked: String? = nil
    ) -> Exit {
        Exit(
            direction: .north,
            destinationID: locationID,
            blockedMessage: blocked,
            doorID: itemID
        )
    }

    /// Creates an exit leading south to the specified location.
    /// - Parameters:
    ///   - locationID: The destination location ID.
    ///   - itemID: Optional door or barrier item ID that controls access.
    ///   - blocked: Optional custom message shown when the exit is blocked.
    /// - Returns: An `Exit` configured for southward movement.
    public static func south(
        _ locationID: LocationID,
        via itemID: ItemID? = nil,
        blocked: String? = nil
    ) -> Exit {
        Exit(
            direction: .south,
            destinationID: locationID,
            blockedMessage: blocked,
            doorID: itemID
        )
    }

    /// Creates an exit leading east to the specified location.
    /// - Parameters:
    ///   - locationID: The destination location ID.
    ///   - itemID: Optional door or barrier item ID that controls access.
    ///   - blocked: Optional custom message shown when the exit is blocked.
    /// - Returns: An `Exit` configured for eastward movement.
    public static func east(
        _ locationID: LocationID,
        via itemID: ItemID? = nil,
        blocked: String? = nil
    ) -> Exit {
        Exit(
            direction: .east,
            destinationID: locationID,
            blockedMessage: blocked,
            doorID: itemID
        )
    }

    /// Creates an exit leading west to the specified location.
    /// - Parameters:
    ///   - locationID: The destination location ID.
    ///   - itemID: Optional door or barrier item ID that controls access.
    ///   - blocked: Optional custom message shown when the exit is blocked.
    /// - Returns: An `Exit` configured for westward movement.
    public static func west(
        _ locationID: LocationID,
        via itemID: ItemID? = nil,
        blocked: String? = nil
    ) -> Exit {
        Exit(
            direction: .west,
            destinationID: locationID,
            blockedMessage: blocked,
            doorID: itemID
        )
    }

    // MARK: - Intermediate Directions

    /// Creates an exit leading northeast to the specified location.
    /// - Parameters:
    ///   - locationID: The destination location ID.
    ///   - itemID: Optional door or barrier item ID that controls access.
    ///   - blocked: Optional custom message shown when the exit is blocked.
    /// - Returns: An `Exit` configured for northeastward movement.
    public static func northeast(
        _ locationID: LocationID,
        via itemID: ItemID? = nil,
        blocked: String? = nil
    ) -> Exit {
        Exit(
            direction: .northeast,
            destinationID: locationID,
            blockedMessage: blocked,
            doorID: itemID
        )
    }

    /// Creates an exit leading northwest to the specified location.
    /// - Parameters:
    ///   - locationID: The destination location ID.
    ///   - itemID: Optional door or barrier item ID that controls access.
    ///   - blocked: Optional custom message shown when the exit is blocked.
    /// - Returns: An `Exit` configured for northwestward movement.
    public static func northwest(
        _ locationID: LocationID,
        via itemID: ItemID? = nil,
        blocked: String? = nil
    ) -> Exit {
        Exit(
            direction: .northwest,
            destinationID: locationID,
            blockedMessage: blocked,
            doorID: itemID
        )
    }

    /// Creates an exit leading southeast to the specified location.
    /// - Parameters:
    ///   - locationID: The destination location ID.
    ///   - itemID: Optional door or barrier item ID that controls access.
    ///   - blocked: Optional custom message shown when the exit is blocked.
    /// - Returns: An `Exit` configured for southeastward movement.
    public static func southeast(
        _ locationID: LocationID,
        via itemID: ItemID? = nil,
        blocked: String? = nil
    ) -> Exit {
        Exit(
            direction: .southeast,
            destinationID: locationID,
            blockedMessage: blocked,
            doorID: itemID
        )
    }

    /// Creates an exit leading southwest to the specified location.
    /// - Parameters:
    ///   - locationID: The destination location ID.
    ///   - itemID: Optional door or barrier item ID that controls access.
    ///   - blocked: Optional custom message shown when the exit is blocked.
    /// - Returns: An `Exit` configured for southwestward movement.
    public static func southwest(
        _ locationID: LocationID,
        via itemID: ItemID? = nil,
        blocked: String? = nil
    ) -> Exit {
        Exit(
            direction: .southwest,
            destinationID: locationID,
            blockedMessage: blocked,
            doorID: itemID
        )
    }

    // MARK: - Vertical Directions

    /// Creates an exit leading up to the specified location.
    /// - Parameters:
    ///   - locationID: The destination location ID.
    ///   - itemID: Optional door or barrier item ID that controls access.
    ///   - blocked: Optional custom message shown when the exit is blocked.
    /// - Returns: An `Exit` configured for upward movement.
    public static func up(
        _ locationID: LocationID,
        via itemID: ItemID? = nil,
        blocked: String? = nil
    ) -> Exit {
        Exit(
            direction: .up,
            destinationID: locationID,
            blockedMessage: blocked,
            doorID: itemID
        )
    }

    /// Creates an exit leading down to the specified location.
    /// - Parameters:
    ///   - locationID: The destination location ID.
    ///   - itemID: Optional door or barrier item ID that controls access.
    ///   - blocked: Optional custom message shown when the exit is blocked.
    /// - Returns: An `Exit` configured for downward movement.
    public static func down(
        _ locationID: LocationID,
        via itemID: ItemID? = nil,
        blocked: String? = nil
    ) -> Exit {
        Exit(
            direction: .down,
            destinationID: locationID,
            blockedMessage: blocked,
            doorID: itemID
        )
    }

    // MARK: - Inside/Outside Directions

    /// Creates an exit leading inside to the specified location.
    /// - Parameters:
    ///   - locationID: The destination location ID.
    ///   - itemID: Optional door or barrier item ID that controls access.
    ///   - blocked: Optional custom message shown when the exit is blocked.
    /// - Returns: An `Exit` configured for movement inside.
    public static func inside(
        _ locationID: LocationID,
        via itemID: ItemID? = nil,
        blocked: String? = nil
    ) -> Exit {
        Exit(
            direction: .inside,
            destinationID: locationID,
            blockedMessage: blocked,
            doorID: itemID
        )
    }

    /// Creates an exit leading outside to the specified location.
    /// - Parameters:
    ///   - locationID: The destination location ID.
    ///   - itemID: Optional door or barrier item ID that controls access.
    ///   - blocked: Optional custom message shown when the exit is blocked.
    /// - Returns: An `Exit` configured for movement outside.
    public static func outside(
        _ locationID: LocationID,
        via itemID: ItemID? = nil,
        blocked: String? = nil
    ) -> Exit {
        Exit(
            direction: .outside,
            destinationID: locationID,
            blockedMessage: blocked,
            doorID: itemID
        )
    }

    // MARK: - Blocked Exits

    /// Creates a permanently blocked exit leading north.
    /// - Parameter blocked: The custom message to display when the player attempts this exit.
    /// - Returns: A blocked `Exit` configured for northward movement.
    public static func north(blocked: String) -> Exit {
        Exit(
            direction: .north,
            destinationID: nil,
            blockedMessage: blocked,
            doorID: nil
        )
    }

    /// Creates a permanently blocked exit leading south.
    /// - Parameter blocked: The custom message to display when the player attempts this exit.
    /// - Returns: A blocked `Exit` configured for southward movement.
    public static func south(blocked: String) -> Exit {
        Exit(
            direction: .south,
            destinationID: nil,
            blockedMessage: blocked,
            doorID: nil
        )
    }

    /// Creates a permanently blocked exit leading east.
    /// - Parameter blocked: The custom message to display when the player attempts this exit.
    /// - Returns: A blocked `Exit` configured for eastward movement.
    public static func east(blocked: String) -> Exit {
        Exit(
            direction: .east,
            destinationID: nil,
            blockedMessage: blocked,
            doorID: nil
        )
    }

    /// Creates a permanently blocked exit leading west.
    /// - Parameter blocked: The custom message to display when the player attempts this exit.
    /// - Returns: A blocked `Exit` configured for westward movement.
    public static func west(blocked: String) -> Exit {
        Exit(
            direction: .west,
            destinationID: nil,
            blockedMessage: blocked,
            doorID: nil
        )
    }

    /// Creates a permanently blocked exit leading up.
    /// - Parameter blocked: The custom message to display when the player attempts this exit.
    /// - Returns: A blocked `Exit` configured for upward movement.
    public static func up(blocked: String) -> Exit {
        Exit(
            direction: .up,
            destinationID: nil,
            blockedMessage: blocked,
            doorID: nil
        )
    }

    /// Creates a permanently blocked exit leading down.
    /// - Parameter blocked: The custom message to display when the player attempts this exit.
    /// - Returns: A blocked `Exit` configured for downward movement.
    public static func down(blocked: String) -> Exit {
        Exit(
            direction: .down,
            destinationID: nil,
            blockedMessage: blocked,
            doorID: nil
        )
    }

    /// Creates a permanently blocked exit leading inside.
    /// - Parameter blocked: The custom message to display when the player attempts this exit.
    /// - Returns: A blocked `Exit` configured for movement inside.
    public static func inside(blocked: String) -> Exit {
        Exit(
            direction: .inside,
            destinationID: nil,
            blockedMessage: blocked,
            doorID: nil
        )
    }

    /// Creates a permanently blocked exit leading outside.
    /// - Parameter blocked: The custom message to display when the player attempts this exit.
    /// - Returns: A blocked `Exit` configured for movement outside.
    public static func outside(blocked: String) -> Exit {
        Exit(
            direction: .outside,
            destinationID: nil,
            blockedMessage: blocked,
            doorID: nil
        )
    }
}

// MARK: - CustomDumpStringConvertible

extension Exit: Comparable {
    public static func < (lhs: Exit, rhs: Exit) -> Bool {
        lhs.direction < rhs.direction
    }
}

extension Exit: CustomDumpStringConvertible {
    /// A custom string representation used by the CustomDump library for debugging output.
    ///
    /// Formats the exit as `direction(details...)` where details include the destination,
    /// blocked message, and door ID if present.
    ///
    /// Example output: `north(destinationID: foyer, door: frontDoor)`
    public var customDumpDescription: String {
        var details = [String]()
        if let destinationID {
            details.append("to: \(destinationID)")
        }
        if let doorID {
            details.append("via: \(doorID)")
        }
        if let blockedMessage {
            details.append("blocked: \(blockedMessage.indent(omitFirst: true))")
        }
        return "\(direction)(\(details.joined(separator: .linebreak)))"
    }
}

// MARK: - MovementBehavior

extension Exit {
    public enum MovementBehavior: Equatable {
        /// Can pass through any exit, even if blocked
        case any

        /// Can pass through closed door that are unlocked
        case closedDoors

        /// Can pass through locked doors
        case lockedDoors

        /// Can pass through locked doors that can be unlocked by one of the specified keys
        case lockedDoorsUnlockedByKeys([ItemID])

        /// Normal interaction with doors
        case normal
    }
}
