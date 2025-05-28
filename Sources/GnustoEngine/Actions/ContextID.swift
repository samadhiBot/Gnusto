import Foundation

/// A unique identifier for a piece of contextual data relevant to an action.
///
/// Unlike `AttributeID` which identifies stored state, `ContextID` typically identifies
/// transient information calculated or gathered specifically for the current action execution.
public struct ContextID: GnustoID {
    /// The underlying string value of the context identifier.
    /// You typically use this when you need to define or check a specific `ContextID`.
    public let rawValue: String

    /// Initializes a `ContextID` with a raw string value.
    ///
    /// Use this initializer to create a `ContextID` programmatically from a string variable.
    /// - Parameter rawValue: The string value that uniquely identifies this context key.
    public init(rawValue: String) {
        assert(!rawValue.isEmpty, "Context ID cannot be empty")
        self.rawValue = rawValue
    }
}

// MARK: - Example Context IDs
// Games can define common context keys.
/*
public extension ContextID {
    static let currentPhase = ContextID("gamePhase")
    static let playerMood = ContextID("playerMood")
    static let timeOfDay = ContextID("timeOfDay")
}
*/
