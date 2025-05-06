/// A global game flag identifier.
///
/// Flags represent boolean states within the game that are not tied to a specific
/// item or location (e.g., "met_wizard", "puzzle_solved").
public struct FlagID: Hashable, Comparable, Codable, ExpressibleByStringLiteral, Sendable {
    public let rawValue: String

    /// Creates a `FlagID` instance from a string literal.
    /// - Parameter value: The string literal representing the flag's unique ID.
    public init(stringLiteral value: String) {
        // Basic validation: ensure non-empty string
        guard !value.isEmpty else {
            // Consider logging a warning or throwing an error in a development build
            // For now, we allow empty strings but it might indicate an issue.
            print("Warning: Creating FlagID with empty string literal.")
            self.rawValue = ""
            return
        }
        // Could add further validation here (e.g., allowed characters) if needed.
        self.rawValue = value
    }

    /// Creates a `FlagID` instance from a raw string value.
    /// - Parameter rawValue: The string representing the flag's unique ID.
    public init(_ rawValue: String) {
        // Apply the same validation as stringLiteral init
        guard !rawValue.isEmpty else {
            print("Warning: Creating FlagID with empty raw string value.")
            self.rawValue = ""
            return
        }
        self.rawValue = rawValue
    }

    /// Compares two `FlagID` instances based on their `rawValue`.
    public static func < (lhs: FlagID, rhs: FlagID) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
