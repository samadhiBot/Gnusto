import Foundation

/// Represents the engine's interpretation of the user's input after parsing.
///
/// This struct serves as a stable, intermediate representation, decoupling the
/// rest of the engine from the specific output format of the underlying parser
/// library (e.g., Nitfol).
public struct UserInput: Equatable, Sendable {
    /// The primary verb identified in the command (e.g., "take", "go", "examine"). Lowercased.
    public let verb: VerbID?

    /// The primary object of the verb (e.g., the thing being taken). Normalized string.
    public let directObject: String?

    /// Modifiers associated with the direct object (e.g., "rusty", "heavy"). Lowercased.
    public let directObjectModifiers: [String]

    /// The preposition(s) connecting the verb/direct object to the indirect object
    /// (e.g., "with", "to", "in", "on"). Lowercased.
    public let prepositions: [String]

    /// The secondary object, often linked by a preposition (e.g., the item used "with"). Normalized string.
    public let indirectObject: String?

    /// Modifiers associated with the indirect object. Lowercased.
    public let indirectObjectModifiers: [String]

    /// The original, unmodified input string.
    public let rawInput: String

    init(
        verb: VerbID?,
        directObject: String? = nil,
        directObjectModifiers: [String] = [],
        prepositions: [String] = [],
        indirectObject: String? = nil,
        indirectObjectModifiers: [String] = [],
        rawInput: String
    ) {
        self.verb = verb
        self.directObject = directObject
        self.directObjectModifiers = directObjectModifiers
        self.prepositions = prepositions
        self.indirectObject = indirectObject
        self.indirectObjectModifiers = indirectObjectModifiers
        self.rawInput = rawInput
    }

    init(
        verb: VerbID,
        directObject: String? = nil,
        directObjectModifiers: String...,
        prepositions: String...,
        indirectObject: String? = nil,
        indirectObjectModifiers: String...,
        rawInput: String
    ) {
        self.verb = verb
        self.directObject = directObject
        self.directObjectModifiers = directObjectModifiers
        self.prepositions = prepositions
        self.indirectObject = indirectObject
        self.indirectObjectModifiers = indirectObjectModifiers
        self.rawInput = rawInput
    }


    // MARK: - Convenience Accessors

    /// Checks if the input was likely a single word (only a verb identified).
    public var isSingleWord: Bool {
        verb != nil && directObject == nil && indirectObject == nil && prepositions.isEmpty
    }

    /// Checks if a direct object was identified.
    public var hasDirectObject: Bool {
        directObject != nil
    }

    /// Checks if an indirect object was identified.
    public var hasIndirectObject: Bool {
        indirectObject != nil
    }

    /// Checks if any prepositions were identified.
    public var hasPreposition: Bool {
        !prepositions.isEmpty
    }
}
