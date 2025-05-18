import CustomDump
import Foundation

/// Represents a one-way connection from one `Location` to another in a specific `Direction`.
///
/// `Exit` objects are stored in a `Location`'s `exits` dictionary, mapping a `Direction`
/// (e.g., `.north`, `.east`) to the `Exit` that defines the path in that direction.
/// An exit can be a simple passage or can be associated with a door (`doorID`)
/// that might be open, closed, or locked, affecting traversal.
public struct Exit: Codable, Hashable, Sendable {
    /// The `LocationID` of the location this exit leads to.
    public var destinationID: LocationID

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

    // --- Initialization ---
    public init(
        destination: LocationID,
        blockedMessage: String? = nil,
        doorID: ItemID? = nil
    ) {
        self.destinationID = destination
        self.blockedMessage = blockedMessage
        self.doorID = doorID
    }

    // TODO: Consider adding properties for:
    // - Visibility (e.g., hidden exit)
    // - One-way exits
    // - Action routines associated with traversing (e.g., FEXIT in ZIL)
}

// MARK: - CustomDumpStringConvertible conformance

extension Exit: CustomDumpStringConvertible {
    public var customDumpDescription: String {
        var details = ["to: \(destinationID.customDumpDescription)"]
        if let blockedMessage { details.append("blocked: \(blockedMessage.multiline)") }
        if let doorID { details.append("door: \(doorID.customDumpDescription)")}
        return "\n\(details.joined(separator: "\n").indent())"

    }
}

extension Dictionary: @retroactive CustomDumpStringConvertible where Key == Direction, Value == Exit {
    public var customDumpDescription: String {
        let elements = self.map { "\($0.customDumpDescription): \($1.customDumpDescription)" }
        return """
            \(elements.joined(separator: "\n").indent())
            """
    }
}
