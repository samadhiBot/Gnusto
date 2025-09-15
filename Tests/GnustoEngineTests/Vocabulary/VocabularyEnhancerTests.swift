import CustomDump
import GnustoEngine
import GnustoTestSupport
import Testing

@Suite("VocabularyEnhancer Tests")
struct VocabularyEnhancerTests {

    @Test("VocabularyEnhancer extracts adjectives from item names")
    func testExtractAdjectivesFromNames() async throws {
        // Given
        let enhancer = VocabularyEnhancer()
        let item = Item(
            id: "sword",
            .name("rusty iron sword"),
            .description("A rusty iron sword with intricate carved patterns.")
        )

        // When
        let result = enhancer.extractAdjectivesAndSynonyms(from: item)

        // Then
        expectNoDifference(result.adjectives, ["rusty"])
        expectNoDifference(result.synonyms, ["intricate", "patterns"])
        // Note: NLTagger is conservative with adjective detection.
        // "iron" may be tagged as a noun, and "intricate"/"carved" depend on context.
    }

    @Test("VocabularyEnhancer extracts synonyms from descriptions")
    func testExtractSynonymsFromDescriptions() async throws {
        // Given
        let enhancer = VocabularyEnhancer()
        let item = Item(
            id: "lamp",
            .name("brass lantern"),
            .description("A brass lantern that serves as a reliable light source.")
        )

        // When
        let result = enhancer.extractAdjectivesAndSynonyms(from: item)

        // Then - NLTagger correctly extracts:
        // - "reliable" as adjective from description (not "brass" since it's in the name)
        // - "lamp" as synonym from item ID
        // - "light" and "source" as synonyms from description
        expectNoDifference(result.adjectives, ["reliable"])
        expectNoDifference(result.synonyms, ["lamp", "light", "source"])

        // Note: "brass" is not extracted as an adjective by the enhancer because it's already
        // in the item name and will be handled by the existing multi-word name processing
    }

    @Test("VocabularyEnhancer merges with explicit adjectives when configured")
    func testMergeWithExplicitAdjectives() async throws {
        // Given
        let config = VocabularyEnhancer.Configuration(shouldMergeWithExplicit: true)
        let enhancer = VocabularyEnhancer(configuration: config)
        let item = Item(
            id: "gem",
            .name("sparkling diamond"),
            .description("A sparkling diamond with brilliant facets."),
            .adjectives("precious", "valuable")
        )

        // When
        let result = enhancer.extractAdjectivesAndSynonyms(from: item)
        let (finalAdjectives, _) = enhancer.combineExtractedTerms(
            for: item,
            extractedAdjectives: result.adjectives,
            extractedSynonyms: result.synonyms
        )

        // Then - Should merge explicit with extracted
        expectNoDifference(finalAdjectives, ["precious", "valuable", "sparkling", "brilliant"])
    }

    @Test("VocabularyEnhancer only uses extracted when no explicit adjectives exist")
    func testOnlyUseExtractedWhenNoExplicit() async throws {
        // Given
        let config = VocabularyEnhancer.Configuration(shouldMergeWithExplicit: false)
        let enhancer = VocabularyEnhancer(configuration: config)
        let itemWithAdjectives = Item(
            id: "gem1",
            .name("sparkling diamond"),
            .description("A sparkling diamond with brilliant facets."),
            .adjectives("precious")
        )
        let itemWithoutAdjectives = Item(
            id: "gem2",
            .name("sparkling diamond"),
            .description("A sparkling diamond with brilliant facets.")
        )

        // When
        let result1 = enhancer.extractAdjectivesAndSynonyms(from: itemWithAdjectives)
        let (finalAdjectives1, _) = enhancer.combineExtractedTerms(
            for: itemWithAdjectives,
            extractedAdjectives: result1.adjectives,
            extractedSynonyms: result1.synonyms
        )

        let result2 = enhancer.extractAdjectivesAndSynonyms(from: itemWithoutAdjectives)
        let (finalAdjectives2, _) = enhancer.combineExtractedTerms(
            for: itemWithoutAdjectives,
            extractedAdjectives: result2.adjectives,
            extractedSynonyms: result2.synonyms
        )

        // Then
        expectNoDifference(finalAdjectives1, ["precious"])  // Uses explicit only, doesn't merge extracted
        expectNoDifference(finalAdjectives2, ["sparkling", "brilliant"])  // Uses extracted when no explicit
    }

