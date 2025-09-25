/// Enumerates errors that can occur during the command parsing phase.
public enum ParseError: Error, Equatable, Sendable {
    /// "ALL" command but player isn't carrying anything.
    case allCommandNothingCarrying

    /// "ALL" command but there's nothing here.
    case allCommandNothingHere

    /// "ALL" command found nothing to take.
    case allCommandNothingToTake

    /// The parser encountered multiple possible interpretations (e.g., "take lamp" when
    /// multiple lamps are present). The associated String often contains a question for
    /// the player (e.g., "Which lamp do you mean?").
    case ambiguity(String)

    /// Multiple items match a noun phrase, creating ambiguity.
    case ambiguousObjectReference(noun: String, options: [String])
    /// Multiple entities match a reference, creating ambiguity.
    case ambiguousReference(options: [String])

    /// A word could refer to multiple verbs, creating ambiguity.
    case ambiguousVerb(phrase: String, verbs: [String])

    /// The input structure didn't match expected grammar (e.g., missing object, wrong preposition).
    case badGrammar(String)

    /// Input was empty or contained only noise words.
    case emptyInput

    /// Expected a direction word but found something else.
    case expectedDirection

    /// Expected a specific particle after a verb but found something else.
    case expectedParticleAfterVerb(expectedParticle: String, verb: Verb, found: Verb)

    /// Expected a specific particle but reached end of input.
    case expectedParticleButReachedEnd(expectedParticle: String)

    /// An unexpected internal error occurred during parsing.
    case internalError(String)

    /// A noun word referred to an item that exists but is not currently in scope (visible/accessible).
    case itemNotInScope(noun: String)

    /// A noun and its modifiers (adjectives) did not match any item in scope.
    case modifierMismatch(noun: String, modifiers: [String])

    /// Player reference cannot be modified by adjectives.
    case playerReferenceCannotBeModified(reference: String, modifiers: [String])

    /// Wrong preposition used with a verb.
    case prepositionMismatch(verb: String, expected: String, found: String)

    /// Pronouns cannot typically be modified by adjectives.
    case pronounCannotBeModified(pronoun: String)

    /// A pronoun (like "it") was used, but the parser doesn't know what it refers to.
    case pronounNotSet(pronoun: String)

    /// A pronoun (like "it") was used, but the item it refers to is not currently in scope.
    case pronounRefersToOutOfScopeItem(pronoun: String)

    /// Syntax rule requires a specific verb that wasn't matched.
    case specificVerbRequired(requiredVerb: String)

    /// Found unexpected words after a complete command.
    case unexpectedWordsAfterCommand(unexpectedWords: String)

    /// The verb doesn't support multiple indirect objects.
    case verbDoesNotSupportMultipleIndirectObjects(Verb)

    /// The verb doesn't support multiple direct objects.
    case verbDoesNotSupportMultipleObjects(Verb)

    /// Parser understood the verb but all syntax rules failed to match.
    case verbSyntaxRulesAllFailed(String)

    /// Parser understood the verb but couldn't parse the additional syntax.
    case verbUnderstoodButSyntaxFailed(String)

    /// The first significant word was not recognized as a known verb.
    case verbUnknown(String)

}
