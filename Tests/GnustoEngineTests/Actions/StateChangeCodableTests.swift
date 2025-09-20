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

@Suite("StateChange.setGlobalCodable Tests")
struct StateChangeCodableTests {

    // MARK: - Basic Creation and Properties Tests

    @Test("StateChange.setGlobalCodable creation and properties")
    func testSetGlobalCodableCreation() throws {
        let original = TestGameSettings(
            difficulty: "Hard",
            musicVolume: 0.8,
            effectsVolume: 0.6
        )
        let wrapper = try AnyCodableSendable(original)
        let change = StateChange.setGlobalCodable(id: "gameSettings", value: wrapper)

        if case .setGlobalCodable(let globalID, let value) = change {
            #expect(globalID == "gameSettings")
            #expect(value == wrapper)
            #expect(value.typeName == "TestGameSettings")
        } else {
            Issue.record("Expected setGlobalCodable case")
        }
    }

    @Test("StateChange.setGlobalCodable with different data types")
    func testSetGlobalCodableWithDifferentTypes() throws {
        let inventory = TestPlayerInventory(items: ["sword", "potion"], capacity: 10, weight: 5.0)
        let difficulty = TestDifficulty.nightmare
        let scores = [100, 250, 500]

        let inventoryWrapper = try AnyCodableSendable(inventory)
        let difficultyWrapper = try AnyCodableSendable(difficulty)
        let scoresWrapper = try AnyCodableSendable(scores)

        let inventoryChange = StateChange.setGlobalCodable(id: "inventory", value: inventoryWrapper)
        let difficultyChange = StateChange.setGlobalCodable(
            id: "difficulty", value: difficultyWrapper)
        let scoresChange = StateChange.setGlobalCodable(id: "highScores", value: scoresWrapper)

        // Verify each change was created correctly
        if case .setGlobalCodable(let id, let value) = inventoryChange {
            #expect(id == "inventory")
            #expect(value.typeName == "TestPlayerInventory")
        } else {
            Issue.record("Expected setGlobalCodable case for inventory")
        }

        if case .setGlobalCodable(let id, let value) = difficultyChange {
            #expect(id == "difficulty")
            #expect(value.typeName == "TestDifficulty")
        } else {
            Issue.record("Expected setGlobalCodable case for difficulty")
        }

        if case .setGlobalCodable(let id, let value) = scoresChange {
            #expect(id == "highScores")
            #expect(value.typeName == "Array<Int>")
        } else {
            Issue.record("Expected setGlobalCodable case for scores")
        }
    }

    @Test("StateChange.setGlobalCodable with complex nested data")
    func testSetGlobalCodableWithComplexData() throws {
        let complexData = TestComplexData(
            id: UUID(),
            timestamp: Date(),
            settings: TestGameSettings(difficulty: "Expert", musicVolume: 0.9, effectsVolume: 0.8),
            difficulty: .hard,
            scores: [1000, 2500, 5000],
            metadata: ["version": "2.0", "platform": "macOS"]
        )

        let wrapper = try AnyCodableSendable(complexData)
        let change = StateChange.setGlobalCodable(id: "gameState", value: wrapper)

        if case .setGlobalCodable(let globalID, let value) = change {
            #expect(globalID == "gameState")
            #expect(value.typeName == "TestComplexData")

            // Verify we can decode the data back
            let decoded = try value.decode(as: TestComplexData.self)
            #expect(decoded == complexData)
        } else {
            Issue.record("Expected setGlobalCodable case")
        }
    }

    // MARK: - Equality Tests

    @Test("StateChange.setGlobalCodable equality - same values")
    func testSetGlobalCodableEquality() throws {
        let data = TestGameSettings(difficulty: "Normal", musicVolume: 0.5, effectsVolume: 0.5)
        let wrapper1 = try AnyCodableSendable(data)
        let wrapper2 = try AnyCodableSendable(data)

        let change1 = StateChange.setGlobalCodable(id: "settings", value: wrapper1)
        let change2 = StateChange.setGlobalCodable(id: "settings", value: wrapper2)

        #expect(change1 == change2)
    }

    @Test("StateChange.setGlobalCodable equality - different IDs")
    func testSetGlobalCodableInequalityDifferentIDs() throws {
        let data = TestGameSettings(difficulty: "Easy", musicVolume: 0.3, effectsVolume: 0.3)
        let wrapper = try AnyCodableSendable(data)

        let change1 = StateChange.setGlobalCodable(id: "settings1", value: wrapper)
        let change2 = StateChange.setGlobalCodable(id: "settings2", value: wrapper)

        #expect(change1 != change2)
    }

