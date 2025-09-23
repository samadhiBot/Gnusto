import Foundation
import Logging

/// A standard, ZIL-inspired implementation of the `Parser` protocol, designed to
/// interpret player input in a manner reminiscent of classic text-adventure games.
///
/// The `StandardParser` takes a raw input string from the player and attempts to
/// transform it into a structured `Command` object that the `GameEngine` can execute.
/// If it cannot understand the input, it returns a descriptive `ParseError`.
///
/// ### Parsing Process Overview:
///
/// 1.  **Tokenization & Normalization:** The input string is broken into individual words (tokens),
///     and typically converted to lowercase for case-insensitive matching.
/// 2.  **Noise Word Removal:** Common, grammatically necessary but semantically unimportant
///     words (e.g., "the", "a", "to") are filtered out. These are defined in the
///     game's `Vocabulary`.
/// 3.  **Adverb Removal:** Words that are adverbs (e.g., "quickly", "slowly") are filtered out.
///     These are defined in the game's `Vocabulary`.
/// 4.  **Verb Identification:** The parser identifies the primary action word (verb).
///     It can recognize multi-word verb synonyms (e.g., "pick up" for "take") if
///     they are defined in the `Vocabulary`.
/// 5.  **Syntax Rule Matching:** The sequence of significant tokens is compared against
///     the `SyntaxRule`s associated with the identified verb (also from `Vocabulary`).
///     Each rule defines a valid grammatical pattern (e.g., VERB-DIRECT_OBJECT,
///     VERB-DIRECT_OBJECT-PREPOSITION-INDIRECT_OBJECT).
/// 6.  **Object Resolution:** Noun phrases are identified as potential direct and indirect
///     objects. This involves:
///     *   Looking up nouns in the `Vocabulary`.
///     *   Considering their context within the `GameState` (e.g., what items are
///         currently visible or held by the player, what pronouns like "it" or "them"
///         currently refer to).
///     *   Applying `ObjectCondition`s specified by the matched `SyntaxRule` (e.g.,
///         an object might need to be `.held` or be a `.container`).
///     *   Attempting to resolve ambiguities (e.g., if "take lamp" is typed and multiple
///         lamps are present).
///
/// ### For Game Developers:
///
/// Game developers typically do not need to call `StandardParser` methods directly.
/// An instance of a `Parser` (like `StandardParser`) is provided to the `GameEngine`
/// during initialization, and the engine uses it internally to process player input.
///
/// To influence parsing behavior, game developers should focus on:
/// *   **Defining a comprehensive `Vocabulary`:** This includes all recognizable verbs
///     (with their synonyms and `SyntaxRule`s), nouns (items, characters, with their
///     adjectives and properties), prepositions, directions, and noise words.
/// *   **Crafting clear `SyntaxRule`s:** Ensure that the grammatical patterns defined for
///     each verb accurately reflect how players are expected to phrase commands.
/// *   **Setting appropriate `ObjectCondition`s:** Use these within `SyntaxRule`s to help
///     the parser disambiguate objects and ensure actions are contextually valid.
/// Result of attempting to match a syntax rule against input tokens.
public struct StandardParser: Parser {
    /// Initializes a new `StandardParser` instance.
    public init() {}

    /// A logger used for internal parser messages, primarily for debugging.
    let logger = Logger(label: "com.samadhibot.Gnusto.StandardParser")

