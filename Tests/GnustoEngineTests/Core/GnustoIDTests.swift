import Foundation
import GnustoTestSupport
import Testing

@testable import GnustoEngine

// MARK: - Test ID Type

/// A test ID type that conforms to GnustoID for testing the protocol's default implementations.
private struct TestID: GnustoID {
    let rawValue: String
}

@Suite("GnustoID Protocol Tests")
struct GnustoIDTests {

    // MARK: - Protocol Conformance Tests

    @Test("GnustoID RawRepresentable Conformance")
    func testRawRepresentableConformance() throws {
        let id = TestID(rawValue: "testValue")
        #expect(id.rawValue == "testValue")

        // Test that it can be used as RawRepresentable
        let rawRepresentable: any RawRepresentable = id
        #expect((rawRepresentable.rawValue as? String) == "testValue")
    }

    @Test("GnustoID ExpressibleByStringLiteral Conformance")
    func testExpressibleByStringLiteralConformance() throws {
        let id: TestID = "literalValue"
        #expect(id.rawValue == "literalValue")
    }

    @Test("GnustoID Convenience Initializer")
    func testConvenienceInitializer() throws {
        let id = TestID("convenienceValue")
        #expect(id.rawValue == "convenienceValue")
    }

    // MARK: - Hashable Tests

    @Test("GnustoID Hashable Conformance")
    func testHashableConformance() throws {
        let id1 = TestID("value1")
        let id2 = TestID("value1")
        let id3 = TestID("value2")

        #expect(id1 == id2)
        #expect(id1 != id3)
        #expect(id1.hashValue == id2.hashValue)

        // Test in collections
        let idSet: Set<TestID> = [id1, id2, id3]
        #expect(idSet.count == 2)  // id1 and id2 should be considered the same
    }

    // MARK: - Comparable Tests

    @Test("GnustoID Comparable Conformance")
    func testComparableConformance() throws {
        let id1 = TestID("apple")
        let id2 = TestID("banana")
        let id3 = TestID("cherry")

        #expect(id1 < id2)
        #expect(id2 < id3)
        #expect(id1 < id3)
        #expect(!(id2 < id1))
        #expect(!(id3 < id2))
    }

    @Test("GnustoID Sorting")
    func testSorting() throws {
        let unsortedIDs = [
            TestID("zebra"),
            TestID("apple"),
            TestID("monkey"),
            TestID("banana"),
        ]
        let sortedIDs = unsortedIDs.sorted()

        let expectedOrder = [
            TestID("apple"),
            TestID("banana"),
            TestID("monkey"),
            TestID("zebra"),
        ]

        #expect(sortedIDs == expectedOrder)
    }

    // MARK: - Codable Tests

    @Test("GnustoID Codable Conformance")
    func testCodableConformance() throws {
        let originalIDs = [
            TestID("first"),
            TestID("second"),
            TestID("third"),
            TestID("special_chars-123@test"),
            TestID("🎮测试"),
        ]

        let encoder = JSONEncoder.sorted(.prettyPrinted)
        let decoder = JSONDecoder()

        for originalID in originalIDs {
            let jsonData = try encoder.encode(originalID)
            let decodedID = try decoder.decode(TestID.self, from: jsonData)

            #expect(decodedID == originalID)
            #expect(decodedID.rawValue == originalID.rawValue)
        }
    }

    @Test("GnustoID JSON Representation")
    func testJSONRepresentation() throws {
        let id = TestID("testValue")
        let encoder = JSONEncoder.sorted()
        let jsonData = try encoder.encode(id)
        let jsonString = String(data: jsonData, encoding: .utf8)

        // Should encode as a plain string, not an object
        #expect(jsonString == "\"testValue\"")
    }

    @Test("GnustoID Array Codable")
    func testArrayCodable() throws {
        let originalIDs = [
            TestID("first"),
            TestID("second"),
            TestID("third"),
        ]

        let encoder = JSONEncoder.sorted()
        let decoder = JSONDecoder()

        let jsonData = try encoder.encode(originalIDs)
        let decodedIDs = try decoder.decode([TestID].self, from: jsonData)

        #expect(decodedIDs == originalIDs)
        #expect(decodedIDs.count == 3)
    }

    @Test("GnustoID Dictionary Codable")
    func testDictionaryCodable() throws {
        let originalDict: [String: TestID] = [
            "key1": "value1",
            "key2": "value2",
        ]

        let encoder = JSONEncoder.sorted()
        let decoder = JSONDecoder()

        let jsonData = try encoder.encode(originalDict)
        let decodedDict = try decoder.decode([String: TestID].self, from: jsonData)

        #expect(decodedDict == originalDict)
        #expect(decodedDict["key1"]?.rawValue == "value1")
        #expect(decodedDict["key2"]?.rawValue == "value2")
    }

    // MARK: - Sendable Tests

