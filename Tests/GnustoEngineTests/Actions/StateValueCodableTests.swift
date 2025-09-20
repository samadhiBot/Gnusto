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

@Suite("StateValue Codable Tests")
struct StateValueCodableTests {

    // MARK: - Basic Creation and Extraction Tests

    @Test("Create StateValue.codable using wrap factory method")
    func testCreateCodableStateValue() throws {
        let original = TestGameSettings(
            difficulty: "Hard",
            musicVolume: 0.8,
            effectsVolume: 0.6
        )

        let stateValue = try StateValue.wrap(original)

        if case .codable(let wrapper) = stateValue {
            #expect(wrapper.typeName == "TestGameSettings")
        } else {
            Issue.record("Expected .codable case")
        }
    }

    @Test("Extract value using toCodable method")
    func testExtractCodableValue() throws {
        let original = TestPlayerInventory(
            items: ["sword", "potion", "key"],
            capacity: 20,
            weight: 15.5
        )

        let stateValue = try StateValue.wrap(original)
        let extracted = stateValue.toCodable(as: TestPlayerInventory.self)

        #expect(extracted == original)
    }

    @Test("toCodable returns nil for wrong type")
    func testToCodableWrongType() throws {
        let original = TestGameSettings(difficulty: "Easy", musicVolume: 0.5, effectsVolume: 0.4)
        let stateValue = try StateValue.wrap(original)

        let extracted = stateValue.toCodable(as: TestPlayerInventory.self)
        #expect(extracted == nil)
    }

    @Test("toCodable returns nil for non-codable StateValue")
    func testToCodableOnNonCodableStateValue() {
        let stateValue = StateValue.bool(true)
        let extracted = stateValue.toCodable(as: TestGameSettings.self)
        #expect(extracted == nil)
    }

    // MARK: - Complex Data Structure Tests

    @Test("Handle complex nested structures")
    func testComplexDataStructure() throws {
        let original = TestComplexData(
            id: UUID(),
            timestamp: Date(),
            settings: TestGameSettings(difficulty: "Hard", musicVolume: 0.9, effectsVolume: 0.8),
            difficulty: .nightmare,
            scores: [100, 250, 500, 1000],
            metadata: ["version": "1.0", "platform": "iOS"]
        )

        let stateValue = try StateValue.wrap(original)
        let extracted = stateValue.toCodable(as: TestComplexData.self)

        #expect(extracted == original)
    }

    @Test("Handle enum types")
    func testEnumHandling() throws {
        let original = TestDifficulty.nightmare
        let stateValue = try StateValue.wrap(original)
        let extracted = stateValue.toCodable(as: TestDifficulty.self)

        #expect(extracted == original)
    }

    @Test("Handle arrays")
    func testArrayHandling() throws {
        let original = ["sword", "shield", "potion", "key"]
        let stateValue = try StateValue.wrap(original)
        let extracted = stateValue.toCodable(as: [String].self)

        #expect(extracted == original)
    }

    @Test("Handle dictionaries")
    func testDictionaryHandling() throws {
        let original = ["health": 100, "mana": 50, "stamina": 75]
        let stateValue = try StateValue.wrap(original)
        let extracted = stateValue.toCodable(as: [String: Int].self)

        #expect(extracted == original)
    }

    // MARK: - StateValue Protocol Conformance Tests

    @Test("StateValue.codable is Codable")
    func testCodableConformance() throws {
        let original = TestGameSettings(
            difficulty: "Expert",
            musicVolume: 0.6,
            effectsVolume: 0.7
        )
        let stateValue = try StateValue.wrap(original)

        // Encode to JSON
        let jsonData = try JSONEncoder().encode(stateValue)
        #expect(!jsonData.isEmpty)

        // Decode from JSON
        let decodedStateValue = try JSONDecoder().decode(StateValue.self, from: jsonData)
        let extractedValue = decodedStateValue.toCodable(as: TestGameSettings.self)

        #expect(extractedValue == original)
    }

