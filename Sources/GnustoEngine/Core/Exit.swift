import CustomDump
import Foundation

/// Represents a connection from one location to another in a specific direction.
public struct Exit: Codable, Hashable, Sendable {
    /// The unique identifier of the location this exit leads to.
    public var destinationID: LocationID

    /// An optional message printed when movement is attempted but fails due to this exit
    /// being blocked. If nil, a default message like "The way is blocked." might be used.
    public var blockedMessage: String? = nil

    /// An optional door identifier, used to represent a door or similar barrier that can be
    /// opened, closed, and locked.
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
