import CustomDump
import Foundation

/// Represents a one-way connection from one `Location` to another in a specific `Direction`.
/// 
/// `Exit` objects are stored in a `Location`'s `exits` dictionary, mapping a `Direction`
/// (e.g., `.north`, `.east`) to the `Exit` that defines the path in that direction.
/// An exit can be a simple passage or can be associated with a door (`doorID`)
/// that might be open, closed, or locked, affecting traversal.
/// 
/// If `destinationID` is `nil`, the exit is permanently blocked (e.g., "You can't go that way").
public struct Exit: Codable, Hashable, Sendable {
    /// The `LocationID` of the location this exit leads to, or `nil` if the exit is permanently blocked.
    ///
    /// When `nil`, this represents an exit that doesn't actually lead anywhere (e.g., repeatedly
    /// going north in Zork's forest). Such exits should typically display either the custom
    /// `blockedMessage` or a default "You can't go that way" message.
    public var destinationID: LocationID?

    /// An optional custom message to be displayed if the player attempts to use this exit
    /// but is prevented from doing so (e.g., because an associated door is closed and locked,
    /// or some other game condition blocks passage).
    /// If `nil`, the `GameEngine` or `ActionHandler` might use a default message.
    public var blockedMessage: String? = nil

    /// An optional `ItemID` that identifies an `Item` acting as a door or barrier for this exit.
    ///
    /// If `doorID` is set, the state of the corresponding `Item` (e.g., whether it's open,
    /// closed, locked) will typically determine if the player can pass through this exit.
    /// The `GoActionHandler` often uses this to check door states.
    public let doorID: ItemID?

    /// Creates a new exit to another location, optionally with a custom blocked message
    /// and/or an associated door item.
    ///
    /// - Parameters:
    ///   - destination: The `LocationID` this exit leads to, or `nil` for a permanently blocked exit.
    ///   - blockedMessage: An optional custom message to display if the player cannot
    ///     use this exit (e.g., due to a closed door or other obstruction). For permanently
    ///     blocked exits (when `destination` is `nil`), this message will be shown instead
    ///     of the default "You can't go that way."
    ///   - doorID: An optional `ItemID` for an item that acts as a door or barrier
    ///     for this exit. If set, the state of this item (e.g., open/closed/locked)
    ///     will typically determine if the player can pass through.
    init(
        destination: LocationID? = nil,
        blockedMessage: String? = nil,
        doorID: ItemID? = nil
    ) {
        self.destinationID = destination
        self.blockedMessage = blockedMessage
        self.doorID = doorID
    }

    /// A factory method for creating a simple exit to another location.
    /// 
    /// This is a shorthand for `Exit(destination: destination)` when you don't need
    /// a custom blocked message or door.
    /// 
    /// Example:
    /// ```swift
    /// .exits([
    ///     .north: .to("garden"),
    ///     .east: .to("kitchen")
    /// ])
    /// ```
    /// 
    /// - Parameters:
    ///   - destination: The `LocationID` this exit leads to.
    ///   - doorID: An optional `ItemID` for an item that acts as a door or barrier for this exit.
    /// - Returns: A new `Exit` instance with the specified destination.
    public static func to(
        _ destination: LocationID,
        via doorID: ItemID? = nil
    ) -> Exit {
        .init(destination: destination, doorID: doorID)
    }

    /// A factory method for creating a permanently blocked exit.
    ///
    /// This creates an exit that doesn't lead anywhere, optionally with a custom message.
    ///
    /// Example:
    /// ```swift
    /// .exits([
    ///     .north: .blocked("The path is overgrown with thorns."),
    /// ])
    /// ```
    ///
    /// - Parameter message: A custom message to display when the player attempts to use this
    ///                      blocked exit. If `nil`, a default message will be used.
    /// - Returns: A new `Exit` instance with no destination.
    public static func blocked(_ message: String) -> Exit {
        .init(destination: nil, blockedMessage: message)
    }

    // TODO: Consider adding properties for:
    // - Visibility (e.g., hidden exit)
    // - One-way exits
    // - Action routines associated with traversing (e.g., FEXIT in ZIL)
}

// MARK: - CustomDumpStringConvertible conformance

extension Exit: CustomDumpStringConvertible {
    public var customDumpDescription: String {
        var details = ["to: \(destinationID?.description ?? "blocked")"]
        if let blockedMessage {
            details.append("blocked: \(blockedMessage.indent(omitFirst: true))")
        }
        if let doorID { details.append("door: \(doorID)")}
        return "\n\(details.joined(separator: "\n").indent())"

    }
}

extension Dictionary: @retroactive CustomDumpStringConvertible where Key == Direction, Value == Exit {
    public var customDumpDescription: String {
        let elements = self.map { "\($0): \($1)" }
        return """
            \(elements.joined(separator: "\n").indent())
            """
    }
}