    /// Parses a raw input string from the player into a structured `Command` or a `ParseError`.
    ///
    /// This method implements the core parsing logic described in the `StandardParser` overview.
    /// It attempts to understand the player's intent by matching their input against the
    /// game's vocabulary and syntax rules. It parses player input into a structured `Command`
    /// using a two-phase approach:
    ///
    /// **Phase 1: Verb Identification**
    /// - Uses longest-match strategy to identify multi-word verbs (e.g., "pick up", "turn on")
    /// - Handles verb ambiguity by collecting all possible matches
    /// - Prioritizes longer verb phrases over shorter ones for specificity
    ///
    /// **Phase 2: Syntax Rule Matching**
    /// - Retrieves syntax rules from action handlers for identified verbs
    /// - Attempts to match input structure against each applicable rule
    /// - Returns the first successful match or the best error encountered
    ///
    /// This approach allows sophisticated command parsing while maintaining
    /// compatibility with traditional IF parsing expectations.
    ///
    /// - Parameters:
    ///   - input: The raw string as entered by the player (e.g., "take brass lantern").
    ///   - vocabulary: The `Vocabulary` for the current game, containing all known words
    ///                 (verbs, nouns, adjectives, prepositions, noise words, directions)
    ///                 and verb syntax rules. This is the primary source of grammatical
    ///                 and lexical knowledge for the parser.
    ///   - engine: The game engine providing essential context for resolving
    ///                object references (e.g., player inventory, item locations, current
    ///                pronoun meanings, items visible or accessible to the player).
    /// - Returns: A `Result` which is either:
    ///   - `.success(Command)`: If parsing was successful. The returned `Command` object
    ///     encapsulates the player's understood intent, including the identified `Verb`,
    ///     resolved `EntityReference`s for direct and/or indirect objects (if any),
    ///     any recognized modifiers (adjectives), the preposition used (if any),
    ///     and the direction (for movement commands). This `Command` is then ready for
    ///     the `GameEngine` to execute.
    ///   - `.failure(ParseError)`: If parsing failed at any stage. The `ParseError` enum
    ///     provides a specific reason for the failure, such as `.verbUnknown` if the main
    ///     action word wasn't recognized, `.itemNotInScope` if a mentioned object isn't
    ///     accessible, `.badGrammar` if the sentence structure didn't match any known rules,
    ///     or `.ambiguity` if the input could be interpreted in multiple ways that the
    ///     parser couldn't resolve on its own.
    public func parse(
        input: String,
        vocabulary: Vocabulary,
        engine: GameEngine
    ) async throws -> Result<Command, ParseError> {
        // 1. Tokenize and Normalize Input
        let tokens = tokenize(input: input)

        // 2. Remove Noise Words
        let significantTokens = removeNoise(
            tokens: tokens,
            noiseWords: vocabulary.noiseWords
        )

        // 3. Remove Adverbs (allow but ignore them)
        let filteredTokens = removeAdverbs(
            tokens: significantTokens,
            adverbs: vocabulary.adverbs
        )

        // 4. Handle Single-Word Direction Command (e.g., "NORTH", "N")
        if filteredTokens.count == 1,
            let directionWord = filteredTokens.first,
            let direction = vocabulary.directions[directionWord]
        {
            return .success(
                Command(verb: .go, direction: direction, rawInput: input)
            )
        }

        // 5. Handle Empty Input (after noise removal and direction check)
        guard filteredTokens.isNotEmpty else {
            return .failure(.emptyInput)
        }

        // 6. Identify Verbs (handling multi-word verb phrases like "pick up", "turn on")
        var candidateVerbs: Set<Verb> = []
        var verbPhraseLength = 0
        var verbPhraseStartIndex = 0

        // Find the longest verb phrase starting from the earliest position in the input.
        // This handles multi-word verbs like "pick up" or "turn on" by preferring
        // longer matches over shorter ones (e.g., "turn on" over just "turn").
        for startIndex in 0..<filteredTokens.count {
            var longestMatchLength = 0
            var potentialMatchVerbs: Set<Verb> = []  // Track verbs for the current longest match length

            // Check token sequences starting from this position, longest first
            for length in (1...min(4, filteredTokens.count - startIndex)).reversed() {
                let subSequence = filteredTokens[startIndex..<(startIndex + length)]
                let verbPhrase = subSequence.joined(separator: " ")

                // Look up the verb associated with this phrase
                if let foundVerb = vocabulary.verbLookup[verbPhrase] {
                    // Found a match
                    if length > longestMatchLength {
                        // New longest length found, clear previous shorter matches and start fresh
                        longestMatchLength = length
                        potentialMatchVerbs = [foundVerb]  // Start with this verb
                        verbPhraseLength = length  // Store the length of this match
                        verbPhraseStartIndex = startIndex  // Store the start index
                    } else if length == longestMatchLength {
                        // Same length as the current longest, add this verb to the set
                        potentialMatchVerbs.insert(foundVerb)
                    }
                    // If length < longestMatchLength, ignore (we only want the longest matches)
                }
            }

            // If we found any matches of the longest possible length starting at this position, use them and stop searching
            if longestMatchLength > 0 {
                candidateVerbs = potentialMatchVerbs  // Assign the set of verbs found at the longest length
                break  // Found the first (and longest) verb match group, stop outer loop
            }
        }

        // Ensure we found at least one recognized verb
        guard candidateVerbs.isNotEmpty else {
            // No verb phrase was recognized in the input
            return .failure(
                .verbUnknown(
                    filteredTokens.first ?? filteredTokens.joined(separator: " ")
                )
            )
        }

        // Collect all syntax rules for the recognized verbs
        var applicableSyntaxRules: [(verb: Verb, rule: SyntaxRule)] = []
        var verbsWithSyntaxRules: Set<Verb> = []

        // Sort verbs for deterministic behavior when multiple verbs are found
        let sortedCandidateVerbs = candidateVerbs.sorted { $0.rawValue < $1.rawValue }

        for verb in sortedCandidateVerbs {
            if let syntaxRules = vocabulary.verbToSyntax[verb] {
                if syntaxRules.isNotEmpty {
                    verbsWithSyntaxRules.insert(verb)
                    for rule in syntaxRules {
                        applicableSyntaxRules.append((verb: verb, rule: rule))
                    }
                }
            }
        }

        // Handle cases where verbs were recognized but have no syntax rules for additional tokens
        if applicableSyntaxRules.isEmpty && filteredTokens.count > verbPhraseLength {
            // The verb is known but can't handle the extra words in the command
            let firstRecognizedVerb = sortedCandidateVerbs[0]
            return .failure(
                .verbUnderstoodButSyntaxFailed(firstRecognizedVerb.rawValue)
            )
        }

        // 7. Match Tokens Against All Potential Syntax Rules
        var successfulParse: Command? = nil
        var bestError: ParseError? = nil

        // Pre-calculate any preposition in the input once, since it's the same for all rules
        let inputPreposition = findInputPreposition(
            tokens: filteredTokens,
            startIndex: verbPhraseStartIndex + verbPhraseLength,
            vocabulary: vocabulary
        )

        // 7. Sort syntax rules by specificity score before matching
        // This ensures more specific rules (like .match(.verb, .on, .directObject))
        // are tried before generic rules (like .match(.knock))
        var scoredRules: [(verb: Verb, rule: SyntaxRule, score: Int)] = []
        for (verb, rule) in applicableSyntaxRules {
            // Create temporary commands for scoring - use dummy proxy reference for objects
            let dummyProxy = ProxyReference.universal(.ground)
            let preposition = inputPreposition.flatMap(Preposition.init)
            let tempCommand = Command(
                verb: verb,
                directObjects: filteredTokens.count > verbPhraseLength ? [dummyProxy] : [],
                indirectObjects: preposition != nil ? [dummyProxy] : [],
                preposition: preposition,
                rawInput: input
            )

            // For .verb tokens, we need to pass the synonyms that match this verb
            // The verb is already validated to be in the vocabulary, so we can use it directly
            let synonymsForThisVerb = rule.pattern.contains(.verb) ? [verb] : []

            let score = await engine.scoreSyntaxRuleForCommand(
                syntaxRule: rule,
                command: tempCommand,
                synonyms: synonymsForThisVerb
            )

            scoredRules.append((verb: verb, rule: rule, score: score))
        }

        // Sort by score (higher scores first)
        let sortedSyntaxRules = scoredRules.sorted { $0.score > $1.score }.map {
            (verb: $0.verb, rule: $0.rule)
        }

        // 8. Match Syntax Rules - Try each rule for each verb until one succeeds
        // Rules are now sorted by specificity, so more specific patterns are tried first
        for (verb, rule) in sortedSyntaxRules {
            let matchResult = await matchRule(
                rule: rule,
                tokens: filteredTokens,
                verbStartIndex: verbPhraseStartIndex,
                verbTokenCount: verbPhraseLength,
                verb: verb,
                vocabulary: vocabulary,
                engine: engine,
                originalInput: input
            )

            switch matchResult {
            case .success(let command):
                // Syntax rule matched - now validate preposition compatibility
                if let requiredPreposition = rule.expectedPreposition {
                    if let inputPreposition {
                        if requiredPreposition == inputPreposition {
                            // Perfect match: required preposition matches input
                            successfulParse = command
                            bestError = nil
                            break
                        } else {
                            // Preposition mismatch - record error and continue
                            let mismatchError = ParseError.prepositionMismatch(
                                verb: verb.rawValue,
                                expected: requiredPreposition,
                                found: inputPreposition
                            )
                            if bestError == nil
                                || shouldReplaceError(existing: bestError!, new: mismatchError)
                            {
                                bestError = mismatchError
                            }
                            continue
                        }
                    } else {
                        // Rule requires preposition but input has none
                        // Allow action handler to provide specific error message
                        if successfulParse == nil {
                            successfulParse = command
                        }
                        continue
                    }
                } else {
                    // Rule accepts any preposition or no preposition
                    if successfulParse == nil {
                        successfulParse = command
                    }
                    continue
                }
            case .failure(let currentError):
                // Rule failed to match - record error if it's better than what we have
                if shouldReplaceError(existing: bestError, new: currentError) {
                    bestError = currentError
                }
            case .notApplicable:
                // Rule doesn't apply - just continue to next rule without recording error
                continue
            }
        }

        // 8. Return Result
        if let successfulParse {
            return .success(successfulParse)
        } else if let bestError {  // Otherwise return best error found
            return .failure(bestError)
        } else {
            // Handle simple verb-only commands or parsing failures
            if applicableSyntaxRules.isEmpty && filteredTokens.count == verbPhraseLength {
                // Input was just a verb phrase with no additional tokens

                // Check for ambiguous verb phrases
                if sortedCandidateVerbs.count > 1 {
                    let verbList = sortedCandidateVerbs.map { $0.rawValue }
                    return .failure(
                        .ambiguousVerb(
                            phrase: filteredTokens.joined(separator: " "),
                            verbs: verbList
                        )
                    )
                }

                // Single verb with no syntax rules - allow it as a simple command
                let recognizedVerb = sortedCandidateVerbs[0]
                let command = Command(verb: recognizedVerb, rawInput: input)
                return .success(command)
            } else {
                // Syntax rules existed but all failed to match

                // Check for ambiguous verbs that all failed
                if sortedCandidateVerbs.count > 1 {
                    let verbList = sortedCandidateVerbs.map { $0.rawValue }
                    return .failure(
                        .ambiguousVerb(
                            phrase: filteredTokens.first ?? "",
                            verbs: verbList
                        )
                    )
                }

                // Single verb failed parsing - provide specific error
                let recognizedVerb = sortedCandidateVerbs[0]
                return .failure(
                    .verbSyntaxRulesAllFailed(recognizedVerb.rawValue)
                )
            }
        }
    }

