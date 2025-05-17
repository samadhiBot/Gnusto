import Foundation
import Logging

/// A standard implementation of the Parser protocol.
/// Aims to replicate common ZIL parser behaviors.
public struct StandardParser: Parser {
    public init() {}

    /// A logger used for unhandled error warnings.
    let logger = Logger(label: "com.samadhibot.Gnusto.StandardParser")

    /// Parses a raw input string into a structured `Command`.
    ///
    /// Follows a ZIL-inspired process:
    /// 1. Tokenize input.
    /// 2. Filter noise words.
    /// 3. Identify verb.
    /// 4. Identify noun phrases (direct/indirect objects, prepositions).
    /// 5. Resolve objects using game state and vocabulary.
    /// 6. Construct Command or return ParseError.
    ///
    /// - Parameters:
    ///   - input: The raw string entered by the player.
    ///   - vocabulary: The game's vocabulary, used to identify known words.
    ///   - gameState: The current state of the game, used for context.
    /// - Returns: A `Result` containing either a successfully parsed `Command` or a `ParseError`.
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

        // Filter out non-alphanumeric characters (except spaces used for separation)
        let allowedChars = CharacterSet.alphanumerics.union(.whitespaces)
        let sanitizedInput = String(input.unicodeScalars.filter { allowedChars.contains($0) })

        return sanitizedInput.lowercased()
             .components(separatedBy: .whitespacesAndNewlines)
             .filter { !$0.isEmpty }
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

        let (doNounExtracted, doModsExtracted) = extractNounAndMods(from: directObjectPhraseTokens, vocabulary: vocabulary)
        let (ioNounExtracted, ioModsExtracted) = extractNounAndMods(from: indirectObjectPhraseTokens, vocabulary: vocabulary)

        let nounToResolveDO = doNounExtracted ?? directObjectPhraseTokens.last
        let modsToUseDO = (doNounExtracted != nil) ? doModsExtracted : Array(directObjectPhraseTokens.dropLast())

        let nounToResolveIO = ioNounExtracted ?? indirectObjectPhraseTokens.last
        let modsToUseIO = (ioNounExtracted != nil) ? ioModsExtracted : Array(indirectObjectPhraseTokens.dropLast())

        let resolvedDirectObjectResult: Result<EntityReference?, ParseError>
        if rule.pattern.contains(.directObject) {
             if let actualNoun = nounToResolveDO {
                 resolvedDirectObjectResult = resolveObject(
                     noun: actualNoun,
                     verb: verb,
                     modifiers: modsToUseDO,
                     in: gameState,
                     using: vocabulary,
                     requiredConditions: rule.directObjectConditions
                 )
             } else {
                 return .failure(.badGrammar("Expected a direct object phrase for verb '\(verb)'."))
             }
        } else {
             resolvedDirectObjectResult = .success(nil)
        }

        let resolvedIndirectObjectResult: Result<EntityReference?, ParseError>
        if rule.pattern.contains(.indirectObject) {
            if let actualNoun = nounToResolveIO {
                resolvedIndirectObjectResult = resolveObject(
                    noun: actualNoun,
                    verb: verb,
                    modifiers: modsToUseIO,
                    in: gameState,
                    using: vocabulary,
                    requiredConditions: rule.indirectObjectConditions
                )
            } else {
                return .failure(.badGrammar("Expected an indirect object phrase for verb '\(verb)'."))
            }
        } else {
            resolvedIndirectObjectResult = .success(nil)
        }

        switch (resolvedDirectObjectResult, resolvedIndirectObjectResult) {
        case (.success(let doRef), .success(let ioRef)):
            let command = Command(
                verb: verb,
                directObject: doRef,
                directObjectModifiers: modsToUseDO,
                indirectObject: ioRef,
                indirectObjectModifiers: modsToUseIO,
                preposition: matchedPreposition,
                direction: matchedDirection,
                rawInput: originalInput
            )
            return .success(command)
        case (.failure(let error), _):
            return .failure(error)
        case (_, .failure(let error)):
            return .failure(error)
        }
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
            if isItemNoun || isLocationNoun || isPlayerAlias || isPronoun {
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
                !vocabulary.directions.keys.contains(word)
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
                            💥 StandardParser cannot distinguish between \
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
