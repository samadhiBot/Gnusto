import CustomDump
import Foundation
import Testing

@testable import GnustoEngine

@Suite("Vocabulary Tests")
struct VocabularyTests {

    // MARK: - Test Setup Helpers

    func createTestItem() -> Item {
        Item(
            id: "testLamp",
            .name("brass lamp"),
            .description("A shiny brass lamp."),
            .synonyms("lantern", "light"),
            .adjectives("brass", "shiny"),
            .isTakable,
            .isLightSource
        )
    }

    func createMultiWordItem() -> Item {
        Item(
            id: "goldCoin",
            .name("gold coin"),
            .description("A valuable gold coin."),
            .synonyms("piece", "money"),
            .adjectives("valuable", "golden"),
            .isTakable
        )
    }

    func createTestLocation() -> Location {
        Location(
            id: "testRoom",
            .name("Test Room"),
            .description("A room for testing."),
            .inherentlyLit
        )
    }

    func createTestVerb() -> Verb {
        Verb(
            id: "examine",
            synonyms: "x", "look at", "inspect",
            syntax: [.match(.verb, .directObject)],
            requiresLight: true
        )
    }

    // MARK: - Basic Initialization Tests

    @Test("Empty vocabulary initialization")
    func testEmptyVocabularyInitialization() throws {
        let vocab = Vocabulary()

        #expect(vocab.verbDefinitions.isEmpty)
        #expect(vocab.items.isEmpty)
        #expect(vocab.adjectives.isEmpty)
        #expect(vocab.locationNames.isEmpty)
        #expect(vocab.directions.isEmpty)

        // Check default values
        #expect(vocab.noiseWords == Vocabulary.defaultNoiseWords)
        #expect(vocab.prepositions == Vocabulary.defaultPrepositions)
        #expect(vocab.pronouns == Vocabulary.defaultPronouns)
        #expect(vocab.specialKeywords == Vocabulary.defaultSpecialKeywords)
        #expect(vocab.conjunctions == Vocabulary.defaultConjunctions)
        #expect(vocab.adverbs == Vocabulary.defaultAdverbs)
    }

    @Test("Vocabulary initialization with parameters")
    func testVocabularyInitializationWithParameters() throws {
        let testVerb = createTestVerb()
        let verbDefinitions = [testVerb.id: testVerb]
        let items = ["lamp": Set([ItemID("testLamp")])]
        let adjectives = ["brass": Set([ItemID("testLamp")])]
        let locationNames = ["room": LocationID("testRoom")]
        let directions = ["north": Direction.north]
        let customNoise: Set<String> = ["custom", "noise"]

        let vocab = Vocabulary(
            verbDefinitions: verbDefinitions,
            items: items,
            adjectives: adjectives,
            locationNames: locationNames,
            directions: directions,
            noiseWords: customNoise
        )

        #expect(vocab.verbDefinitions == verbDefinitions)
        #expect(vocab.items == items)
        #expect(vocab.adjectives == adjectives)
        #expect(vocab.locationNames == locationNames)
        #expect(vocab.directions == directions)
        #expect(vocab.noiseWords == customNoise)
    }

    // MARK: - Default Word Sets Tests

    @Test("Default noise words are appropriate")
    func testDefaultNoiseWords() throws {
        let noiseWords = Vocabulary.defaultNoiseWords

        // Test common articles
        #expect(noiseWords.contains("a"))
        #expect(noiseWords.contains("an"))
        #expect(noiseWords.contains("the"))
        #expect(noiseWords.contains("this"))
        #expect(noiseWords.contains("that"))
        #expect(noiseWords.contains("these"))
        #expect(noiseWords.contains("those"))
        #expect(noiseWords.contains("some"))

        // Test punctuation
        #expect(noiseWords.contains("."))
        #expect(noiseWords.contains("!"))
        #expect(noiseWords.contains("?"))
        #expect(noiseWords.contains(":"))
        #expect(noiseWords.contains(";"))
        #expect(noiseWords.contains("\""))
        #expect(noiseWords.contains("'"))
        #expect(noiseWords.contains("("))
        #expect(noiseWords.contains(")"))
    }