    /// Helper to find the preposition in the input tokens *after* the verb phrase.
    private func findInputPreposition(
        tokens: [String],
        startIndex: Int,
        vocabulary: Vocabulary
    ) -> String? {
        for i in startIndex..<tokens.count {
            let currentToken = tokens[i]
            if vocabulary.prepositions.contains(currentToken) {
                // Found the first preposition after the verb phrase.
                return currentToken
            }
            // Removed the early break: Continue searching even if we encounter nouns/adjectives,
            // as the preposition might appear after the direct object phrase.
        }
        // No preposition found in the remaining tokens.
        return nil
    }

    /// Determines if a new parsing error should replace the existing best error.
    /// Prioritizes resolution errors > ambiguity > grammar > other.
    private func isResolutionError(_ error: ParseError) -> Bool {
        switch error {
        case .itemNotInScope, .modifierMismatch, .pronounNotSet, .pronounRefersToOutOfScopeItem:
            true
        default:
            false
        }
    }

    private func isAmbiguityError(_ error: ParseError) -> Bool {
        switch error {
        case .ambiguity, .ambiguousObjectReference:
            true
        default:
            false
        }
    }

    private func isGrammarError(_ error: ParseError) -> Bool {
        switch error {
        case .badGrammar: true
        default: false
        }
    }

    private func errorPriority(_ error: ParseError) -> Int {
        if isResolutionError(error) { return 4 }
        if isAmbiguityError(error) { return 3 }
        if isGrammarError(error) { return 2 }
        if case .verbUnknown = error { return 1 }
        if case .emptyInput = error { return 0 }
        return 0  // Default lowest priority
    }

    private func shouldReplaceError(existing: ParseError?, new: ParseError) -> Bool {
        guard let existing else {
            return true
        }
        return errorPriority(new) > errorPriority(existing)
    }

    /// Splits the input string into lowercase tokens.
    func tokenize(input: String) -> [String] {
        // Simple whitespace and punctuation separation, converts to lowercase.
        // ZIL tokenization was more complex (e.g., dictionary separators).

        // Allow alphanumeric characters, spaces, commas (for conjunctions), and hyphens (for compound adjectives)
        let allowedChars = CharacterSet.alphanumerics.union(.whitespaces).union(
            CharacterSet(charactersIn: ",-")
        )
        let sanitizedInput = String(input.unicodeScalars.filter { allowedChars.contains($0) })

        // Split by whitespace and also treat commas as separate tokens
        var tokens = [String]()
        let words = sanitizedInput.lowercased()
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { $0.isNotEmpty }

        for word in words {
            if word.contains(",") {
                // Split words containing commas
                let parts = word.components(separatedBy: ",")
                for (index, part) in parts.enumerated() {
                    if part.isNotEmpty {
                        tokens.append(part)
                    }
                    // Add comma as separate token (except after the last part)
                    if index < parts.count - 1 {
                        tokens.append(",")
                    }
                }
            } else {
                tokens.append(word)
            }
        }

        return tokens
    }

    /// Filters out noise words from a token list.
    func removeNoise(
        tokens: [String],
        noiseWords: Set<String>
    ) -> [String] {
        tokens.filter { !noiseWords.contains($0) }
    }

    /// Filters out adverbs from a token list.
    func removeAdverbs(
        tokens: [String],
        adverbs: Set<String>
    ) -> [String] {
        tokens.filter { !adverbs.contains($0) }
    }

    // MARK: - Syntax Matching Logic

