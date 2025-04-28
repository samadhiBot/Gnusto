import CustomDump
import Foundation
import Testing

@testable import GnustoEngine

@Suite("ActionResult Tests")
struct ActionResultTests {

    @Test("ActionResult Initialization")
    func testActionResultInitialization() {
        let change = StateChange(
            entityId: .item("lamp"),
            propertyKey: .itemProperties,
            oldValue: StateValue.itemProperties([.lightSource]),
            newValue: StateValue.itemProperties([ItemProperty.lightSource, ItemProperty.on])
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
            entityId: .item("door"),
            propertyKey: .itemProperties,
            oldValue: StateValue.itemProperties([ItemProperty.openable]),
            newValue: StateValue.itemProperties([ItemProperty.openable, ItemProperty.open])
        )

        #expect(change.entityId == .item("door"))
        #expect(change.propertyKey == .itemProperties)
        #expect(change.oldValue == StateValue.itemProperties([ItemProperty.openable]))
        #expect(change.newValue == StateValue.itemProperties([ItemProperty.openable, ItemProperty.open]))
    }

    @Test("StateChange Initialization without Old Value")
    func testStateChangeInitializationWithoutOldValue() {
        let change = StateChange(
            entityId: .player,
            propertyKey: .playerScore,
            newValue: StateValue.int(10)
        )

        #expect(change.entityId == .player)
        #expect(change.propertyKey == .playerScore)
        #expect(change.oldValue == nil)
        #expect(change.newValue == StateValue.int(10))
    }

    @Test("StateChange Initialization for Global Flag")
    func testStateChangeInitializationGlobalFlag() {
        let change = StateChange(
            entityId: .global,
            propertyKey: .globalFlag(key: "lightsOut"),
            oldValue: StateValue.bool(false),
            newValue: StateValue.bool(true)
        )

        #expect(change.propertyKey == StatePropertyKey.globalFlag(key: "lightsOut"))
        #expect(change.newValue == StateValue.bool(true))
    }

    @Test("StateChange Initialization for Game Specific State")
    func testStateChangeInitializationGameSpecific() {
        let change = StateChange(
            entityId: .global,
            propertyKey: .gameSpecificState(key: "puzzleCounter"),
            oldValue: StateValue.int(5),
            newValue: StateValue.int(6)
        )

        #expect(change.propertyKey == StatePropertyKey.gameSpecificState(key: "puzzleCounter"))
        #expect(change.newValue == StateValue.int(6))
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
