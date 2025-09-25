import CustomDump
import Foundation
import Testing

@testable import GnustoEngine

@Suite("FuseState Payload Tests")
struct FuseStatePayloadTests {

    // MARK: - Basic Payload Functionality Tests

    @Test("Create FuseState with type-safe payload")
    func testCreateFuseStateWithPayload() throws {
        struct CustomPayload: Codable, Sendable, Equatable {
            let message: String
            let count: Int
        }

        let payload = CustomPayload(message: "test", count: 42)
        let fuseState = try FuseState(turns: 5, payload: payload)

        #expect(fuseState.turns == 5)
        #expect(fuseState.hasPayload(ofType: CustomPayload.self))

        let retrievedPayload = fuseState.getPayload(as: CustomPayload.self)
        #expect(retrievedPayload == payload)
    }

    @Test("Create FuseState with no payload")
    func testCreateFuseStateWithoutPayload() {
        let fuseState = FuseState(turns: 3)

        #expect(fuseState.turns == 3)
        #expect(fuseState.payload == nil)
        #expect(!fuseState.hasPayload(ofType: String.self))
    }

    @Test("Retrieve payload with wrong type returns nil")
    func testRetrievePayloadWithWrongType() throws {
        struct CorrectPayload: Codable, Sendable, Equatable {
            let value: String
        }

        struct WrongPayload: Codable, Sendable, Equatable {
            let different: Int
        }

        let payload = CorrectPayload(value: "correct")
        let fuseState = try FuseState(turns: 2, payload: payload)

        #expect(fuseState.getPayload(as: WrongPayload.self) == nil)
        #expect(!fuseState.hasPayload(ofType: WrongPayload.self))
        #expect(fuseState.hasPayload(ofType: CorrectPayload.self))
    }

    @Test("Type-safe payload access preserves type safety")
    func testTypeSafePayloadAccess() throws {
        let stringPayload = "test string"
        let intPayload = 123
        let arrayPayload = ["a", "b", "c"]

        let stringFuse = try FuseState(turns: 1, payload: stringPayload)
        let intFuse = try FuseState(turns: 1, payload: intPayload)
        let arrayFuse = try FuseState(turns: 1, payload: arrayPayload)

        #expect(stringFuse.getPayload(as: String.self) == "test string")
        #expect(stringFuse.getPayload(as: Int.self) == nil)

        #expect(intFuse.getPayload(as: Int.self) == 123)
        #expect(intFuse.getPayload(as: String.self) == nil)

        #expect(arrayFuse.getPayload(as: [String].self) == ["a", "b", "c"])
        #expect(arrayFuse.getPayload(as: String.self) == nil)
    }

    // MARK: - Common Payload Types Tests

    @Test("EnemyLocationPayload creation and access")
    func testEnemyLocationPayload() throws {
        let enemyID = ItemID("goblin")
        let locationID = LocationID("cave")
        let message = "The goblin stirs."

        let payload = FuseState.EnemyLocationPayload(
            enemyID: enemyID,
            locationID: locationID,
            message: message
        )

        let fuseState = try FuseState(turns: 3, payload: payload)

        let retrievedPayload = fuseState.getPayload(as: FuseState.EnemyLocationPayload.self)
        #expect(retrievedPayload?.enemyID == enemyID)
        #expect(retrievedPayload?.locationID == locationID)
        #expect(retrievedPayload?.message == message)
    }

    @Test("StatusEffectPayload creation and access")
    func testStatusEffectPayload() throws {
        let itemID = ItemID("player")

        let payload = FuseState.StatusEffectPayload(
            itemID: itemID,
            effect: .poisoned
        )

        let fuseState = try FuseState(turns: 5, payload: payload)

        let retrievedPayload = fuseState.getPayload(as: FuseState.StatusEffectPayload.self)
        #expect(retrievedPayload?.itemID == itemID)
        #expect(retrievedPayload?.effect == .poisoned)
    }

    // EnvironmentalPayload was removed - it was unused stringly-typed code

    // MARK: - Convenience Constructor Tests

    @Test("FuseState.enemyLocation convenience constructor")
    func testEnemyLocationConvenienceConstructor() throws {
        let fuseState = try FuseState.enemyLocation(
            turns: 4,
            enemyID: "orc",
            locationID: "battlefield",
            message: "The orc recovers."
        )

        #expect(fuseState.turns == 4)

        let payload = fuseState.getPayload(as: FuseState.EnemyLocationPayload.self)
        #expect(payload?.enemyID == ItemID("orc"))
        #expect(payload?.locationID == LocationID("battlefield"))
        #expect(payload?.message == "The orc recovers.")
    }

    @Test("FuseState.statusEffect convenience constructor")
    func testStatusEffectConvenienceConstructor() throws {
        let fuseState = try FuseState.statusEffect(
            turns: 6,
            itemID: "wizard",
            effect: .cursed
        )

        #expect(fuseState.turns == 6)

        let payload = fuseState.getPayload(as: FuseState.StatusEffectPayload.self)
        #expect(payload?.itemID == ItemID("wizard"))
        #expect(payload?.effect == .cursed)
    }