    /// Attempts to match a sequence of tokens against a specific SyntaxRule.
    private func matchRule(
        rule: SyntaxRule,
        tokens: [String],
        verbStartIndex: Int,
        verbTokenCount: Int,
        verb: Verb,
        vocabulary: Vocabulary,
        engine: GameEngine,
        originalInput: String
    ) async -> RuleMatchResult {
        var tokenCursor = verbStartIndex + verbTokenCount
        var directObjectPhraseTokens = [String]()
        var indirectObjectPhraseTokens = [String]()
        var matchedPreposition: Preposition? = nil
        var matchedDirection: Direction? = nil

        for patternIndex in 1..<rule.pattern.count {
            let tokenType = rule.pattern[patternIndex]

            // Check if we've run out of tokens
            guard tokenCursor < tokens.count else {
                // Different handling based on token type
                switch tokenType {
                case .particle:
                    // Particles are structural and required - if missing, this rule doesn't apply
                    return .notApplicable
                case .directObject, .directObjects, .indirectObject, .indirectObjects, .direction:
                    // Objects and directions can be missing - let action handlers provide better error messages
                    break
                case .verb:
                    // This shouldn't happen since verb is at index 0
                    continue
                case .specificVerb:
                    // This shouldn't happen since verb is at index 0
                    continue
                }
                break
            }

            switch tokenType {
            case .verb:
                continue

            case .specificVerb(let requiredVerb):
                // Verify that the command uses the specific verb required by this rule
                guard verb == requiredVerb else {
                    return .notApplicable
                }
                continue

            case .directObject, .directObjects:
                let phraseEndIndex = findEndOfNounPhrase(
                    startIndex: tokenCursor,
                    tokens: tokens,
                    pattern: rule.pattern,
                    patternIndex: patternIndex,
                    vocabulary: vocabulary
                )
                if phraseEndIndex > tokenCursor {
                    directObjectPhraseTokens = Array(tokens[tokenCursor..<phraseEndIndex])
                    tokenCursor = phraseEndIndex
                }
            // If no direct object found, leave directObjectPhraseTokens empty
            // Action handlers will provide appropriate error messages

            case .indirectObject, .indirectObjects:
                // Special case: for the specific pattern .indirectObject followed by .directObjects
                // (like "give wizard scroll"), we need to consume only one token for the indirect object
                let isSpecificPattern =
                    tokenType == .indirectObject
                    && patternIndex + 1 < rule.pattern.count
                    && rule.pattern[patternIndex + 1] == .directObjects

                if isSpecificPattern {
                    // For "give wizard scroll" pattern, consume just one token for the indirect object
                    if tokenCursor < tokens.count {
                        indirectObjectPhraseTokens = [tokens[tokenCursor]]
                        tokenCursor += 1
                    }
                } else {
                    // Use the normal approach for all other patterns
                    let phraseEndIndex = findEndOfNounPhrase(
                        startIndex: tokenCursor,
                        tokens: tokens,
                        pattern: rule.pattern,
                        patternIndex: patternIndex,
                        vocabulary: vocabulary
                    )
                    if phraseEndIndex > tokenCursor {
                        indirectObjectPhraseTokens = Array(tokens[tokenCursor..<phraseEndIndex])
                        tokenCursor = phraseEndIndex
                    }
                }
            // If no indirect object found, leave indirectObjectPhraseTokens empty
            // Action handlers will provide appropriate error messages

            case .direction:
                let currentToken = tokens[tokenCursor]
                if let direction = vocabulary.directions[currentToken] {
                    matchedDirection = direction
                    tokenCursor += 1
                } else {
                    return .failure(.expectedDirection)
                }

            case .particle(let expectedParticle):
                let currentToken = tokens[tokenCursor]
                guard currentToken == expectedParticle else {
                    // Particle mismatch means this rule doesn't apply, not a parsing error
                    return .notApplicable
                }
                matchedPreposition = Preposition(stringLiteral: currentToken)
                tokenCursor += 1
            }
        }

        if tokenCursor < tokens.count {
            return .failure(
                .unexpectedWordsAfterCommand(
                    unexpectedWords: Array(tokens[tokenCursor...]).joined(separator: " ")
                )
            )
        }

        // Parse multiple noun phrases connected by conjunctions
        let directObjectPhrases = parseConjunctedNounPhrases(
            from: directObjectPhraseTokens,
            vocabulary: vocabulary
        )
        let indirectObjectPhrases = parseConjunctedNounPhrases(
            from: indirectObjectPhraseTokens,
            vocabulary: vocabulary
        )

        // Handle direct object resolution (including ALL and conjunctions)
        var resolvedDirectObjects: [ProxyReference] = []
        var isAllCommandDO = false
        var isMultipleObjectsDO = false

        if rule.pattern.contains(.directObject) || rule.pattern.contains(.directObjects) {
            let allowsMultiple = rule.pattern.contains(.directObjects)
            // If no direct object phrases were parsed, leave resolvedDirectObjects empty
            // The action handler will provide appropriate error messages
            if directObjectPhrases.isNotEmpty {
                // Check if we have multiple phrases (conjunctions) and the rule allows multiple objects
                if directObjectPhrases.count > 1 && allowsMultiple {
                    isMultipleObjectsDO = true
                } else if directObjectPhrases.count > 1 {
                    return .failure(
                        .verbDoesNotSupportMultipleObjects(verb)
                    )
                }

                // Process each noun phrase
                for (noun, modifiers) in directObjectPhrases {
                    let lowercasedNoun = noun.lowercased()

                    // Check if this is an ALL command
                    if vocabulary.specialKeywords.contains(lowercasedNoun) {
                        if allowsMultiple {
                            isAllCommandDO = true
                            let allObjectsResult = await resolveAllObjects(
                                verb: verb,
                                modifiers: modifiers,
                                vocabulary: vocabulary,
                                engine: engine
                            )
                            switch allObjectsResult {
                            case .success(let objects):
                                resolvedDirectObjects.append(contentsOf: objects)
                            case .failure(let error):
                                return .failure(error)
                            }
                        } else {
                            // Command doesn't support multiple objects but user tried "all"
                            return .failure(
                                .verbDoesNotSupportMultipleObjects(verb)
                            )
                        }
                    } else if vocabulary.pronouns.contains(lowercasedNoun)
                        && lowercasedNoun == "them"
                    {
                        // Handle plural pronoun that might refer to multiple objects
                        guard modifiers.isEmpty else {
                            return .failure(
                                .pronounCannotBeModified(pronoun: lowercasedNoun)
                            )
                        }

                        guard
                            let referredEntityRefs = await engine.gameState.pronoun?
                                .entityReferences,
                            referredEntityRefs.isNotEmpty
                        else {
                            return .failure(.pronounNotSet(pronoun: lowercasedNoun))
                        }

                        // If "them" refers to multiple objects and the rule allows multiple objects
                        if referredEntityRefs.count > 1 && allowsMultiple {
                            var resolvedPronounCandidates = [ProxyReference]()

                            for ref in referredEntityRefs {
                                switch ref {
                                case .item(let item):
                                    let itemCandidates = await engine.itemsReachableByPlayer()
                                    if let matchingProxy = itemCandidates.first(where: {
                                        $0.id == item.id
                                    }) {
                                        resolvedPronounCandidates.append(.item(matchingProxy))
                                    }
                                case .location(let location):
                                    if await engine.gameState.locations[location.id] != nil {
                                        await resolvedPronounCandidates.append(
                                            ProxyReference(from: ref, with: engine)
                                        )
                                    }
                                case .player:
                                    await resolvedPronounCandidates.append(
                                        ProxyReference(from: ref, with: engine)
                                    )
                                case .universal:
                                    await resolvedPronounCandidates.append(
                                        ProxyReference(from: ref, with: engine)
                                    )
                                }
                            }

                            if resolvedPronounCandidates.isEmpty {
                                return .failure(
                                    .pronounRefersToOutOfScopeItem(pronoun: lowercasedNoun)
                                )
                            } else {
                                resolvedDirectObjects.append(contentsOf: resolvedPronounCandidates)
                            }
                        } else {
                            // Single object pronoun resolution or multiple objects not allowed
                            let singleObjectResult = await resolveObject(
                                noun: noun,
                                verb: verb,
                                modifiers: modifiers,
                                using: vocabulary,
                                engine: engine
                            )
                            switch singleObjectResult {
                            case .success(let objectRef):
                                if let objectRef {
                                    resolvedDirectObjects.append(objectRef)
                                }
                            case .failure(let error):
                                return .failure(error)
                            }
                        }
                    } else {
                        // Regular single object resolution
                        let singleObjectResult = await resolveObject(
                            noun: noun,
                            verb: verb,
                            modifiers: modifiers,
                            using: vocabulary,
                            engine: engine
                        )
                        switch singleObjectResult {
                        case .success(let objectRef):
                            if let objectRef {
                                resolvedDirectObjects.append(objectRef)
                            }
                        case .failure(let error):
                            return .failure(error)
                        }
                    }
                }
            }
        }

        // Handle indirect object resolution (including ALL and conjunctions)
        var resolvedIndirectObjects: [ProxyReference] = []
        var isAllCommandIO = false
        var isMultipleObjectsIO = false

        if rule.pattern.contains(.indirectObject) || rule.pattern.contains(.indirectObjects) {
            let allowsMultiple = rule.pattern.contains(.indirectObjects)

            // If no indirect object phrases were parsed, leave resolvedIndirectObjects empty
            // The action handler will provide appropriate error messages
            if indirectObjectPhrases.isEmpty {
                // Continue with empty indirect objects - action handlers will handle this
            } else {

                // Check if we have multiple phrases (conjunctions) and the rule allows multiple objects
                if indirectObjectPhrases.count > 1 && allowsMultiple {
                    isMultipleObjectsIO = true
                } else if indirectObjectPhrases.count > 1 {
                    return .failure(
                        .verbDoesNotSupportMultipleIndirectObjects(verb)
                    )
                }

                // Process each noun phrase
                for (noun, modifiers) in indirectObjectPhrases {
                    let lowercasedNoun = noun.lowercased()

                    // Check if this is an ALL command
                    if vocabulary.specialKeywords.contains(lowercasedNoun) {
                        if allowsMultiple {
                            isAllCommandIO = true
                            let allObjectsResult = await resolveAllObjects(
                                verb: verb,
                                modifiers: modifiers,
                                vocabulary: vocabulary,
                                engine: engine
                            )
                            switch allObjectsResult {
                            case .success(let objects):
                                resolvedIndirectObjects.append(contentsOf: objects)
                            case .failure(let error):
                                return .failure(error)
                            }
                        } else {
                            // Command doesn't support multiple objects but user tried "all"
                            return .failure(
                                .verbDoesNotSupportMultipleIndirectObjects(verb)
                            )
                        }
                    } else if vocabulary.pronouns.contains(lowercasedNoun)
                        && lowercasedNoun == "them"
                    {
                        // Handle plural pronoun that might refer to multiple objects
                        guard modifiers.isEmpty else {
                            return .failure(
                                .pronounCannotBeModified(pronoun: lowercasedNoun)
                            )
                        }

                        guard
                            let referredEntityRefs = await engine.gameState.pronoun?
                                .entityReferences,
                            referredEntityRefs.isNotEmpty
                        else {
                            return .failure(.pronounNotSet(pronoun: lowercasedNoun))
                        }

                        // If "them" refers to multiple objects and the rule allows multiple objects
                        if referredEntityRefs.count > 1 && allowsMultiple {
                            var resolvedPronounCandidates = [ProxyReference]()

                            for ref in referredEntityRefs {
                                switch ref {
                                case .item(let item):
                                    let itemCandidates = await engine.itemsReachableByPlayer()
                                    if let matchingProxy = itemCandidates.first(where: {
                                        $0.id == item.id
                                    }) {
                                        resolvedPronounCandidates.append(.item(matchingProxy))
                                    }
                                case .location(let location):
                                    if await engine.gameState.locations[location.id] != nil {
                                        await resolvedPronounCandidates.append(
                                            ProxyReference(from: ref, with: engine)
                                        )
                                    }
                                case .player:
                                    await resolvedPronounCandidates.append(
                                        ProxyReference(from: ref, with: engine)
                                    )
                                case .universal:
                                    await resolvedPronounCandidates.append(
                                        ProxyReference(from: ref, with: engine)
                                    )
                                }
                            }

                            if resolvedPronounCandidates.isEmpty {
                                return .failure(
                                    .pronounRefersToOutOfScopeItem(pronoun: lowercasedNoun)
                                )
                            } else {
                                resolvedIndirectObjects.append(
                                    contentsOf: resolvedPronounCandidates)
                            }
                        } else {
                            // Single object pronoun resolution or multiple objects not allowed
                            let singleObjectResult = await resolveObject(
                                noun: noun,
                                verb: verb,
                                modifiers: modifiers,
                                using: vocabulary,
                                engine: engine
                            )
                            switch singleObjectResult {
                            case .success(let objectRef):
                                if let objectRef {
                                    resolvedIndirectObjects.append(objectRef)
                                }
                            case .failure(let error):
                                return .failure(error)
                            }
                        }
                    } else {
                        // Regular single object resolution
                        let singleObjectResult = await resolveObject(
                            noun: noun,
                            verb: verb,
                            modifiers: modifiers,
                            using: vocabulary,
                            engine: engine
                        )
                        switch singleObjectResult {
                        case .success(let objectRef):
                            if let objectRef {
                                resolvedIndirectObjects.append(objectRef)
                            }
                        case .failure(let error):
                            return .failure(error)
                        }
                    }
                }
            }
        }  // Close the else block for indirect object processing

        // Create command with multiple object support
        let command = Command(
            verb: verb,
            directObjects: resolvedDirectObjects.sorted(),
            directObjectModifiers: directObjectPhrases.first?.1 ?? [],  // Use modifiers from first phrase
            indirectObjects: resolvedIndirectObjects.sorted(),
            indirectObjectModifiers: indirectObjectPhrases.first?.1 ?? [],  // Use modifiers from first phrase
            isAllCommand: isAllCommandDO || isAllCommandIO || isMultipleObjectsDO
                || isMultipleObjectsIO,
            preposition: matchedPreposition,
            direction: matchedDirection,
            rawInput: originalInput
        )
        return .success(command)
    }

