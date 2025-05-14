import Foundation

/// Represents a parsed player command, ready for execution.
public struct Command: Equatable, Sendable {
    // --- Stored Properties (Alphabetical) ---

    /// The resolved direct object(s), if any.
    /// Note: Using `ItemID?` for now. Might evolve to `[EntityID]?` or similar for plural/ambiguous cases.
    public var directObject: EntityReference?

    /// Any modifiers associated with the direct object (adjectives, ordinals).
    public let directObjectModifiers: [String]

    /// The resolved indirect object(s), if any.
    public var indirectObject: EntityReference?

    /// Any modifiers associated with the indirect object.
    public let indirectObjectModifiers: [String]

    /// The preposition connecting the verb/direct object to the indirect object (e.g., "put lantern IN case").
    /// Note: Using `String?` for now. Might become a `PrepositionID?` later.
    public let preposition: String?

    /// The direction associated with the command, if applicable (e.g., GO NORTH).
    public var direction: Direction?

    /// The original raw input string, for context or error messages.
    public let rawInput: String

    /// The primary verb identified in the input.
    public let verbID: VerbID

    // --- Initialization ---
    /// Initializes a new Command structure.
    public init(
        verbID: VerbID,
        directObject: EntityReference? = nil,
        directObjectModifiers: [String] = [],
        indirectObject: EntityReference? = nil,
        indirectObjectModifiers: [String] = [],
        preposition: String? = nil,
        direction: Direction? = nil,
        rawInput: String
    ) {
        self.verbID = verbID
        self.directObject = directObject
        self.directObjectModifiers = directObjectModifiers
        self.indirectObject = indirectObject
        self.indirectObjectModifiers = indirectObjectModifiers
        self.preposition = preposition
        self.direction = direction
        self.rawInput = rawInput
    }
}