    // Environmental convenience constructor was removed - it was unused stringly-typed code

    // Environmental constructor with empty parameters was removed - it was unused stringly-typed code

    // MARK: - Codable Conformance Tests

    @Test("FuseState with payload is JSON serializable")
    func testFuseStateJSONSerialization() throws {
        struct TestPayload: Codable, Sendable, Equatable {
            let id: String
            let count: Int
            let active: Bool
        }

        let originalPayload = TestPayload(id: "test", count: 5, active: true)
        let originalFuseState = try FuseState(turns: 10, payload: originalPayload)

        // Encode to JSON
        let jsonData = try JSONEncoder.sorted().encode(originalFuseState)
        #expect(!jsonData.isEmpty)

        // Decode from JSON
        let decodedFuseState = try JSONDecoder().decode(FuseState.self, from: jsonData)

        #expect(decodedFuseState.turns == originalFuseState.turns)

        let decodedPayload = decodedFuseState.getPayload(as: TestPayload.self)
        #expect(decodedPayload == originalPayload)
    }

    @Test("Round-trip JSON serialization preserves payload types")
    func testRoundTripSerialization() throws {
        let enemyPayload = FuseState.EnemyLocationPayload(
            enemyID: "dragon",
            locationID: "lair",
            message: "The dragon roars."
        )

        let originalFuse = try FuseState(turns: 7, payload: enemyPayload)

        let jsonData = try JSONEncoder.sorted().encode(originalFuse)
        let decodedFuse = try JSONDecoder().decode(FuseState.self, from: jsonData)

        #expect(decodedFuse == originalFuse)

        let decodedPayload = decodedFuse.getPayload(as: FuseState.EnemyLocationPayload.self)
        #expect(decodedPayload == enemyPayload)
    }

    @Test("FuseState without payload serializes correctly")
    func testFuseStateWithoutPayloadSerialization() throws {
        let originalFuseState = FuseState(turns: 3)

        let jsonData = try JSONEncoder.sorted().encode(originalFuseState)
        let decodedFuseState = try JSONDecoder().decode(FuseState.self, from: jsonData)

        #expect(decodedFuseState.turns == 3)
        #expect(decodedFuseState.payload == nil)
        #expect(decodedFuseState == originalFuseState)
    }

    // MARK: - Equatable and Hashable Tests

    @Test("FuseState equality with same payloads")
    func testFuseStateEqualityWithSamePayloads() throws {
        let payload = FuseState.StatusEffectPayload(itemID: "player", effect: .blessed)

        let fuse1 = try FuseState(turns: 3, payload: payload)
        let fuse2 = try FuseState(turns: 3, payload: payload)

        #expect(fuse1 == fuse2)
        #expect(fuse1.hashValue == fuse2.hashValue)
    }

    @Test("FuseState inequality with different payloads")
    func testFuseStateInequalityWithDifferentPayloads() throws {
        let payload1 = FuseState.StatusEffectPayload(itemID: "player", effect: .blessed)
        let payload2 = FuseState.StatusEffectPayload(itemID: "player", effect: .cursed)

        let fuse1 = try FuseState(turns: 3, payload: payload1)
        let fuse2 = try FuseState(turns: 3, payload: payload2)

        #expect(fuse1 != fuse2)
    }

    @Test("FuseState with payload vs without payload")
    func testFuseStateWithVsWithoutPayload() throws {
        let payload = "test payload"

        let fuseWithPayload = try FuseState(turns: 2, payload: payload)
        let fuseWithoutPayload = FuseState(turns: 2)

        #expect(fuseWithPayload != fuseWithoutPayload)
    }

    @Test("FuseState inequality with different turn counts")
    func testFuseStateInequalityWithDifferentTurns() throws {
        let payload = "same payload"

        let fuse1 = try FuseState(turns: 1, payload: payload)
        let fuse2 = try FuseState(turns: 2, payload: payload)

        #expect(fuse1 != fuse2)
    }

    // MARK: - Edge Cases and Error Handling

    @Test("Empty payload handling")
    func testEmptyPayloadHandling() throws {
        struct EmptyPayload: Codable, Sendable, Equatable {}

        let payload = EmptyPayload()
        let fuseState = try FuseState(turns: 1, payload: payload)

        #expect(fuseState.hasPayload(ofType: EmptyPayload.self))
        let retrieved = fuseState.getPayload(as: EmptyPayload.self)
        #expect(retrieved == payload)
    }

