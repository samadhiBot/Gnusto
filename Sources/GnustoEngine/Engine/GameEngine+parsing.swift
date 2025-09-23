import Foundation

// MARK: - Parsing and Error Handling

extension GameEngine {
    /// Reports user-friendly messages for action responses (errors or simple feedback)
    /// to the player. This method is used internally by the engine to translate
    /// `ActionResponse` enum cases, often thrown or returned by `ActionHandler`
    /// validation or processing steps, into textual feedback for the player.
    ///
    /// It also logs more detailed information for certain critical errors like
    /// `.internalEngineError`.
    func describe(_ response: ActionResponse) async -> String {
        switch response {
        case .cannotDo(let context, let item):
            await messenger.cannotDo(context.command, item: item.withDefiniteArticle)
        case .cannotDoThat(let context):
            messenger.cannotDoThat(context.command)
        case .cannotDoWithThat(let context, let item, let instrument):
            await messenger.cannotDoWithThat(
                context.command,
                item: item.withDefiniteArticle,
                instrument: instrument?.withDefiniteArticle
            )
        case .cannotDoYourself(let context):
            messenger.cannotDoYourself(context.command)
        case .circularDependency(let error):
            messenger.circularDependency(error)
        case .containerIsClosed(let item):
            await messenger.containerIsClosed(item.withDefiniteArticle)
        case .containerIsOpen(let item):
            await messenger.containerIsAlreadyOpen(item.withDefiniteArticle)
        case .directionIsBlocked(let reason):
            messenger.directionIsBlocked(reason)
        case .doWhat(let context):
            messenger.doWhat(context.command)
        case .internalEngineError(let error):
            messenger.internalEngineError(error)
        case .invalidDirection:
            messenger.invalidDirection()
        case .invalidIndirectObject(let objectName):
            await messenger.invalidIndirectObject(objectName?.withDefiniteArticle ?? "that")
        case .invalidValue(let value):
            messenger.internalEngineError(value)
        case .itemNotAccessible(let item):
            await messenger.itemNotAccessible(
                item.isTouched ? item.withDefiniteArticle : messenger.anySuchThing()
            )
        case .itemNotHeld(let item):
            await messenger.itemNotHeld(item.withDefiniteArticle)
        case .playerCannotCarryMore:
            messenger.playerCannotCarryMore()
        case .roomIsDark:
            messenger.roomIsDark()
        case .targetIsNotAContainer(let item):
            await messenger.targetIsNotAContainer(item.withDefiniteArticle)
        case .unknownItem(let itemID):
            messenger.unknownItem(itemID)
        case .feedback(let feedback):
            feedback
        case .fileManagerError(let url):
            "File operation failed: \(url.path)"
        case .multipleObjectsNotSupported(let context):
            messenger.multipleObjectsNotSupported(context.command)
        case .unknownLocation(let locationID):
            messenger.unknownLocation(locationID)
        }
    }

