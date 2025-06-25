import CustomDump
import Foundation
import Testing

@testable import GnustoEngine

@Suite("Verb Struct Tests")
struct VerbTests {

    // MARK: - Test Setup

    let verbIDTake: VerbID = "take"
    let synonymsTake: Set<String> = ["get", "pick up"]
    let verbIDLook: VerbID = "look"

    func createTakeVerb() -> Verb {
        Verb(id: "take", synonyms: "get", "pick up")
    }

    func createLookVerb() -> Verb {
        Verb(id: verbIDLook)
    }

    func createVerbWithSyntax() -> Verb {
        Verb(
            id: "put",
            synonyms: "place", "set",
            syntax: [.match(.verb, .directObject, .indirectObject)],
            requiresLight: true
        )
    }

    func createVerbNoLight() -> Verb {
        Verb(
            id: "inventory",
            synonyms: "i", "inv",
            syntax: [.match(.verb)],
            requiresLight: false
        )
    }

    // MARK: - Basic Initialization Tests

    @Test("Verb initialization with synonyms")
    func testVerbInitializationWithSynonyms() throws {
        let verb = createTakeVerb()

        #expect(verb.id == verbIDTake)
        #expect(verb.synonyms == synonymsTake)
        #expect(verb.syntax.isEmpty)
        #expect(verb.requiresLight == true)  // Default value
    }

    @Test("Verb initialization without synonyms")
    func testVerbInitializationWithoutSynonyms() throws {
        let verb = createLookVerb()

        #expect(verb.id == verbIDLook)
        #expect(verb.synonyms.isEmpty)
        #expect(verb.syntax.isEmpty)
        #expect(verb.requiresLight == true)  // Default value
    }

    @Test("Verb initialization with all parameters")
    func testVerbInitializationWithAllParameters() throws {
        let verb = createVerbWithSyntax()

        #expect(verb.id.rawValue == "put")
        #expect(verb.synonyms == ["place", "set"])
        #expect(verb.syntax.count == 1)
        #expect(verb.requiresLight == true)
    }

    @Test("Verb initialization with requiresLight false")
    func testVerbInitializationWithRequiresLightFalse() throws {
        let verb = createVerbNoLight()

        #expect(verb.id.rawValue == "inventory")
        #expect(verb.synonyms == ["i", "inv"])
        #expect(verb.syntax.count == 1)
        #expect(verb.requiresLight == false)
    }

    @Test("Verb initialization with variadic synonyms")
    func testVerbInitializationWithVariadicSynonyms() throws {
        let verb = Verb(id: "examine", synonyms: "x", "look at", "inspect", "check")

        #expect(verb.id.rawValue == "examine")
        #expect(verb.synonyms == ["x", "look at", "inspect", "check"])
        #expect(verb.requiresLight == true)
    }

    @Test("Verb initialization with empty synonyms")
    func testVerbInitializationWithEmptySynonyms() throws {
        let verb = Verb(id: "quit")

        #expect(verb.id.rawValue == "quit")
        #expect(verb.synonyms.isEmpty)
        #expect(verb.syntax.isEmpty)
        #expect(verb.requiresLight == true)
    }

    // MARK: - Property Modification Tests

    @Test("Verb property modification")
    func testVerbPropertyModification() throws {
        var verb = createLookVerb()

        #expect(verb.synonyms.isEmpty)
        verb.synonyms.insert("examine")
        #expect(verb.synonyms == ["examine"])

        verb.synonyms.insert("x")
        #expect(verb.synonyms == ["examine", "x"])
    }

    @Test("Verb syntax modification")
    func testVerbSyntaxModification() throws {
        var verb = createLookVerb()

        #expect(verb.syntax.isEmpty)
        verb.syntax.append(.match(.verb, .directObject))
        #expect(verb.syntax.count == 1)
    }

    @Test("Verb requiresLight modification")
    func testVerbRequiresLightModification() throws {
        var verb = createLookVerb()

        #expect(verb.requiresLight == true)
        verb.requiresLight = false
        #expect(verb.requiresLight == false)
    }

    // MARK: - Equatable Conformance Tests

    @Test("Verb equality with identical properties")
    func testVerbEquality() throws {
        let verb1 = createTakeVerb()
        let verb2 = createTakeVerb()

        #expect(verb1 == verb2)
    }

