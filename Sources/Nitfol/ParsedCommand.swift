import Foundation

/// Represents a parsed player command with identified components.
public struct ParsedCommand: Equatable {
    /// The primary verb of the command (e.g., "take", "go", "examine").
    public let verb: String?

    /// The primary object of the verb (e.g., the thing being taken, examined, opened).
    public let directObject: String?

    /// Modifiers associated with the direct object (e.g., "rusty", "heavy").
    public let directObjectModifiers: [String]

    /// The preposition connecting the verb/direct object to the indirect object
    /// (e.g., "with", "to", "in", "on").
    public let prepositions: [String]

    /// The secondary object, often linked by a preposition (e.g., the item used "with",
    /// the recipient given "to", the container put "in").
    public let indirectObject: String?

    /// Modifiers associated with the indirect object.
    public let indirectObjectModifiers: [String]

    /// Initializes a ParsedCommand structure.
    ///
    /// - Parameters:
    ///   - verb: The main action verb.
    ///   - directObject: The primary object.
    ///   - directObjectModifiers: Adjectives or descriptors for the direct object.
    ///   - prepositions: The linking preposition(s).
    ///   - indirectObject: The secondary object.
    ///   - indirectObjectModifiers: Adjectives or descriptors for the indirect object.
    public init(
        verb: String?,
        directObject: String? = nil,
        directObjectModifiers: [String] = [],
        prepositions: String...,
        indirectObject: String? = nil,
        indirectObjectModifiers: [String] = []
    ) {
        self.verb = verb
        self.directObject = directObject
        self.directObjectModifiers = directObjectModifiers
        self.prepositions = prepositions
        self.indirectObject = indirectObject
        self.indirectObjectModifiers = indirectObjectModifiers
    }

    /// Initializes a ParsedCommand structure.
    ///
    /// - Parameters:
    ///   - verb: The main action verb.
    ///   - directObject: The primary object.
    ///   - directObjectModifiers: Adjectives or descriptors for the direct object.
    ///   - prepositions: The linking preposition(s).
    ///   - indirectObject: The secondary object.
    ///   - indirectObjectModifiers: Adjectives or descriptors for the indirect object.
    public init(
        verb: String?,
        directObject: String? = nil,
        directObjectModifiers: [String] = [],
        prepositions: [String] = [],
        indirectObject: String? = nil,
        indirectObjectModifiers: [String] = []
    ) {
        self.verb = verb
        self.directObject = directObject
        self.directObjectModifiers = directObjectModifiers
        self.prepositions = prepositions
        self.indirectObject = indirectObject
        self.indirectObjectModifiers = indirectObjectModifiers
    }

    public var isSingleWord: Bool {
        verb != nil && !hasDirectObject && !hasIndirectObject && !hasPreposition
    }

    public var hasDirectObject: Bool {
        directObject != nil
    }

    public var hasIndirectObject: Bool {
        indirectObject != nil
    }

    public var hasPreposition: Bool {
        !prepositions.isEmpty
    }
}