    /// Reports a parsing error to the player.
    /// This method is used internally by the engine to translate `ParseError` enum cases
    /// into textual feedback for the player when their input cannot be understood.
    /// For `.internalError` cases, it also logs detailed information.
    func report(parseError: ParseError, originalInput: String? = nil) async {
        let message =
            switch parseError {
            case .allCommandNothingCarrying:
                ".allCommandNothingCarrying"
            case .allCommandNothingHere:
                messenger.allCommandNothingHere()
            case .allCommandNothingToTake:
                ".allCommandNothingToTake"
            case .ambiguity(let text):
                messenger.ambiguity(text)
            case .ambiguousReference(let options):
                // For now, just show the message - choice handling would need more context
                messenger.ambiguousReference(options)
            case .ambiguousObjectReference(let noun, let options):
                messenger.ambiguousObjectReference(noun, options: options)
            case .ambiguousVerb(let phrase, let verbs):
                messenger.ambiguousVerb(phrase, verbs: verbs)
            case .badGrammar(let text):
                messenger.badGrammar(text)
            case .emptyInput:
                messenger.emptyInput()
            case .expectedDirection:
                messenger.expectedDirection()
            case .expectedParticleAfterVerb(let expectedParticle, let verb, let found):
                messenger.expectedParticleAfterVerb(expectedParticle, verb: verb, found: found)
            case .expectedParticleButReachedEnd(let expectedParticle):
                messenger.expectedParticleButReachedEnd(expectedParticle)
            case .internalError(let error):
                messenger.internalParseError(error)
            case .itemNotInScope(let noun):
                messenger.itemNotInScope(noun)
            case .modifierMismatch(let noun, let modifiers):
                messenger.modifierMismatch(noun, modifiers: modifiers)
            case .playerReferenceCannotBeModified(let reference, let modifiers):
                messenger.playerReferenceCannotBeModified(reference, modifiers: modifiers)
            case .prepositionMismatch(let verb, let expected, let found):
                messenger.prepositionMismatch(verb, expected: expected, found: found)
            case .pronounCannotBeModified(let pronoun):
                messenger.pronounCannotBeModified(pronoun)
            case .pronounNotSet(let pronoun):
                messenger.pronounNotSet(pronoun)
            case .pronounRefersToOutOfScopeItem(let pronoun):
                messenger.pronounRefersToOutOfScopeItem(pronoun)
            case .specificVerbRequired(let requiredVerb):
                messenger.specificVerbRequired(requiredVerb)
            case .unexpectedWordsAfterCommand(let unexpectedWords):
                messenger.unexpectedWordsAfterCommand(unexpectedWords)
            case .verbUnknown(let verbPhrase):
                messenger.verbUnknown(verbPhrase)
            case .verbDoesNotSupportMultipleIndirectObjects(let verb):
                messenger.verbDoesNotSupportMultipleIndirectObjects(verb)
            case .verbDoesNotSupportMultipleObjects(let verb):
                messenger.verbDoesNotSupportMultipleObjects(verb)
            case .verbSyntaxRulesAllFailed(let verb):
                messenger.verbSyntaxRulesAllFailed(verb)
            case .verbUnderstoodButSyntaxFailed(let verb):
                messenger.verbUnderstoodButSyntaxFailed(verb)
            }

        await ioHandler.print(message)

        // Store disambiguation context if this was an ambiguous reference
        switch parseError {
        case .ambiguousObjectReference(let noun, let options):
            storeDisambiguationContext(originalInput: originalInput, noun: noun, options: options)
        case .ambiguousReference(let options):
            // For generic references, we need to extract the noun from the original input
            if let originalInput {
                let words = originalInput.lowercased().split(separator: " ").map(String.init)
                // Try to find the noun by looking for common patterns
                // This is a simplified heuristic - in a full implementation you might want more sophisticated noun extraction
                if let potentialNoun = extractNounFromCommand(words) {
                    storeDisambiguationContext(
                        originalInput: originalInput,
                        noun: potentialNoun,
                        options: options
                    )
                }
            }
        default:
            break
        }

        if case .internalError(let details) = parseError {
            logError("ParseError: \(details)")
        }
    }
}

// MARK: - Disambiguation

extension GameEngine {
    /// Extracts the likely noun from a command for disambiguation purposes
    /// This is a simple heuristic that works for basic IF commands
    func extractNounFromCommand(_ words: [String]) -> String? {
        // Skip the first word (verb)
        let remainingWords = Array(words.dropFirst())

        // Look for the direct object (usually the first noun after the verb)
        // Skip prepositions like "on", "in", "with", etc.
        let prepositions = Set(["on", "in", "with", "at", "under", "over", "through", "to", "from"])

        for word in remainingWords {
            if !prepositions.contains(word) {
                return word
            }
        }

        return remainingWords.first
    }