    /// Parses a token sequence that may contain multiple noun phrases connected by conjunctions.
    /// Returns an array of (noun, modifiers) tuples, one for each noun phrase.
    /// For example, "sword and lantern" becomes [("sword", []), ("lantern", [])]
    /// and "red book, blue pen and green pencil" becomes [("book", ["red"]), ("pen", ["blue"]), ("pencil", ["green"])]
    private func parseConjunctedNounPhrases(
        from tokens: [String],
        vocabulary: Vocabulary
    ) -> [(noun: String, modifiers: [String])] {
        guard tokens.isNotEmpty else { return [] }

        // Split the tokens by conjunctions
        var phrases: [[String]] = []
        var currentPhrase = [String]()

        for token in tokens {
            if vocabulary.conjunctions.contains(token) {
                // Found a conjunction, save current phrase and start a new one
                if currentPhrase.isNotEmpty {
                    phrases.append(currentPhrase)
                    currentPhrase = []
                }
            } else {
                currentPhrase.append(token)
            }
        }

        // Add the last phrase
        if currentPhrase.isNotEmpty {
            phrases.append(currentPhrase)
        }

        // If no conjunctions were found, we have a single phrase
        if phrases.isEmpty && tokens.isNotEmpty {
            phrases = [tokens]
        }

        // Extract noun and modifiers from each phrase
        let result: [(noun: String, modifiers: [String])] = phrases.compactMap { phrase in
            let (noun, mods) = extractNounAndMods(from: phrase, vocabulary: vocabulary)
            // If we can't extract a noun, use the last word in the phrase as the noun
            // This allows unknown nouns to be handled by the resolution phase
            let finalNoun = noun ?? phrase.last
            guard let finalNoun = finalNoun else { return nil }

            // If we used the fallback noun (phrase.last), don't include it as a modifier too
            let finalMods = noun != nil ? mods : mods.filter { $0 != finalNoun }

            return (noun: finalNoun, modifiers: finalMods)
        }

        return result
    }

