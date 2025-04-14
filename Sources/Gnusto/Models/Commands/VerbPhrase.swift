import Foundation

/// Represents a potential trigger for a command handler, combining a verb with
/// an optional preposition.
///
/// This is used by the `CommandRegistry` and `ActionDispatcher` to match user input
/// (like "turn on" or "look") to the appropriate handler.
public struct VerbPhrase: Hashable, Sendable {
    /// The verb string (e.g., "turn", "look", "pick").
    public let verb: String

    /// The optional preposition string (e.g., "on", "up", "in").
    public let preposition: String?

    public init(
        verb: String,
        preposition: String? = nil
    ) {
        self.verb = verb.lowercased()
        self.preposition = preposition?.lowercased()
    }
}
