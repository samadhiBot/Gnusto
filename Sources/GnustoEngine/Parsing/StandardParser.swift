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
/// 3.  **Verb Identification:** The parser identifies the primary action word (verb).
///     It can recognize multi-word verb synonyms (e.g., "pick up" for "take") if
///     they are defined in the `Vocabulary`.
/// 4.  **Syntax Rule Matching:** The sequence of significant tokens is compared against
///     the `SyntaxRule`s associated with the identified verb (also from `Vocabulary`).
///     Each rule defines a valid grammatical pattern (e.g., VERB-DIRECT_OBJECT,
///     VERB-DIRECT_OBJECT-PREPOSITION-INDIRECT_OBJECT).
/// 5.  **Object Resolution:** Noun phrases are identified as potential direct and indirect
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
public struct StandardParser: Parser {
    /// Initializes a new `StandardParser` instance.
    public init() {}

    /// A logger used for internal parser messages, primarily for debugging.
    let logger = Logger(label: "com.samadhibot.Gnusto.StandardParser")

    /// Parses a raw input string from the player into a structured `Command` or a `ParseError`.
    ///
    /// This method implements the core parsing logic described in the `StandardParser` overview.
    /// It attempts to understand the player's intent by matching their input against the
    /// game's vocabulary and syntax rules.
    ///
    /// - Parameters:
    ///   - input: The raw string as entered by the player (e.g., "take brass lantern").
    ///   - vocabulary: The `Vocabulary` for the current game, containing all known words
    ///                 (verbs, nouns, adjectives, prepositions, noise words, directions)
    ///                 and verb syntax rules. This is the primary source of grammatical
    ///                 and lexical knowledge for the parser.
    ///   - gameState: The current `GameState`, providing essential context for resolving
    ///                object references (e.g., player inventory, item locations, current
    ///                pronoun meanings, items visible or accessible to the player).
    /// - Returns: A `Result` which is either:
    ///   - `.success(Command)`: If parsing was successful. The returned `Command` object
    ///     encapsulates the player's understood intent, including the identified `VerbID`,
    ///     resolved `EntityReference`s for direct and/or indirect objects (if any),
    ///     any recognized modifiers (adjectives), the preposition used (if any),
    ///     and the direction (for movement commands). This `Command` is then ready for
    ///     the `GameEngine` to execute.
    ///   - `.failure(ParseError)`: If parsing failed at any stage. The `ParseError` enum
    ///     provides a specific reason for the failure, such as `.unknownVerb` if the main
    ///     action word wasn't recognized, `.itemNotInScope` if a mentioned object isn't
    ///     accessible, `.badGrammar` if the sentence structure didn't match any known rules,
    ///     or `.ambiguity` if the input could be interpreted in multiple ways that the
    ///     parser couldn't resolve on its own.
    public func parse(
        input: String,
        vocabulary: Vocabulary,
        gameState: GameState
    ) -> Result<Command, ParseError> {
        // 1. Tokenize and Normalize Input
        let tokens = tokenize(input: input)

        // 2. Remove Noise Words
        let significantTokens = removeNoise(tokens: tokens, noiseWords: vocabulary.noiseWords)

        // 3. Handle Single-Word Direction Command (e.g., "NORTH", "N")
        if significantTokens.count == 1,
           let directionWord = significantTokens.first,
           let direction = vocabulary.directions[directionWord]
        {
            // Assume a default movement verb like 'go'
            // TODO: Make the default movement verb configurable or a constant
            let defaultGoVerbID = VerbID("go") // Placeholder
            let command = Command(verb: defaultGoVerbID, direction: direction, rawInput: input)
            return .success(command)
        }

        // 4. Handle Empty Input (after noise removal and direction check)
        guard !significantTokens.isEmpty else {
            return .failure(.emptyInput)
        }

        // 5. Identify Verb (handling multi-word synonyms)
        var matchedVerbIDs: Set<VerbID> = [] // Store all potential verb IDs
        var verbTokenCount = 0
        var verbStartIndex = 0

        // Iterate through possible starting positions for the verb
        for i in 0..<significantTokens.count {
            var longestMatchLength = 0
            var potentialMatchIDs: Set<VerbID> = [] // Track IDs for the current longest match length

            // Check token sequences starting from index i
            for length in (1...min(4, significantTokens.count - i)).reversed() { // Check up to 4-word verbs, reversed for longest match first
                let subSequence = significantTokens[i..<(i + length)]
                let verbPhrase = subSequence.joined(separator: " ")

                // Look up the set of verbs associated with this phrase
                if let foundVerbIDs = vocabulary.verbSynonyms[verbPhrase] { // Now returns Set<VerbID>?
                    // Found potential matches
                    if length > longestMatchLength {
                        // New longest length found, clear previous shorter matches and start fresh
                        longestMatchLength = length
                        potentialMatchIDs = foundVerbIDs // Assign the whole set
                        verbTokenCount = length // Store the length of this match
                        verbStartIndex = i // Store the start index
                    } else if length == longestMatchLength {
                        // Same length as the current longest, add these IDs to the set
                        potentialMatchIDs.formUnion(foundVerbIDs) // Use formUnion to add all IDs
                    }
                    // If length < longestMatchLength, ignore (we only want the longest matches)
                }
            }

            // If we found any matches of the longest possible length starting at index i, use them and stop searching
            if longestMatchLength > 0 {
                matchedVerbIDs = potentialMatchIDs // Assign the set of IDs found at the longest length
                // verbTokenCount and verbStartIndex are already set when longestMatchLength was updated
                break // Found the first (and longest) verb match group, stop outer loop
            }
        }


        // Ensure at least one verb was matched
        guard !matchedVerbIDs.isEmpty else {
            // No known single or multi-word verb/synonym found
            return .failure(.unknownVerb(significantTokens.first ?? significantTokens.joined(separator: " "))) // Use first word as guess
        }

        // ***** REVISED: Fetch rules for ALL matched VerbIDs *****
        var allPotentialRules: [(verb: VerbID, rule: SyntaxRule)] = []
        var verbsWithRules: Set<VerbID> = [] // Track which verbs actually have rules
        for verb in matchedVerbIDs {
            if let verbDef = vocabulary.verbDefinitions[verb] {
                if !verbDef.syntax.isEmpty {
                    verbsWithRules.insert(verb)
                    for rule in verbDef.syntax {
                        allPotentialRules.append((verb: verb, rule: rule))
                    }
                }
            }
        }

        // Handle cases where verb(s) were matched but NONE have rules, and there are extra tokens
        if allPotentialRules.isEmpty && significantTokens.count > verbTokenCount {
            // Provide a generic error based on the *first* matched verb ID (arbitrary choice in ambiguity)
            let firstMatchedID = matchedVerbIDs.first!
            return .failure(.badGrammar("I understand the verb '\(firstMatchedID.rawValue)', but not the rest of that sentence."))
        }

        // 6. Match Tokens Against All Potential Syntax Rules
        var successfulParse: Command? = nil
        var bestError: ParseError? = nil

        // Pre-calculate input preposition once, as it's the same for all rules
        let inputPreposition = findInputPreposition(tokens: significantTokens, startIndex: verbStartIndex + verbTokenCount, vocabulary: vocabulary)

        for (verb, rule) in allPotentialRules { // Iterate through all potential rules
            let matchResult = matchRule(
                rule: rule,
                tokens: significantTokens,
                verbStartIndex: verbStartIndex,
                verb: verb, // <<< Pass the specific verb for this rule
                vocabulary: vocabulary,
                gameState: gameState,
                originalInput: input
            )

            switch matchResult {
            case .success(let command): // Command already contains the correct verb from matchRule
                // Rule matched structurally. Now check prepositions.
                if let requiredPrep = rule.requiredPreposition {
                    // Rule requires a specific preposition
                    if let inputPrep = inputPreposition {
                        // Input also has a preposition
                        if requiredPrep == inputPrep {
                            // PREPOSITIONS MATCH - DEFINITIVE SUCCESS
                            successfulParse = command // Command has the correct verb
                            bestError = nil // Clear any previous error
                            break // Found the best possible match for this input
                        } else {
                            // PREPOSITIONS MISMATCH - Record error, continue
                            // Use the specific verb associated with this rule
                            let mismatchError = ParseError.badGrammar(
                                "Preposition mismatch for verb '\(verb)' (expected '\(requiredPrep)', found '\(inputPrep)')."
                            )
                            if bestError == nil || shouldReplaceError(existing: bestError!, new: mismatchError) {
                                bestError = mismatchError
                            }
                            continue // Try next rule, this one is invalid for this input
                        }
                    } else {
                        // RULE REQUIRES PREP, INPUT HAS NONE - Record error, continue
                        // Use the specific verb associated with this rule
                        let missingPrepError = ParseError.badGrammar("Verb '\(verb)' requires preposition '\(requiredPrep)' which was missing.")
                        if bestError == nil || shouldReplaceError(existing: bestError!, new: missingPrepError) {
                            bestError = missingPrepError
                        }
                        continue // Try next rule, this one is invalid for this input
                    }
                } else {
                    // RULE REQUIRES NO SPECIFIC PREPOSITION
                    // If the input *also* has no preposition, this is a strong match.
                    // If the input *does* have a preposition, this is still a structural match,
                    // but potentially weaker than one where prepositions align. ZIL often ignores extra preps.
                    // Let's treat this as a potential success but keep looking for a better (preposition-matching) rule.
                    // However, for simplicity now, let's consider it a success unless we find a better one later.
                    // TODO: Refine logic if ZIL treats extra prepositions differently (e.g., as errors).
                    if successfulParse == nil { // Only take this if we don't have a preposition-matched success yet
                        successfulParse = command // Command has the correct verb
                        // Don't clear bestError here, a later rule might still be better or produce a higher-priority error
                    }
                    // Continue searching for a potentially better match (e.g., one that uses the input preposition)
                    continue
                }
            case .failure(let currentError):
                // Structural failure reported by matchRule
                if bestError == nil || shouldReplaceError(existing: bestError!, new: currentError) {
                     bestError = currentError
                }
                // Continue to the next rule (implicit in loop structure)
            }
        } // End rule loop
        endRuleLoop: // Label for goto

        // 7. Return Result
        if let command = successfulParse {
            return .success(command)
        } else if let error = bestError { // Otherwise return best error found
             return .failure(error)
        } else {
            // Handle simple verb-only commands or internal error
             if allPotentialRules.isEmpty && significantTokens.count == verbTokenCount {
                 // Input was just a verb phrase matching one or more verbs, none of which had rules.
                 // Pick the first matched verb ID as the canonical one (arbitrary choice).
                 let firstMatchedID = matchedVerbIDs.first!
                 let command = Command(verb: firstMatchedID, rawInput: input)
                 return .success(command)
             } else {
                 // If we get here, rules existed, but none resulted in success or a recorded error.
                 // This likely means structural matches occurred, but preposition checks failed,
                 // or no structural matches occurred at all. bestError should ideally have been set.
                 // Provide a generic grammar error based on the *first* matched verb ID (arbitrary choice).
                 let firstMatchedID = matchedVerbIDs.first!
                 return .failure(.badGrammar("I understood '\(firstMatchedID.rawValue)' but couldn't parse the rest of the sentence with its known grammar rules."))
             }
        }
    }

