/// Enumerates errors that can occur during the command parsing phase.
public enum ParseError: Error, Equatable, Sendable {
    /// Input was empty or contained only noise words.
    case emptyInput

    /// The first significant word was not recognized as a known verb.
    case verbUnknown(String)

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

    /// An unexpected internal error occurred during parsing.
    case internalError(String)

    // MARK: - Verb Understanding Errors

    /// Parser understood the verb but couldn't parse the additional syntax.
    case verbUnderstoodButSyntaxFailed(String)

    /// A word could refer to multiple verbs, creating ambiguity.
    case ambiguousVerb(phrase: String, verbs: [String])

    /// Parser understood the verb but all syntax rules failed to match.
    case verbSyntaxRulesAllFailed(String)

    // MARK: - Specific Syntax Errors

    /// Expected a specific particle but reached end of input.
    case expectedParticleButReachedEnd(expectedParticle: String)

    /// Syntax rule requires a specific verb that wasn't matched.
    case specificVerbRequired(requiredVerb: String)

    /// Expected a direction word but found something else.
    case expectedDirection

    /// Expected a specific particle after a verb but found something else.
    case expectedParticleAfterVerb(expectedParticle: String, verb: Verb, found: Verb)

    /// Found unexpected words after a complete command.
    case unexpectedWordsAfterCommand(unexpectedWords: String)

    /// The verb doesn't support multiple direct objects.
    case verbDoesNotSupportMultipleObjects(Verb)

    /// The verb doesn't support multiple indirect objects.
    case verbDoesNotSupportMultipleIndirectObjects(Verb)

    /// Wrong preposition used with a verb.
    case prepositionMismatch(verb: String, expected: String, found: String)

    // MARK: - Object Resolution Errors

    /// Player reference cannot be modified by adjectives.
    case playerReferenceCannotBeModified(reference: String, modifiers: [String])

    /// Pronouns cannot typically be modified by adjectives.
    case pronounCannotBeModified(pronoun: String)

    /// Multiple items match a noun phrase, creating ambiguity.
    case ambiguousObjectReference(noun: String, options: [String])

    /// Multiple entities match a reference, creating ambiguity.
    case ambiguousReference(options: [String])

    // MARK: - ALL Command Errors

    /// "ALL" command found nothing to take.
    case allCommandNothingToTake

    /// "ALL" command but player isn't carrying anything.
    case allCommandNothingCarrying

    /// "ALL" command but there's nothing here.
    case allCommandNothingHere
}