    /// Extracts the likely noun and preceding modifiers from a phrase.
    /// Filters noise words, identifies known nouns, and assumes the last known noun is primary.
    private func extractNounAndMods(
        from phrase: [String],
        vocabulary: Vocabulary
    ) -> (noun: String?, mods: [String]) {
        // Note: Input phrase has already been processed by removeNoise, so no need to filter again
        let significantPhrase = phrase
        guard significantPhrase.isNotEmpty else { return (nil, []) }

        // First, check if the entire phrase (joined) matches any known item or location
        // Only do this for multi-word phrases to avoid interfering with single-word cases
        if significantPhrase.count > 1 {
            let fullPhrase = significantPhrase.joined(separator: " ").lowercased()

            // Check if the full phrase is a known item or location
            let isKnownCompoundNoun =
                vocabulary.items.keys.contains(fullPhrase)
                || vocabulary.locationNames.keys.contains(fullPhrase)

            if isKnownCompoundNoun {
                // First, check if the compound noun itself is unambiguous
                let compoundItemCount = vocabulary.items[fullPhrase]?.count ?? 0
                let compoundLocationCount = vocabulary.locationNames[fullPhrase] != nil ? 1 : 0

                if compoundItemCount + compoundLocationCount == 1 {
                    // Compound noun is unambiguous, use it directly
                    if vocabulary.items.keys.contains(fullPhrase) {
                        return (fullPhrase, [])
                    }
                    if vocabulary.locationNames.keys.contains(fullPhrase) {
                        return (fullPhrase, [])
                    }
                }

                // If compound noun is ambiguous, check if we should prefer modifier+noun interpretation
                // If the last word is an ambiguous noun (multiple items), prefer modifier parsing
                if let lastWord = significantPhrase.last?.lowercased(),
                    let itemIDs = vocabulary.items[lastWord],
                    itemIDs.count > 1
                {
                    // Check if earlier words are valid adjectives
                    let potentialModifiers = significantPhrase.dropLast()
                    let allAreAdjectives = potentialModifiers.allSatisfy { word in
                        vocabulary.adjectives.keys.contains(word.lowercased())
                    }
                    if allAreAdjectives {
                        // Prefer modifier+noun interpretation for disambiguation
                        // Continue with normal parsing logic below
                    } else {
                        // Use compound noun interpretation
                        if vocabulary.items.keys.contains(fullPhrase) {
                            return (fullPhrase, [])
                        }
                        if vocabulary.locationNames.keys.contains(fullPhrase) {
                            return (fullPhrase, [])
                        }
                    }
                } else {
                    // No ambiguity or last word not a noun, use compound interpretation
                    if vocabulary.items.keys.contains(fullPhrase) {
                        return (fullPhrase, [])
                    }
                    if vocabulary.locationNames.keys.contains(fullPhrase) {
                        return (fullPhrase, [])
                    }
                }
            }
        }

        var knownNounIndices: [Int] = []
        for (index, word) in significantPhrase.enumerated() {
            let isItemNoun = vocabulary.items.keys.contains(word)
            let isLocationNoun = vocabulary.locationNames.keys.contains(word)
            let isPlayerAlias = vocabulary.playerAliases.contains(word)
            let isPronoun = vocabulary.pronouns.contains(word)
            let isSpecialKeyword = vocabulary.specialKeywords.contains(word)
            if isItemNoun || isLocationNoun || isPlayerAlias || isPronoun || isSpecialKeyword {
                knownNounIndices.append(index)
            }
        }

        guard let lastNounIndex = knownNounIndices.last else {
            // No known nouns found, but for multi-word phrases, try the full phrase as a noun
            // This handles cases like "box c" where the individual words don't match
            // but the combination might refer to a specific item
            if significantPhrase.count > 1 {
                let fullPhrase = significantPhrase.joined(separator: " ").lowercased()
                return (fullPhrase, [])
            }

            let potentialMods = significantPhrase.filter { word in
                !vocabulary.items.keys.contains(word)
                    && !vocabulary.locationNames.keys.contains(word)
                    && !vocabulary.playerAliases.contains(word)
                    && !vocabulary.verbLookup.keys.contains(word)
                    && !vocabulary.prepositions.contains(word)
                    && !vocabulary.directions.keys.contains(word)
                    && !vocabulary.specialKeywords.contains(word)
            }
            return (nil, potentialMods)
        }
        let noun = significantPhrase[lastNounIndex]

        var mods = [String]()
        for index in 0..<lastNounIndex {
            let word = significantPhrase[index]
            let isKnownNoun = knownNounIndices.contains(index)
            let isKnownVerb = vocabulary.verbLookup.keys.contains(word)
            let isKnownPrep = vocabulary.prepositions.contains(word)
            let isKnownDirection = vocabulary.directions.keys.contains(word)

            // Refined logic: Include words before the chosen noun as modifiers if they are:
            // 1. Not verbs, prepositions, or directions (original logic)
            // 2. Not known nouns UNLESS we're dealing with a compound phrase that matches a specific item

            // First check if this might be part of a compound phrase
            let potentialCompoundPhrase = significantPhrase[index...lastNounIndex].joined(
                separator: " "
            ).lowercased()
            let isPartOfCompoundPhrase =
                vocabulary.items.keys.contains(potentialCompoundPhrase)
                || vocabulary.locationNames.keys.contains(potentialCompoundPhrase)

            if !isKnownVerb && !isKnownPrep && !isKnownDirection {
                // Include as modifier if it's not a known noun, OR if it's part of a compound phrase
                if !isKnownNoun || isPartOfCompoundPhrase {
                    mods.append(word)
                }
            }
        }

        return (noun, mods)
    }

    // MARK: - Object Resolution Helpers