    /// Helper to find the preposition in the input tokens *after* the verb phrase.
    private func findInputPreposition(tokens: [String], startIndex: Int, vocabulary: Vocabulary) -> String? {
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
        case .itemNotInScope, .modifierMismatch, .unknownNoun, .pronounNotSet, .pronounRefersToOutOfScopeItem:
            return true
        default:
            return false
        }
    }

    private func isAmbiguityError(_ error: ParseError) -> Bool {
         switch error {
         case .ambiguity, .ambiguousPronounReference:
             return true
         default:
             return false
         }
    }

     private func isGrammarError(_ error: ParseError) -> Bool {
         switch error {
         case .badGrammar:
             return true
         default:
             return false
         }
     }

    private func errorPriority(_ error: ParseError) -> Int {
        if isResolutionError(error) { return 4 }
        if isAmbiguityError(error) { return 3 }
        if isGrammarError(error) { return 2 }
        if case .unknownVerb = error { return 1 }
        if case .emptyInput = error { return 0 }
        return 0 // Default lowest priority
    }

    private func shouldReplaceError(existing: ParseError, new: ParseError) -> Bool {
        return errorPriority(new) > errorPriority(existing)
    }

    /// Splits the input string into lowercase tokens.
    func tokenize(input: String) -> [String] {
        // Simple whitespace and punctuation separation, converts to lowercase.
        // ZIL tokenization was more complex (e.g., dictionary separators).

        // Allow alphanumeric characters, spaces, and commas (for conjunctions)
        let allowedChars = CharacterSet.alphanumerics.union(.whitespaces).union(CharacterSet(charactersIn: ","))
        let sanitizedInput = String(input.unicodeScalars.filter { allowedChars.contains($0) })

        // Split by whitespace and also treat commas as separate tokens
        var tokens: [String] = []
        let words = sanitizedInput.lowercased()
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
        
        for word in words {
            if word.contains(",") {
                // Split words containing commas
                let parts = word.components(separatedBy: ",")
                for (index, part) in parts.enumerated() {
                    if !part.isEmpty {
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

    // MARK: - Syntax Matching Logic (New)

    /// Attempts to match a sequence of tokens against a specific SyntaxRule.
    private func matchRule(
        rule: SyntaxRule,
        tokens: [String],
        verbStartIndex: Int,
        verb: VerbID,
        _debugHook: (() -> Void)? = nil, // Add parameter for debug hook
        vocabulary: Vocabulary,
        gameState: GameState,
        originalInput: String
    ) -> Result<Command, ParseError> {
        _debugHook?() // Call the hook
        var tokenCursor = verbStartIndex + 1
        var directObjectPhraseTokens: [String] = []
        var indirectObjectPhraseTokens: [String] = []
        var matchedPreposition: String? = nil
        var matchedDirection: Direction? = nil

        for patternIndex in 1..<rule.pattern.count {
            let tokenType = rule.pattern[patternIndex]

            guard tokenCursor < tokens.count else {
                let remainingPattern = rule.pattern[patternIndex...]
                let onlyObjectsRemain = remainingPattern.allSatisfy { $0 == .directObject || $0 == .indirectObject }
                if onlyObjectsRemain {
                     break
                } else {
                    return .failure(.badGrammar("Command seems incomplete, expected more input like '\(tokenType)'."))
                }
            }

            switch tokenType {
            case .verb: continue

            case .directObject:
                let phraseEndIndex = findEndOfNounPhrase(
                    startIndex: tokenCursor,
                    tokens: tokens,
                    pattern: rule.pattern,
                    patternIndex: patternIndex,
                    vocabulary: vocabulary
                )
                guard phraseEndIndex > tokenCursor else {
                    let context = (tokenCursor < tokens.count) ? "'\(tokens[tokenCursor])'" : "end of input"
                    return .failure(
                        .badGrammar(
                            "Expected a direct object phrase for verb '\(verb)', but found \(context)."
                        )
                    )
                }
                directObjectPhraseTokens = Array(tokens[tokenCursor..<phraseEndIndex])
                tokenCursor = phraseEndIndex

            case .preposition:
                let currentToken = tokens[tokenCursor]
                let expectedPrep = rule.requiredPreposition
                let isKnownPrep = vocabulary.prepositions.contains(currentToken)

                // Check if the current token is a known preposition.
                // The check for *which* specific preposition is required
                // happens *after* matchRule returns success.
                guard isKnownPrep else {
                    let expectedType = expectedPrep ?? "a preposition"
                    return .failure(.badGrammar("Expected \(expectedType) but found '\(currentToken)'."))
                }

                // If the rule *does* require a specific preposition, and the current token
                // *isn't* it, this specific match attempt might be wrong, but don't fail
                // the entire rule structurally yet. Store the token found.
                // The calling function (`parse`) will validate if the required one was present.
                matchedPreposition = currentToken
                tokenCursor += 1

            case .indirectObject:
                 let phraseEndIndex = findEndOfNounPhrase(
                    startIndex: tokenCursor,
                    tokens: tokens,
                    pattern: rule.pattern,
                    patternIndex: patternIndex,
                    vocabulary: vocabulary
                 )
                 guard phraseEndIndex > tokenCursor else {
                    let context = (tokenCursor < tokens.count) ? "'\(tokens[tokenCursor])'" : "end of input"
                     return .failure(.badGrammar("Expected an indirect object phrase for verb '\(verb)', but found \(context)."))
                 }
                indirectObjectPhraseTokens = Array(tokens[tokenCursor..<phraseEndIndex])
                tokenCursor = phraseEndIndex

            case .direction:
                 let currentToken = tokens[tokenCursor]
                 if let direction = vocabulary.directions[currentToken] {
                     matchedDirection = direction
                     tokenCursor += 1
                 } else {
                     return .failure(.badGrammar("Expected a direction (like north, s, up) but found '\(currentToken)'."))
                 }

            case .particle(let expectedParticle):
                let currentToken = tokens[tokenCursor]
                guard currentToken == expectedParticle else {
                    return .failure(.badGrammar("Expected '\(expectedParticle)' after '\(tokens[verbStartIndex])' but found '\(currentToken)'."))
                }
                tokenCursor += 1
            }
        }

        if tokenCursor < tokens.count {
            return .failure(.badGrammar("Unexpected words found after command: '\(Array(tokens[tokenCursor...]).joined(separator: " "))'"))
        }

        // Parse multiple noun phrases connected by conjunctions
        let directObjectPhrases = parseConjunctedNounPhrases(from: directObjectPhraseTokens, vocabulary: vocabulary)
        let indirectObjectPhrases = parseConjunctedNounPhrases(from: indirectObjectPhraseTokens, vocabulary: vocabulary)

        // Handle direct object resolution (including ALL and conjunctions)
        var resolvedDirectObjects: [EntityReference] = []
        var isAllCommandDO = false
        var isMultipleObjectsDO = false
        
        if rule.pattern.contains(.directObject) {
            if directObjectPhrases.isEmpty {
                return .failure(.badGrammar("Expected a direct object phrase for verb '\(verb)'."))
            }
            
            // Check if we have multiple phrases (conjunctions) and the rule allows multiple objects
            if directObjectPhrases.count > 1 && rule.directObjectConditions.contains(.allowsMultiple) {
                isMultipleObjectsDO = true
            } else if directObjectPhrases.count > 1 {
                return .failure(.badGrammar("The verb '\(verb)' doesn't support multiple objects."))
            }
            
            // Process each noun phrase
            for (noun, modifiers) in directObjectPhrases {
                let lowercasedNoun = noun.lowercased()
                
                // Check if this is an ALL command and the rule allows multiple objects
                if vocabulary.specialKeywords.contains(lowercasedNoun) && 
                   rule.directObjectConditions.contains(.allowsMultiple) {
                    isAllCommandDO = true
                    let allObjectsResult = resolveAllObjects(
                        verb: verb,
                        modifiers: modifiers,
                        in: gameState,
                        using: vocabulary,
                        requiredConditions: rule.directObjectConditions
                    )
                    switch allObjectsResult {
                    case .success(let objects):
                        resolvedDirectObjects.append(contentsOf: objects)
                    case .failure(let error):
                        return .failure(error)
                    }
                } else {
                    // Regular single object resolution
                    let singleObjectResult = resolveObject(
                        noun: noun,
                        verb: verb,
                        modifiers: modifiers,
                        in: gameState,
                        using: vocabulary,
                        requiredConditions: rule.directObjectConditions
                    )
                    switch singleObjectResult {
                    case .success(let objectRef):
                        if let ref = objectRef {
                            resolvedDirectObjects.append(ref)
                        }
                    case .failure(let error):
                        return .failure(error)
                    }
                }
            }
        }

        // Handle indirect object resolution (including ALL and conjunctions)
        var resolvedIndirectObjects: [EntityReference] = []
        var isAllCommandIO = false
        var isMultipleObjectsIO = false
        
        if rule.pattern.contains(.indirectObject) {
            if indirectObjectPhrases.isEmpty {
                return .failure(.badGrammar("Expected an indirect object phrase for verb '\(verb)'."))
            }
            
            // Check if we have multiple phrases (conjunctions) and the rule allows multiple objects
            if indirectObjectPhrases.count > 1 && rule.indirectObjectConditions.contains(.allowsMultiple) {
                isMultipleObjectsIO = true
            } else if indirectObjectPhrases.count > 1 {
                return .failure(.badGrammar("The verb '\(verb)' doesn't support multiple indirect objects."))
            }
            
            // Process each noun phrase
            for (noun, modifiers) in indirectObjectPhrases {
                let lowercasedNoun = noun.lowercased()
                
                // Check if this is an ALL command and the rule allows multiple objects
                if vocabulary.specialKeywords.contains(lowercasedNoun) && 
                   rule.indirectObjectConditions.contains(.allowsMultiple) {
                    isAllCommandIO = true
                    let allObjectsResult = resolveAllObjects(
                        verb: verb,
                        modifiers: modifiers,
                        in: gameState,
                        using: vocabulary,
                        requiredConditions: rule.indirectObjectConditions
                    )
                    switch allObjectsResult {
                    case .success(let objects):
                        resolvedIndirectObjects.append(contentsOf: objects)
                    case .failure(let error):
                        return .failure(error)
                    }
                } else {
                    // Regular single object resolution
                    let singleObjectResult = resolveObject(
                        noun: noun,
                        verb: verb,
                        modifiers: modifiers,
                        in: gameState,
                        using: vocabulary,
                        requiredConditions: rule.indirectObjectConditions
                    )
                    switch singleObjectResult {
                    case .success(let objectRef):
                        if let ref = objectRef {
                            resolvedIndirectObjects.append(ref)
                        }
                    case .failure(let error):
                        return .failure(error)
                    }
                }
            }
        }

        // Create command with multiple object support
        let command = Command(
            verb: verb,
            directObjects: resolvedDirectObjects,
            directObjectModifiers: directObjectPhrases.first?.1 ?? [], // Use modifiers from first phrase
            indirectObjects: resolvedIndirectObjects,
            indirectObjectModifiers: indirectObjectPhrases.first?.1 ?? [], // Use modifiers from first phrase
            isAllCommand: isAllCommandDO || isAllCommandIO || isMultipleObjectsDO || isMultipleObjectsIO,
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
        guard !tokens.isEmpty else { return [] }
        
        // Split the tokens by conjunctions
        var phrases: [[String]] = []
        var currentPhrase: [String] = []
        
        for token in tokens {
            if vocabulary.conjunctions.contains(token) {
                // Found a conjunction, save current phrase and start a new one
                if !currentPhrase.isEmpty {
                    phrases.append(currentPhrase)
                    currentPhrase = []
                }
            } else {
                currentPhrase.append(token)
            }
        }
        
        // Add the last phrase
        if !currentPhrase.isEmpty {
            phrases.append(currentPhrase)
        }
        
        // If no conjunctions were found, we have a single phrase
        if phrases.isEmpty && !tokens.isEmpty {
            phrases = [tokens]
        }
        
        // Extract noun and modifiers from each phrase
        let result: [(noun: String, modifiers: [String])] = phrases.compactMap { phrase in
            let (noun, mods) = extractNounAndMods(from: phrase, vocabulary: vocabulary)
            // If we can't extract a noun, use the last word in the phrase as the noun
            // This allows unknown nouns to be handled by the resolution phase
            let finalNoun = noun ?? phrase.last
            guard let finalNoun = finalNoun else { return nil }
            return (noun: finalNoun, modifiers: mods)
        }
        
        return result
    }

    /// Extracts the likely noun and preceding modifiers from a phrase.
    /// Filters noise words, identifies known nouns, and assumes the last known noun is primary.
    private func extractNounAndMods(
        from phrase: [String],
        vocabulary: Vocabulary
    ) -> (noun: String?, mods: [String]) {
        let significantPhrase = phrase.filter { !vocabulary.noiseWords.contains($0) }
        guard !significantPhrase.isEmpty else { return (nil, []) }

        let playerAliases: Set<String> = ["me", "self", "myself"]
        var knownNounIndices: [Int] = []
        for (index, word) in significantPhrase.enumerated() {
            let isItemNoun = vocabulary.items.keys.contains(word)
            let isLocationNoun = vocabulary.locationNames.keys.contains(word)
            let isPlayerAlias = playerAliases.contains(word)
            let isPronoun = vocabulary.pronouns.contains(word)
            let isSpecialKeyword = vocabulary.specialKeywords.contains(word)
            if isItemNoun || isLocationNoun || isPlayerAlias || isPronoun || isSpecialKeyword {
                knownNounIndices.append(index)
            }
        }

        guard let lastNounIndex = knownNounIndices.last else {
            let potentialMods = significantPhrase.filter { word in
                !vocabulary.items.keys.contains(word) &&
                !vocabulary.locationNames.keys.contains(word) &&
                !playerAliases.contains(word) &&
                !vocabulary.verbSynonyms.keys.contains(word) &&
                !vocabulary.prepositions.contains(word) &&
                !vocabulary.directions.keys.contains(word) &&
                !vocabulary.specialKeywords.contains(word)
            }
            return (nil, potentialMods)
        }
        let noun = significantPhrase[lastNounIndex]

        var mods: [String] = []
        for index in 0..<lastNounIndex {
            let word = significantPhrase[index]
            let isKnownNoun = knownNounIndices.contains(index)
            let isKnownVerb = vocabulary.verbSynonyms.keys.contains(word)
            let isKnownPrep = vocabulary.prepositions.contains(word)
            let isKnownDirection = vocabulary.directions.keys.contains(word)

            if !isKnownNoun && !isKnownVerb && !isKnownPrep && !isKnownDirection {
                mods.append(word)
            }
        }

        return (noun, mods)
    }

    // MARK: - Object Resolution Helpers

    /// Resolves a noun phrase (noun + modifiers) to a specific EntityReference within the game context.
    func resolveObject(
        noun: String,
        verb: VerbID,
        modifiers: [String],
        in gameState: GameState,
        using vocabulary: Vocabulary,
        requiredConditions: ObjectCondition
    ) -> Result<EntityReference?, ParseError> {
        let lowercasedNoun = noun.lowercased()
        let playerAliases: Set<String> = ["me", "self", "myself"]

        // 1. Handle Player Aliases
        if playerAliases.contains(lowercasedNoun) {
            guard modifiers.isEmpty else {
                return .failure(
                    .badGrammar("""
                        Player reference '\(lowercasedNoun)' cannot be modified by \
                        '\(modifiers.joined(separator: " "))'.
                        """)
                )
            }
            return .success(.player)
        }

        // 2. Handle Pronouns
        if vocabulary.pronouns.contains(lowercasedNoun) {
            guard modifiers.isEmpty else {
                return .failure(
                    .badGrammar(
                        "Pronouns like '\(lowercasedNoun)' usually cannot be modified."
                    )
                )
            }
            // gameState.pronouns now stores Set<EntityReference>?
            guard
                let referredEntityRefs = gameState.pronouns[lowercasedNoun],
                !referredEntityRefs.isEmpty
            else {
                return .failure(.pronounNotSet(pronoun: lowercasedNoun))
            }

            var resolvedPronounCandidates: [EntityReference] = []

            for ref in referredEntityRefs {
                switch ref {
                case .item(let itemID):
                    // Check scope for this specific itemID
                    let itemCandidates = gatherCandidates(
                        in: gameState,
                        requiredConditions: requiredConditions
                    )
                    if itemCandidates.keys.contains(itemID) { // Check if item is in the general candidate pool
                        // Modifiers (adjectives) usually don't apply to pronouns directly,
                        // but if they did, this is where they'd be checked against the item's adjectives.
                        // For now, if the pronoun refers to an item and that item is in scope, consider it a match.
                        resolvedPronounCandidates.append(ref)
                    }
                case .location(let locID):
                    // Location scope: A named location is generally considered in scope if it exists.
                    if gameState.locations[locID] != nil {
                        resolvedPronounCandidates.append(ref)
                    }
                case .player: // Pronoun referring to player
                    resolvedPronounCandidates.append(ref)
                }
            }

            if resolvedPronounCandidates.isEmpty {
                return .failure(.pronounRefersToOutOfScopeItem(pronoun: lowercasedNoun))
            } else if resolvedPronounCandidates.count > 1 {
                // Build a more generic ambiguity message if pronouns can refer to non-items.
                let descriptions = resolvedPronounCandidates.map {
                    entityRefToString($0, gameState: gameState)
                }
                return .failure(
                    .ambiguousPronounReference("""
                        Which '\(lowercasedNoun)' do you mean: \
                        \(descriptions.commaListing("or"))?
                        """)
                )
            } else {
                return .success(resolvedPronounCandidates.first!)
            }
        }

        // 3. Noun Resolution (Items and Locations)
        var potentialEntities: [EntityReference] = []

        // Check for items
        if let itemIDs = vocabulary.items[lowercasedNoun] {
            for itemID in itemIDs {
                potentialEntities.append(.item(itemID))
            }
        }

        // Check for locations
        if let locationID = vocabulary.locationNames[lowercasedNoun] {
            potentialEntities.append(.location(locationID))
        }

        guard !potentialEntities.isEmpty else {
            return .failure(.unknownNoun(noun))
        }

        // 4. Scope, Conditions, Modifiers, and Disambiguation
        var resolvedAndScopedEntities: [EntityReference] = []

        for entityRef in potentialEntities {
            switch entityRef {
            case .item(let itemID):
                // Debug returns success on first ID match
                if verb == .debug, itemID.rawValue == noun { return .success(entityRef) }

                // Use existing item-centric scoping and filtering
                let itemCandidates = gatherCandidates(
                    in: gameState,
                    requiredConditions: requiredConditions
                )
                if itemCandidates.keys.contains(itemID) { // Check if item is in the general candidate pool
                    // Pass the specific item's snapshot for modifier checking
                    if let item = gameState.items[itemID] {
                        if filterCandidates(item: item, modifiers: modifiers) {
                            resolvedAndScopedEntities.append(.item(itemID))
                        } else if !modifiers.isEmpty {
                            // Modifier mismatch, but item was in scope. Do not add, let error be handled later if no other match.
                        }
                    } else {
                        // This case should ideally not be reached if itemID came from vocabulary.items
                        // and gameState.items is consistent. Perhaps a warning or error here?
                        // For now, if item is nil, it won't be added.
                    }
                }
            case .location(let locationID):
                // Debug returns success on first ID match
                if verb == .debug, locationID.rawValue == noun { return .success(entityRef) }

                // Location scope: A named location is generally considered in scope.
                // Conditions for locations are less common in ObjectCondition but could be checked.
                guard modifiers.isEmpty else {
                    // Locations typically aren't modified by adjectives in the same way items are.
                    // Consider this a parse error for now or decide to ignore modifiers for locations.
                    // Returning nothing here, will lead to .modifierMismatch if no item matches.
                    continue // Skip this candidate if modifiers are present
                }
                // TODO: Add check for location-specific requiredConditions if they become a concept.
                // For now, if it's a location reference, it's valid if named.
                if let _ = gameState.locations[locationID] { // Verify location actually exists in current game state
                    resolvedAndScopedEntities.append(.location(locationID))
                }

            case .player: // Should have been handled by player alias check, but defensive
                if modifiers.isEmpty {
                    resolvedAndScopedEntities.append(.player)
                }
            }
        }

        if resolvedAndScopedEntities.isEmpty {
            // If we had potential entities but none survived scoping/modifiers
            if !potentialEntities.isEmpty && !modifiers.isEmpty {
                 return .failure(.modifierMismatch(noun: noun, modifiers: modifiers))
            }
            return .failure(.itemNotInScope(noun: noun)) // Or a more generic EntityNotInScope
        }

        if resolvedAndScopedEntities.count > 1 {
            // Enhanced ambiguity message logic
            let itemEntities = resolvedAndScopedEntities.compactMap { ref -> Item? in
                if case let .item(id) = ref {
                    gameState.items[id]
                } else {
                    nil
                }
            }
            if !itemEntities.isEmpty && itemEntities.count == resolvedAndScopedEntities.count {
                // All ambiguous are items
                let baseName = itemEntities.first?.name ?? "item"
                let allSameName = itemEntities.allSatisfy { $0.name == baseName }
                let adjectiveSets = itemEntities.map { Set($0.adjectives) }
                let allSameAdjectives = adjectiveSets.dropFirst().allSatisfy { $0 == adjectiveSets.first }
                if allSameName {
                    if allSameAdjectives {
                        // All truly identical
                        logger.error("""
                            StandardParser cannot distinguish between \
                            \(itemEntities.count) identical items
                            """)
                        return .failure(.ambiguity("Which \(baseName) do you mean?"))
                    } else {
                        // List with adjectives
                        let descriptions: [String] = itemEntities.map { item in
                            if let adj = item.adjectives.sorted().first {
                                "the \(adj) \(item.name)"
                            } else {
                                "the \(item.name)"
                            }
                        }
                        return .failure(
                            .ambiguity(
                                "Which do you mean, \(descriptions.commaListing("or"))?"
                            )
                        )
                    }
                }
            }
            // Fallback: original logic
            let descriptions = resolvedAndScopedEntities.map {
                entityRefToString($0, gameState: gameState)
            }
            return .failure(.ambiguity("Which do you mean: \(descriptions.commaListing("or"))?"))
        }

        return .success(resolvedAndScopedEntities.first!)
    }

    /// Resolves ALL keywords to multiple objects based on verb and conditions.
    func resolveAllObjects(
        verb: VerbID,
        modifiers: [String],
        in gameState: GameState,
        using vocabulary: Vocabulary,
        requiredConditions: ObjectCondition
    ) -> Result<[EntityReference], ParseError> {
        // Get all candidates that match the required conditions
        let itemCandidates = gatherCandidates(
            in: gameState,
            requiredConditions: requiredConditions
        )
        
        // Filter candidates based on verb-specific criteria
        var validItems: [Item] = []
        
        for item in itemCandidates.values {
            // Apply verb-specific filtering (similar to Zork's TAKEBIT, etc.)
            var isValidForVerb = false
            
            switch verb {
            case .take:
                // For TAKE ALL, only include takable items not already held
                isValidForVerb = item.hasFlag(.isTakable) && item.parent != .player
            case .drop:
                // For DROP ALL, only include items currently held by player
                isValidForVerb = item.parent == .player
            case .examine:
                // For EXAMINE ALL, include all visible items
                isValidForVerb = true
            default:
                // For other verbs, include all items (let action handler decide)
                isValidForVerb = true
            }
            
            if isValidForVerb {
                // Apply modifier filtering if any modifiers are specified
                if filterCandidates(item: item, modifiers: modifiers) {
                    validItems.append(item)
                }
            }
        }
        
        // Sort items for consistent ordering (by name, then by ID)
        validItems.sort { lhs, rhs in
            if lhs.name != rhs.name {
                return lhs.name < rhs.name
            }
            return lhs.id.rawValue < rhs.id.rawValue
        }
        
        guard !validItems.isEmpty else {
            // Return appropriate error based on context
            if modifiers.isEmpty {
                            switch verb {
            case .take:
                return .failure(.itemNotInScope(noun: "There is nothing here to take."))
            case .drop:
                return .failure(.itemNotInScope(noun: "You aren't carrying anything."))
            default:
                return .failure(.itemNotInScope(noun: "There is nothing here."))
            }
            } else {
                return .failure(.modifierMismatch(noun: "all", modifiers: modifiers))
            }
        }
        
        // Convert to EntityReferences
        let entityRefs = validItems.map { EntityReference.item($0.id) }
        return .success(entityRefs)
    }

    /// Gathers all potential candidate ItemIDs currently in scope and matching required conditions.
    /// NOTE: This function remains item-centric for now. It's used by `resolveObject` for item candidates.
    func gatherCandidates(
        in gameState: GameState,
        requiredConditions: ObjectCondition
    ) -> [ItemID: Item] {
        var candidates: [ItemID: Item] = [:]
        let currentLocationID = gameState.player.currentLocationID
        let allItems = gameState.items

        let mustBeHeld = requiredConditions.contains(.held)
        let mustBeInRoom = requiredConditions.contains(.inRoom)
        let mustBeOnGround = requiredConditions.contains(.onGround)
        let mustBePerson = requiredConditions.contains(.person)
        let mustBeContainer = requiredConditions.contains(.container)

        func checkItemConditions(_ item: Item) -> Bool {
            if mustBePerson && !item.hasFlag(.isPerson) { return false }
            if mustBeContainer && !item.hasFlag(.isContainer) { return false }
            return true
        }

        func gatherRecursive(parentEntity: ParentEntity, currentDepth: Int = 0, maxDepth: Int = 5) {
            guard currentDepth <= maxDepth else { return }

            for item in allItems.values where item.parent == parentEntity {
                if checkItemConditions(item) {
                    var meetsScopeCondition = false
                    if mustBeHeld { meetsScopeCondition = (item.parent == .player) }
                    else if mustBeOnGround { meetsScopeCondition = (item.parent == .location(currentLocationID)) }
                    else if mustBeInRoom {
                        let isGlobal = gameState.locations[currentLocationID]?.localGlobals.contains(item.id) ?? false
                        meetsScopeCondition = (item.parent == .location(currentLocationID) || isGlobal)
                    }
                    else {
                         if item.parent == .player || item.parent == .location(currentLocationID) { meetsScopeCondition = true }
                         else if case .item(let containerID) = item.parent {
                             if let container = allItems[containerID],
                                (container.parent == .player || container.parent == .location(currentLocationID)) {
                                 let isContainerOpen = container.attributes[.isOpen]?.toBool ?? false
                                 if (container.hasFlag(.isContainer) && isContainerOpen) || container.hasFlag(.isSurface) {
                                     meetsScopeCondition = true
                                 }
                             }
                         } else if gameState.locations[currentLocationID]?.localGlobals.contains(item.id) ?? false {
                              meetsScopeCondition = true
                         }
                    }

                    if meetsScopeCondition {
                        candidates[item.id] = item
                    }
                }

                let isContainerOpen = item.attributes[.isOpen]?.toBool ?? false
                if (item.hasFlag(.isContainer) && isContainerOpen) || item.hasFlag(.isSurface) {
                     gatherRecursive(parentEntity: .item(item.id), currentDepth: currentDepth + 1)
                }
            }
        }

        gatherRecursive(parentEntity: .player)
        gatherRecursive(parentEntity: .location(currentLocationID))

        if mustBeInRoom || (!mustBeHeld && !mustBeOnGround) {
            if let location = gameState.locations[currentLocationID] {
                for itemID in location.localGlobals {
                    if let globalItem = allItems[itemID], checkItemConditions(globalItem) {
                        candidates[itemID] = globalItem
                    }
                }
            }
        }

        return candidates
    }

    /// Filters a set of candidate ItemIDs based on a list of required modifiers (adjectives).
    func filterCandidates(
        item: Item,
        modifiers: [String]
    ) -> Bool {
        guard !modifiers.isEmpty else {
            return true // No modifiers, the item is a valid match by default
        }

        let lowercasedModifiers = Set(modifiers.map { $0.lowercased() })
        return lowercasedModifiers.isSubset(of: Set(item.adjectives.map { $0.lowercased() }))
    }

    // MARK: - Private Helpers (New/Modified for Syntax Matching)

    /// Helper to convert an EntityReference to a descriptive string for ambiguity messages.
    private func entityRefToString(
        _ reference: EntityReference,
        gameState: GameState
    ) -> String {
        switch reference {
        case .item(let id):
            "the \(gameState.items[id]?.name ?? id.rawValue)"
        case .location(let id):
            "the \(gameState.locations[id]?.name ?? id.rawValue)"
        case .player:
            "yourself"
        }
    }

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
                case .preposition:
                    if vocabulary.prepositions.contains(currentToken) {
                        isBoundaryToken = true
                    }
                case .direction:
                    if vocabulary.directions.keys.contains(currentToken) {
                        isBoundaryToken = true
                    }
                case .verb:
                    if vocabulary.verbSynonyms.keys.contains(currentToken) {
                        isBoundaryToken = true
                    }
                case .particle(let expectedParticle):
                    if currentToken == expectedParticle {
                        isBoundaryToken = true
                    }
                case .directObject, .indirectObject:
                    break
                }

                if isBoundaryToken {
                    return boundaryIndex
                }
            }

            boundaryIndex += 1
        }

        return boundaryIndex
    }
}

// Helper to access failure value easily (avoids force unwrap)
// Moved to file scope
private extension Result where Success == EntityReference?, Failure == ParseError {
    var failureValue: Failure? {
        guard case .failure(let error) = self else { return nil }
        return error
    }
}