    @Test("StateChange.setGlobalCodable equality - different values")
    func testSetGlobalCodableInequalityDifferentValues() throws {
        let data1 = TestGameSettings(difficulty: "Easy", musicVolume: 0.3, effectsVolume: 0.3)
        let data2 = TestGameSettings(difficulty: "Hard", musicVolume: 0.8, effectsVolume: 0.8)

        let wrapper1 = try AnyCodableSendable(data1)
        let wrapper2 = try AnyCodableSendable(data2)

        let change1 = StateChange.setGlobalCodable(id: "settings", value: wrapper1)
        let change2 = StateChange.setGlobalCodable(id: "settings", value: wrapper2)

        #expect(change1 != change2)
    }

    @Test("StateChange.setGlobalCodable inequality with other StateChange cases")
    func testSetGlobalCodableInequalityWithOtherCases() throws {
        let data = TestGameSettings(difficulty: "Test", musicVolume: 0.5, effectsVolume: 0.5)
        let wrapper = try AnyCodableSendable(data)

        let codableChange = StateChange.setGlobalCodable(id: "settings", value: wrapper)
        let boolChange = StateChange.setGlobalBool(id: "settings", value: true)
        let intChange = StateChange.setGlobalInt(id: "settings", value: 42)
        let stringChange = StateChange.setGlobalString(id: "settings", value: "test")

        #expect(codableChange != boolChange)
        #expect(codableChange != intChange)
        #expect(codableChange != stringChange)
    }

    // MARK: - Codable Conformance Tests

    @Test("StateChange.setGlobalCodable is JSON serializable")
    func testSetGlobalCodableJSONSerialization() throws {
        let data = TestGameSettings(
            difficulty: "Serialization Test",
            musicVolume: 0.75,
            effectsVolume: 0.65
        )
        let wrapper = try AnyCodableSendable(data)
        let change = StateChange.setGlobalCodable(id: "serializationTest", value: wrapper)

        // Encode to JSON
        let jsonData = try JSONEncoder().encode(change)
        #expect(!jsonData.isEmpty)

        // Decode from JSON
        let decodedChange = try JSONDecoder().decode(StateChange.self, from: jsonData)

        #expect(decodedChange == change)

        // Verify the decoded change has the correct structure
        if case .setGlobalCodable(let globalID, let value) = decodedChange {
            #expect(globalID == "serializationTest")
            #expect(value.typeName == "TestGameSettings")

            let decodedData = try value.decode(as: TestGameSettings.self)
            #expect(decodedData == data)
        } else {
            Issue.record("Expected setGlobalCodable case after JSON round-trip")
        }
    }

    @Test("StateChange.setGlobalCodable round-trip JSON serialization")
    func testSetGlobalCodableRoundTripSerialization() throws {
        let complexData = TestComplexData(
            id: UUID(),
            timestamp: Date(),
            settings: TestGameSettings(
                difficulty: "RoundTrip", musicVolume: 0.42, effectsVolume: 0.73),
            difficulty: .nightmare,
            scores: [999, 1337, 2048],
            metadata: ["test": "roundTrip", "encoding": "json"]
        )

        let wrapper = try AnyCodableSendable(complexData)
        let originalChange = StateChange.setGlobalCodable(id: "roundTripTest", value: wrapper)

        let jsonData = try JSONEncoder().encode(originalChange)
        let decodedChange = try JSONDecoder().decode(StateChange.self, from: jsonData)

        #expect(decodedChange == originalChange)

        if case .setGlobalCodable(let globalID, let value) = decodedChange {
            let decodedData = try value.decode(as: TestComplexData.self)
            #expect(decodedData == complexData)
        } else {
            Issue.record("Expected setGlobalCodable case after round-trip")
        }
    }

    // MARK: - Integration Tests

    @Test("StateChange.setGlobalCodable works alongside other global state changes")
    func testIntegrationWithOtherGlobalStateChanges() throws {
        let settings = TestGameSettings(
            difficulty: "Integration", musicVolume: 0.6, effectsVolume: 0.4)
        let wrapper = try AnyCodableSendable(settings)

        let changes = [
            StateChange.setGlobalCodable(id: "settings", value: wrapper),
            StateChange.setGlobalBool(id: "debugMode", value: true),
            StateChange.setGlobalInt(id: "score", value: 1000),
            StateChange.setGlobalString(id: "playerName", value: "TestPlayer"),
            StateChange.setFlag(.isNoOp),
            StateChange.clearFlag(.isNoOp),
        ]

        // Verify all changes are different
        for i in 0..<changes.count {
            for j in (i + 1)..<changes.count {
                #expect(changes[i] != changes[j])
            }
        }

        // Verify the codable change is correctly structured
        if case .setGlobalCodable(let id, let value) = changes[0] {
            #expect(id == "settings")
            let decoded = try value.decode(as: TestGameSettings.self)
            #expect(decoded == settings)
        } else {
            Issue.record("Expected setGlobalCodable case in integration test")
        }
    }

