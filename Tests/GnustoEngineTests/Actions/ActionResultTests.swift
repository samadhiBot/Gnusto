import CustomDump
import Foundation
import Testing

@testable import GnustoEngine

@Suite("ActionResult Tests")
struct ActionResultTests {

    // MARK: - Initial Setup and Examples

    // — Simple Examples for Initialization Tests —
    let simpleChange = StateChange(
        entityID: .item("lamp"),
        attribute: .itemAttribute(.isOn),
        oldValue: false,
        newValue: true
    )
    let simpleEffect = SideEffect(
        type: .startFuse,
        targetID: .fuse("bomb"),
        parameters: ["duration": .int(10)]
    )

    // — Examples for Merging/Applying Tests —
    // Note: These are now instance properties. `testResult` uses them,
    // so it needs to be accessed within a test method or be computed.
    private let change1 = StateChange(
        entityID: .item("lamp"),
        attribute: .itemAttribute(.isOn),
        oldValue: false,
        newValue: true
    )
    private let change2 = StateChange(
        entityID: .item("lamp"),
        attribute: .itemAttribute(.isTouched),
        oldValue: false,
        newValue: true
    )
    private let change3 = StateChange(
        entityID: .location("cave"),
        attribute: .locationAttribute(.isVisited), // Corrected: .isVisited
        oldValue: false,
        newValue: true
    )

    // Computed property to create the ActionResult using other instance properties
    private var testResult: ActionResult {
        ActionResult(
            message: "Test message", // Message as String
            stateChanges: [change1, change2, change3] // Use instance properties
            // sideEffects: [] // Add if needed
        )
    }

    // — More Complex Examples for Apply/Validation —
    let turnOnLampChanges = [
        StateChange(
            entityID: .item("lamp"),
            attribute: .itemAttribute(.isOn),
            oldValue: false,
            newValue: true
        ),
        StateChange( // Mark cave visited when lamp is turned on (example)
            entityID: .location("cave"),
            attribute: .locationAttribute(.isVisited),
            oldValue: false,
            newValue: true
        )
    ]

    // MARK: - Basic Initialization Tests

    @Test("ActionResult Initialization - Full")
    func testActionResultFullInitialization() {
        let result = ActionResult(
            message: "The lamp is now on.",
            stateChanges: [simpleChange],
            sideEffects: [simpleEffect]
        )

        #expect(result.message == "The lamp is now on.")
        #expect(result.stateChanges.count == 1)
        #expect(result.sideEffects.count == 1)
        #expect(result.stateChanges.first == simpleChange)
        #expect(result.sideEffects.first == simpleEffect)
    }

    @Test("ActionResult Initialization - Defaults")
    func testActionResultDefaultInitialization() {
        let result = ActionResult("You can’t do that.")

        #expect(result.message == "You can’t do that.")
        #expect(result.stateChanges.isEmpty)
        #expect(result.sideEffects.isEmpty)
    }

    @Test("StateChange Initialization - Full")
    func testStateChangeInitializationFull() {
        let change = StateChange(
            entityID: .item("door"),
            attribute: .itemAttribute(.isOpen),
            oldValue: false,
            newValue: true
        )

        #expect(change.entityID == .item("door"))
        #expect(change.attribute == .itemAttribute(.isOpen))
        #expect(change.oldValue == false)
        #expect(change.newValue == true)
    }

    @Test("StateChange Initialization - No Old Value")
    func testStateChangeInitializationWithoutOldValue() {
        let change = StateChange(
            entityID: .player,
            attribute: .playerScore,
            newValue: .int(10)
        )

        #expect(change.entityID == .player)
        #expect(change.attribute == .playerScore)
        #expect(change.oldValue == nil)
        #expect(change.newValue == .int(10))
    }

    @Test("StateChange Initialization - Set Flag")
    func testStateChangeInitializationSetFlag() {
        let change = StateChange(
            entityID: .global,
            attribute: .setFlag("lightsOut"),
            oldValue: false,
            newValue: true
        )

        #expect(change.attribute == .setFlag("lightsOut"))
        #expect(change.newValue == true)
        #expect(change.oldValue == false)
    }

    @Test("StateChange Initialization - Game Specific")
    func testStateChangeInitializationGameSpecific() {
        let change = StateChange(
            entityID: .global,
            attribute: .globalState(attributeID: "puzzleCounter"),
            oldValue: .int(5),
            newValue: .int(6)
        )

        #expect(change.attribute == .globalState(attributeID: "puzzleCounter"))
        #expect(change.newValue == .int(6))
    }