    @Test("StateValue.codable round-trip serialization")
    func testRoundTripSerialization() throws {
        let original = TestComplexData(
            id: UUID(),
            timestamp: Date(),
            settings: TestGameSettings(difficulty: "Insane", musicVolume: 1.0, effectsVolume: 0.9),
            difficulty: .hard,
            scores: [42, 100, 999],
            metadata: ["creator": "test", "build": "debug"]
        )

        let stateValue1 = try StateValue.wrap(original)
        let jsonData = try JSONEncoder().encode(stateValue1)
        let stateValue2 = try JSONDecoder().decode(StateValue.self, from: jsonData)
        let extracted = stateValue2.toCodable(as: TestComplexData.self)

        #expect(extracted == original)
    }

    @Test("StateValue.codable is Hashable")
    func testHashableConformance() throws {
        let data = TestGameSettings(difficulty: "Medium", musicVolume: 0.5, effectsVolume: 0.5)

        let stateValue1 = try StateValue.wrap(data)
        let stateValue2 = try StateValue.wrap(data)

        #expect(stateValue1 == stateValue2)
        #expect(stateValue1.hashValue == stateValue2.hashValue)
    }

    @Test("StateValue.codable inequality for different data")
    func testHashableInequality() throws {
        let data1 = TestGameSettings(difficulty: "Easy", musicVolume: 0.3, effectsVolume: 0.3)
        let data2 = TestGameSettings(difficulty: "Hard", musicVolume: 0.8, effectsVolume: 0.8)

        let stateValue1 = try StateValue.wrap(data1)
        let stateValue2 = try StateValue.wrap(data2)

        #expect(stateValue1 != stateValue2)
        #expect(stateValue1.hashValue != stateValue2.hashValue)
    }

    // MARK: - CustomDumpStringConvertible Tests

    @Test("StateValue.codable has proper debug description")
    func testCustomDumpDescription() throws {
        let original = TestGameSettings(difficulty: "Debug", musicVolume: 0.4, effectsVolume: 0.3)
        let stateValue = try StateValue.wrap(original)

        let description = stateValue.customDumpDescription
        #expect(description == "codable(TestGameSettings)")
    }

    @Test("StateValue.codable description for different types")
    func testCustomDumpDescriptionForDifferentTypes() throws {
        let settings = TestGameSettings(difficulty: "Normal", musicVolume: 0.5, effectsVolume: 0.5)
        let inventory = TestPlayerInventory(items: ["item"], capacity: 1, weight: 1.0)
        let difficulty = TestDifficulty.hard

        let settingsStateValue = try StateValue.wrap(settings)
        let inventoryStateValue = try StateValue.wrap(inventory)
        let difficultyStateValue = try StateValue.wrap(difficulty)

        #expect(settingsStateValue.customDumpDescription == "codable(TestGameSettings)")
        #expect(inventoryStateValue.customDumpDescription == "codable(TestPlayerInventory)")
        #expect(difficultyStateValue.customDumpDescription == "codable(TestDifficulty)")
    }

    // MARK: - Integration with Other StateValue Cases

    @Test("StateValue.codable works alongside other cases")
    func testIntegrationWithOtherCases() throws {
        let codableValue = try StateValue.wrap(
            TestGameSettings(difficulty: "Test", musicVolume: 0.5, effectsVolume: 0.5))
        let boolValue = StateValue.bool(true)
        let intValue = StateValue.int(42)
        let stringValue = StateValue.string("test")

        // Test that all work together in collections
        let values = [codableValue, boolValue, intValue, stringValue]

        #expect(values.count == 4)
        #expect(values[0].toCodable(as: TestGameSettings.self) != nil)
        #expect(values[1].toBool == true)
        #expect(values[2].toInt == 42)
        #expect(values[3].toString == "test")
    }

    @Test("StateValue.codable equality with other cases returns false")
    func testInequalityWithOtherCases() throws {
        let codableValue = try StateValue.wrap(
            TestGameSettings(difficulty: "Test", musicVolume: 0.5, effectsVolume: 0.5))
        let boolValue = StateValue.bool(true)
        let intValue = StateValue.int(42)

        #expect(codableValue != boolValue)
        #expect(codableValue != intValue)
    }

    // MARK: - Error Handling Tests

    @Test("StateValue.wrap throws for non-encodable data")
    func testWrapThrowsForNonEncodableData() {
        struct NonEncodableData: Codable, Sendable {
            let value = "test"

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
            _ = try StateValue.wrap(NonEncodableData())
        }
    }