    @Test("Optional values in payload")
    func testOptionalValuesInPayload() throws {
        struct OptionalPayload: Codable, Sendable, Equatable {
            let required: String
            let optional: String?
        }

        let payload1 = OptionalPayload(required: "test", optional: "value")
        let payload2 = OptionalPayload(required: "test", optional: nil)

        let fuse1 = try FuseState(turns: 1, payload: payload1)
        let fuse2 = try FuseState(turns: 1, payload: payload2)

        let retrieved1 = fuse1.getPayload(as: OptionalPayload.self)
        let retrieved2 = fuse2.getPayload(as: OptionalPayload.self)

        #expect(retrieved1?.optional == "value")
        #expect(retrieved2?.optional == nil)
        #expect(retrieved1?.required == "test")
        #expect(retrieved2?.required == "test")
    }

    @Test("Complex nested payload structures")
    func testComplexNestedPayloadStructures() throws {
        struct InnerData: Codable, Sendable, Equatable {
            let id: String
            let values: [Int]
        }

        struct ComplexPayload: Codable, Sendable, Equatable {
            let name: String
            let data: [InnerData]
            let metadata: [String: String]
        }

        let inner1 = InnerData(id: "first", values: [1, 2, 3])
        let inner2 = InnerData(id: "second", values: [4, 5, 6])

        let complexPayload = ComplexPayload(
            name: "complex",
            data: [inner1, inner2],
            metadata: ["type": "test", "version": "1.0"]
        )

        let fuseState = try FuseState(turns: 5, payload: complexPayload)
        let retrieved = fuseState.getPayload(as: ComplexPayload.self)

        #expect(retrieved == complexPayload)
        #expect(retrieved?.data.count == 2)
        #expect(retrieved?.data.first?.values == [1, 2, 3])
        #expect(retrieved?.metadata["type"] == "test")
    }

    @Test("Large payload data handling")
    func testLargePayloadDataHandling() throws {
        struct LargePayload: Codable, Sendable, Equatable {
            let largeArray: [String]
            let largeDictionary: [String: Int]
        }

        let payload = LargePayload(
            largeArray: Array(repeating: "item", count: 100),
            largeDictionary: Dictionary(uniqueKeysWithValues: (0..<100).map { ("key\($0)", $0) })
        )

        let fuseState = try FuseState(turns: 1, payload: payload)
        let retrieved = fuseState.getPayload(as: LargePayload.self)

        #expect(retrieved?.largeArray.count == 100)
        #expect(retrieved?.largeDictionary.count == 100)
        #expect(retrieved == payload)
    }

    // MARK: - Internal Initializer Tests

    @Test("Internal initializer for engine use")
    func testInternalInitializer() throws {
        let payload = try AnyCodableSendable("test payload")
        let fuseState = FuseState(turns: 3, payload: payload)

        #expect(fuseState.turns == 3)
        #expect(fuseState.getPayload(as: String.self) == "test payload")
    }

    // MARK: - Type Name Preservation Tests

    @Test("Payload type names are preserved in AnyCodableSendable")
    func testPayloadTypeNamePreservation() throws {
        struct CustomType: Codable, Sendable, Equatable {
            let value: String
        }

        let payload = CustomType(value: "test")
        let fuseState = try FuseState(turns: 1, payload: payload)

        // The type name should be preserved in the underlying AnyCodableSendable
        #expect(fuseState.payload?.typeName.contains("CustomType") == true)
    }

    // MARK: - Payload Type Safety Tests

    @Test("Different payload types don't interfere")
    func testDifferentPayloadTypesDontInterfere() throws {
        struct PayloadA: Codable, Sendable, Equatable {
            let valueA: String
        }

        struct PayloadB: Codable, Sendable, Equatable {
            let valueB: Int
        }

        let payloadA = PayloadA(valueA: "test")
        let payloadB = PayloadB(valueB: 42)

        let fuseA = try FuseState(turns: 1, payload: payloadA)
        let fuseB = try FuseState(turns: 1, payload: payloadB)

        // Each fuse should only return its correct payload type
        #expect(fuseA.getPayload(as: PayloadA.self) == payloadA)
        #expect(fuseA.getPayload(as: PayloadB.self) == nil)

        #expect(fuseB.getPayload(as: PayloadB.self) == payloadB)
        #expect(fuseB.getPayload(as: PayloadA.self) == nil)
    }

    @Test("Primitive types as payloads work correctly")
    func testPrimitiveTypesAsPayloads() throws {
        let stringFuse = try FuseState(turns: 1, payload: "test string")
        let intFuse = try FuseState(turns: 1, payload: 42)
        let boolFuse = try FuseState(turns: 1, payload: true)
        let doubleFuse = try FuseState(turns: 1, payload: 3.14)

        #expect(stringFuse.getPayload(as: String.self) == "test string")
        #expect(intFuse.getPayload(as: Int.self) == 42)
        #expect(boolFuse.getPayload(as: Bool.self) == true)
        #expect(doubleFuse.getPayload(as: Double.self) == 3.14)

        // Cross-type access should return nil
        #expect(stringFuse.getPayload(as: Int.self) == nil)
        #expect(intFuse.getPayload(as: String.self) == nil)
        #expect(boolFuse.getPayload(as: Double.self) == nil)
    }
}
