import Foundation

/// A standard implementation of the Parser protocol.
/// Aims to replicate common ZIL parser behaviors.
public struct StandardParser: Parser {
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
            let command = Command(verbID: defaultGoVerbID, direction: direction, rawInput: input)
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

        print("%%% PARSER DEBUG: Matched Verb IDs: \(matchedVerbIDs), Verb Tokens: \(significantTokens[verbStartIndex..<(verbStartIndex + verbTokenCount)])")

        // Ensure at least one verb was matched
        guard !matchedVerbIDs.isEmpty else {
            // No known single or multi-word verb/synonym found
            return .failure(.unknownVerb(significantTokens.first ?? significantTokens.joined(separator: " "))) // Use first word as guess
        }

        // ***** NEW: Determine the single canonical VerbID to use *****
        // If multiple IDs matched (ambiguous synonym?), we might need error handling.
        // For now, assume the first one is the intended canonical ID.
        guard let canonicalVerbID = matchedVerbIDs.first else {
            // This should be impossible if matchedVerbIDs is not empty
            return .failure(.internalError("Verb matched, but no canonical ID found."))
        }
        print("%%% PARSER DEBUG: Determined canonicalVerbID: \(canonicalVerbID)")
        // TODO: Add check here if matchedVerbIDs.count > 1 and handle ambiguity?

        // 5b. Get Syntax Rules using the *canonical* ID
        var rulesForCanonicalVerb: [SyntaxRule] = []
        if let verbDef = vocabulary.verbDefinitions[canonicalVerbID] { // Use canonical ID
             rulesForCanonicalVerb = verbDef.syntax
        } else {
            // If canonical ID has no definition (shouldn't happen if vocab is consistent)
            // Handle simple verb-only case later if rules list ends up empty
        }

        // Handle cases where canonical verb exists but has NO rules...
        if rulesForCanonicalVerb.isEmpty && significantTokens.count > verbTokenCount {
            // Provide a generic error based on the canonical verb ID.
            return .failure(.badGrammar("I understand the verb '\(canonicalVerbID.rawValue)', but not the rest of that sentence."))
        }

        // 6. Match Tokens Against Syntax Rules
        var successfulParse: Command? = nil
        var bestError: ParseError? = nil

        for rule in rulesForCanonicalVerb { // Iterate rules for the canonical verb
            let matchResult = matchRule(
                rule: rule,
                tokens: significantTokens,
                verbStartIndex: verbStartIndex,
                verbID: canonicalVerbID, // <<< Pass the canonical ID
                _debugHook: { print("%%% PARSER DEBUG: Calling matchRule with verbID: \(canonicalVerbID)") }, // Add debug print
                vocabulary: vocabulary,
                gameState: gameState,
                originalInput: input
            )

            if case .success(let command) = matchResult {
                // Rule matched structurally. Now check prepositions.
                let inputPreposition = findInputPreposition(tokens: significantTokens, startIndex: verbStartIndex + verbTokenCount, vocabulary: vocabulary)

                if let requiredPrep = rule.requiredPreposition {
                    // Rule requires a specific preposition
                    if let inputPrep = inputPreposition {
                        // Input also has a preposition
                        if requiredPrep == inputPrep {
                            // PREPOSITIONS MATCH - DEFINITIVE SUCCESS
                            successfulParse = command
                            bestError = nil // Clear any previous error
                            break // Found the best possible match for this input
                        } else {
                            // PREPOSITIONS MISMATCH - Record error, continue
                            let mismatchError = ParseError.badGrammar("Preposition mismatch for verb '\(canonicalVerbID.rawValue)' (expected '\(requiredPrep)', found '\(inputPrep)').") // Use canonicalVerbID
                            if bestError == nil || shouldReplaceError(existing: bestError!, new: mismatchError) {
                                bestError = mismatchError
                            }
                            continue // Try next rule, this one is invalid for this input
                        }
                    } else {
                        // RULE REQUIRES PREP, INPUT HAS NONE - Record error, continue
                        let missingPrepError = ParseError.badGrammar("Verb '\(canonicalVerbID.rawValue)' requires preposition '\(requiredPrep)' which was missing.") // Use canonicalVerbID
                        if bestError == nil || shouldReplaceError(existing: bestError!, new: missingPrepError) {
                            bestError = missingPrepError
                        }
                        continue // Try next rule, this one is invalid for this input
                    }
                } else {
                    // RULE REQUIRES NO SPECIFIC PREPOSITION - DEFINITIVE SUCCESS (structurally)
                    // This rule is a valid interpretation of the input structure.
                    successfulParse = command
                    bestError = nil // Clear any previous error
                    break // Found a valid match
                }
            } else if case .failure(let currentError) = matchResult {
                // Structural failure reported by matchRule
                if bestError == nil || shouldReplaceError(existing: bestError!, new: currentError) {
                     bestError = currentError
                }
                // Continue to the next rule (implicit in loop structure)
            }
        } // End rule loop