    @Test("Default prepositions are comprehensive")
    func testDefaultPrepositions() throws {
        let prepositions = Vocabulary.defaultPrepositions

        // Test common prepositions used in IF
        #expect(prepositions.contains("in"))
        #expect(prepositions.contains("on"))
        #expect(prepositions.contains("under"))
        #expect(prepositions.contains("behind"))
        #expect(prepositions.contains("with"))
        #expect(prepositions.contains("to"))
        #expect(prepositions.contains("from"))
        #expect(prepositions.contains("at"))
        #expect(prepositions.contains("about"))
        #expect(prepositions.contains("through"))
        #expect(prepositions.contains("over"))
        #expect(prepositions.contains("into"))
        #expect(prepositions.contains("onto"))
        #expect(prepositions.contains("inside"))
        #expect(prepositions.contains("up"))
        #expect(prepositions.contains("down"))
        #expect(prepositions.contains("for"))
    }

    @Test("Default pronouns are standard")
    func testDefaultPronouns() throws {
        let pronouns = Vocabulary.defaultPronouns

        #expect(pronouns.contains("it"))
        #expect(pronouns.contains("them"))
    }

    @Test("Default special keywords are appropriate")
    func testDefaultSpecialKeywords() throws {
        let keywords = Vocabulary.defaultSpecialKeywords

        #expect(keywords.contains("all"))
        #expect(keywords.contains("everything"))
        #expect(keywords.contains("each"))
    }

    @Test("Default conjunctions support multiple objects")
    func testDefaultConjunctions() throws {
        let conjunctions = Vocabulary.defaultConjunctions

        #expect(conjunctions.contains("and"))
        #expect(conjunctions.contains(","))
    }

    @Test("Default adverbs are common")
    func testDefaultAdverbs() throws {
        let adverbs = Vocabulary.defaultAdverbs

        #expect(adverbs.contains("carefully"))
        #expect(adverbs.contains("quickly"))
        #expect(adverbs.contains("slowly"))
        #expect(adverbs.contains("quietly"))
        #expect(adverbs.contains("loudly"))
        #expect(adverbs.contains("gently"))
        #expect(adverbs.contains("softly"))
        #expect(adverbs.contains("rapidly"))
        #expect(adverbs.contains("thoroughly"))
        #expect(adverbs.contains("vigorously"))
    }

    // MARK: - Adding Verbs Tests

    @Test("Add verb to vocabulary")
    func testAddVerb() throws {
        var vocab = Vocabulary()
        let testVerb = createTestVerb()

        vocab.add(verb: testVerb)

        #expect(vocab.verbDefinitions[testVerb.id] == testVerb)
        #expect(vocab.verbDefinitions.count == 1)
    }

    @Test("Add multiple verbs to vocabulary")
    func testAddMultipleVerbs() throws {
        var vocab = Vocabulary()
        let verb1 = Verb(id: "take", synonyms: "get", "grab")
        let verb2 = Verb(id: "drop", synonyms: "put down", "release")

        vocab.add(verb: verb1)
        vocab.add(verb: verb2)

        #expect(vocab.verbDefinitions.count == 2)
        #expect(vocab.verbDefinitions[.take] == verb1)
        #expect(vocab.verbDefinitions[.drop] == verb2)
    }

    @Test("Add verb overwrites existing verb with same ID")
    func testAddVerbOverwrites() throws {
        var vocab = Vocabulary()
        let verb1 = Verb(id: "test", synonyms: "old")
        let verb2 = Verb(id: "test", synonyms: "new")

        vocab.add(verb: verb1)
        vocab.add(verb: verb2)

        #expect(vocab.verbDefinitions.count == 1)
        #expect(vocab.verbDefinitions[Verb("test")] == verb2)
        #expect(vocab.verbDefinitions[Verb("test")]?.synonyms == ["new"])
    }

    // MARK: - Adding Items Tests

