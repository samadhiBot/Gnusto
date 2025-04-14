import Foundation

/// Represents a connection from one location to another in a specific direction.
public struct Exit: Codable, Equatable, Sendable {
    /// The ID of the location this exit leads to.
    public var destination: LocationID

    // --- Optional Conditions/Properties ---

    /// An optional message printed when movement is attempted but fails due to this exit being blocked.
    /// If nil, a default message like "The way is blocked." might be used.
    public var blockedMessage: String? = nil

    /// An optional `ItemID` required to pass through this exit (e.g., a key for a locked door).
    public var requiredKey: ItemID? = nil

    /// Indicates if this exit represents a door or similar barrier that can be opened/closed.
    public var isDoor: Bool = false

    /// If `isDoor` is true, indicates if the door is currently open.
    public var isOpen: Bool = true // Doors often start open unless specified

    /// If `isDoor` is true, indicates if the door is locked.
    public var isLocked: Bool = false

    // --- Initialization ---
    public init(
        destination: LocationID,
        blockedMessage: String? = nil,
        requiredKey: ItemID? = nil,
        isDoor: Bool = false,
        isOpen: Bool = true,
        isLocked: Bool = false
    ) {
        self.destination = destination
        self.blockedMessage = blockedMessage
        self.requiredKey = requiredKey
        self.isDoor = isDoor
        self.isOpen = isDoor ? isOpen : true // isOpen/isLocked only relevant if it's a door
        self.isLocked = isDoor ? isLocked : false
    }

    // TODO: Consider adding properties for:
    // - Visibility (e.g., hidden exit)
    // - One-way exits
    // - Action routines associated with traversing (e.g., FEXIT in ZIL)
}
