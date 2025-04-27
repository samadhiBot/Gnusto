import CustomDump
import Foundation
import Testing

@testable import GnustoEngine

@Suite("ActionResult Tests")
struct ActionResultTests {

    @Test("ActionResult Initialization")
    func testActionResultInitialization() {
        let change = StateChange(
            objectId: "lamp",
            propertyKey: .itemProperties,
            oldValue: .itemProperties([.lightSource]),
            newValue: .itemProperties([.lightSource, .on])
        )
        let effect = SideEffect(
            type: .startFuse,
            targetId: "bomb",
            parameters: ["duration": .int(10)]
        )

        let result = ActionResult(
            success: true,
            message: "The lamp is now on.",
            stateChanges: [change],
            sideEffects: [effect]
        )

        #expect(result.success == true)
        #expect(result.message == "The lamp is now on.")
        #expect(result.stateChanges.count == 1)
        #expect(result.sideEffects.count == 1)
        #expect(result.stateChanges.first == change)
        #expect(result.sideEffects.first == effect)
    }

    @Test("ActionResult Default Initializer Values")
    func testActionResultDefaultInitialization() {
        let result = ActionResult(
            success: false,
            message: "You can't do that."
        )

        #expect(result.success == false)
        #expect(result.message == "You can't do that.")
        #expect(result.stateChanges.isEmpty == true)
        #expect(result.sideEffects.isEmpty == true)
    }

    @Test("StateChange Initialization")
    func testStateChangeInitialization() {
        let change = StateChange(
            objectId: "door",
            propertyKey: .itemProperties,
            oldValue: .itemProperties([.openable]),
            newValue: .itemProperties([.openable, .open])
        )

        #expect(change.objectId == "door")
        #expect(change.propertyKey == .itemProperties)
        #expect(change.oldValue == .itemProperties([.openable]))
        #expect(change.newValue == .itemProperties([.openable, .open]))
    }

    @Test("StateChange Initialization without Old Value")
    func testStateChangeInitializationWithoutOldValue() {
        let change = StateChange(
            objectId: "player",
            propertyKey: .playerScore,
            newValue: .int(10)
        )

        #expect(change.objectId == "player")
        #expect(change.propertyKey == .playerScore)
        #expect(change.oldValue == nil)
        #expect(change.newValue == .int(10))
    }

    @Test("StateChange Initialization for Global Flag")
    func testStateChangeInitializationGlobalFlag() {
        let change = StateChange(
            objectId: "unused",
            propertyKey: .globalFlag(key: "lightsOut"),
            oldValue: .bool(false),
            newValue: .bool(true)
        )

        #expect(change.propertyKey == .globalFlag(key: "lightsOut"))
        #expect(change.newValue == .bool(true))
    }

    @Test("StateChange Initialization for Game Specific State")
    func testStateChangeInitializationGameSpecific() {
        let change = StateChange(
            objectId: "unused",
            propertyKey: .gameSpecificState(key: "puzzleCounter"),
            oldValue: .int(5),
            newValue: .int(6)
        )

        #expect(change.propertyKey == .gameSpecificState(key: "puzzleCounter"))
        #expect(change.newValue == .int(6))
    }

    @Test("SideEffect Initialization")
    func testSideEffectInitialization() {
        let effect = SideEffect(
            type: .runDaemon,
            targetId: "clock",
            parameters: [
                "interval": .int(60),
                "message": .string("Tick tock")
            ]
        )

        #expect(effect.type == .runDaemon)
        #expect(effect.targetId == "clock")
        #expect(effect.parameters.count == 2)
        #expect(effect.parameters["interval"] == .int(60))
        #expect(effect.parameters["message"] == .string("Tick tock"))
    }

    @Test("SideEffect Initialization with Default Parameters")
    func testSideEffectInitializationWithDefaultParameters() {
        let effect = SideEffect(
            type: .stopDaemon,
            targetId: "clock"
        )

        #expect(effect.type == .stopDaemon)
        #expect(effect.targetId == "clock")
        #expect(effect.parameters.isEmpty == true)
    }

    @Test("StateValue Codable Conformance")
    func testStateValueCodable() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let values: [StateValue] = [
            .bool(true),
            .int(123),
            .string("hello"),
            .itemID("key"),
            .itemProperties([.takable, .lightSource]),
            .locationProperties([.inherentlyLit]),
            .parentEntity(.player)
        ]

        for value in values {
            let encodedData = try encoder.encode(value)
            let decodedValue = try decoder.decode(StateValue.self, from: encodedData)
            #expect(decodedValue == value)
        }
    }

    @Test("StatePropertyKey Codable Conformance")
    func testStatePropertyKeyCodable() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let keys: [StatePropertyKey] = [
            .itemParent,
            .itemProperties,
            .locationProperties,
            .playerScore,
            .globalFlag(key: "testFlag"),
            .gameSpecificState(key: "testCounter")
        ]

        for key in keys {
            let encodedData = try encoder.encode(key)
            let decodedKey = try decoder.decode(StatePropertyKey.self, from: encodedData)
            #expect(decodedKey == key)
        }
    }

}