    /// Resolves a noun phrase (noun + modifiers) to a specific EntityReference within the game context.
    func resolveObject(
        noun: String,
        verb: Verb,
        modifiers: [String],
        using vocabulary: Vocabulary,
        engine: GameEngine
    ) async -> Result<ProxyReference?, ParseError> {
        let lowercasedNoun = noun.lowercased()

        // 1. Handle Player Aliases
        if vocabulary.playerAliases.contains(lowercasedNoun) {
            guard modifiers.isEmpty else {
                return .failure(
                    .playerReferenceCannotBeModified(
                        reference: lowercasedNoun, modifiers: modifiers
                    )
                )
            }
            return await .success(
                .player(PlayerProxy(with: engine))
            )
        }

        // 2. Handle Pronouns
        if vocabulary.pronouns.contains(lowercasedNoun) {
            guard modifiers.isEmpty else {
                return .failure(
                    .pronounCannotBeModified(pronoun: lowercasedNoun)
                )
            }
            // gameState.pronouns now stores Set<EntityReference>?
            guard
                let referredEntityRefs = await engine.gameState.pronoun?.entityReferences,
                referredEntityRefs.isNotEmpty
            else {
                return .failure(.pronounNotSet(pronoun: lowercasedNoun))
            }

            var resolvedPronounCandidates = [ProxyReference]()

            for ref in referredEntityRefs {
                switch ref {
                case .item(let item):
                    // Check scope for this specific itemID
                    let itemCandidates = await engine.itemsReachableByPlayer()

                    // Check if any item candidate has the same ID as the pronoun reference
                    if let matchingProxy = itemCandidates.first(where: { $0.id == item.id }) {
                        // Modifiers (adjectives) usually don't apply to pronouns directly,
                        // but if they did, this is where they'd be checked against the item's adjectives.
                        // For now, if the pronoun refers to an item and that item is in scope, consider it a match.
                        resolvedPronounCandidates.append(.item(matchingProxy))
                    }
                case .location(let location):
                    // Location scope: A named location is generally considered in scope if it exists.
                    if await engine.gameState.locations[location.id] != nil {
                        await resolvedPronounCandidates.append(
                            ProxyReference(from: ref, with: engine)
                        )
                    }
                case .player:  // Pronoun referring to player
                    await resolvedPronounCandidates.append(
                        ProxyReference(from: ref, with: engine)
                    )
                case .universal:
                    // Universal objects are always considered in scope
                    await resolvedPronounCandidates.append(
                        ProxyReference(from: ref, with: engine)
                    )
                }
            }

            if resolvedPronounCandidates.isEmpty {
                return .failure(
                    .pronounRefersToOutOfScopeItem(pronoun: lowercasedNoun)
                )
            } else if resolvedPronounCandidates.count > 1 {
                // Build a more generic ambiguity message if pronouns can refer to non-items.
                return .failure(
                    .ambiguousObjectReference(
                        noun: lowercasedNoun,
                        options: await resolvedPronounCandidates.asyncMap {
                            await $0.withDefiniteArticle
                        }
                    )
                )
            } else {
                return .success(resolvedPronounCandidates[0])
            }
        }

        // 3. Noun Resolution (Items and Locations)
        var potentialEntities: [ProxyReference] = []

        // First, try alternative interpretations if modifiers are present
        // Check if any modifier could actually be the primary noun
        if modifiers.isNotEmpty {
            for modifier in modifiers {
                let lowercasedModifier = modifier.lowercased()

                // Check if the modifier is actually a noun for some items
                if let itemIDs = vocabulary.items[lowercasedModifier] {
                    for itemID in itemIDs {
                        // Only consider this alternative if the item is specifically identified by this modifier
                        // and also has the current noun as part of its name/synonyms
                        let itemProxy = await engine.item(itemID)

                        let itemNameWords = Set(
                            await itemProxy.name.lowercased().split(separator: " ").map(String.init)
                        )
                        let itemSynonyms = Set(await itemProxy.synonyms.map { $0.lowercased() })
                        let allItemWords = itemNameWords.union(itemSynonyms)

                        // If this item contains both the modifier and the noun in its identity,
                        // consider it as an alternative interpretation
                        if allItemWords.contains(lowercasedModifier)
                            && allItemWords.contains(lowercasedNoun)
                        {
                            potentialEntities.append(.item(itemProxy))
                        }
                    }
                }
            }
        }

        // Check for items using the main noun
        if let itemIDs = vocabulary.items[lowercasedNoun] {
            for itemID in itemIDs {
                let item = await engine.item(itemID)
                potentialEntities.append(
                    .item(item)
                )
            }
        }

        // Check for locations
        if let locationID = vocabulary.locationNames[lowercasedNoun] {
            let location = await engine.location(locationID)
            potentialEntities.append(
                .location(location)
            )
        }

        // If no entities found in vocabulary, check for universal objects as fallback
        if potentialEntities.isEmpty {
            // Check if the noun matches any universal objects
            if let universalObjects = vocabulary.universals[lowercasedNoun],
                let closestMatch = universalObjects.closestMatch(to: lowercasedNoun)
            {
                return .success(.universal(closestMatch))
            }

            // No universal objects found either, create an unresolved item reference
            // This allows action handlers to provide more specific error messages

            // Create a fake Item for the unresolved reference
            let unresolvedItem = Item(id: ItemID(noun))
            let unresolvedProxy = ItemProxy(item: unresolvedItem, engine: engine)
            let unresolvedRef = ProxyReference.item(unresolvedProxy)
            return .success(unresolvedRef)
        }

        // 4. Scope, Conditions, Modifiers, and Disambiguation
        var resolvedAndScopedProxies = [ProxyReference]()

        for entityRef in potentialEntities {
            switch entityRef {
            case .item(let itemProxy):
                // Debug returns success on first ID match
                if verb == .debug, itemProxy.id.rawValue == noun {
                    return .success(entityRef)
                }

                // Use existing item-centric scoping and filtering
                let itemCandidates = await engine.itemsReachableByPlayer()

                // Check if item is in the general candidate pool
                if itemCandidates.contains(itemProxy),
                    await filterCandidates(item: itemProxy, modifiers: modifiers)
                {
                    resolvedAndScopedProxies.append(.item(itemProxy))
                }

            case .location(let locationProxy):
                // Debug returns success on first ID match
                if verb == .debug, locationProxy.id.rawValue == noun {
                    return .success(entityRef)
                }

                // Location scope: A named location is generally considered in scope.
                // Conditions for locations are less common in ObjectCondition but could be checked.
                guard modifiers.isEmpty else {
                    // Locations typically aren't modified by adjectives in the same way items are.
                    // Consider this a parse error for now or decide to ignore modifiers for locations.
                    // Returning nothing here, will lead to .modifierMismatch if no item matches.
                    continue  // Skip this candidate if modifiers are present
                }
                // TODO: Add check for location-specific requiredConditions if they become a concept.
                // For now, if it's a location reference, it's valid if named.
                if await engine.gameState.locations[locationProxy.id] != nil {  // Verify location actually exists in current game state
                    resolvedAndScopedProxies.append(.location(locationProxy))
                }

            case .player:  // Should have been handled by player alias check, but defensive
                if modifiers.isEmpty {
                    await resolvedAndScopedProxies.append(
                        .player(PlayerProxy(with: engine))
                    )
                }
            case .universal:
                // Universal objects are always considered in scope if modifiers match
                // For now, we don't apply modifier filtering to universals
                if modifiers.isEmpty {
                    resolvedAndScopedProxies.append(entityRef)
                }
            }
        }

        if resolvedAndScopedProxies.isEmpty {
            // Special case: If modifiers are provided, check if the full phrase (modifiers + noun)
            // matches a synonym for any item that exists but is not accessible
            if modifiers.isNotEmpty {
                let fullPhrase = (modifiers + [noun]).joined(separator: " ").lowercased()

                // Look through all items to see if any have this full phrase as a synonym
                for (_, itemIDs) in vocabulary.items {
                    for itemID in itemIDs {
                        let item = await engine.item(itemID)

                        // Check if the full phrase matches the item's name or any synonym
                        let itemNameLowercase = await item.name.lowercased()
                        let itemSynonyms = await item.synonyms.map { $0.lowercased() }

                        if itemNameLowercase == fullPhrase || itemSynonyms.contains(fullPhrase) {
                            // This exact phrase refers to a specific item, but it's not accessible
                            // Return an unresolved reference to trigger "Any such thing lurks beyond your reach."
                            let proxy = await engine.item(ItemID(fullPhrase))
                            return .success(
                                .item(proxy)
                            )
                        }
                    }
                }

                // Check if any accessible items match the noun but not the modifiers
                let itemCandidates = await engine.itemsReachableByPlayer()
                let accessiblePotentialItems = potentialEntities.compactMap { proxy -> Item? in
                    guard
                        case .item(let itemProxy) = proxy,
                        itemCandidates.contains(itemProxy)
                    else {
                        return nil
                    }
                    return itemProxy.item
                }

                if accessiblePotentialItems.isNotEmpty {
                    // We have accessible items with this noun but none match the modifiers
                    return .failure(.modifierMismatch(noun: noun, modifiers: modifiers))
                }
            }

            // If we had potential entities but none survived scoping/modifiers,
            // still return the first potential entity to allow action handlers
            // to provide more specific error messages
            if potentialEntities.isNotEmpty {
                // Return the first potential entity even if out of scope
                return .success(potentialEntities[0])
            }

            // This case should not happen given our changes above, but keep as fallback
            return .failure(.itemNotInScope(noun: noun))
        }

        if resolvedAndScopedProxies.count > 1 {
            // Enhanced ambiguity message logic
            let itemEntities = resolvedAndScopedProxies.compactMap { ref -> ItemProxy? in
                if case .item(let itemProxy) = ref {
                    itemProxy
                } else {
                    nil
                }
            }

            // Priority-based disambiguation: prefer held items
            if itemEntities.isNotEmpty && itemEntities.count == resolvedAndScopedProxies.count {
                // All ambiguous entities are items - check for held items
                let heldItems: [ItemProxy] = await withThrowingTaskGroup(
                    of: (ItemProxy, Bool).self
                ) { group in
                    for item in itemEntities {
                        group.addTask {
                            (item, await item.playerIsHolding)
                        }
                    }
                    var results: [(ItemProxy, Bool)] = []
                    do {
                        for try await result in group {
                            results.append(result)
                        }
                    } catch {
                        // If we can't determine held status, continue with normal disambiguation
                        return []
                    }
                    return results.filter { $0.1 }.map { $0.0 }
                }

                // If exactly one item is held, prefer it automatically
                if heldItems.count == 1 {
                    return .success(.item(heldItems[0]))
                }
            }

            if itemEntities.isNotEmpty && itemEntities.count == resolvedAndScopedProxies.count {
                // All ambiguous are items
                let baseName = await itemEntities.first?.name ?? "item"
                let allSameName = await withTaskGroup(of: Bool.self) { group in
                    for item in itemEntities {
                        group.addTask {
                            await item.name == baseName
                        }
                    }
                    var results: [Bool] = []
                    for await result in group {
                        results.append(result)
                    }
                    return results.allSatisfy { $0 }
                }
                let adjectiveSets = await withTaskGroup(of: [String].self) { group in
                    for item in itemEntities {
                        group.addTask {
                            await item.adjectives
                        }
                    }
                    var results: [String] = []
                    for await result in group {
                        results.append(contentsOf: result)
                    }
                    return results
                }
                let allSameAdjectives = adjectiveSets.dropFirst().allSatisfy {
                    $0 == adjectiveSets.first
                }
                if allSameName {
                    if allSameAdjectives {
                        // All truly identical
                        logger.error(
                            """
                            StandardParser cannot distinguish between \
                            \(itemEntities.count) identical items
                            """
                        )
                        return .failure(
                            .ambiguousObjectReference(noun: baseName, options: [])
                        )
                    } else {
                        // List with adjectives
                        let descriptions: [String] = await withTaskGroup(of: String.self) { group in
                            for item in itemEntities {
                                group.addTask {
                                    let adjectives = await item.adjectives
                                    let name = await item.name
                                    if let adj = adjectives.sorted().first {
                                        return "the \(adj) \(name)"
                                    } else {
                                        return "the \(name)"
                                    }
                                }
                            }
                            var results = [String]()
                            for await result in group {
                                results.append(result)
                            }
                            return results
                        }
                        return .failure(
                            .ambiguousObjectReference(
                                noun: baseName,
                                options: descriptions.sorted()
                            )
                        )
                    }
                }
            }
            // Fallback: original logic
            return await .failure(
                .ambiguousReference(
                    options: resolvedAndScopedProxies.asyncMap {
                        await $0.withDefiniteArticle
                    }
                )
            )
        }

        return .success(resolvedAndScopedProxies[0])
    }