    @Test("Add simple item to vocabulary")
    func testAddSimpleItem() throws {
        var vocab = Vocabulary()
        let item = createTestItem()

        vocab.add(item: item)

        // Check item name mapping
        #expect(vocab.items["brass lamp"]?.contains(item.id) == true)
        #expect(vocab.items["testlamp"]?.contains(item.id) == true)

        // Check synonyms
        #expect(vocab.items["lantern"]?.contains(item.id) == true)
        #expect(vocab.items["light"]?.contains(item.id) == true)

        // Check adjectives
        #expect(vocab.adjectives["brass"]?.contains(item.id) == true)
        #expect(vocab.adjectives["shiny"]?.contains(item.id) == true)
    }

    @Test("Add multi-word item to vocabulary")
    func testAddMultiWordItem() throws {
        var vocab = Vocabulary()
        let item = createMultiWordItem()

        vocab.add(item: item)

        // Check full name
        #expect(vocab.items["gold coin"]?.contains(item.id) == true)

        // Check individual words - last word as noun
        #expect(vocab.items["coin"]?.contains(item.id) == true)

        // Check first word as adjective
        #expect(vocab.adjectives["gold"]?.contains(item.id) == true)

        // Check explicit adjectives
        #expect(vocab.adjectives["valuable"]?.contains(item.id) == true)
        #expect(vocab.adjectives["golden"]?.contains(item.id) == true)

        // Check synonyms
        #expect(vocab.items["piece"]?.contains(item.id) == true)
        #expect(vocab.items["money"]?.contains(item.id) == true)
    }

    @Test("Add item with multi-word synonyms")
    func testAddItemWithMultiWordSynonyms() throws {
        var vocab = Vocabulary()
        let item = Item(
            id: "book",
            .name("leather book"),
            .synonyms("old tome", "ancient text"),
            .isTakable
        )

        vocab.add(item: item)

        // Check multi-word synonym handling
        #expect(vocab.items["old tome"]?.contains(item.id) == true)
        #expect(vocab.items["tome"]?.contains(item.id) == true)
        #expect(vocab.adjectives["old"]?.contains(item.id) == true)

        #expect(vocab.items["ancient text"]?.contains(item.id) == true)
        #expect(vocab.items["text"]?.contains(item.id) == true)
        #expect(vocab.adjectives["ancient"]?.contains(item.id) == true)
    }

    @Test("Multiple items with same noun create item set")
    func testMultipleItemsSameNoun() throws {
        var vocab = Vocabulary()
        let lamp1 = Item(id: "lamp1", .name("brass lamp"), .isTakable)
        let lamp2 = Item(id: "lamp2", .name("silver lamp"), .isTakable)

        vocab.add(item: lamp1)
        vocab.add(item: lamp2)

        let lampItems = vocab.items["lamp"]
        #expect(lampItems?.count == 2)
        #expect(lampItems?.contains(lamp1.id) == true)
        #expect(lampItems?.contains(lamp2.id) == true)
    }

    // MARK: - Adding Locations Tests

    @Test("Add location to vocabulary")
    func testAddLocation() throws {
        var vocab = Vocabulary()
        let location = createTestLocation()

        vocab.add(location: location)

        #expect(vocab.locationNames["test room"] == location.id)
        #expect(vocab.locationNames["testroom"] == location.id)
    }

    @Test("Add multiple locations to vocabulary")
    func testAddMultipleLocations() throws {
        var vocab = Vocabulary()
        let room1 = Location(id: "room1", .name("Living Room"))
        let room2 = Location(id: "room2", .name("Kitchen"))

        vocab.add(location: room1)
        vocab.add(location: room2)

        #expect(vocab.locationNames["living room"] == room1.id)
        #expect(vocab.locationNames["room1"] == room1.id)
        #expect(vocab.locationNames["kitchen"] == room2.id)
        #expect(vocab.locationNames["room2"] == room2.id)
        #expect(vocab.locationNames.count == 4)
    }

    // MARK: - Verb Synonyms Computed Property Tests

