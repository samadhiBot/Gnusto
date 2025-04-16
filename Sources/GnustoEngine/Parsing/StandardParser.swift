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

        // 5. Identify Verb
        guard let verbIndex = significantTokens.firstIndex(where: { vocabulary.verbs.keys.contains($0) }) else {
            // If no verb found, *maybe* it's an implicit direction?
            // Consider if "NORTH HOUSE" should imply "GO NORTH HOUSE"? ZIL often did.
            // For now, stick to explicit verbs or single-word directions.
            return .failure(.unknownVerb(significantTokens.first ?? significantTokens.joined(separator: " "))) // Use first word if available
        }
        let verbWord = significantTokens[verbIndex]
        guard let verbID = vocabulary.verbs[verbWord] else {
            return .failure(.internalError("Verb word '\(verbWord)' found in keys but not dictionary."))
        }

        // 5. Get Syntax Rules for the Verb
        guard let rules = vocabulary.syntaxRules[verbID], !rules.isEmpty else {
            // If no rules defined, assume simple V or V+DO (like original basic parser)
            // TODO: Or should this be an error? Requires verbs to have syntax.
            // Let's try basic V+DO fallback for now.
            let phrase = significantTokens[(verbIndex + 1)...]
            let (noun, mods) = extractNounAndMods(from: Array(phrase), vocabulary: vocabulary)
            if let noun = noun {
                let resolveResult = resolveObject(noun: noun, modifiers: mods, isPronoun: vocabulary.isPronoun(noun), in: gameState, using: vocabulary, requiredConditions: .none)
                switch resolveResult {
                case .success(let objID):
                    let command = Command(verbID: verbID, directObject: objID, directObjectModifiers: mods, rawInput: input)
                    return .success(command)
                case .failure(let error):
                    return .failure(error)
                }
            } else {
                 // Just the verb
                 let command = Command(verbID: verbID, rawInput: input)
                 return .success(command)
            }
        }

        // 6. Match Tokens Against Syntax Rules
        var successfulParse: Command? = nil
        var bestError: ParseError? = nil // Keep track of the most informative error

        for rule in rules {
            let matchResult = matchRule(rule: rule, tokens: significantTokens, verbIndex: verbIndex, vocabulary: vocabulary, gameState: gameState, originalInput: input)

            switch matchResult {
            case .success(let command):
                // Found a successful match! (Could potentially find multiple? ZIL prioritized)
                // For now, take the first success.
                successfulParse = command
                bestError = nil // Clear any previous error if we find success
                break // Exit loop on first success
            case .failure(let currentError):
                // Prioritize resolution errors over grammar errors
                if bestError == nil || (isResolutionError(currentError) && !isResolutionError(bestError!)) {
                     bestError = currentError
                }
                // Continue trying other rules
            }
            if successfulParse != nil { break } // Exit outer loop if success found
        }

        // 7. Return Result
        if let command = successfulParse {
            return .success(command)
        } else if let error = bestError {
            // Return the best error encountered if no rule matched successfully
            return .failure(error)
        } else {
            // Should not happen if rules exist but none matched and no error recorded
            return .failure(.internalError("Syntax rules existed but none matched and no error recorded for input: \(input)"))
        }
    }

    /// Splits the input string into lowercase tokens.
    internal func tokenize(input: String) -> [String] {
        // Simple whitespace and punctuation separation, converts to lowercase.
        // ZIL tokenization was more complex (e.g., dictionary separators).
        input.lowercased()
             .components(separatedBy: .whitespacesAndNewlines.union(.punctuationCharacters))
             .filter { !$0.isEmpty }
    }

    /// Filters out noise words from a token list.
    internal func removeNoise(tokens: [String], noiseWords: Set<String>) -> [String] {
        tokens.filter { !noiseWords.contains($0) }
    }

    // MARK: - Syntax Matching Logic (New)

    /// Attempts to match a sequence of tokens against a specific SyntaxRule.
    private func matchRule(rule: SyntaxRule, tokens: [String], verbIndex: Int, vocabulary: Vocabulary, gameState: GameState, originalInput: String) -> Result<Command, ParseError> {

        let verbWord = tokens[verbIndex]
        guard let verbID = vocabulary.verbs[verbWord] else { return .failure(.internalError("Verb disappeared?")) } // Should be safe

        var tokenCursor = verbIndex + 1
        var directObjectPhraseTokens: [String] = []
        var indirectObjectPhraseTokens: [String] = []
        var matchedPreposition: String? = nil
        var matchedDirection: Direction? = nil // Store the matched direction

        // Iterate through the expected pattern *after* the verb. Assumes pattern[0] is .verb
        for patternIndex in 1..<rule.pattern.count {
            let tokenType = rule.pattern[patternIndex]

            guard tokenCursor < tokens.count else {
                // Ran out of input tokens but pattern expected more
                // Check if remaining expected tokens are optional (e.g., only objects)
                let remainingPattern = rule.pattern[patternIndex...]
                let onlyObjectsRemain = remainingPattern.allSatisfy { $0 == .directObject || $0 == .indirectObject }
                if onlyObjectsRemain {
                     break // Okay to end early if only optional objects remain
                } else {
                    return .failure(.badGrammar("Command seems incomplete, expected more input like '\(tokenType)'."))
                }
            }

            switch tokenType {
            case .verb: continue // Should be pattern[0], skipped by loop start

            case .directObject:
                // Consume tokens until next expected pattern element (preposition?) or end
                let phraseEndIndex = findEndOfNounPhrase(startIndex: tokenCursor, tokens: tokens, pattern: rule.pattern, patternIndex: patternIndex, vocabulary: vocabulary)

                // Ensure we consume at least one token if DO is expected.
                guard phraseEndIndex > tokenCursor else {
                    let context = (tokenCursor < tokens.count) ? "'\(tokens[tokenCursor])'" : "end of input"
                    return .failure(.badGrammar("Expected a direct object phrase for verb '\(verbID.rawValue)', but found \(context)."))
                }
                directObjectPhraseTokens = Array(tokens[tokenCursor..<phraseEndIndex])
                tokenCursor = phraseEndIndex

            case .preposition:
                let currentToken = tokens[tokenCursor]
                let expectedPrep = rule.requiredPreposition // May be nil
                let isKnownPrep = vocabulary.prepositions.contains(currentToken)

                // Check if the rule requires a specific preposition
                if let required = expectedPrep {
                    guard currentToken == required else {
                        return .failure(.badGrammar("Expected preposition '\(required)' but found '\(currentToken)'."))
                    }
                } else {
                    // Rule expects *any* preposition here
                    guard isKnownPrep else {
                         return .failure(.badGrammar("Expected a preposition but found '\(currentToken)'."))
                    }
                }
                // If we reach here, the preposition is valid for the rule.
                matchedPreposition = currentToken
                tokenCursor += 1 // Consume the preposition token

            case .indirectObject:
                // Consume remaining tokens until the end
                 let phraseEndIndex = findEndOfNounPhrase(startIndex: tokenCursor, tokens: tokens, pattern: rule.pattern, patternIndex: patternIndex, vocabulary: vocabulary)
                 // Ensure we consume at least one token if IO is expected.
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
                     tokenCursor += 1 // Consume the direction token
                 } else {
                     return .failure(.badGrammar("Expected a direction (like north, s, up) but found '\(currentToken)'."))
                 }
            }
        }

        // After iterating through the pattern, check if any input tokens remain unconsumed.
        // This indicates extra words that didn't fit the pattern.
        if tokenCursor < tokens.count {
            return .failure(.badGrammar("Unexpected words found after command: '\(Array(tokens[tokenCursor...]).joined(separator: " "))'"))
        }


        // --- Object Resolution ---
        // Use the extracted token arrays
        let (doNounExtracted, doModsExtracted) = extractNounAndMods(from: directObjectPhraseTokens, vocabulary: vocabulary)
        let (ioNounExtracted, ioModsExtracted) = extractNounAndMods(from: indirectObjectPhraseTokens, vocabulary: vocabulary)

        // Determine the noun/mods to use for resolution, falling back to last word if no known noun found
        let nounToResolveDO = doNounExtracted ?? directObjectPhraseTokens.last
        let modsToUseDO = (doNounExtracted != nil) ? doModsExtracted : Array(directObjectPhraseTokens.dropLast())

        let nounToResolveIO = ioNounExtracted ?? indirectObjectPhraseTokens.last
        let modsToUseIO = (ioNounExtracted != nil) ? ioModsExtracted : Array(indirectObjectPhraseTokens.dropLast())

        // Resolve Direct Object
        let resolvedDirectObjectResult: Result<ItemID?, ParseError>
        if rule.pattern.contains(.directObject) {
             // Attempt resolution if a potential noun was identified for the DO slot
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
                 // No phrase tokens were consumed for the DO slot by findEndOfNounPhrase
                 return .failure(.badGrammar("Missing direct object phrase for verb '\(verbID.rawValue)'."))
             }
        } else {
             resolvedDirectObjectResult = .success(nil) // Rule doesn't expect DO
        }

        // Resolve Indirect Object
        let resolvedIndirectObjectResult: Result<ItemID?, ParseError>
        if rule.pattern.contains(.indirectObject) {
            // Attempt resolution if a potential noun was identified for the IO slot
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
                // No phrase tokens were consumed for the IO slot by findEndOfNounPhrase
                return .failure(.badGrammar("Missing indirect object phrase for verb '\(verbID.rawValue)'."))
            }
        } else {
            resolvedIndirectObjectResult = .success(nil) // Rule doesn't expect IO
        }

        // --- Build Command ---
        switch (resolvedDirectObjectResult, resolvedIndirectObjectResult) {
        case (.success(let doID), .success(let ioID)):
            let command = Command(
                verbID: verbID,
                directObject: doID,
                directObjectModifiers: doModsExtracted,
                indirectObject: ioID,
                indirectObjectModifiers: ioModsExtracted,
                preposition: matchedPreposition,
                direction: matchedDirection,
                rawInput: originalInput
            )
            return .success(command)
        case (.failure(let error), _): return .failure(error)
        case (_, .failure(let error)): return .failure(error)
        }
    }

    /// Extracts the likely noun and preceding modifiers from a phrase.
    /// Filters noise words, identifies known nouns, and assumes the last known noun is primary.
    private func extractNounAndMods(from phrase: [String], vocabulary: Vocabulary) -> (noun: String?, mods: [String]) {
        // 1. Filter out noise words
        let significantPhrase = phrase.filter { !vocabulary.noiseWords.contains($0) }
        guard !significantPhrase.isEmpty else { return (nil, []) }

        // 2. Identify known nouns and their indices
        var knownNounIndices: [Int] = []
        for (index, word) in significantPhrase.enumerated() {
            // Check if word is known item noun OR a known pronoun
            let isItemNoun = vocabulary.items.keys.contains(word)
            let isPronoun = (vocabulary.pronouns.contains(word))
            if isItemNoun || isPronoun {
                knownNounIndices.append(index)
            }
        }

        // 3. Determine the primary noun (assume last known noun)
        guard let lastNounIndex = knownNounIndices.last else {
            // No known noun found. Maybe it's just modifiers? Or an unknown word?
            // For now, return no noun and all significant words as potential modifiers.
            // This might be wrong if the input was just "xyzzy".
            // TODO: Consider returning an error or handling unknown single words?
            return (nil, significantPhrase)
        }
        let noun = significantPhrase[lastNounIndex]

        // 4. Collect modifiers (words before the last noun that aren't other known nouns)
        var mods: [String] = []
        for index in 0..<lastNounIndex {
            // Only include words that are *not* identified as known nouns themselves.
            // Avoids treating "small box key" as noun=key, mods=["small", "box"]
            if !knownNounIndices.contains(index) {
                mods.append(significantPhrase[index])
            }
        }

        return (noun, mods)
    }

    // MARK: - Object Resolution Helpers

    /// Resolves a noun phrase (noun + modifiers) to a specific ItemID within the game context.
    /// Incorporates checking required conditions based on the SyntaxRule.
    internal func resolveObject(noun: String, modifiers: [String], isPronoun: Bool, in gameState: GameState, using vocabulary: Vocabulary, requiredConditions: ObjectCondition) -> Result<ItemID?, ParseError> { // Added conditions

        // --- Pronoun Handling (remains largely the same, but might check conditions?) ---
        if isPronoun {
            // TODO: Should pronoun resolution also check conditions like .held, .inRoom?
            // ZIL likely did this. For now, we check basic pronoun logic.
            guard modifiers.isEmpty else {
                return .failure(.badGrammar("Pronouns like '\(noun)' usually cannot be modified."))
            }
            guard let referredIDs = gameState.pronouns[noun] else {
                return .failure(.pronounNotSet(pronoun: noun))
            }
            guard !referredIDs.isEmpty else {
                 return .failure(.pronounNotSet(pronoun: noun))
            }
            let candidatesInScope = gatherCandidates(in: gameState, requiredConditions: requiredConditions) // Pass conditions
            let resolvedIDsInScope = referredIDs.filter { candidatesInScope.keys.contains($0) }
            if resolvedIDsInScope.isEmpty {
                return .failure(.pronounRefersToOutOfScopeItem(pronoun: noun))
            } else if resolvedIDsInScope.count > 1 {
                 return .failure(.ambiguousPronounReference("Which one of \"\(noun)\" do you mean?"))
            } else {
                return .success(resolvedIDsInScope.first!)
            }
        }

        // --- Regular Noun Handling ---
        guard let potentialItemIDs = vocabulary.items[noun] else {
            return .failure(.unknownNoun(noun))
        }

        // Gather candidates IN SCOPE and matching CONDITIONS
        let candidatesMatchingScopeAndConditions = gatherCandidates(in: gameState, requiredConditions: requiredConditions)
        let relevantCandidateIDs = potentialItemIDs.filter { candidatesMatchingScopeAndConditions.keys.contains($0) }

        guard !relevantCandidateIDs.isEmpty else {
             // No items for this noun match the required scope/conditions (e.g., need .held but it's on ground)
             // This could be .itemNotInScope or a more specific error based on conditions.
             // For now, stick with .itemNotInScope.
            return .failure(.itemNotInScope(noun: noun))
        }

        // Filter by Modifiers
        if modifiers.isEmpty {
            if relevantCandidateIDs.count > 1 {
                return .failure(.ambiguity("Which \(noun) do you mean?"))
            } else {
                return .success(relevantCandidateIDs.first!)
            }
        } else {
            // Pass the relevant candidates (already scoped/conditioned) to filter by adjectives
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
    internal func gatherCandidates(in gameState: GameState, requiredConditions: ObjectCondition) -> [ItemID: Item] { // Added conditions
        var candidates: [ItemID: Item] = [:]
        let currentLocationID = gameState.player.currentLocationID
        let allItems = gameState.items

        // --- Filter Logic based on requiredConditions ---
        let mustBeHeld = requiredConditions.contains(.held)
        let mustBeInRoom = requiredConditions.contains(.inRoom) // Explicitly in room (incl globals)
        let mustBeOnGround = requiredConditions.contains(.onGround) // Only directly in room
        let mustBePerson = requiredConditions.contains(.person)
        let mustBeContainer = requiredConditions.contains(.container)
        // TODO: Handle .allowsMultiple? Maybe return Set instead?

        func checkItemConditions(_ item: Item) -> Bool {
            if mustBePerson && !item.hasProperty(.person) { return false }
            if mustBeContainer && !item.hasProperty(.container) { return false }
            // ... add checks for other boolean conditions ...
            return true
        }

        // Function to recursively gather items meeting base scope and conditions
        func gatherRecursive(parentEntity: ParentEntity, currentDepth: Int = 0, maxDepth: Int = 5) {
            guard currentDepth <= maxDepth else { return } // Prevent infinite loops

            for item in allItems.values where item.parent == parentEntity {
                if checkItemConditions(item) { // Check basic property conditions first

                    // Check scope conditions based on requirement
                    var meetsScopeCondition = false
                    if mustBeHeld { meetsScopeCondition = (item.parent == .player) }
                    else if mustBeOnGround { meetsScopeCondition = (item.parent == .location(currentLocationID)) }
                    else if mustBeInRoom { // In room OR global
                        let isGlobal = gameState.locations[currentLocationID]?.globals.contains(item.id) ?? false
                        meetsScopeCondition = (item.parent == .location(currentLocationID) || isGlobal)
                    }
                    else { // No specific location condition, just needs to be reachable (basic scope)
                         // This part re-implements the basic scope check from previous version
                         if item.parent == .player || item.parent == .location(currentLocationID) { meetsScopeCondition = true }
                         else if case .item(let containerID) = item.parent {
                             if let container = allItems[containerID],
                                (container.parent == .player || container.parent == .location(currentLocationID)),
                                (container.hasProperty(.container) && container.hasProperty(.open)) || container.hasProperty(.surface) {
                                 meetsScopeCondition = true // Reachable inside/on accessible container/surface
                             }
                         } else if gameState.locations[currentLocationID]?.globals.contains(item.id) ?? false {
                              meetsScopeCondition = true // Global in room
                         }
                    }

                    if meetsScopeCondition {
                        candidates[item.id] = item
                    }
                }

                // Recurse into open containers/surfaces regardless of item meeting conditions,
                // as children might meet conditions.
                if (item.hasProperty(.container) && item.hasProperty(.open)) || item.hasProperty(.surface) {
                     gatherRecursive(parentEntity: .item(item.id), currentDepth: currentDepth + 1)
                }
            }
        }

        // Start gathering from player inventory and current location
        gatherRecursive(parentEntity: .player)
        gatherRecursive(parentEntity: .location(currentLocationID))

        // Explicitly add globals if condition is .inRoom or no condition
        if mustBeInRoom || (!mustBeHeld && !mustBeOnGround) {
             if let location = gameState.locations[currentLocationID] {
                for itemID in location.globals {
                    if let globalItem = allItems[itemID], checkItemConditions(globalItem) {
                         // Check conditions again for the global item itself
                        candidates[itemID] = globalItem
                    }
                }
            }
        }

        // TODO: Consider light source / darkness
        return candidates
    }

    /// Filters a set of candidate ItemIDs based on a list of required modifiers (adjectives).
    internal func filterCandidates(ids: Set<ItemID>, modifiers: [String], candidates: [ItemID: Item]) -> Set<ItemID> {
        guard !modifiers.isEmpty else {
            return ids // No modifiers to filter by
        }

        let lowercasedModifiers = Set(modifiers.map { $0.lowercased() })

        return ids.filter { itemID in
            guard let item = candidates[itemID] else { return false }
            // Check if all provided modifiers are present in the item's adjectives
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
    private func findEndOfNounPhrase(startIndex: Int, tokens: [String], pattern: [SyntaxTokenType], patternIndex: Int, vocabulary: Vocabulary) -> Int {
        var endIndex = startIndex
        let nextPatternIndex = patternIndex + 1
        let nextExpectedType: SyntaxTokenType? = (nextPatternIndex < pattern.count) ? pattern[nextPatternIndex] : nil

        while endIndex < tokens.count {
            let currentToken = tokens[endIndex]

            // Check if the current token signals the start of the *next* pattern element.
            if let nextType = nextExpectedType {
                var stop = false
                switch nextType {
                case .preposition:
                    if vocabulary.prepositions.contains(currentToken) {
                        // Check if the specific preposition required by the rule is found *later*
                        // This is tricky. For now, simplest: stop if *any* preposition is found
                        // when a preposition is expected next.
                        stop = true
                    }
                case .directObject, .indirectObject:
                    // If the next element is another object, how do we separate them?
                    // Usually by a conjunction ("and") or context.
                    // Simple approach: Assume the current noun phrase ends here if we encounter
                    // something that looks like the start of the *next* object phrase.
                    // Requires smarter noun identification. Deferring this complexity.
                    break // Continue consuming for now
                case .verb:
                     // Seeing a verb likely ends the current noun phrase.
                     if vocabulary.verbs.keys.contains(currentToken) {
                         stop = true
                     }
                case .direction:
                    // If the next expected token is a direction, and the current token IS a direction,
                    // then the noun phrase ends here.
                    if vocabulary.directions.keys.contains(currentToken) {
                        stop = true
                    }
                }
                if stop {
                    return endIndex // Stop *before* the token that matches the next pattern element type.
                }
            }

            // TODO: Add more sophisticated checks? Stop if currentToken is clearly
            // not an adjective or noun suitable for the current phrase?
            // E.g., if we see a preposition here but the *next* expected type isn't preposition.

            // Consume the current token as part of the noun phrase
            endIndex += 1
        }

        // If we reach the end, the phrase extends to the end of the tokens.
        return endIndex
    }

    /// Determines if a ParseError is related to object resolution issues.
    private func isResolutionError(_ error: ParseError) -> Bool {
        switch error {
        case .unknownNoun, .itemNotInScope, .modifierMismatch, .ambiguity, .pronounNotSet, .pronounRefersToOutOfScopeItem, .ambiguousPronounReference:
            return true
        case .emptyInput, .unknownVerb, .badGrammar, .internalError:
            return false
        }
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
