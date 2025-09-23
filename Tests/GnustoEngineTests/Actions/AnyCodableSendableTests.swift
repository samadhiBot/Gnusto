import CustomDump
import Foundation
import Testing

@testable import GnustoEngine

// MARK: - Test Data Types

private struct TestGameSettings: Codable, Sendable, Equatable {
    let difficulty: String
    let musicVolume: Double
    let effectsVolume: Double
}

private struct TestPlayerInventory: Codable, Sendable, Equatable {
    let items: [String]
    let capacity: Int
    let weight: Double
}

private enum TestDifficulty: String, Codable, Sendable, CaseIterable {
    case easy = "Easy"
    case normal = "Normal"
    case hard = "Hard"
    case nightmare = "Nightmare"
}

private struct TestComplexData: Codable, Sendable, Equatable {
    let id: UUID
    let timestamp: Date
    let settings: TestGameSettings
    let difficulty: TestDifficulty
    let scores: [Int]
    let metadata: [String: String]
}

// Non-Sendable type for negative testing
private struct NonSendableType: Codable {
    let value: String
}

@Suite("AnyCodableSendable Tests")
struct AnyCodableSendableTests {

    // MARK: - Basic Creation and Decoding Tests

    @Test("Create and decode simple struct")
    func testCreateAndDecodeSimpleStruct() throws {
        let original = TestGameSettings(
            difficulty: "Hard",
            musicVolume: 0.8,
            effectsVolume: 0.6
        )

        let wrapper = try AnyCodableSendable(original)
        let decoded = try wrapper.decode(as: TestGameSettings.self)

        #expect(decoded == original)
        #expect(wrapper.typeName == "TestGameSettings")
    }

    @Test("Create and decode with optional return")
    func testTryDecodeSuccess() throws {
        let original = TestPlayerInventory(
            items: ["sword", "potion", "key"],
            capacity: 20,
            weight: 15.5
        )

        let wrapper = try AnyCodableSendable(original)
        let decoded = wrapper.tryDecode(as: TestPlayerInventory.self)

        #expect(decoded == original)
    }

    @Test("TryDecode returns nil for wrong type")
    func testTryDecodeWrongType() throws {
        let original = TestGameSettings(
            difficulty: "Easy",
            musicVolume: 0.5,
            effectsVolume: 0.4
        )
        let wrapper = try AnyCodableSendable(original)

        let decoded = wrapper.tryDecode(as: TestPlayerInventory.self)
        #expect(decoded == nil)
    }

