import Foundation

/// Represents a structured and validated player command, ready for the `GameEngine` to execute.
///
/// A `Command` is the output of a successful parsing operation by a `Parser` (like `StandardParser`).
/// It encapsulates the player's intent by identifying the core verb, any direct or indirect
/// objects involved (as `EntityReference`s), associated modifiers (like adjectives),
/// prepositions, and directions. It also retains the original raw input string for context.
public struct Command: Equatable, Sendable {
    // --- Stored Properties (Alphabetical) ---

    /// The primary entity that is the direct target of the verb, if any.
    /// For example, in "take lantern", the lantern is the direct object.
    /// It is represented as an `EntityReference`, which can be an item, location, or the player.
    public var directObject: EntityReference?

    /// Adjectives or other descriptive words associated with the `directObject` as they
    /// appeared in the player's input (e.g., ["brass", "small"] for "take small brass lantern").
    /// These are used by the parser during object resolution and can be useful for context
    /// in action handlers.
    public let directObjectModifiers: [String]

    /// The secondary entity involved in the command, often connected to the direct object
    /// by a preposition, if any.
    /// For example, in "put lantern in case", the case is the indirect object.
    /// Represented as an `EntityReference`.
    public var indirectObject: EntityReference?

    /// Adjectives or other descriptive words associated with the `indirectObject` from the
    /// player's input (e.g., ["wooden"] for "put key in wooden box").
    public let indirectObjectModifiers: [String]

    /// The preposition (e.g., "in", "on", "with") that links the verb or direct object
    /// to the `indirectObject`, if one was used and identified by the parser.
    /// For example, "in" for "put lantern IN case".
    public let preposition: String?

    /// The specific `Direction` (e.g., `.north`, `.up`) associated with the command,
    /// typically for movement commands like "go north" or shorthand like "north".
    public var direction: Direction?

    /// The original, unmodified input string exactly as the player typed it.
    /// This is useful for debugging, logging, or displaying exact player input in messages.
    public let rawInput: String

    /// The primary `VerbID` identified by the parser as the core action the player
    /// intends to perform (e.g., `.take`, `.look`, `.go`).
    public let verb: VerbID

    // --- Initialization ---
    /// Initializes a new `Command` structure with all its components.
    ///
    /// This initializer is primarily used by `Parser` implementations when they successfully
    /// interpret a player's input. Game developers typically don't create `Command` objects directly.
    ///
    /// - Parameters:
    ///   - verb: The `VerbID` of the main action.
    ///   - directObject: The resolved `EntityReference` for the direct object, if any.
    ///   - directObjectModifiers: Modifiers for the direct object.
    ///   - indirectObject: The resolved `EntityReference` for the indirect object, if any.
    ///   - indirectObjectModifiers: Modifiers for the indirect object.
    ///   - preposition: The preposition used, if any.
    ///   - direction: The `Direction` specified, if any.
    ///   - rawInput: The original player input string.
    public init(
        verb: VerbID,
        directObject: EntityReference? = nil,
        directObjectModifiers: [String] = [],
        indirectObject: EntityReference? = nil,
        indirectObjectModifiers: [String] = [],
        preposition: String? = nil,
        direction: Direction? = nil,
        rawInput: String
    ) {
        self.verb = verb
        self.directObject = directObject
        self.directObjectModifiers = directObjectModifiers
        self.indirectObject = indirectObject
        self.indirectObjectModifiers = indirectObjectModifiers
        self.preposition = preposition
        self.direction = direction
        self.rawInput = rawInput
    }
}