    /// Resolves ALL keywords to multiple objects based on verb and conditions.
    func resolveAllObjects(
        verb: Verb,
        modifiers: [String],
        vocabulary: Vocabulary,
        engine: GameEngine
    ) async -> Result<[ProxyReference], ParseError> {
        await .success(
            engine.itemsReachableByPlayer().map(ProxyReference.item)
        )
    }

    /// Filters a set of candidate ItemIDs based on a list of required modifiers (adjectives).
    func filterCandidates(
        item: ItemProxy,
        modifiers: [String]
    ) async -> Bool {
        // No modifiers, the item is a valid match by default
        if modifiers.isEmpty { return true }

        let lowercasedModifiers = Set(modifiers.map { $0.lowercased() })
        return lowercasedModifiers.isSubset(of: await item.adjectives)
    }

    // MARK: - Private Helpers (New/Modified for Syntax Matching)

    /// Finds the range of tokens corresponding to a noun phrase within the token list,
    /// starting from a given index.
    /// Stops consuming tokens if a token matching the type of the *next* element in the
    /// pattern is encountered (e.g., stops before a preposition if the pattern expects one next).
    ///
    /// - Parameters:
    ///   - startIndex: The index in `tokens` to start looking from.
    ///   - tokens: The array of significant input tokens.
    ///   - pattern: The full SyntaxRule pattern being matched.
    ///   - patternIndex: The index of the *current* noun phrase element (e.g., .directObject)
    ///                 within the `pattern` array.
    ///   - vocabulary: The game vocabulary.
    /// - Returns: The index marking the end of the noun phrase (exclusive). If no valid phrase
    ///            is found, returns `startIndex`.
    private func findEndOfNounPhrase(
        startIndex: Int,
        tokens: [String],
        pattern: [SyntaxTokenType],
        patternIndex: Int,
        vocabulary: Vocabulary
    ) -> Int {
        var boundaryIndex = startIndex
        let nextPatternIndex = patternIndex + 1

        while boundaryIndex < tokens.count {
            let currentToken = tokens[boundaryIndex]

            if nextPatternIndex < pattern.count {
                let nextExpectedType = pattern[nextPatternIndex]
                var isBoundaryToken = false

                switch nextExpectedType {
                case .direction:
                    if vocabulary.directions.keys.contains(currentToken) {
                        isBoundaryToken = true
                    }
                case .verb:
                    if vocabulary.verbLookup.keys.contains(currentToken) {
                        isBoundaryToken = true
                    }
                case .specificVerb(let requiredVerb):
                    // Check if current token matches the required verb
                    if let verb = vocabulary.verbLookup[currentToken],
                        verb == requiredVerb
                    {
                        isBoundaryToken = true
                    }
                case .particle(let expectedParticle):
                    if currentToken == expectedParticle {
                        isBoundaryToken = true
                    }
                case .directObject, .directObjects, .indirectObject, .indirectObjects:
                    break
                }

                if isBoundaryToken {
                    return boundaryIndex
                }
            } else {
                // If there's no next pattern element, stop consuming at prepositions
                // that aren't explicitly expected by the pattern
                if vocabulary.prepositions.contains(currentToken) {
                    // Check if this preposition is explicitly expected by the current pattern
                    let prepositionExpectedInPattern = pattern.contains { patternElement in
                        if case .particle(let expectedParticle) = patternElement {
                            return expectedParticle == currentToken
                        }
                        return false
                    }

                    if !prepositionExpectedInPattern {
                        // Stop consuming tokens at unexpected prepositions
                        return boundaryIndex
                    }
                }
            }

            boundaryIndex += 1
        }

        return boundaryIndex
    }
}

// MARK: - RuleMatchResult

extension StandardParser {
    enum RuleMatchResult {
        /// Rule matched successfully and produced a valid command
        case success(Command)
        /// Rule failed due to a parsing error (e.g., unknown noun, ambiguity)
        case failure(ParseError)
        /// Rule doesn't apply to this input (e.g., particle mismatch, wrong verb)
        case notApplicable
    }
}