    @Test("Decode throws for wrong type")
    func testDecodeThrowsForWrongType() throws {
        let original = TestGameSettings(
            difficulty: "Easy",
            musicVolume: 0.5,
            effectsVolume: 0.4
        )
        let wrapper = try AnyCodableSendable(original)

        #expect(throws: DecodingError.self) {
            _ = try wrapper.decode(as: TestPlayerInventory.self)
        }
    }

    // MARK: - Type Information Tests

    @Test("Type name is correctly stored")
    func testTypeNameStorage() throws {
        let settings = TestGameSettings(
            difficulty: "Normal",
            musicVolume: 0.7,
            effectsVolume: 0.5
        )
        let inventory = TestPlayerInventory(
            items: ["map"],
            capacity: 10,
            weight: 2.0
        )

        let settingsWrapper = try AnyCodableSendable(settings)
        let inventoryWrapper = try AnyCodableSendable(inventory)

        #expect(settingsWrapper.typeName == "TestGameSettings")
        #expect(inventoryWrapper.typeName == "TestPlayerInventory")
    }

    // MARK: - Complex Data Tests

    @Test("Handle complex nested data structures")
    func testComplexDataStructure() throws {
        let original = TestComplexData(
            id: UUID(),
            timestamp: Date(),
            settings: TestGameSettings(
                difficulty: "Hard",
                musicVolume: 0.9,
                effectsVolume: 0.8
            ),
            difficulty: .nightmare,
            scores: [100, 250, 500, 1_000],
            metadata: ["version": "1.0", "platform": "iOS"]
        )

        let wrapper = try AnyCodableSendable(original)
        let decoded = try wrapper.decode(as: TestComplexData.self)

        #expect(decoded == original)
    }

    @Test("Handle enum types")
    func testEnumHandling() throws {
        let original = TestDifficulty.nightmare
        let wrapper = try AnyCodableSendable(original)
        let decoded = try wrapper.decode(as: TestDifficulty.self)

        #expect(decoded == original)
        #expect(wrapper.typeName == "TestDifficulty")
    }

    @Test("Handle arrays")
    func testArrayHandling() throws {
        let original = ["sword", "shield", "potion", "key"]
        let wrapper = try AnyCodableSendable(original)
        let decoded = try wrapper.decode(as: [String].self)

        #expect(decoded == original)
        #expect(wrapper.typeName == "Array<String>")
    }

    @Test("Handle dictionaries")
    func testDictionaryHandling() throws {
        let original = ["health": 100, "mana": 50, "stamina": 75]
        let wrapper = try AnyCodableSendable(original)
        let decoded = try wrapper.decode(as: [String: Int].self)

        #expect(decoded == original)
        #expect(wrapper.typeName == "Dictionary<String, Int>")
    }

    // MARK: - Codable Conformance Tests

    @Test("AnyCodableSendable can be JSON encoded and decoded")
    func testJSONSerialization() throws {
        let original = TestGameSettings(
            difficulty: "Expert",
            musicVolume: 0.6,
            effectsVolume: 0.7
        )

        let wrapper = try AnyCodableSendable(original)

        // Encode to JSON
        let jsonData = try JSONEncoder.sorted().encode(wrapper)
        #expect(!jsonData.isEmpty)

        // Decode from JSON
        let decodedWrapper = try JSONDecoder().decode(AnyCodableSendable.self, from: jsonData)
        let decodedValue = try decodedWrapper.decode(as: TestGameSettings.self)

        #expect(decodedValue == original)
        #expect(decodedWrapper.typeName == wrapper.typeName)
    }

    @Test("Round-trip JSON serialization preserves data")
    func testRoundTripJSONSerialization() throws {
        let original = TestComplexData(
            id: UUID(),
            timestamp: Date(),
            settings: TestGameSettings(
                difficulty: "Insane",
                musicVolume: 1.0,
                effectsVolume: 0.9
            ),
            difficulty: .hard,
            scores: [42, 100, 999],
            metadata: ["creator": "test", "build": "debug"]
        )

        let wrapper1 = try AnyCodableSendable(original)
        let jsonData = try JSONEncoder.sorted().encode(wrapper1)
        let wrapper2 = try JSONDecoder().decode(AnyCodableSendable.self, from: jsonData)
        let decoded = try wrapper2.decode(as: TestComplexData.self)

        #expect(decoded == original)
    }

    // MARK: - Hashable Conformance Tests

    @Test("Equal wrappers have equal hashes")
    func testHashableEquality() throws {
        // Use simple string data for deterministic JSON encoding
        let data = "test string for hash equality"

        let wrapper1 = try AnyCodableSendable(data)
        let wrapper2 = try AnyCodableSendable(data)

        #expect(wrapper1 == wrapper2)
        #expect(wrapper1.hashValue == wrapper2.hashValue)
    }

    @Test("Different wrappers have different hashes")
    func testHashableInequality() throws {
        let data1 = "first test string"
        let data2 = "second test string"

        let wrapper1 = try AnyCodableSendable(data1)
        let wrapper2 = try AnyCodableSendable(data2)

        #expect(wrapper1 != wrapper2)
        #expect(wrapper1.hashValue != wrapper2.hashValue)
    }

    @Test("Wrappers of different types are not equal")
    func testDifferentTypesNotEqual() throws {
        let settings = TestGameSettings(
            difficulty: "Normal",
            musicVolume: 0.5,
            effectsVolume: 0.5
        )
        let inventory = TestPlayerInventory(
            items: ["item"],
            capacity: 1,
            weight: 1.0
        )

        let wrapper1 = try AnyCodableSendable(settings)
        let wrapper2 = try AnyCodableSendable(inventory)

        #expect(wrapper1 != wrapper2)
    }

    // MARK: - Error Handling Tests

    @Test("Encoding non-encodable data throws")
    func testEncodingError() {
        // Create a type that will fail encoding
        struct NonEncodableData: Codable, Sendable {
            var date = Date.distantFuture  // This should encode fine actually

            func encode(to encoder: Encoder) throws {
                throw EncodingError.invalidValue(
                    "test",
                    EncodingError.Context(
                        codingPath: [],
                        debugDescription: "Intentional encoding failure"
                    )
                )
            }
        }

        #expect(throws: EncodingError.self) {
            _ = try AnyCodableSendable(NonEncodableData())
        }
    }

    // MARK: - Edge Cases

    @Test("Empty struct handling")
    func testEmptyStruct() throws {
        struct EmptyStruct: Codable, Sendable, Equatable {}

        let original = EmptyStruct()
        let wrapper = try AnyCodableSendable(original)
        let decoded = try wrapper.decode(as: EmptyStruct.self)

        #expect(decoded == original)
    }

    @Test("Optional values handling")
    func testOptionalValues() throws {
        struct OptionalData: Codable, Sendable, Equatable {
            let required: String
            let optional: String?
        }

        let data1 = OptionalData(required: "test", optional: "value")
        let data2 = OptionalData(required: "test", optional: nil)

        let wrapper1 = try AnyCodableSendable(data1)
        let wrapper2 = try AnyCodableSendable(data2)

        let decoded1 = try wrapper1.decode(as: OptionalData.self)
        let decoded2 = try wrapper2.decode(as: OptionalData.self)

        #expect(decoded1 == data1)
        #expect(decoded2 == data2)
    }

    @Test("Large data handling")
    func testLargeDataHandling() throws {
        let largeArray = Array(repeating: "test string", count: 10_000)

        let wrapper = try AnyCodableSendable(largeArray)
        let decoded = try wrapper.decode(as: [String].self)

        #expect(decoded.count == 10_000)
        #expect(decoded.allSatisfy { $0 == "test string" })
    }

    // MARK: - Custom Encoder/Decoder Tests

    @Test("Custom JSON encoder configuration")
    func testCustomEncoderConfiguration() throws {
        let original = TestComplexData(
            id: UUID(),
            timestamp: Date(),
            settings: TestGameSettings(
                difficulty: "Custom",
                musicVolume: 0.42,
                effectsVolume: 0.73
            ),
            difficulty: .easy,
            scores: [1, 2, 3],
            metadata: ["test": "value"]
        )

        // Test that the internal encoder/decoder can handle the data properly
        let wrapper = try AnyCodableSendable(original)
        let decoded = try wrapper.decode(as: TestComplexData.self)

        #expect(decoded == original)
    }
}