    /// Stores disambiguation context for handling future responses
    /// - Parameters:
    ///   - originalInput: The original command input that caused disambiguation
    ///   - noun: The ambiguous noun from the command
    ///   - options: The disambiguation options presented to the user
    func storeDisambiguationContext(
        originalInput: String?, noun: String, options: [String]
    ) {
        guard let originalInput else { return }

        // Try to extract the verb from the original input
        let words = originalInput.lowercased().split(separator: " ").map(String.init)
        if let firstWord = words.first {
            let verb = Verb(id: firstWord)
            lastDisambiguationContext = (originalInput: originalInput, verb: verb, noun: noun)
            lastDisambiguationOptions = options
        }
    }

    /// Attempts to handle a disambiguation response by matching it against recent options
    /// and retrying the original command with the selected item.
    /// - Parameters:
    ///   - input: The user's input that might be a disambiguation response
    ///   - context: The stored disambiguation context from the previous turn
    /// - Returns: True if the input was handled as a disambiguation response, false otherwise
    func tryHandleDisambiguationResponse(
        input: String,
        context: (originalInput: String, verb: Verb, noun: String)
    ) async -> Bool {
        guard let options = lastDisambiguationOptions else {
            return false
        }

        let trimmedInput = input.trimmingCharacters(in: .whitespacesAndNewlines)

        // Check if the input matches one of the disambiguation options
        for option in options {
            let lowercaseOption = option.lowercased()
            let lowercaseInput = trimmedInput.lowercased()

            // Try multiple matching strategies
            let isMatch =
                lowercaseOption == lowercaseInput  // Exact match
                || removeNoiseWords(lowercaseOption) == lowercaseInput  // Option without noise words
                || removeNoiseWords(lowercaseInput) == lowercaseOption  // Input without noise words
                || removeNoiseWords(lowercaseOption) == removeNoiseWords(lowercaseInput)  // Both without noise words

            if isMatch {
                // Clear disambiguation context since we found a match
                lastDisambiguationContext = nil
                lastDisambiguationOptions = nil

                // Found a match - reconstruct the original command with the specific item
                let specificNoun = option.replacingOccurrences(of: "the ", with: "")

                // Replace only the first occurrence of the noun to avoid replacing it in other words
                let reconstructedCommand = replaceFirstOccurrence(
                    of: context.noun,
                    with: specificNoun,
                    in: context.originalInput
                )

                // Parse and execute the reconstructed command
                do {
                    let parseResult = try await parser.parse(
                        input: reconstructedCommand,
                        vocabulary: vocabulary,
                        engine: self
                    )

                    switch parseResult {
                    case .success(let command):
                        _ = try await execute(command: command)
                    case .failure(let error):
                        await report(parseError: error, originalInput: reconstructedCommand)
                    }

                    return true
                } catch {
                    logError("Error processing disambiguation response: \(error)")
                    return false
                }
            }
        }

        // If no match found, clear the context to avoid confusion
        lastDisambiguationContext = nil
        lastDisambiguationOptions = nil
        return false
    }

    /// Replaces the first occurrence of a substring with another string
    /// - Parameters:
    ///   - target: The substring to replace
    ///   - replacement: The replacement string
    ///   - source: The source string
    /// - Returns: The string with the first occurrence replaced
    func replaceFirstOccurrence(
        of target: String,
        with replacement: String,
        in source: String
    ) -> String {
        if let range = source.range(of: target) {
            return source.replacingCharacters(in: range, with: replacement)
        }
        return source
    }

    /// Removes noise words from a string using the vocabulary system
    /// - Parameter text: The text to clean
    /// - Returns: The text with noise words removed
    func removeNoiseWords(_ text: String) -> String {
        let words = text.split(separator: " ").map(String.init)
        let filteredWords = words.filter { word in
            !vocabulary.noiseWords.contains(word.lowercased())
        }
        return filteredWords.joined(separator: " ")
    }
}