    @Test("Verb synonyms mapping includes primary ID")
    func testVerbSynonymsIncludesPrimaryID() throws {
        var vocab = Vocabulary()
        let verb = Verb(id: "examine", synonyms: "x", "look at")

        vocab.add(verb: verb)

        let synonymMapping = vocab.verbSynonyms

        // Primary ID should be mapped
        #expect(synonymMapping["examine"]?.contains(.examine) == true)

        // Synonyms should be mapped
        #expect(synonymMapping["x"]?.contains(.examine) == true)
        #expect(synonymMapping["look at"]?.contains(.examine) == true)
    }

    @Test("Verb synonyms mapping handles multiple verbs with same synonym")
    func testVerbSynonymsMultipleVerbsSameSynonym() throws {
        var vocab = Vocabulary()
        let verb1 = Verb(id: "light", synonyms: "ignite")
        let verb2 = Verb(id: "burn", synonyms: "ignite")

        vocab.add(verb: verb1)
        vocab.add(verb: verb2)

        let synonymMapping = vocab.verbSynonyms

        // Both verbs should be mapped to the shared synonym
        let igniteVerbs = synonymMapping["ignite"]
        #expect(igniteVerbs?.count == 2)
        #expect(igniteVerbs?.contains(.light) == true)
        #expect(igniteVerbs?.contains(.burn) == true)
    }

    @Test("Verb synonyms mapping is case insensitive")
    func testVerbSynonymsMappingCaseInsensitive() throws {
        var vocab = Vocabulary()
        let verb = Verb(id: "EXAMINE", synonyms: "X", "Look At")

        vocab.add(verb: verb)

        let synonymMapping = vocab.verbSynonyms

        // All should be lowercase in mapping
        #expect(synonymMapping["examine"]?.contains(Verb("EXAMINE")) == true)
        #expect(synonymMapping["x"]?.contains(Verb("EXAMINE")) == true)
        #expect(synonymMapping["look at"]?.contains(Verb("EXAMINE")) == true)

        // Uppercase keys should not exist
        #expect(synonymMapping["EXAMINE"] == nil)
        #expect(synonymMapping["X"] == nil)
        #expect(synonymMapping["Look At"] == nil)
    }

    // MARK: - Build Method Tests

    @Test("Build vocabulary with no parameters creates empty vocabulary with debug verb")
    func testBuildEmptyVocabulary() throws {
        let vocab = Vocabulary.build()

        #expect(vocab.items.isEmpty)
        #expect(vocab.locationNames.isEmpty)

        // Should have debug verb in debug builds
        #if DEBUG
            #expect(vocab.verbDefinitions[.debug] != nil)
        #else
            #expect(vocab.verbDefinitions.isEmpty)
        #endif

        // Should have standard directions
        #expect(vocab.directions["north"] == .north)
        #expect(vocab.directions["n"] == .north)
        #expect(vocab.directions.count > 0)
    }

    @Test("Build vocabulary with items and verbs")
    func testBuildVocabularyWithContent() throws {
        let items = [createTestItem(), createMultiWordItem()]
        let locations = [createTestLocation()]
        let verbs = [createTestVerb()]

        let vocab = Vocabulary.build(items: items, locations: locations, verbs: verbs)

        // Check items were added
        #expect(vocab.items["brass lamp"]?.contains(items[0].id) == true)
        #expect(vocab.items["gold coin"]?.contains(items[1].id) == true)

        // Check locations were added
        #expect(vocab.locationNames["test room"] == locations[0].id)

        // Check verbs were added
        #expect(vocab.verbDefinitions[.examine] == verbs[0])

        // Should still have standard directions
        #expect(vocab.directions["north"] == .north)
    }

    // MARK: - Standard Directions Tests

