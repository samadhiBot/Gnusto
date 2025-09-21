import Foundation

// MARK: - Game Initialization

extension GameEngine {
    /// Builds the initial game state and vocabulary from a blueprint, handling item enhancement.
    ///
    /// This method performs the essential setup work for creating a new game:
    /// 1. Combines custom and default action handlers to extract verb definitions
    /// 2. Creates a vocabulary enhancer for automatic adjective/synonym extraction
    /// 3. Enhances items with extracted adjectives and synonyms based on their names
    /// 4. Builds the game vocabulary from enhanced items, locations, and verbs
    /// 5. Creates the initial game state with all entities and empty runtime state
    ///
    /// - Parameter blueprint: The game blueprint containing all static game definitions
    /// - Returns: A tuple containing the initial game state and vocabulary
    internal static func buildInitialGameState(
        from blueprint: GameBlueprint
    ) async -> (GameState, Vocabulary) {
        // Combine custom and default action handlers to extract all verb definitions
        let allHandlers = blueprint.customActionHandlers + Self.defaultActionHandlers
        let (allVerbs, verbToSyntax) = Self.extractVerbDefinitions(from: allHandlers)

        // Create default vocabulary enhancer for automatic adjective/synonym extraction
        let vocabularyEnhancer = VocabularyEnhancer()

        // Enhance items with extracted adjectives and synonyms
        let enhancedItems = blueprint.items.map { item in
            // Get existing adjectives and synonyms
            var finalAdjectives = item.properties[.adjectives]?.toStrings ?? []
            var finalSynonyms = item.properties[.synonyms]?.toStrings ?? []

            // Check if enhancement is needed (fewer than 2 existing terms)
            let needsAdjectiveEnhancement = finalAdjectives.count < 2
            let needsSynonymEnhancement = finalSynonyms.count < 2

            // Only extract if enhancement is needed for either adjectives or synonyms
            let (enhancedAdjectives, enhancedSynonyms): (Set<String>, Set<String>)
            if needsAdjectiveEnhancement || needsSynonymEnhancement {
                let extractionResult = vocabularyEnhancer.extractAdjectivesAndSynonyms(from: item)
                let combinedTerms = vocabularyEnhancer.combineExtractedTerms(
                    for: item,
                    extractedAdjectives: needsAdjectiveEnhancement
                        ? extractionResult.adjectives : [],
                    extractedSynonyms: needsSynonymEnhancement ? extractionResult.synonyms : []
                )
                enhancedAdjectives = combinedTerms.adjectives
                enhancedSynonyms = combinedTerms.synonyms
            } else {
                enhancedAdjectives = finalAdjectives
                enhancedSynonyms = finalSynonyms
            }

            // Also extract adjectives from multi-word names (same logic as Vocabulary.add)
            let itemName = item.properties[.name]?.toString ?? item.id.rawValue
            let lowercasedName = itemName.lowercased()
            let nameWords = lowercasedName.split(separator: " ").map(String.init)
            if nameWords.count > 1 {
                // Add earlier words as adjectives (e.g., "gold" from "gold coin")
                for word in nameWords.dropLast() {
                    finalAdjectives.insert(word)
                }
            }

            // Use the enhanced results (enhancement logic is handled in combineExtractedTerms)
            finalAdjectives = enhancedAdjectives
            finalSynonyms = enhancedSynonyms

            // Create new item with enhanced properties
            var enhancedItem = item
            if !finalAdjectives.isEmpty {
                enhancedItem.properties[.adjectives] = .stringSet(finalAdjectives)
            }
            if !finalSynonyms.isEmpty {
                enhancedItem.properties[.synonyms] = .stringSet(finalSynonyms)
            }

            return enhancedItem
        }

        let gameVocabulary = Vocabulary.build(
            items: enhancedItems,
            locations: blueprint.locations,
            verbs: allVerbs,
            verbToSyntax: verbToSyntax,
            enhancer: vocabularyEnhancer
        )

        let gameState = GameState(
            locations: blueprint.locations,
            items: enhancedItems,
            player: blueprint.player,
            pronoun: nil,
            activeFuses: [:],
            activeDaemons: [:],
            globalState: [:]
        )

        return (gameState, gameVocabulary)
    }

    /// Extracts verb definitions from action handlers to build vocabulary.
    ///
    /// This method analyzes all action handlers to discover:
    /// 1. Verbs from handler synonyms (for `.verb` tokens in syntax rules)
    /// 2. Specific verbs from syntax rules (for `.specificVerb` tokens)
    /// 3. Mappings from verbs to their syntax rules for parser validation
    ///
    /// When multiple handlers handle the same verb, their syntax rules are combined.
    ///
    /// - Parameter handlers: The action handlers to extract verbs from
    /// - Returns: A tuple containing all discovered verbs and verb-to-syntax mappings
    internal static func extractVerbDefinitions(
        from handlers: [ActionHandler]
    ) -> ([Verb], [Verb: [SyntaxRule]]) {
        var verbs: [Verb] = []
        var verbToSyntax: [Verb: [SyntaxRule]] = [:]

        for handler in handlers {
            // Extract verbs from handler.verbs (for .verb tokens in syntax rules)
            for verb in handler.synonyms {
                // Add the verb if not already present
                if !verbs.contains(verb) {
                    verbs.append(verb)
                }

                // Map this verb to the handler's syntax rules
                // If multiple handlers handle the same verb, combine their syntax rules
                if verbToSyntax[verb] == nil {
                    verbToSyntax[verb] = handler.syntax
                } else {
                    verbToSyntax[verb]?.append(contentsOf: handler.syntax)
                }
            }

            // Extract specific verbs from syntax rules (for .climb, .get, etc.)
            for syntaxRule in handler.syntax {
                for token in syntaxRule.pattern {
                    if case .specificVerb(let specificVerb) = token {
                        // Add the specific verb if not already present
                        if !verbs.contains(specificVerb) {
                            verbs.append(specificVerb)
                        }

                        // Map this specific verb to this syntax rule
                        if verbToSyntax[specificVerb] == nil {
                            verbToSyntax[specificVerb] = [syntaxRule]
                        } else {
                            verbToSyntax[specificVerb]?.append(syntaxRule)
                        }
                    }
                }
            }
        }

        return (verbs, verbToSyntax)
    }
}