    @Test("SideEffect Initialization - Full")
    func testSideEffectInitializationFull() {
        let effect = SideEffect(
            type: .runDaemon,
            targetID: .daemon("clock"),
            parameters: [
                "interval": .int(60),
                "message": .string("Tick tock")
            ]
        )

        #expect(effect.type == .runDaemon)
        #expect(effect.targetID == .daemon("clock"))
        #expect(effect.parameters.count == 2)
        #expect(effect.parameters["interval"] == .int(60))
        #expect(effect.parameters["message"] == .string("Tick tock"))
    }

    @Test("SideEffect Initialization - Defaults")
    func testSideEffectInitializationWithDefaultParameters() {
        let effect = SideEffect(
            type: .stopDaemon,
            targetID: .daemon("clock")
        )

        #expect(effect.type == .stopDaemon)
        #expect(effect.targetID == .daemon("clock"))
        #expect(effect.parameters.isEmpty)
    }

    // MARK: - Codable Conformance Tests

    @Test("StateValue Codable Conformance")
    func testStateValueCodable() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let values: [StateValue] = [
            true,
            .int(123),
            .string("hello"),
            .itemID("key"),
            .itemIDSet(["key1", "key2"]),
            .stringSet(["adj1", "adj2"]),
            .parentEntity(.player),
            .locationID("room1"),
        ]

        for value in values {
            let encodedData = try encoder.encode(value)
            let decodedValue = try decoder.decode(StateValue.self, from: encodedData)
            #expect(decodedValue == value, "Failed for \(value)")
        }
    }

    @Test("StateattributeID Codable Conformance")
    func testStateattributeIDCodable() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let keys: [AttributeKey] = [
            .itemAttribute(.adjectives),
            .itemAttribute(.capacity),
            .itemAttribute(.isContainer),
            .itemParent,
            .locationAttribute(.inherentlyLit),
            .locationAttribute(.isSacred),
            .playerScore,
            .playerLocation,
            .setFlag("testFlag"),
            .globalState(attributeID: "testCounter")
        ]

        for key in keys {
            let encodedData = try encoder.encode(key)
            let decodedKey = try decoder.decode(AttributeKey.self, from: encodedData)
            #expect(decodedKey == key, "Failed for \(key)")
        }
    }

    // MARK: - Merging Tests (Assuming merge logic exists on ActionResult)

    // Helper to create a simple item change for testing ActionResult merging
    private func createTestItemChange(
        id: ItemID,
        attributeID: AttributeID,
        oldValue: StateValue? = nil,
        newValue: StateValue
    ) -> StateChange {
        StateChange(
            entityID: .item(id),
            attribute: .itemAttribute(attributeID),
            oldValue: oldValue,
            newValue: newValue
        )
    }

    // Helper to create a simple location change for testing ActionResult merging
    private func createTestLocationChange(
        id: LocationID,
        attributeID: AttributeID,
        oldValue: StateValue? = nil,
        newValue: StateValue
    ) -> StateChange {
        StateChange(
            entityID: .location(id),
            attribute: .locationAttribute(attributeID),
            oldValue: oldValue,
            newValue: newValue
        )
    }

    // Helper to create a simple global change
    private func createGlobalChange(
        attributeID: AttributeKey,
        oldValue: StateValue? = nil,
        newValue: StateValue
    ) -> StateChange {
        StateChange(
            entityID: .global,
            attribute: attributeID,
            oldValue: oldValue,
            newValue: newValue
        )
    }

    // Corrected SideEffect initialization:
    let sideEffect1 = SideEffect(
        type: .scheduleEvent,
        targetID: .fuse("fuse"),
        parameters: [
            "turns": .int(5),
            "eventName": .string("FuseBurnDown")
        ]
    )

    @Test("ActionResult Initialization - Previous Structure Style")
    func testInitializationFromPreviousStyle() {
        // Initialize here where self.change1, self.change2 etc. are accessible
        let resultWithChangesAndEffects = ActionResult(
            message: "Action succeeded.",
            stateChanges: [change1, change2], // Using the corrected change1/change2
            sideEffects: [sideEffect1]      // Using the corrected sideEffect1
        )

        #expect(resultWithChangesAndEffects.message == "Action succeeded.")
        #expect(resultWithChangesAndEffects.stateChanges.count == 2)
        #expect(resultWithChangesAndEffects.stateChanges.contains(change1))
        #expect(resultWithChangesAndEffects.stateChanges.contains(change2))
        #expect(resultWithChangesAndEffects.sideEffects.count == 1)

        // Check if the side effect is the correct type and has params
        let effect = resultWithChangesAndEffects.sideEffects.first
        #expect(effect?.type == .scheduleEvent)
        #expect(effect?.targetID == .fuse("fuse"))
        #expect(effect?.parameters["turns"] == .int(5))
        #expect(effect?.parameters["eventName"] == .string("FuseBurnDown"))
    }
}
