/// Enumerates errors that can occur during the command parsing phase.
public enum ParseError: Error, Equatable, Sendable {
    /// Input was empty or contained only noise words.
    case emptyInput

    /// The first significant word was not recognized as a known verb.
    case unknownVerb(String)

    /// A noun word used did not correspond to any known item ID.
    case unknownNoun(String)

    /// A noun word referred to an item that exists but is not currently in scope (visible/accessible).
    case itemNotInScope(noun: String)

    /// A noun and its modifiers (adjectives) did not match any item in scope.
    case modifierMismatch(noun: String, modifiers: [String])

    /// The parser encountered multiple possible interpretations (e.g., "take lamp" when multiple lamps are present).
    /// The associated String often contains a question for the player (e.g., "Which lamp do you mean?").
    case ambiguity(String)

    /// The input structure didn't match expected grammar (e.g., missing object, wrong preposition).
    case badGrammar(String)

    /// A pronoun (like "it") was used, but the parser doesn't know what it refers to.
    case pronounNotSet(pronoun: String)

    /// A pronoun (like "it") was used, but the item it refers to is not currently in scope.
    case pronounRefersToOutOfScopeItem(pronoun: String)

    /// A pronoun (like "it") could refer to multiple items ambiguously.
    case ambiguousPronounReference(String) // Similar to .ambiguity, but specifically for pronouns

    /// An unexpected internal error occurred during parsing.
    case internalError(String)
}