    @Test("Standard directions are comprehensive")
    func testStandardDirections() throws {
        var vocab = Vocabulary()
        vocab.addStandardDirections()

        // Cardinal directions
        #expect(vocab.directions["north"] == .north)
        #expect(vocab.directions["n"] == .north)
        #expect(vocab.directions["south"] == .south)
        #expect(vocab.directions["s"] == .south)
        #expect(vocab.directions["east"] == .east)
        #expect(vocab.directions["e"] == .east)
        #expect(vocab.directions["west"] == .west)
        #expect(vocab.directions["w"] == .west)

        // Diagonal directions
        #expect(vocab.directions["northeast"] == .northeast)
        #expect(vocab.directions["ne"] == .northeast)
        #expect(vocab.directions["northwest"] == .northwest)
        #expect(vocab.directions["nw"] == .northwest)
        #expect(vocab.directions["southeast"] == .southeast)
        #expect(vocab.directions["se"] == .southeast)
        #expect(vocab.directions["southwest"] == .southwest)
        #expect(vocab.directions["sw"] == .southwest)

        // Vertical directions
        #expect(vocab.directions["up"] == .up)
        #expect(vocab.directions["u"] == .up)
        #expect(vocab.directions["down"] == .down)
        #expect(vocab.directions["d"] == .down)

        // In/out directions
        #expect(vocab.directions["in"] == .inside)
        #expect(vocab.directions["out"] == .outside)
    }

    // MARK: - Helper Methods Tests

    @Test("isPronoun method works correctly")
    func testIsPronoun() throws {
        let vocab = Vocabulary()

        #expect(vocab.isPronoun("it") == true)
        #expect(vocab.isPronoun("them") == true)
        #expect(vocab.isPronoun("IT") == true)  // Case insensitive
        #expect(vocab.isPronoun("THEM") == true)

        #expect(vocab.isPronoun("lamp") == false)
        #expect(vocab.isPronoun("") == false)
        #expect(vocab.isPronoun("notapronoun") == false)
    }

    @Test("isPronoun with custom pronouns")
    func testIsPronounWithCustom() throws {
        let customPronouns: Set<String> = ["he", "she", "they"]
        let vocab = Vocabulary(pronouns: customPronouns)

        #expect(vocab.isPronoun("he") == true)
        #expect(vocab.isPronoun("she") == true)
        #expect(vocab.isPronoun("they") == true)

        #expect(vocab.isPronoun("it") == false)  // Not in custom set
        #expect(vocab.isPronoun("them") == false)
    }

    // MARK: - Codable Conformance Tests

    @Test("Empty vocabulary encodes and decodes correctly")
    func testVocabularyCodableEmpty() throws {
        let originalVocab = Vocabulary()

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let encoded = try encoder.encode(originalVocab)
        let decoded = try decoder.decode(Vocabulary.self, from: encoded)

        expectNoDifference(decoded, originalVocab)
    }

    @Test("Vocabulary with content encodes and decodes correctly")
    func testVocabularyCodableWithContent() throws {
        let items = [createTestItem()]
        let locations = [createTestLocation()]
        let verbs = [createTestVerb()]

        let originalVocab = Vocabulary.build(items: items, locations: locations, verbs: verbs)

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let encoded = try encoder.encode(originalVocab)
        let decoded = try decoder.decode(Vocabulary.self, from: encoded)

        // Test key components
        expectNoDifference(decoded.verbDefinitions, originalVocab.verbDefinitions)
        expectNoDifference(decoded.items, originalVocab.items)
        expectNoDifference(decoded.adjectives, originalVocab.adjectives)
        expectNoDifference(decoded.locationNames, originalVocab.locationNames)
        expectNoDifference(decoded.directions, originalVocab.directions)
        expectNoDifference(decoded.noiseWords, originalVocab.noiseWords)
    }

    @Test("Vocabulary decodes with missing optional fields")
    func testVocabularyDecodeMissingFields() throws {
        // Create JSON with minimal required fields
        let jsonString = """
            {
                "items": {},
                "adjectives": {},
                "noiseWords": ["the", "a"],
                "adverbs": ["quickly"],
                "prepositions": ["in", "on"],
                "pronouns": ["it"],
                "directions": {"north": "north"},
                "specialKeywords": ["all"],
                "conjunctions": ["and"]
            }
            """
        let jsonData = jsonString.data(using: .utf8)!

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(Vocabulary.self, from: jsonData)

        // Should have empty verbDefinitions and locationNames
        #expect(decoded.verbDefinitions.isEmpty)
        #expect(decoded.locationNames.isEmpty)

        // Should have provided values
        #expect(decoded.items.isEmpty)
        #expect(decoded.adjectives.isEmpty)
        #expect(decoded.noiseWords == ["the", "a"])
        #expect(decoded.directions["north"] == Direction.north)
    }

