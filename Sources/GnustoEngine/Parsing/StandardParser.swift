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
        var matchedVerbID: VerbID? = nil
        var verbTokenCount = 0
        var verbStartIndex = 0

        // Iterate through possible starting positions for the verb
        for i in 0..<significantTokens.count {
            var longestMatchLength = 0
            var potentialMatchID: VerbID? = nil

            // Check token sequences starting from index i
            for length in (1...min(4, significantTokens.count - i)).reversed() { // Check up to 4-word verbs, reversed for longest match first
                let subSequence = significantTokens[i..<(i + length)]
                let verbPhrase = subSequence.joined(separator: " ")

                if let foundVerbID = vocabulary.verbs[verbPhrase] {
                    print("DEBUG: Vocab lookup success: '\(verbPhrase)' maps to \(foundVerbID)")
                    // Found a potential match
                    if length > longestMatchLength {
                        longestMatchLength = length
                        potentialMatchID = foundVerbID
                        // Don't break yet, continue checking shorter phrases from this start index
                        // in case a shorter phrase is also a verb (though less likely with longest-first check)
                    }
                }
            }

            // If we found the longest possible match starting at index i, use it and stop searching
            if longestMatchLength > 0 {
                matchedVerbID = potentialMatchID
                verbTokenCount = longestMatchLength
                verbStartIndex = i
                break // Found the first (and longest) verb match, stop outer loop
            }
        }

        guard let verbID = matchedVerbID else {
             // No known single or multi-word verb/synonym found
             return .failure(.unknownVerb(significantTokens.first ?? significantTokens.joined(separator: " "))) // Use first word as guess
        }

        // 5b. Get Syntax Rules for the Verb
        let rules = vocabulary.syntaxRules[verbID] ?? [] // Get rules or empty array
        print("DEBUG: Rules fetched for \(verbID): \(rules)")

        if rules.isEmpty {
            // No explicit rules defined for this verb.
            // Succeed ONLY if the input was just the verb phrase.
            if significantTokens.count == verbTokenCount {
                let command = Command(verbID: verbID, rawInput: input)
                return .success(command)
            } else {
                // Verb found, but has extra words and no defined syntax rules.
                return .failure(.badGrammar("I understand the verb '\(verbID.rawValue)', but not the rest of that sentence."))
            }
        }

        // 6. Match Tokens Against Syntax Rules (using the non-empty `rules` array)
        var successfulParse: Command? = nil
        var bestError: ParseError? = nil

        for rule in rules {
            let matchResult = matchRule(
                rule: rule,
                tokens: significantTokens,
                verbStartIndex: verbStartIndex,
                vocabulary: vocabulary,
                gameState: gameState,
                originalInput: input
            )

            if case .success(let command) = matchResult {
                successfulParse = command
                bestError = nil // Clear error on success
                break // Found a match, exit the rule loop immediately
            } else if case .failure(let currentError) = matchResult {
                // Update bestError based on priority
                if bestError == nil || (isResolutionError(currentError) && !isResolutionError(bestError!)) {
                     bestError = currentError
                }
                // Continue to the next rule
            }
            // Removed the potentially problematic extra break check here
        }

        // 7. Return Result
        if let command = successfulParse {
            return .success(command) // Return success if a rule matched
        } else if let error = bestError {
             return .failure(error) // Return the best error if no rule matched
        } else {
             // This should only happen if 'rules' was empty AND the initial checks failed.
             // Or if matchRule somehow returned neither success nor failure.
             return .failure(.internalError("Parsing failed unexpectedly for input: \(input)"))
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
        vocabulary: Vocabulary,
        gameState: GameState,
        originalInput: String
    ) -> Result<Command, ParseError> {
        print("DEBUG: Attempting matchRule with rule: \(rule.pattern) against tokens: \(tokens)")

        let initialVerbWord = tokens[verbStartIndex]
        guard let initialVerbID = vocabulary.verbs[initialVerbWord] else { return .failure(.internalError("Verb disappeared?")) } // Should be safe

        var tokenCursor = verbStartIndex + 1
        var directObjectPhraseTokens: [String] = []
        var indirectObjectPhraseTokens: [String] = []
        var matchedPreposition: String? = nil
        var matchedDirection: Direction? = nil
        var matchedParticle: String? = nil // Added to store the matched particle

        // Iterate through the expected pattern *after* the verb. Assumes pattern[0] is .verb
        for patternIndex in 1..<rule.pattern.count {
            let tokenType = rule.pattern[patternIndex]

            guard tokenCursor < tokens.count else {
                // Ran out of input tokens but pattern expected more
                let remainingPattern = rule.pattern[patternIndex...]
                let onlyObjectsRemain = remainingPattern.allSatisfy { $0 == .directObject || $0 == .indirectObject }
                if onlyObjectsRemain {
                     break // Okay to end early if only optional objects remain
                } else {
                    // More specific error if we know what was expected
                    return .failure(.badGrammar("Command seems incomplete, expected more input like '\(tokenType)'."))
                }
            }

            switch tokenType {
            case .verb: continue // Should be pattern[0], skipped by loop start

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
                    return .failure(.badGrammar("Expected a direct object phrase for verb '\(initialVerbID.rawValue)', but found \(context)."))
                }
                directObjectPhraseTokens = Array(tokens[tokenCursor..<phraseEndIndex])
                tokenCursor = phraseEndIndex

            case .preposition:
                let currentToken = tokens[tokenCursor]
                let expectedPrep = rule.requiredPreposition
                let isKnownPrep = vocabulary.prepositions.contains(currentToken)
                if let required = expectedPrep {
                    guard currentToken == required else {
                        return .failure(.badGrammar("Expected preposition '\(required)' but found '\(currentToken)'."))
                    }
                } else {
                    guard isKnownPrep else {
                         return .failure(.badGrammar("Expected a preposition but found '\(currentToken)'."))
                    }
                }
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
                     return .failure(.badGrammar("Expected an indirect object phrase for verb '\(initialVerbID.rawValue)', but found \(context)."))
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
                    return .failure(.badGrammar("Expected '\(expectedParticle)' after '\(initialVerbWord)' but found '\(currentToken)'."))
                }
                matchedParticle = currentToken
                print("DEBUG: Matched particle '\(currentToken)' for initial verb '\(initialVerbWord)'")
                tokenCursor += 1 // Consume the particle token
            }
        }

        // After iterating through the pattern, check if any input tokens remain unconsumed.
        if tokenCursor < tokens.count {
            return .failure(.badGrammar("Unexpected words found after command: '\(Array(tokens[tokenCursor...]).joined(separator: " "))'"))
        }

        // --- Object Resolution ---
        let (doNounExtracted, doModsExtracted) = extractNounAndMods(from: directObjectPhraseTokens, vocabulary: vocabulary)
        let (ioNounExtracted, ioModsExtracted) = extractNounAndMods(from: indirectObjectPhraseTokens, vocabulary: vocabulary)

        let nounToResolveDO = doNounExtracted ?? directObjectPhraseTokens.last
        let modsToUseDO = (doNounExtracted != nil) ? doModsExtracted : Array(directObjectPhraseTokens.dropLast())

        let nounToResolveIO = ioNounExtracted ?? indirectObjectPhraseTokens.last
        let modsToUseIO = (ioNounExtracted != nil) ? ioModsExtracted : Array(indirectObjectPhraseTokens.dropLast())

        // Resolve Direct Object
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
                 // Return the more user-friendly badGrammar error
                 return .failure(.badGrammar("Expected a direct object phrase for verb '\(initialVerbID.rawValue)'."))
             }
        } else {
             resolvedDirectObjectResult = .success(nil)
        }

        // Resolve Indirect Object
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
                // Return the more user-friendly badGrammar error
                return .failure(.badGrammar("Expected an indirect object phrase for verb '\(initialVerbID.rawValue)'."))
            }
        } else {
            resolvedIndirectObjectResult = .success(nil)
        }

        // --- Determine Final Verb ID based on Particles ---
        print("DEBUG: Reached final verb ID check. initialVerbID=\(initialVerbID), matchedParticle=\(matchedParticle ?? "nil") for rule: \(rule.pattern)") // DEBUG PRINT
        var finalVerbID = initialVerbID // Default to the initial verb

        switch initialVerbID.rawValue {
        case "turn", "switch":
            // These verbs REQUIRE a particle ("on" or "off")
            guard let particle = matchedParticle else {
                // This *shouldn't* happen if rule matching worked, as all rules have particles.
                // Indicates internal inconsistency or bad rule match.
                return .failure(.internalError("Verb '\(initialVerbID.rawValue)' matched rule but particle missing."))
            }
            guard particle == "on" || particle == "off" else {
                // Matched a particle, but it wasn't "on" or "off"
                return .failure(.badGrammar("Expected 'on' or 'off' after '\(initialVerbID.rawValue)', not '\(particle)'."))
            }
            // Set the specific final ID based on the matched particle
            finalVerbID = (particle == "on") ? VerbID("turn_on") : VerbID("turn_off")

        case "blow":
            // This verb REQUIRES the "out" particle
            guard let particle = matchedParticle else {
                return .failure(.internalError("Verb 'blow' matched rule but particle missing."))
            }
            guard particle == "out" else {
                return .failure(.badGrammar("Expected 'out' after 'blow', not '\(particle)'."))
            }
            // Map "blow out" to "turn_off"
            finalVerbID = VerbID("turn_off")

        case "light":
            // This verb maps directly and should NOT have a particle
            guard matchedParticle == nil else {
                return .failure(.badGrammar("Verb 'light' doesn't take a particle like '\(matchedParticle!)'."))
            }
            finalVerbID = VerbID("turn_on")

        case "extinguish":
            // This verb maps directly and should NOT have a particle
            guard matchedParticle == nil else {
                return .failure(.badGrammar("Verb 'extinguish' doesn't take a particle like '\(matchedParticle!)'."))
            }
            finalVerbID = VerbID("turn_off")

        default:
            // Any other verb. Ensure no unexpected particle was matched.
            guard matchedParticle == nil else {
                return .failure(.badGrammar("Verb '\(initialVerbID.rawValue)' doesn't take a particle like '\(matchedParticle!)'."))
            }
            // finalVerbID remains the initialVerbID
        }

        // --- Build Command ---
        switch (resolvedDirectObjectResult, resolvedIndirectObjectResult) {
        case (.success(let doID), .success(let ioID)):
            let command = Command(
                verbID: finalVerbID, // Use the potentially modified verbID
                directObject: doID,
                directObjectModifiers: doModsExtracted,
                indirectObject: ioID,
                indirectObjectModifiers: ioModsExtracted,
                preposition: matchedPreposition,
                direction: matchedDirection,
                rawInput: originalInput
            )
            // ADD DEBUG PRINT HERE to see which rule actually succeeded
            print("DEBUG: matchRule SUCCESS. Matched rule: \(rule.pattern), finalVerbID: \(finalVerbID), particle: \(matchedParticle ?? "nil")")
            return .success(command)
        case (.failure(let error), _): return .failure(error)
        case (_, .failure(let error)): return .failure(error)
        }
    }

    /// Extracts the likely noun and preceding modifiers from a phrase.
    /// Filters noise words, identifies known nouns, and assumes the last known noun is primary.
    private func extractNounAndMods(
        from phrase: [String],
        vocabulary: Vocabulary
    ) -> (noun: String?, mods: [String]) {
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
            // Return nil noun and filter the phrase for valid modifiers only.
            let potentialMods = significantPhrase.filter { word in
                // A word is a potential modifier if it's NOT a known noun, verb, prep, or direction
                !vocabulary.items.keys.contains(word) &&
                !vocabulary.verbs.keys.contains(word) &&
                !vocabulary.prepositions.contains(word) &&
                !vocabulary.directions.keys.contains(word)
                // Note: Pronouns are implicitly handled as they'd be caught by knownNounIndices check
            }
            return (nil, potentialMods)
        }
        let noun = significantPhrase[lastNounIndex]

        // 4. Collect modifiers (words before the last noun that aren't other known words)
        var mods: [String] = []
        for index in 0..<lastNounIndex {
            let word = significantPhrase[index]
            // Exclude other known nouns, verbs, prepositions, and directions from being modifiers
            let isKnownNoun = knownNounIndices.contains(index)
            let isKnownVerb = vocabulary.verbs.keys.contains(word)
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
    ) -> Result<ItemID?, ParseError> { // Added conditions

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
    internal func gatherCandidates(
        in gameState: GameState,
        requiredConditions: ObjectCondition
    ) -> [ItemID: Item] { // Added conditions
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
    internal func filterCandidates(
        ids: Set<ItemID>,
        modifiers: [String],
        candidates: [ItemID: Item]
    ) -> Set<ItemID> {
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
    private func findEndOfNounPhrase(
        startIndex: Int,
        tokens: [String],
        pattern: [SyntaxTokenType],
        patternIndex: Int,
        vocabulary: Vocabulary
    ) -> Int {
        var boundaryIndex = startIndex // Use a separate index for the boundary
        let nextPatternIndex = patternIndex + 1

        while boundaryIndex < tokens.count {
            let currentToken = tokens[boundaryIndex]

            // Check if the current token signals the start of the *next* non-object pattern element.
            if nextPatternIndex < pattern.count {
                let nextExpectedType = pattern[nextPatternIndex]
                var isBoundaryToken = false

                switch nextExpectedType {
                case .preposition:
                    // Is the current token a preposition that marks the boundary?
                    if vocabulary.prepositions.contains(currentToken) {
                        isBoundaryToken = true
                    }
                case .direction:
                    // Is the current token a direction?
                    if vocabulary.directions.keys.contains(currentToken) {
                        isBoundaryToken = true
                    }
                case .verb:
                    // Is the current token a verb?
                    if vocabulary.verbs.keys.contains(currentToken) {
                        isBoundaryToken = true
                    }
                case .particle(let expectedParticle):
                    // Is the current token the specific particle expected?
                    if currentToken == expectedParticle {
                        isBoundaryToken = true
                    }
                case .directObject, .indirectObject:
                    // We don't automatically stop for subsequent objects.
                    break
                }

                if isBoundaryToken {
                    // Found the boundary. The noun phrase ends *before* this token.
                    return boundaryIndex
                }
            }

            // Haven't found the boundary; this token is part of the noun phrase.
            boundaryIndex += 1
        }

        // Reached the end of the input tokens.
        return boundaryIndex // which is now tokens.count
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