    // MARK: - Edge Cases

    @Test("Empty struct handling")
    func testEmptyStruct() throws {
        struct EmptyStruct: Codable, Sendable, Equatable {}

        let original = EmptyStruct()
        let stateValue = try StateValue.wrap(original)
        let extracted = stateValue.toCodable(as: EmptyStruct.self)

        #expect(extracted == original)
    }

    @Test("Optional values handling")
    func testOptionalValues() throws {
        struct OptionalData: Codable, Sendable, Equatable {
            let required: String
            let optional: String?
        }

        let data1 = OptionalData(required: "test", optional: "value")
        let data2 = OptionalData(required: "test", optional: nil)

        let stateValue1 = try StateValue.wrap(data1)
        let stateValue2 = try StateValue.wrap(data2)

        let extracted1 = stateValue1.toCodable(as: OptionalData.self)
        let extracted2 = stateValue2.toCodable(as: OptionalData.self)

        #expect(extracted1 == data1)
        #expect(extracted2 == data2)
    }

    @Test("Nested StateValue doesn't interfere with codable extraction")
    func testNestedStateValueHandling() throws {
        // Create a structure that contains StateValue-like properties but isn't actually StateValue
        struct DataWithStateValueLikeFields: Codable, Sendable, Equatable {
            let bool: Bool
            let int: Int
            let string: String
        }

        let original = DataWithStateValueLikeFields(bool: true, int: 42, string: "test")
        let stateValue = try StateValue.wrap(original)
        let extracted = stateValue.toCodable(as: DataWithStateValueLikeFields.self)

        #expect(extracted == original)
    }

    @Test("Large data structures are handled correctly")
    func testLargeDataStructures() throws {
        struct LargeData: Codable, Sendable, Equatable {
            let largeArray: [String]
            let largeDictionary: [String: Int]
        }

        let original = LargeData(
            largeArray: Array(repeating: "test string", count: 1000),
            largeDictionary: Dictionary(uniqueKeysWithValues: (0..<1000).map { ("key\($0)", $0) })
        )

        let stateValue = try StateValue.wrap(original)
        let extracted = stateValue.toCodable(as: LargeData.self)

        #expect(extracted == original)
        #expect(extracted?.largeArray.count == 1000)
        #expect(extracted?.largeDictionary.count == 1000)
    }

    // MARK: - Type Safety Tests

    @Test("Type safety prevents incorrect extraction")
    func testTypeSafety() throws {
        let settings = TestGameSettings(difficulty: "Test", musicVolume: 0.5, effectsVolume: 0.5)
        let stateValue = try StateValue.wrap(settings)

        // These should all return nil due to type mismatch
        #expect(stateValue.toCodable(as: TestPlayerInventory.self) == nil)
        #expect(stateValue.toCodable(as: TestDifficulty.self) == nil)
        #expect(stateValue.toCodable(as: [String].self) == nil)
        #expect(stateValue.toCodable(as: [String: Int].self) == nil)

        // But the correct type should work
        #expect(stateValue.toCodable(as: TestGameSettings.self) == settings)
    }

    @Test("Multiple different codable types in same collection")
    func testMultipleCodableTypesInCollection() throws {
        let settings = TestGameSettings(difficulty: "Mixed", musicVolume: 0.6, effectsVolume: 0.4)
        let inventory = TestPlayerInventory(items: ["axe"], capacity: 5, weight: 3.0)
        let difficulty = TestDifficulty.normal

        let stateValues = [
            try StateValue.wrap(settings),
            try StateValue.wrap(inventory),
            try StateValue.wrap(difficulty),
        ]

        #expect(stateValues[0].toCodable(as: TestGameSettings.self) == settings)
        #expect(stateValues[1].toCodable(as: TestPlayerInventory.self) == inventory)
        #expect(stateValues[2].toCodable(as: TestDifficulty.self) == difficulty)

        // Cross-type extraction should fail
        #expect(stateValues[0].toCodable(as: TestPlayerInventory.self) == nil)
        #expect(stateValues[1].toCodable(as: TestDifficulty.self) == nil)
        #expect(stateValues[2].toCodable(as: TestGameSettings.self) == nil)
    }
}
