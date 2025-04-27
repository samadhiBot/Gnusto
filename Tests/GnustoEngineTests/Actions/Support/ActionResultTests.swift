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
            property: "isOn",
            oldValue: AnyCodable(false),
            newValue: AnyCodable(true)
        )
        let effect = SideEffect(
            type: .startFuse,
            targetId: "bomb",
            parameters: ["duration": AnyCodable(10)]
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
        #expect(result.stateChanges.first?.objectId == "lamp")
        #expect(result.sideEffects.first?.type == .startFuse)
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
            property: "isOpen",
            oldValue: AnyCodable(false),
            newValue: AnyCodable(true)
        )

        #expect(change.objectId == "door")
        #expect(change.property == "isOpen")
        #expect(change.oldValue?.value as? Bool == false)
        #expect(change.newValue.value as? Bool == true)
    }

    @Test("StateChange Initialization without Old Value")
    func testStateChangeInitializationWithoutOldValue() {
        let change = StateChange(
            objectId: "player",
            property: "score",
            newValue: AnyCodable(10)
        )

        #expect(change.objectId == "player")
        #expect(change.property == "score")
        #expect(change.oldValue == nil)
        #expect(change.newValue.value as? Int == 10)
    }

    @Test("SideEffect Initialization")
    func testSideEffectInitialization() {
        let effect = SideEffect(
            type: .runDaemon,
            targetId: "clock",
            parameters: [
                "interval": AnyCodable(60),
                "message": AnyCodable("Tick tock")
            ]
        )

        #expect(effect.type == .runDaemon)
        #expect(effect.targetId == "clock")
        #expect(effect.parameters.count == 2)
        #expect(effect.parameters["interval"]?.value as? Int == 60)
        #expect(effect.parameters["message"]?.value as? String == "Tick tock")
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

    @Test("SideEffectType Codable Conformance")
    func testSideEffectTypeCodable() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let types: [SideEffectType] = [.startFuse, .stopFuse, .runDaemon, .stopDaemon, .scheduleEvent]

        for type in types {
            let encodedData = try encoder.encode(type)
            let decodedType = try decoder.decode(SideEffectType.self, from: encodedData)
            #expect(decodedType == type)

            // Verify string representation
            let stringValue = String(data: encodedData, encoding: .utf8)
            #expect(stringValue == "\"\(type.rawValue)\"")
        }
    }

}