    @Test("VocabularyEnhancer respects configuration limits")
    func testConfigurationLimits() async throws {
        // Given
        let config = VocabularyEnhancer.Configuration(
            maxAdjectives: 2,
            maxSynonyms: 1
        )
        let enhancer = VocabularyEnhancer(configuration: config)
        let item = Item(
            id: "sword",
            .name("ancient rusty iron sword"),
            .description(
                "An ancient rusty iron sword with sharp edges, deadly blade, and ornate handle.")
        )

        // When
        let result = enhancer.extractAdjectivesAndSynonyms(from: item)

        // Then - Should respect limits (can't predict exact content due to NLTagger variability)
        #expect(result.adjectives.count <= 2)
        #expect(result.synonyms.count <= 1)
    }

    @Test("Vocabulary.build integrates VocabularyEnhancer")
    func testVocabularyBuildIntegration() async throws {
        // Given
        let enhancer = VocabularyEnhancer()
        let item = Item(
            id: "sword",
            .name("rusty sword"),
            .description("A rusty sword with a sharp blade.")
        )

        // When
        let vocabulary = Vocabulary.build(
            items: [item],
            enhancer: enhancer
        )

        // Then
        // The vocabulary should include extracted adjectives for item disambiguation
        #expect(vocabulary.adjectives["rusty"]?.contains("sword") == true)
        #expect(vocabulary.adjectives["sharp"]?.contains("sword") == true)
        #expect(vocabulary.items["sword"]?.contains("sword") == true)
        #expect(vocabulary.items["blade"]?.contains("sword") == true)
    }

    @Test("VocabularyEnhancer handles complete item ID and name extraction")
    func testCompleteItemIDAndNameExtraction() async throws {
        // Given: Your exact example
        let enhancer = VocabularyEnhancer()
        let lamp = Item(
            id: "lamp",
            .name("brass lantern"),
            .description("A brass lantern that serves as a reliable light source.")
        )

        // When
        let result = enhancer.extractAdjectivesAndSynonyms(from: lamp)

        // Then: Enhanced vocabulary should extract:
        // - "reliable" as adjective from description
        // - "lamp" (item ID) as synonym since it's not in the name
        // - "light" and "source" as synonyms from description
        // - "brass" is handled by existing multi-word name processing, not the enhancer

        expectNoDifference(result.adjectives, ["reliable"])
        expectNoDifference(result.synonyms, ["lamp", "light", "source"])

        // When: We build a vocabulary with this item
        let vocabulary = Vocabulary.build(items: [lamp], enhancer: enhancer)

        // Then: The complete vocabulary should include:
        // - "brass" from multi-word name processing
        // - "reliable" from NLTagger enhancement
        #expect(vocabulary.adjectives["brass"]?.contains("lamp") == true)  // From name
        #expect(vocabulary.adjectives["reliable"]?.contains("lamp") == true)  // From enhancer

        // And synonyms:
        // - "lamp" from item ID
        // - "light" and "source" from description
        #expect(vocabulary.items["lamp"]?.contains("lamp") == true)  // Item ID
        #expect(vocabulary.items["light"]?.contains("lamp") == true)  // From enhancer
        #expect(vocabulary.items["source"]?.contains("lamp") == true)  // From enhancer
        #expect(vocabulary.items["lantern"]?.contains("lamp") == true)  // From name
        #expect(vocabulary.items["brass lantern"]?.contains("lamp") == true)  // Full name
    }
}