    @Test("Verb inequality with different IDs")
    func testVerbInequalityDifferentIDs() throws {
        let verb1 = createTakeVerb()
        let verb2 = createLookVerb()

        #expect(verb1 != verb2)
    }

    @Test("Verb inequality with different synonyms")
    func testVerbInequalityDifferentSynonyms() throws {
        let verb1 = Verb(id: "test", synonyms: "synonym1")
        let verb2 = Verb(id: "test", synonyms: "synonym2")

        #expect(verb1 != verb2)
    }

    @Test("Verb inequality with different syntax")
    func testVerbInequalityDifferentSyntax() throws {
        let verb1 = Verb(id: "test", syntax: [.match(.verb)])
        let verb2 = Verb(id: "test", syntax: [.match(.verb, .directObject)])

        #expect(verb1 != verb2)
    }

    @Test("Verb inequality with different requiresLight")
    func testVerbInequalityDifferentRequiresLight() throws {
        let verb1 = Verb(id: "test", requiresLight: true)
        let verb2 = Verb(id: "test", requiresLight: false)

        #expect(verb1 != verb2)
    }

    // MARK: - Codable Conformance Tests

    @Test("Verb encodes and decodes correctly")
    func testVerbCodable() throws {
        let originalVerb = createTakeVerb()

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let jsonData = try encoder.encode(originalVerb)
        let decodedVerb = try decoder.decode(Verb.self, from: jsonData)

        #expect(decodedVerb.id == originalVerb.id)
        #expect(decodedVerb.synonyms == originalVerb.synonyms)
        #expect(decodedVerb.syntax == originalVerb.syntax)
        #expect(decodedVerb.requiresLight == originalVerb.requiresLight)
    }

    @Test("Verb with requiresLight false encodes correctly")
    func testVerbRequiresLightFalseCodable() throws {
        let originalVerb = createVerbNoLight()

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let jsonData = try encoder.encode(originalVerb)
        let decodedVerb = try decoder.decode(Verb.self, from: jsonData)

        #expect(decodedVerb == originalVerb)
        #expect(decodedVerb.requiresLight == false)
    }

    @Test("Verb with complex syntax encodes correctly")
    func testVerbComplexSyntaxCodable() throws {
        let originalVerb = createVerbWithSyntax()

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let jsonData = try encoder.encode(originalVerb)
        let decodedVerb = try decoder.decode(Verb.self, from: jsonData)

        expectNoDifference(decodedVerb, originalVerb)
    }

    @Test("Verb decodes with missing requiresLight defaults to true")
    func testVerbDecodeMissingRequiresLight() throws {
        // Create JSON without requiresLight field
        let jsonString = """
            {
                "id": "test",
                "synonyms": ["syn1", "syn2"],
                "syntax": []
            }
            """
        let jsonData = jsonString.data(using: .utf8)!

        let decoder = JSONDecoder()
        let decodedVerb = try decoder.decode(Verb.self, from: jsonData)

        #expect(decodedVerb.id.rawValue == "test")
        #expect(decodedVerb.synonyms == ["syn1", "syn2"])
        #expect(decodedVerb.syntax.isEmpty)
        #expect(decodedVerb.requiresLight == true)  // Should default to true
    }

    @Test("Verb encodes requiresLight only when false")
    func testVerbEncodingOptimization() throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys

        // Verb with requiresLight = true should not encode the field
        let verbTrue = Verb(id: "test", requiresLight: true)
        let datTrue = try encoder.encode(verbTrue)
        let jsonTrue = String(data: datTrue, encoding: .utf8)!
        #expect(!jsonTrue.contains("requiresLight"))