        // 7. Return Result
        if let command = successfulParse {
            return .success(command)
        } else if let error = bestError { // Otherwise return best error found
             return .failure(error)
        } else {
            // Handle simple verb-only commands or internal error
             if rulesForCanonicalVerb.isEmpty && significantTokens.count == verbTokenCount { // Use rulesForCanonicalVerb
                 // Input was just a verb phrase matching a verb with no rules
                 let command = Command(verbID: canonicalVerbID, rawInput: input) // <<< Use canonical ID
                 return .success(command)
             } else {
                 // If we get here, rules existed, but none resulted in success or a recorded error.
                 // ... Provide a generic grammar error based on the canonical verb matched.
                 return .failure(.badGrammar("I understood '\(canonicalVerbID.rawValue)' but couldn't parse the rest of the sentence with its known grammar rules.")) // Use canonicalVerbID
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
    internal func tokenize(input: String) -> [String] {
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
    internal func removeNoise(
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
        verbID: VerbID,
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
        var matchedParticle: String? = nil

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
                    return .failure(.badGrammar("Expected a direct object phrase for verb '\(verbID.rawValue)', but found \(context)."))
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
                     return .failure(.badGrammar("Expected an indirect object phrase for verb '\(verbID.rawValue)', but found \(context)."))
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
                matchedParticle = currentToken
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

        let resolvedDirectObjectResult: Result<ItemID?, ParseError>
        if rule.pattern.contains(.directObject) {
             if let actualNoun = nounToResolveDO {
                 resolvedDirectObjectResult = resolveObject(
                     noun: actualNoun,
                     modifiers: modsToUseDO,
                     isPronoun: vocabulary.isPronoun(actualNoun),
                     in: gameState,
                     using: vocabulary,
                     requiredConditions: rule.directObjectConditions
                 )
             } else {
                 return .failure(.badGrammar("Expected a direct object phrase for verb '\(verbID.rawValue)'."))
             }
        } else {
             resolvedDirectObjectResult = .success(nil)
        }

        let resolvedIndirectObjectResult: Result<ItemID?, ParseError>
        if rule.pattern.contains(.indirectObject) {
            if let actualNoun = nounToResolveIO {
                resolvedIndirectObjectResult = resolveObject(
                    noun: actualNoun,
                    modifiers: modsToUseIO,
                    isPronoun: vocabulary.isPronoun(actualNoun),
                    in: gameState,
                    using: vocabulary,
                    requiredConditions: rule.indirectObjectConditions
                )
            } else {
                return .failure(.badGrammar("Expected an indirect object phrase for verb '\(verbID.rawValue)'."))
            }
        } else {
            resolvedIndirectObjectResult = .success(nil)
        }

        switch (resolvedDirectObjectResult, resolvedIndirectObjectResult) {
        case (.success(let doID), .success(let ioID)):
            let command = Command(
                verbID: verbID,
                directObject: doID,
                directObjectModifiers: modsToUseDO,
                indirectObject: ioID,
                indirectObjectModifiers: modsToUseIO,
                preposition: matchedPreposition,
                direction: matchedDirection,
                rawInput: originalInput
            )
            return .success(command)
        case (.failure(let error), _):
            print("%%% PARSER DEBUG: matchRule failed resolving DO: \(error)")
            return .failure(error)
        case (_, .failure(let error)):
            print("%%% PARSER DEBUG: matchRule failed resolving IO: \(error)")
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

        var knownNounIndices: [Int] = []
        for (index, word) in significantPhrase.enumerated() {
            let isItemNoun = vocabulary.items.keys.contains(word)
            let isPronoun = (vocabulary.pronouns.contains(word))
            if isItemNoun || isPronoun {
                knownNounIndices.append(index)
            }
        }

        guard let lastNounIndex = knownNounIndices.last else {
            let potentialMods = significantPhrase.filter { word in
                !vocabulary.items.keys.contains(word) &&
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

    /// Resolves a noun phrase (noun + modifiers) to a specific ItemID within the game context.
    /// Incorporates checking required conditions based on the SyntaxRule.
    internal func resolveObject(
        noun: String,
        modifiers: [String],
        isPronoun: Bool,
        in gameState: GameState,
        using vocabulary: Vocabulary,
        requiredConditions: ObjectCondition
    ) -> Result<ItemID?, ParseError> {
        if isPronoun {
            guard modifiers.isEmpty else {
                return .failure(.badGrammar("Pronouns like '\(noun)' usually cannot be modified."))
            }
            guard let referredIDs = gameState.pronouns[noun] else {
                return .failure(.pronounNotSet(pronoun: noun))
            }
            guard !referredIDs.isEmpty else {
                 return .failure(.pronounNotSet(pronoun: noun))
            }
            let candidatesInScope = gatherCandidates(in: gameState, requiredConditions: requiredConditions)
            let resolvedIDsInScope = referredIDs.filter { candidatesInScope.keys.contains($0) }
            if resolvedIDsInScope.isEmpty {
                return .failure(.pronounRefersToOutOfScopeItem(pronoun: noun))
            } else if resolvedIDsInScope.count > 1 {
                 return .failure(.ambiguousPronounReference("Which one of \"\(noun)\" do you mean?"))
            } else {
                return .success(resolvedIDsInScope.first!)
            }
        }

        guard let potentialItemIDs = vocabulary.items[noun] else {
            return .failure(.unknownNoun(noun))
        }

        let candidatesMatchingScopeAndConditions = gatherCandidates(in: gameState, requiredConditions: requiredConditions)
        let relevantCandidateIDs = potentialItemIDs.filter { candidatesMatchingScopeAndConditions.keys.contains($0) }

        guard !relevantCandidateIDs.isEmpty else {
             return .failure(.itemNotInScope(noun: noun))
        }

        if modifiers.isEmpty {
            if relevantCandidateIDs.count > 1 {
                return .failure(.ambiguity("Which \(noun) do you mean?"))
            } else {
                return .success(relevantCandidateIDs.first!)
            }
        } else {
            let matchingIDs = filterCandidates(ids: relevantCandidateIDs, modifiers: modifiers, candidates: candidatesMatchingScopeAndConditions)

            if matchingIDs.isEmpty {
                return .failure(.modifierMismatch(noun: noun, modifiers: modifiers))
            } else if matchingIDs.count > 1 {
                return .failure(.ambiguity("Which \(modifiers.joined(separator: " ")) \(noun) do you mean?"))
            } else {
                return .success(matchingIDs.first!)
            }
        }
    }

    /// Gathers all potential candidate ItemIDs currently in scope and matching required conditions.
    internal func gatherCandidates(
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
            if mustBePerson && !item.hasProperty(.person) { return false }
            if mustBeContainer && !item.hasProperty(.container) { return false }
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
                        let isGlobal = gameState.locations[currentLocationID]?.globals.contains(item.id) ?? false
                        meetsScopeCondition = (item.parent == .location(currentLocationID) || isGlobal)
                    }
                    else {
                         if item.parent == .player || item.parent == .location(currentLocationID) { meetsScopeCondition = true }
                         else if case .item(let containerID) = item.parent {
                             if let container = allItems[containerID],
                                (container.parent == .player || container.parent == .location(currentLocationID)),
                                (container.hasProperty(.container) && container.hasProperty(.open)) || container.hasProperty(.surface) {
                                 meetsScopeCondition = true
                             }
                         } else if gameState.locations[currentLocationID]?.globals.contains(item.id) ?? false {
                              meetsScopeCondition = true
                         }
                    }

                    if meetsScopeCondition {
                        candidates[item.id] = item
                    }
                }

                if (item.hasProperty(.container) && item.hasProperty(.open)) || item.hasProperty(.surface) {
                     gatherRecursive(parentEntity: .item(item.id), currentDepth: currentDepth + 1)
                }
            }
        }

        gatherRecursive(parentEntity: .player)
        gatherRecursive(parentEntity: .location(currentLocationID))

        if mustBeInRoom || (!mustBeHeld && !mustBeOnGround) {
             if let location = gameState.locations[currentLocationID] {
                for itemID in location.globals {
                    if let globalItem = allItems[itemID], checkItemConditions(globalItem) {
                         candidates[itemID] = globalItem
                    }
                }
            }
        }

        return candidates
    }

    /// Filters a set of candidate ItemIDs based on a list of required modifiers (adjectives).
    internal func filterCandidates(
        ids: Set<ItemID>,
        modifiers: [String],
        candidates: [ItemID: Item]
    ) -> Set<ItemID> {
        guard !modifiers.isEmpty else {
            return ids
        }

        let lowercasedModifiers = Set(modifiers.map { $0.lowercased() })

        return ids.filter { itemID in
            guard let item = candidates[itemID] else { return false }
            return lowercasedModifiers.isSubset(of: Set(item.adjectives.map { $0.lowercased() }))
        }
    }

    // Add public initializer if needed (structs get internal one by default)
    public init() {}

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
private extension Result where Success == ItemID?, Failure == ParseError {
    var failureValue: Failure? {
        guard case .failure(let error) = self else { return nil }
        return error
    }
}