    // MARK: - Equatable Conformance Tests

    @Test("Empty vocabularies are equal")
    func testVocabularyEqualityEmpty() throws {
        let vocab1 = Vocabulary()
        let vocab2 = Vocabulary()

        #expect(vocab1 == vocab2)
    }

    @Test("Vocabularies with same content are equal")
    func testVocabularyEqualitySameContent() throws {
        let items = [createTestItem()]
        let vocab1 = Vocabulary.build(items: items)
        let vocab2 = Vocabulary.build(items: items)

        #expect(vocab1 == vocab2)
    }

    @Test("Vocabularies with different content are not equal")
    func testVocabularyInequalityDifferentContent() throws {
        let vocab1 = Vocabulary.build(items: [createTestItem()])
        let vocab2 = Vocabulary.build(items: [createMultiWordItem()])

        #expect(vocab1 != vocab2)
    }

    @Test("Vocabularies with different verb definitions are not equal")
    func testVocabularyInequalityDifferentVerbs() throws {
        var vocab1 = Vocabulary()
        var vocab2 = Vocabulary()

        vocab1.add(verb: Verb(id: "test1"))
        vocab2.add(verb: Verb(id: "test2"))

        #expect(vocab1 != vocab2)
    }

    // MARK: - Sendable Conformance Tests

    @Test("Vocabulary is Sendable")
    func testVocabularySendableConformance() async throws {
        let vocab = Vocabulary.build(items: [createTestItem()])

        await withCheckedContinuation { continuation in
            Task {
                #expect(vocab.items.count > 0)
                continuation.resume()
            }
        }
    }

    // MARK: - Performance Tests

    @Test("Vocabulary operations are efficient")
    func testVocabularyPerformance() throws {
        let startTime = Date()

        // Create vocabulary with many items
        let items = (1...100).map { i in
            Item(
                id: ItemID("item\(i)"),
                .name("test item \(i)"),
                .synonyms("synonym\(i)", "alt\(i)"),
                .adjectives("adj\(i)", "desc\(i)"),
                .isTakable
            )
        }

        let vocab = Vocabulary.build(items: items)

        // Test verb synonyms computation
        let synonyms = vocab.verbSynonyms

        let endTime = Date()
        let elapsed = endTime.timeIntervalSince(startTime)

        // Should complete quickly (less than 1 second for 100 items)
        #expect(elapsed < 1.0)
        #expect(vocab.items.count > 0)
    }

    // MARK: - Edge Cases Tests

    @Test("Vocabulary handles empty strings gracefully")
    func testVocabularyEmptyStrings() throws {
        var vocab = Vocabulary()
        let item = Item(
            id: "test",
            .name(""),  // Empty name
            .synonyms("", "valid"),  // Empty synonym
            .adjectives("", "good"),  // Empty adjective
            .isTakable
        )

        vocab.add(item: item)

        // Should handle empty strings without crashing
        #expect(vocab.items[""]?.contains(item.id) == true)
        #expect(vocab.items["valid"]?.contains(item.id) == true)
        #expect(vocab.adjectives[""]?.contains(item.id) == true)
        #expect(vocab.adjectives["good"]?.contains(item.id) == true)
    }

    @Test("Vocabulary handles case sensitivity correctly")
    func testVocabularyCaseSensitivity() throws {
        var vocab = Vocabulary()
        let item = Item(
            id: "test",
            .name("BRASS LAMP"),
            .synonyms("LANTERN"),
            .adjectives("SHINY"),
            .isTakable
        )

        vocab.add(item: item)

        // Should be stored in lowercase
        #expect(vocab.items["brass lamp"]?.contains(item.id) == true)
        #expect(vocab.items["lantern"]?.contains(item.id) == true)
        #expect(vocab.adjectives["shiny"]?.contains(item.id) == true)

        // Uppercase versions should not exist
        #expect(vocab.items["BRASS LAMP"] == nil)
        #expect(vocab.items["LANTERN"] == nil)
        #expect(vocab.adjectives["SHINY"] == nil)
    }
}
