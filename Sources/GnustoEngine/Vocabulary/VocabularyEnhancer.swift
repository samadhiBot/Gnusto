import Foundation
import NaturalLanguage

/// Enhances vocabulary by automatically extracting adjectives and synonyms from item text
/// using Apple's NaturalLanguage framework.
public struct VocabularyEnhancer: Sendable, Equatable {

    /// Configuration options for vocabulary enhancement
    public struct Configuration: Sendable, Equatable {
        /// Whether to enable automatic vocabulary enhancement
        public let isEnabled: Bool

        /// Whether to merge extracted terms with explicit ones (true) or only use when missing (false)
        public let shouldMergeWithExplicit: Bool

        /// Minimum word length to consider for extraction
        public let minimumWordLength: Int

        /// Maximum number of adjectives to extract per item
        public let maxAdjectives: Int

        /// Maximum number of synonyms to extract per item
        public let maxSynonyms: Int

        /// Words to exclude from extraction (common words that aren't useful for gameplay)
        public let excludedWords: Set<String>

        public init(
            isEnabled: Bool = true,
            shouldMergeWithExplicit: Bool = true,
            minimumWordLength: Int = 3,
            maxAdjectives: Int = 8,
            maxSynonyms: Int = 5,
            excludedWords: Set<String> = Self.defaultExcludedWords
        ) {
            self.isEnabled = isEnabled
            self.shouldMergeWithExplicit = shouldMergeWithExplicit
            self.minimumWordLength = minimumWordLength
            self.maxAdjectives = maxAdjectives
            self.maxSynonyms = maxSynonyms
            self.excludedWords = excludedWords
        }

        /// Default set of words to exclude from extraction
        public static let defaultExcludedWords: Set<String> = [
            // Articles and pronouns
            "the", "a", "an", "this", "that", "these", "those", "it", "its",
            // Common prepositions
            "of", "in", "on", "at", "by", "for", "with", "from", "to", "into", "onto",
            // Common verbs that might appear in descriptions
            "is", "are", "was", "were", "has", "have", "had", "can", "could", "will", "would",
            // Overly common adjectives
            "good", "bad", "nice", "great", "big", "small", "old", "new",
            // Common nouns that aren't useful synonyms
            "thing", "item", "object", "piece", "part", "way", "time", "place",
        ]
    }

    /// Result of vocabulary enhancement
    public struct ExtractionResult: Sendable, Equatable {
        public let adjectives: Set<String>
        public let synonyms: Set<String>

        public init(adjectives: Set<String>, synonyms: Set<String>) {
            self.adjectives = adjectives
            self.synonyms = synonyms
        }
    }

    public let configuration: Configuration

    public init(configuration: Configuration = Configuration()) {
        self.configuration = configuration
    }

    /// Extracts adjectives and potential synonyms from an item's name and description
    /// - Parameter item: The item to analyze
    /// - Returns: Extracted adjectives and synonyms
    public func extractAdjectivesAndSynonyms(from item: Item) -> ExtractionResult {
        guard configuration.isEnabled else {
            return ExtractionResult(adjectives: [], synonyms: [])
        }

        // Get text to analyze
        let itemName = item.properties[.name]?.toString ?? item.id.rawValue
        let itemDescription = item.properties[.description]?.toString ?? ""

        // Combine name and description for analysis
        let combinedText = "\(itemName). \(itemDescription)"

        // Extract linguistic features
        let extractedAdjectives = extractAdjectives(
            from: combinedText
        )
        let extractedSynonyms = extractSynonyms(
            from: combinedText,
            itemName: itemName,
            itemID: item.id.rawValue
        )
        return ExtractionResult(
            adjectives: extractedAdjectives,
            synonyms: extractedSynonyms
        )
    }