    @Test("StateChange.setGlobalCodable vs StateChange.setGlobalState comparison")
    func testComparisonWithSetGlobalState() throws {
        let data = TestGameSettings(difficulty: "Comparison", musicVolume: 0.7, effectsVolume: 0.3)

        // Create using setGlobalCodable
        let wrapper = try AnyCodableSendable(data)
        let codableChange = StateChange.setGlobalCodable(id: "comparison", value: wrapper)

        // Create using setGlobalState with wrapped value
        let stateValue = try StateValue.wrap(data)
        let stateChange = StateChange.setGlobalState(id: "comparison", value: stateValue)

        // These should be different change types even with the same data
        #expect(codableChange != stateChange)

        // But both should contain the same underlying data
        if case .setGlobalCodable(_, let codableValue) = codableChange,
            case .setGlobalState(_, let stateValueWrapper) = stateChange
        {

            let decodedFromCodable = try codableValue.decode(as: TestGameSettings.self)
            let decodedFromState = stateValueWrapper.toCodable(as: TestGameSettings.self)

            #expect(decodedFromCodable == data)
            #expect(decodedFromState == data)
            #expect(decodedFromCodable == decodedFromState)
        } else {
            Issue.record("Expected both changes to decode properly")
        }
    }

    // MARK: - Error Handling Tests

    @Test("StateChange.setGlobalCodable with encoding errors")
    func testSetGlobalCodableWithEncodingErrors() {
        struct FailingEncodableData: Codable, Sendable {
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
            let data = FailingEncodableData()
            let wrapper = try AnyCodableSendable(data)
            _ = StateChange.setGlobalCodable(id: "failing", value: wrapper)
        }
    }

    // MARK: - Edge Cases

    @Test("StateChange.setGlobalCodable with empty struct")
    func testSetGlobalCodableWithEmptyStruct() throws {
        struct EmptyStruct: Codable, Sendable, Equatable {}

        let data = EmptyStruct()
        let wrapper = try AnyCodableSendable(data)
        let change = StateChange.setGlobalCodable(id: "empty", value: wrapper)

        if case .setGlobalCodable(let globalID, let value) = change {
            #expect(globalID == "empty")
            #expect(value.typeName == "EmptyStruct")

            let decoded = try value.decode(as: EmptyStruct.self)
            #expect(decoded == data)
        } else {
            Issue.record("Expected setGlobalCodable case")
        }
    }

    @Test("StateChange.setGlobalCodable with optional data")
    func testSetGlobalCodableWithOptionalData() throws {
        struct OptionalData: Codable, Sendable, Equatable {
            let required: String
            let optional: String?
        }

        let dataWithValue = OptionalData(required: "test", optional: "value")
        let dataWithNil = OptionalData(required: "test", optional: nil)

        let wrapper1 = try AnyCodableSendable(dataWithValue)
        let wrapper2 = try AnyCodableSendable(dataWithNil)

        let change1 = StateChange.setGlobalCodable(id: "optional1", value: wrapper1)
        let change2 = StateChange.setGlobalCodable(id: "optional2", value: wrapper2)

        #expect(change1 != change2)

        if case .setGlobalCodable(_, let value) = change1 {
            let decoded = try value.decode(as: OptionalData.self)
            #expect(decoded == dataWithValue)
        } else {
            Issue.record("Expected setGlobalCodable case for optional data with value")
        }

        if case .setGlobalCodable(_, let value) = change2 {
            let decoded = try value.decode(as: OptionalData.self)
            #expect(decoded == dataWithNil)
        } else {
            Issue.record("Expected setGlobalCodable case for optional data with nil")
        }
    }

    @Test("StateChange.setGlobalCodable with large data structures")
    func testSetGlobalCodableWithLargeData() throws {
        struct LargeData: Codable, Sendable, Equatable {
            let largeArray: [String]
            let largeDictionary: [String: Int]
        }

        let data = LargeData(
            largeArray: Array(repeating: "test string", count: 100),
            largeDictionary: Dictionary(uniqueKeysWithValues: (0..<100).map { ("key\($0)", $0) })
        )

        let wrapper = try AnyCodableSendable(data)
        let change = StateChange.setGlobalCodable(id: "largeData", value: wrapper)

        if case .setGlobalCodable(let globalID, let value) = change {
            #expect(globalID == "largeData")

            let decoded = try value.decode(as: LargeData.self)
            #expect(decoded == data)
            #expect(decoded.largeArray.count == 100)
            #expect(decoded.largeDictionary.count == 100)
        } else {
            Issue.record("Expected setGlobalCodable case for large data")
        }
    }

    // MARK: - Performance Considerations

    @Test("StateChange.setGlobalCodable factory method consistency")
    func testFactoryMethodConsistency() throws {
        let data = TestGameSettings(difficulty: "Consistency", musicVolume: 0.5, effectsVolume: 0.5)
        let wrapper = try AnyCodableSendable(data)

        let change1 = StateChange.setGlobalCodable(id: "consistency", value: wrapper)
        let change2 = StateChange.setGlobalCodable(id: "consistency", value: wrapper)

        #expect(change1 == change2)
    }
}