    @Test("GnustoID Sendable Compliance")
    func testSendableCompliance() async throws {
        let testIDs = [
            TestID("first"),
            TestID("second"),
            TestID("third"),
        ]

        // Test that TestID can be safely passed across actor boundaries
        let results = await withTaskGroup(of: TestID.self) { group in
            for testID in testIDs {
                group.addTask {
                    testID
                }
            }

            var collectedResults: [TestID] = []
            for await result in group {
                collectedResults.append(result)
            }
            return collectedResults
        }

        #expect(results.count == testIDs.count)

        // Verify all original IDs are present in results
        for originalID in testIDs {
            #expect(results.contains(originalID))
        }
    }

    // MARK: - Edge Cases

    @Test("GnustoID Special Characters")
    func testSpecialCharacters() throws {
        let specialChars = "!@#$%^&*()_+-=[]{}|;':\",./<>?"
        let id = TestID(specialChars)
        #expect(id.rawValue == specialChars)

        // Test that special characters work with encoding/decoding
        let encoder = JSONEncoder.sorted()
        let decoder = JSONDecoder()
        let jsonData = try encoder.encode(id)
        let decodedID = try decoder.decode(TestID.self, from: jsonData)
        #expect(decodedID == id)
    }

    @Test("GnustoID Unicode Support")
    func testUnicodeSupport() throws {
        let unicodeString = "🎮🗝️魔法钥匙测试"
        let id = TestID(unicodeString)
        #expect(id.rawValue == unicodeString)

        // Test that Unicode works with all operations
        let id2: TestID = "🎮🗝️魔法钥匙测试"
        #expect(id == id2)

        // Test encoding/decoding
        let encoder = JSONEncoder.sorted()
        let decoder = JSONDecoder()
        let jsonData = try encoder.encode(id)
        let decodedID = try decoder.decode(TestID.self, from: jsonData)
        #expect(decodedID == id)
    }

    @Test("GnustoID Very Long String")
    func testVeryLongString() throws {
        let longString = String(repeating: "a", count: 10_000)
        let id = TestID(longString)
        #expect(id.rawValue == longString)
        #expect(id.rawValue.count == 10_000)
    }

    @Test("GnustoID Whitespace Handling")
    func testWhitespaceHandling() throws {
        let id1 = TestID(" leadingSpace")
        let id2 = TestID("trailingSpace ")
        let id3 = TestID(" spaces ")
        let id4 = TestID("no\tTab\nNewline")

        #expect(id1.rawValue == " leadingSpace")
        #expect(id2.rawValue == "trailingSpace ")
        #expect(id3.rawValue == " spaces ")
        #expect(id4.rawValue == "no\tTab\nNewline")

        // All should be different
        #expect(id1 != id2)
        #expect(id2 != id3)
        #expect(id3 != id4)
    }

    // MARK: - Performance Tests

    @Test("GnustoID Large Collection Performance")
    func testLargeCollectionPerformance() throws {
        // Create a large set of TestIDs
        let testIDs = (0..<1_000).map { TestID("test\($0)") }
        let testSet = Set(testIDs)

        #expect(testSet.count == 1_000)

        // Test lookup performance
        let lookupID = TestID("test500")
        #expect(testSet.contains(lookupID))
    }

    // MARK: - Type Safety Tests

    @Test("GnustoID Type Safety")
    func testTypeSafety() throws {
        // Test that different ID types are properly type-safe
        let testID = TestID("value")
        let itemID: ItemID = "value"

        // These should have the same raw value but be different types
        #expect(testID.rawValue == itemID.rawValue)

        // Test that they can't be accidentally mixed in collections
        // (This is enforced at compile time, but we can test runtime behavior)
        let testDict: [TestID: String] = [testID: "test"]
        #expect(testDict[testID] == "test")

        let itemDict: [ItemID: String] = [itemID: "item"]
        #expect(itemDict[itemID] == "item")
    }

    // MARK: - Protocol Extension Tests

    @Test("GnustoID Default Implementation Coverage")
    func testDefaultImplementationCoverage() throws {
        // Test that all required protocol methods have default implementations
        let id: TestID = "test"

        // Test RawRepresentable
        #expect(id.rawValue == "test")

        // Test ExpressibleByStringLiteral
        let literalID: TestID = "literal"
        #expect(literalID.rawValue == "literal")

        // Test convenience initializer
        let convenienceID = TestID("convenience")
        #expect(convenienceID.rawValue == "convenience")

        // Test Comparable
        let id1 = TestID("a")
        let id2 = TestID("b")
        #expect(id1 < id2)

        // Test Codable
        let encoder = JSONEncoder.sorted()
        let decoder = JSONDecoder()
        let jsonData = try encoder.encode(id)
        let decodedID = try decoder.decode(TestID.self, from: jsonData)
        #expect(decodedID == id)
    }
}