    /// Combines extracted terms with existing terms based on configuration.
    /// - Parameter item: The item to check
    /// - Parameter extractedAdjectives: Adjectives extracted by NLTagger
    /// - Parameter extractedSynonyms: Synonyms extracted by NLTagger
    /// - Returns: The adjectives and synonyms to actually use
    public func combineExtractedTerms(
        for item: Item,
        extractedAdjectives: Set<String>,
        extractedSynonyms: Set<String>
    ) -> (adjectives: Set<String>, synonyms: Set<String>) {
        let existingAdjectives = item.properties[.adjectives]?.toStrings ?? []
        let existingSynonyms = item.properties[.synonyms]?.toStrings ?? []

        let finalAdjectives: Set<String>
        let finalSynonyms: Set<String>

        if configuration.shouldMergeWithExplicit {
            // Merge extracted with explicit, removing duplicates
            finalAdjectives = existingAdjectives.union(extractedAdjectives)
            finalSynonyms = existingSynonyms.union(extractedSynonyms)
        } else {
            // Only use extracted if no explicit ones exist
            finalAdjectives = existingAdjectives.isEmpty ? extractedAdjectives : existingAdjectives
            finalSynonyms = existingSynonyms.isEmpty ? extractedSynonyms : existingSynonyms
        }

        return (adjectives: finalAdjectives, synonyms: finalSynonyms)
    }

    // MARK: - Private Implementation

    private func extractAdjectives(from text: String) -> Set<String> {
        let tagger = NLTagger(tagSchemes: [.lexicalClass])
        tagger.string = text

        var adjectives: Set<String> = []
        let options: NLTagger.Options = [.omitPunctuation, .omitWhitespace]

        tagger.enumerateTags(
            in: text.startIndex..<text.endIndex,
            unit: .word,
            scheme: .lexicalClass,
            options: options
        ) { tag, tokenRange in
            guard tag == .adjective, adjectives.count < configuration.maxAdjectives else {
                return true
            }

            let word = String(text[tokenRange]).lowercased()

            if isValidExtractedWord(word) {
                adjectives.insert(word)
            }

            return true
        }

        return adjectives
    }

    private func extractSynonyms(
        from text: String,
        itemName: String,
        itemID: String
    ) -> Set<String> {
        let tagger = NLTagger(tagSchemes: [.lexicalClass])
        tagger.string = text

        var synonyms: Set<String> = []
        let options: NLTagger.Options = [.omitPunctuation, .omitWhitespace]
        let itemNameWords = Set(itemName.lowercased().split(separator: " ").map(String.init))

        // First, check if the item ID should be included as a synonym
        // Include it if it's different from the name and not already contained in the name
        let lowercasedItemID = itemID.lowercased()
        let lowercasedItemName = itemName.lowercased()
        if lowercasedItemID != lowercasedItemName
            && !itemNameWords.contains(lowercasedItemID)
            && isValidExtractedWord(lowercasedItemID)
            && isValidSynonym(lowercasedItemID)
        {
            synonyms.insert(lowercasedItemID)
        }

        // Then extract synonyms from the text using NLTagger
        tagger.enumerateTags(
            in: text.startIndex..<text.endIndex,
            unit: .word,
            scheme: .lexicalClass,
            options: options
        ) { tag, tokenRange in
            guard let tag,
                tag == .noun,
                synonyms.count < configuration.maxSynonyms
            else {
                return true
            }

            let word = String(text[tokenRange]).lowercased()

            // Only include nouns that aren't already in the item name and are valid
            if !itemNameWords.contains(word) && isValidExtractedWord(word) && isValidSynonym(word) {
                synonyms.insert(word)
            }

            return true
        }

        return synonyms
    }

    private func isValidExtractedWord(_ word: String) -> Bool {
        word.count >= configuration.minimumWordLength
            && !configuration.excludedWords.contains(word)
            && word.allSatisfy { $0.isLetter || $0 == "-" }
    }

    private func isValidSynonym(_ word: String) -> Bool {
        [
            "anything",
            "everything",
            "items",
            "nothing",
            "objects",
            "something",
            "stuff",
            "things",
        ].contains(word) == false
    }
}