        // Verb with requiresLight = false should encode the field
        let verbFalse = Verb(id: "test", requiresLight: false)
        let dataFalse = try encoder.encode(verbFalse)
        let jsonFalse = String(data: dataFalse, encoding: .utf8)!
        #expect(jsonFalse.contains("requiresLight"))
        #expect(jsonFalse.contains("false"))
    }

    // MARK: - Value Semantics Tests

    @Test("Verb value semantics")
    func testVerbValueSemantics() throws {
        let verb1 = createTakeVerb()
        var verb2 = verb1

        #expect(verb1.id == verbIDTake)
        #expect(verb2.id == verbIDTake)
        #expect(verb1.synonyms == synonymsTake)
        #expect(verb2.synonyms == synonymsTake)

        verb2.synonyms.insert("acquire")

        // Changes to verb2 should NOT affect verb1
        #expect(verb1.synonyms == synonymsTake)
        #expect(verb2.synonyms == ["get", "pick up", "acquire"])
    }

    @Test("Verb copy independence")
    func testVerbCopyIndependence() throws {
        let originalVerb = createVerbWithSyntax()
        var copiedVerb = originalVerb

        // Modify the copy
        copiedVerb.synonyms.insert("drop")
        copiedVerb.requiresLight = false

        // Original should be unchanged
        #expect(originalVerb.synonyms == ["place", "set"])
        #expect(originalVerb.requiresLight == true)

        // Copy should be changed
        #expect(copiedVerb.synonyms == ["place", "set", "drop"])
        #expect(copiedVerb.requiresLight == false)
    }

    // MARK: - Identifiable Conformance Tests

    @Test("Verb Identifiable conformance")
    func testVerbIdentifiableConformance() throws {
        let verb = createTakeVerb()

        // Test that id property works as Identifiable requires
        #expect(verb.id == verbIDTake)

        // Test usage in contexts that require Identifiable
        let verbs = [verb]
        let verbByID = Dictionary(uniqueKeysWithValues: verbs.map { ($0.id, $0) })
        #expect(verbByID[verbIDTake] == verb)
    }

    // MARK: - Sendable Conformance Tests

    @Test("Verb is Sendable")
    func testVerbSendableConformance() async throws {
        let verb = createTakeVerb()

        await withCheckedContinuation { continuation in
            Task {
                #expect(verb.id == verbIDTake)
                #expect(verb.synonyms == synonymsTake)
                continuation.resume()
            }
        }
    }

    // MARK: - Collection Usage Tests

    @Test("Verbs work correctly in collections")
    func testVerbsInCollections() throws {
        let verbs = [createTakeVerb(), createLookVerb(), createVerbWithSyntax()]

        #expect(verbs.count == 3)

        let takeVerb = verbs.first { $0.id == .take }
        #expect(takeVerb != nil)
        #expect(takeVerb?.synonyms == synonymsTake)

        let verbsWithLight = verbs.filter { $0.requiresLight }
        #expect(verbsWithLight.count == 3)

        let verbsWithoutLight = verbs.filter { !$0.requiresLight }
        #expect(verbsWithoutLight.count == 0)
    }

    @Test("Verbs work as dictionary values")
    func testVerbsAsDictionaryValues() throws {
        let verbDict: [VerbID: Verb] = [
            .take: createTakeVerb(),
            .look: createLookVerb(),
        ]

        #expect(verbDict.count == 2)
        #expect(verbDict[.take]?.synonyms == synonymsTake)
        #expect(verbDict[.look]?.synonyms.isEmpty == true)
    }

    // MARK: - Edge Cases Tests

    @Test("Verb with duplicate synonyms")
    func testVerbWithDuplicateSynonyms() throws {
        let verb = Verb(id: "test", synonyms: "syn", "syn", "other")

        // Set should automatically handle duplicates
        #expect(verb.synonyms == ["syn", "other"])
    }

    @Test("Verb with empty string synonym")
    func testVerbWithEmptyStringSynonym() throws {
        let verb = Verb(id: "test", synonyms: "valid", "", "another")

        #expect(verb.synonyms.contains(""))
        #expect(verb.synonyms.contains("valid"))
        #expect(verb.synonyms.contains("another"))
        #expect(verb.synonyms.count == 3)
    }

    @Test("Verb with many synonyms")
    func testVerbWithManySynonyms() throws {
        var verb = Verb(id: "test")

        // Add synonyms individually since variadic init doesn't accept array
        for i in 1...100 {
            verb.synonyms.insert("synonym\(i)")
        }

        #expect(verb.synonyms.count == 100)
        #expect(verb.synonyms.contains("synonym1"))
        #expect(verb.synonyms.contains("synonym100"))
    }
}
