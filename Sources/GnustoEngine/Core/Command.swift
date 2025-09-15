import Foundation

/// Represents a structured and validated player command, ready for the `GameEngine` to execute.
///
/// A `Command` is the output of a successful parsing operation by a `Parser` (like `StandardParser`).
/// It encapsulates the player's intent by identifying the core verb, any direct or indirect
/// objects involved (as `ProxyReference`s), associated modifiers (like adjectives),
/// prepositions, and directions. It also retains the original raw input string for context.
///
/// Commands can involve single objects (e.g., "take lamp") or multiple objects when using
/// ALL (e.g., "take all", "drop all").
public struct Command: Equatable, Sendable {
    // --- Stored Properties (Alphabetical) ---

    /// The primary entity that is the direct target of the verb, if any.
    /// For example, in "take lantern", the lantern is the direct object.
    /// It is represented as a `ProxyReference`, which provides pre-resolved proxy objects
    /// for better ergonomics in action handlers.
    ///
    /// For backward compatibility with single-object commands. When `directObjects` contains
    /// multiple items, this returns the first one, or nil if the array is empty.
    public var directObject: ProxyReference? {
        directObjects.first
    }

    /// All direct objects for this command. For single-object commands, this contains
    /// one element. For ALL commands like "take all", this contains all applicable objects.
    public let directObjects: [ProxyReference]

    /// Adjectives or other descriptive words associated with the direct object(s) as they
    /// appeared in the player's input (e.g., ["brass", "small"] for "take small brass lantern").
    /// These are used by the parser during object resolution and can be useful for context
    /// in action handlers.
    public let directObjectModifiers: [String]

    /// The secondary entity involved in the command, often connected to the direct object
    /// by a preposition, if any.
    /// For example, in "put lantern in case", the case is the indirect object.
    /// Represented as a `ProxyReference`.
    ///
    /// For backward compatibility with single-object commands. When `indirectObjects` contains
    /// multiple items, this returns the first one, or nil if the array is empty.
    public var indirectObject: ProxyReference? {
        indirectObjects.first
    }

    /// All indirect objects for this command. For single-object commands, this contains
    /// one element. For ALL commands, this may contain multiple objects.
    public let indirectObjects: [ProxyReference]

    /// Adjectives or other descriptive words associated with the indirect object(s) from the
    /// player's input (e.g., ["wooden"] for "put key in wooden box").
    public let indirectObjectModifiers: [String]

    /// Indicates whether this command was parsed with ALL (e.g., "take all").
    /// This helps action handlers determine whether to process multiple objects
    /// and provide appropriate feedback.
    public let isAllCommand: Bool

    /// The preposition (e.g., "in", "on", "with") that links the verb or direct object
    /// to the `indirectObject`, if one was used and identified by the parser.
    /// For example, "in" for "put lantern IN case".
    public let preposition: Preposition?

    /// The specific `Direction` (e.g., `.north`, `.up`) associated with the command,
    /// typically for movement commands like "go north" or shorthand like "north".
    public var direction: Direction?

    /// The original, unmodified input string exactly as the player typed it.
    /// This is useful for debugging, logging, or displaying exact player input in messages.
    public let rawInput: String?

    /// The primary `Verb` identified by the parser as the core action the player
    /// intends to perform (e.g., `.take`, `.look`, `.go`).
    public let verb: Verb

    // --- Initialization ---

    /// Initializes a new `Command` structure with all its components.
    ///
    /// This initializer is primarily used by `Parser` implementations when they successfully
    /// interpret a player's input. Game developers typically don't create `Command` objects directly.
    ///
    /// - Parameters:
    ///   - verb: The `Verb` of the main action.
    ///   - directObject: The resolved `ProxyReference` for the direct object, if any.
    ///   - directObjectModifiers: Modifiers for the direct object.
    ///   - indirectObject: The resolved `ProxyReference` for the indirect object, if any.
    ///   - indirectObjectModifiers: Modifiers for the indirect object.
    ///   - preposition: The preposition used, if any.
    ///   - direction: The `Direction` specified, if any.
    ///   - rawInput: The original player input string.
    public init(
        verb: Verb,
        directObject: ProxyReference? = nil,
        directObjectModifiers: [String] = [],
        indirectObject: ProxyReference? = nil,
        indirectObjectModifiers: [String] = [],
        preposition: Preposition? = nil,
        direction: Direction? = nil,
        rawInput: String? = nil
    ) {
        self.verb = verb
        self.directObjects = directObject.map { [$0] } ?? []
        self.directObjectModifiers = directObjectModifiers
        self.indirectObjects = indirectObject.map { [$0] } ?? []
        self.indirectObjectModifiers = indirectObjectModifiers
        self.isAllCommand = false
        self.preposition = preposition
        self.direction = direction
        self.rawInput = rawInput
    }

