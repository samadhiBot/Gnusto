import CustomDump
import Foundation
import Testing

@testable import GnustoEngine

@Suite("ActionResult Tests")
struct ActionResultTests {

    // MARK: - Initial Setup and Examples

    // --- Simple Examples for Initialization Tests ---
    let simpleChange = StateChange(
        entityID: .item("lamp"),
        attributeKey: .itemAttribute(.isOn),
        oldValue: false,
        newValue: true
    )
    let simpleEffect = SideEffect(
        type: .startFuse,
        targetID: .fuse("bomb"),
        parameters: ["duration": .int(10)]
    )

    // --- Examples for Merging/Applying Tests ---
    // Note: These are now instance properties. `testResult` uses them,
    // so it needs to be accessed within a test method or be computed.
    private let change1 = StateChange(
        entityID: .item("lamp"),
        attributeKey: .itemAttribute(.isOn),
        oldValue: false,
        newValue: true
    )
    private let change2 = StateChange(
        entityID: .item("lamp"),
        attributeKey: .itemAttribute(.isTouched),
        oldValue: false,
        newValue: true
    )
    private let change3 = StateChange(
        entityID: .location("cave"),
        attributeKey: .locationAttribute(.isVisited), // Corrected: .isVisited
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

    // --- More Complex Examples for Apply/Validation ---
    let turnOnLampChanges = [
        StateChange(
            entityID: .item("lamp"),
            attributeKey: .itemAttribute(.isOn),
            oldValue: false,
            newValue: true
        ),
        StateChange( // Mark cave visited when lamp is turned on (example)
            entityID: .location("cave"),
            attributeKey: .locationAttribute(.isVisited),
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
        let result = ActionResult("You can't do that.")

        #expect(result.message == "You can't do that.")
        #expect(result.stateChanges.isEmpty == true)
        #expect(result.sideEffects.isEmpty == true)
    }

    @Test("StateChange Initialization - Full")
    func testStateChangeInitializationFull() {
        let change = StateChange(
            entityID: .item("door"),
            attributeKey: .itemAttribute(.isOpen),
            oldValue: false,
            newValue: true
        )

        #expect(change.entityID == .item("door"))
        #expect(change.attributeKey == .itemAttribute(.isOpen))
        #expect(change.oldValue == false)
        #expect(change.newValue == true)
    }

    @Test("StateChange Initialization - No Old Value")
    func testStateChangeInitializationWithoutOldValue() {
        let change = StateChange(
            entityID: .player,
            attributeKey: .playerScore,
            newValue: .int(10)
        )

        #expect(change.entityID == .player)
        #expect(change.attributeKey == .playerScore)
        #expect(change.oldValue == nil)
        #expect(change.newValue == StateValue.int(10))
    }

    @Test("StateChange Initialization - Set Flag")
    func testStateChangeInitializationSetFlag() {
        let change = StateChange(
            entityID: .global,
            attributeKey: .setFlag("lightsOut"),
            oldValue: false,
            newValue: true
        )

        #expect(change.attributeKey == AttributeKey.setFlag("lightsOut"))
        #expect(change.newValue == true)
        #expect(change.oldValue == false)
    }

    @Test("StateChange Initialization - Game Specific")
    func testStateChangeInitializationGameSpecific() {
        let change = StateChange(
            entityID: .global,
            attributeKey: .globalState(key: "puzzleCounter"),
            oldValue: .int(5),
            newValue: .int(6)
        )

        #expect(change.attributeKey == AttributeKey.globalState(key: "puzzleCounter"))
        #expect(change.newValue == StateValue.int(6))
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
        #expect(effect.parameters.isEmpty == true)
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

    @Test("StateattributeKey Codable Conformance")
    func testStateattributeKeyCodable() throws {
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
            .globalState(key: "testCounter")
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
        key: AttributeID,
        oldValue: StateValue? = nil,
        newValue: StateValue
    ) -> StateChange {
        StateChange(
            entityID: .item(id),
            attributeKey: .itemAttribute(key),
            oldValue: oldValue,
            newValue: newValue
        )
    }

    // Helper to create a simple location change for testing ActionResult merging
    private func createTestLocationChange(
        id: LocationID,
        key: AttributeID,
        oldValue: StateValue? = nil,
        newValue: StateValue
    ) -> StateChange {
        StateChange(
            entityID: .location(id),
            attributeKey: .locationAttribute(key),
            oldValue: oldValue,
            newValue: newValue
        )
    }

    // Helper to create a simple global change
    private func createGlobalChange(
        key: AttributeKey,
        oldValue: StateValue? = nil,
        newValue: StateValue
    ) -> StateChange {
        StateChange(entityID: .global, attributeKey: key, oldValue: oldValue, newValue: newValue)
    }

    // Example tests assuming an `ActionResult.merged(with:)` method exists
    // These will need adjustment if the merge API is different.

    @Test func testMergeSimpleResults() throws {
        let result1 = ActionResult(
            message: "First action.",
            stateChanges: [
                createTestItemChange(id: "lamp", key: .isOn, oldValue: false, newValue: true)
            ]
        )
        let result2 = ActionResult(
            message: "Second action.",
            stateChanges: [
                createTestLocationChange(id: "room", key: .isVisited, oldValue: false, newValue: true)
            ]
        )

        // Assuming a merge function combines changes and messages
        // let mergedResult = try result1.merged(with: result2)
        // #expect(mergedResult.message == "First action.\nSecond action.") // Example merge logic
        // #expect(mergedResult.changes.count == 2)
        // #expect(mergedResult.changes.contains { $0.attributeKey == .itemAttribute(.isOn) })
        // #expect(mergedResult.changes.contains { $0.attributeKey == .locationAttribute(.isVisited) })
        // #expect(mergedResult.success == true) // Both successful
    }

    @Test func testMergeOverlappingChanges_SameEntitySameProperty() throws {
        let result1 = ActionResult(
            message: "Action 1.",
            stateChanges: [
                createTestItemChange(id: "lamp", key: .isOn, oldValue: false, newValue: true) // Lamp Off -> On
            ]
        )
        let result2 = ActionResult(
            message: "Action 2.",
            stateChanges: [
                createTestItemChange(id: "lamp", key: .isOn, oldValue: true, newValue: false) // Lamp On -> Off
            ]
        )

        // Assuming merge coalesces changes
        // let mergedResult = try result1.merged(with: result2)
        // #expect(mergedResult.changes.count == 1) // Should coalesce
        // let finalChange = try #require(mergedResult.changes.first)
        // #expect(finalChange.entityID == .item("lamp"))
        // #expect(finalChange.attributeKey == .itemAttribute(.isOn))
        // #expect(finalChange.oldValue == false) // Original old value from result1
        // #expect(finalChange.newValue == false) // Final new value from result2
    }

    // MARK: - Apply/Validation Tests (Require Mock Engine/State)

    // These tests would typically involve a MockGameState or similar
    // to verify application and validation logic.
    // The structure below assumes such mocks exist.

    /* // Uncomment and adapt when mock infrastructure is ready
    @Test func testValidationSuccess() async throws {
        let mockState = MockGameState()
        mockState.items["lamp"] = Item(id: "lamp", name: "Lamp", attributes: [.isOn: false])
        mockState.locations["cave"] = Location(id: "cave", name: "Cave", attributes: [.isVisited: false])

        let result = ActionResult(
            message: "Turned on lamp and noted visit.",
            stateChanges: turnOnLampChanges
        )

        try await result.validate(against: mockState) // Expect no error
    }

    @Test func testValidationFailureWrongOldValue() async throws {
        let mockState = MockGameState()
        mockState.items["lamp"] = Item(id: "lamp", name: "Lamp", attributes: [.isOn: true]) // Lamp starts ON

        let result = ActionResult(
            message: "Turn on lamp.",
            stateChanges: [
                 StateChange(
                    entityID: .item("lamp"),
                    attributeKey: .itemAttribute(.isOn),
                    oldValue: false, // Expects OFF
                    newValue: true
                )
            ]
        )

        await #expect(throws: StateValidationError.oldValueMismatch) {
            try await result.validate(against: mockState)
        }
    }

    @Test func testApplyChangesSuccess() async throws {
        let mockState = MockGameState()
        mockState.items["lamp"] = Item(id: "lamp", name: "Lamp", attributes: [.isOn: false])
        mockState.locations["cave"] = Location(id: "cave", name: "Cave", attributes: [.isVisited: false])
        mockState.globals[.playerLocation] = .locationID("start")

        let result = ActionResult(
            message: "Applied changes.",
            stateChanges: turnOnLampChanges + [
                 StateChange(
                    entityID: .global,
                    attributeKey: .playerLocation,
                    oldValue: .locationID("start"),
                    newValue: .locationID("cave")
                 )
            ]
        )

        try await result.apply(to: mockState)

        #expect(mockState.items["lamp"].attributes[.isOn] == true)
        #expect(mockState.locations["cave"].attributes[.isVisited] == true)
        #expect(mockState.globals[.playerLocation] == .locationID("cave"))
    }
    */

    // --- Test Setup for previous structure ---

    // These properties are kept for context but are now initialized differently
    // or within test functions.

    // let change1: StateChange = ... (defined above)
    // let change2: StateChange = ... (defined above)

    // Corrected SideEffect initialization:
    let sideEffect1 = SideEffect(
        type: .scheduleEvent,
        targetID: .fuse("fuse"),
        parameters: [
            "turns": .int(5),
            "eventName": .string("FuseBurnDown")
        ]
    )

    // --- Tests from previous structure (adapted) ---

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
