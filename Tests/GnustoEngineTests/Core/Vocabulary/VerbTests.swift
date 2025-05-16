import Testing
import Foundation // For JSONEncoder/Decoder
@testable import GnustoEngine

@Suite("Verb Struct Tests")
struct VerbTests {

    // — Test Setup —
    let verbIDTake: VerbID = "take"
    let synonymsTake: Set<String> = ["get", "pick up"]

    let verbIDLook: VerbID = "look"

    func createTakeVerb() -> Verb {
        Verb(id: "take", synonyms: "get", "pick up")
    }

    func createLookVerb() -> Verb {
        Verb(id: verbIDLook)
    }

    // — Tests —

    @Test("Verb Initialization with Synonyms")
    func testVerbInitializationWithSynonyms() throws {
        let verb = createTakeVerb()

        #expect(verb.id == verbIDTake)
        #expect(verb.synonyms == synonymsTake)
    }

    @Test("Verb Initialization without Synonyms")
    func testVerbInitializationWithoutSynonyms() throws {
        let verb = createLookVerb()

        #expect(verb.id == verbIDLook)
        #expect(verb.synonyms.isEmpty)
    }

    @Test("Verb Property Modification")
    func testVerbPropertyModification() throws {
        var verb = createLookVerb() // Must be var to modify

        #expect(verb.synonyms.isEmpty)
        verb.synonyms.insert("examine")
        #expect(verb.synonyms == ["examine"])
    }

    @Test("Verb Codable Conformance")
    func testVerbCodable() throws {
        let originalVerb = createTakeVerb()

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let jsonData = try encoder.encode(originalVerb)
        let decodedVerb = try decoder.decode(Verb.self, from: jsonData)

        #expect(decodedVerb.id == originalVerb.id)
        #expect(decodedVerb.synonyms == originalVerb.synonyms)
    }

    @Test("Verb Value Semantics")
    func testVerbValueSemantics() throws {
        let verb1 = createTakeVerb()
        var verb2 = verb1 // Creates a copy

        #expect(verb1.id == verbIDTake)
        #expect(verb2.id == verbIDTake)
        #expect(verb1.synonyms == synonymsTake)
        #expect(verb2.synonyms == synonymsTake)

        verb2.synonyms.insert("acquire")
        // ID is let, cannot be changed

        // Changes to verb2 should NOT affect verb1
        #expect(verb1.synonyms == synonymsTake)
        #expect(verb2.synonyms == ["get", "pick up", "acquire"])
    }
}