    /// Initializes a new `Command` structure supporting multiple objects.
    ///
    /// This initializer is used when parsing ALL commands or other multi-object scenarios.
    ///
    /// - Parameters:
    ///   - verb: The `Verb` of the main action.
    ///   - directObjects: Array of resolved `ProxyReference`s for direct objects.
    ///   - directObjectModifiers: Modifiers for the direct objects.
    ///   - indirectObjects: Array of resolved `ProxyReference`s for indirect objects.
    ///   - indirectObjectModifiers: Modifiers for the indirect objects.
    ///   - isAllCommand: Whether this command was parsed with ALL.
    ///   - preposition: The preposition used, if any.
    ///   - direction: The `Direction` specified, if any.
    ///   - rawInput: The original player input string.
    public init(
        verb: Verb,
        directObjects: [ProxyReference] = [],
        directObjectModifiers: [String] = [],
        indirectObjects: [ProxyReference] = [],
        indirectObjectModifiers: [String] = [],
        isAllCommand: Bool = false,
        preposition: Preposition? = nil,
        direction: Direction? = nil,
        rawInput: String? = nil
    ) {
        self.verb = verb
        self.directObjects = directObjects
        self.directObjectModifiers = directObjectModifiers
        self.indirectObjects = indirectObjects
        self.indirectObjectModifiers = indirectObjectModifiers
        self.isAllCommand = isAllCommand
        self.preposition = preposition
        self.direction = direction
        self.rawInput = rawInput
    }
}

// MARK: - Command helpers

extension Command {
    /// Returns the gerund form of the command's verb.
    ///
    /// The gerund is the -ing form of the verb, useful for creating progressive
    /// or descriptive text about the action being performed.
    ///
    /// For example:
    /// - "take" becomes "taking"
    /// - "examine" becomes "examining"
    /// - "go" becomes "going"
    ///
    /// - Returns: A string containing the gerund form of the verb.
    public var gerund: String {
        verb.gerund
    }

    /// Returns the past participle form of the command's verb.
    ///
    /// The past participle is useful for creating narrative text about actions
    /// that have been completed or attempted.
    ///
    /// For example:
    /// - "take" becomes "taken"
    /// - "examine" becomes "examined"
    /// - "go" becomes "gone"
    ///
    /// - Returns: A string containing the past participle form of the verb.
    public var pastParticiple: String {
        verb.pastParticiple
    }

    /// Returns `true` if the command's verb includes one or more of the specified intents.
    ///
    /// This method checks whether the command's verb supports any particular intents, such as
    /// `.take`, `.examine`, or `.move`. This is useful for determining what kind of action the
    /// player is trying to perform.
    ///
    /// - Parameter intents: One or more `Intent`s to check for.
    /// - Returns: `true` if the verb includes the intent, `false` otherwise.
    public func hasIntent(_ intents: Intent...) -> Bool {
        verb.intents.intersects(intents)
    }

    /// Returns all `Intent`s associated with the command's verb.
    ///
    /// This property exposes the full set of intents that the verb represents, such as `.take`,
    /// `.examine`, or `.move`. Intents provide a way to categorize and understand what kind of
    /// high-level action the player intends to perform.
    /// - Returns: An array of `Intent` values linked to the verb.
    public var intents: [Intent] {
        verb.intents
    }

    /// Returns `true` if the command's verb matches any of the specified intents.
    ///
    /// This method checks whether the command's verb supports any of the provided intents.
    /// If the `others` array is empty, this method returns `true` (matches all).
    /// Otherwise, it returns `true` if there's any intersection between the verb's intents
    /// and the provided intents.
    ///
    /// - Parameter intents: An array of `Intent`s to check against the verb's intents.
    /// - Returns: `true` if the verb matches any of the specified intents or if `others`
    ///            is empty, `false` otherwise.
    public func matchesIntents(_ intents: [Intent]) -> Bool {
        if intents.isEmpty {
            true
        } else {
            verb.intents.intersects(intents)
        }
    }

    /// A textual representation of the verb phrase including any preposition.
    ///
    /// This computed property returns a string that represents the complete verb phrase
    /// for the command. If the command includes a preposition (e.g., "in", "on", "with"),
    /// it combines the verb with the preposition. Otherwise, it returns just the verb's
    /// description.
    ///
    /// For example:
    /// - "take" (verb only)
    /// - "put in" (verb + preposition)
    /// - "look at" (verb + preposition)
    ///
    /// - Returns: A string containing the verb phrase, optionally including the preposition.
    public var verbPhrase: String {
        if let preposition {
            switch preposition {
            case .with:
                verb.description
            default:
                "\(verb) \(preposition.rawValue)"
            }
        } else {
            verb.description
        }
    }
}
