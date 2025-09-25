import CustomDump
import Foundation
import GnustoEngine
import GnustoTestSupport
import Testing

@Suite("ActionResult Tests")
struct ActionResultTests {

    // MARK: - Initial Setup and Examples

    // - Simple Examples for Initialization Tests -
    let simpleChange = StateChange.setItemProperty(id: "lamp", property: .isOn, value: .bool(true))
    let simpleEffect = try? SideEffect.startFuse("bomb", turns: 10)

    // - Examples for Merging/Applying Tests -
    // Note: These are now instance properties. `testResult` uses them,
    // so it needs to be accessed within a test method or be computed.
    private let change1 = StateChange.setItemProperty(
        id: "lamp", property: .isOn, value: .bool(true))
    private let change2 = StateChange.setItemProperty(
        id: "lamp", property: .isTouched, value: .bool(true))
    private let change3 = StateChange.setLocationProperty(
        id: "cave", property: .isVisited, value: .bool(true))

    // Computed property to create the ActionResult using other instance properties
    private var testResult: ActionResult {
        ActionResult(
            message: "🤡 Test message",  // Message as String
            changes: [change1, change2, change3]  // Use instance properties
            // effects: [] // Add if needed
        )
    }

    // - More Complex Examples for Apply/Validation -
    let turnOnLampChanges = [
        StateChange.setItemProperty(id: "lamp", property: .isOn, value: .bool(true)),
        StateChange.setLocationProperty(id: "cave", property: .isVisited, value: .bool(true)),  // Mark cave visited when lamp is turned on (example)
    ]

    // MARK: - Basic Initialization Tests

    @Test("ActionResult Initialization - Full")
    func testActionResultFullInitialization() {
        let result = ActionResult(
            message: "The lamp is now on.",
            changes: [simpleChange],
            effects: [simpleEffect]
        )

        #expect(result.message == "The lamp is now on.")
        #expect(result.changes.count == 1)
        #expect(result.effects.count == 1)
        #expect(result.changes.first == simpleChange)
        #expect(result.effects.first == simpleEffect)
    }

    @Test("ActionResult Initialization - Defaults")
    func testActionResultDefaultInitialization() {
        let result = ActionResult("You can't do that.")

        #expect(result.message == "You can't do that.")
        #expect(result.changes.isEmpty)
        #expect(result.effects.isEmpty)
    }

    @Test("StateChange Initialization - Full")
    func testStateChangeInitializationFull() {
        let change = StateChange.setItemProperty(id: "door", property: .isOpen, value: .bool(true))

        // Test the enum case directly
        if case .setItemProperty(let id, let property, let value) = change {
            #expect(id == "door")
            #expect(property == .isOpen)
            #expect(value == .bool(true))
        } else {
            Issue.record("Expected setItemProperty case")
        }
    }

    @Test("StateChange Initialization - Player Score")
    func testStateChangeInitializationPlayerScore() {
        let change = StateChange.setPlayerScore(to: 10)

        if case .setPlayerScore(let score) = change {
            #expect(score == 10)
        } else {
            Issue.record("Expected setPlayerScore case")
        }
    }

    @Test("StateChange Initialization - Set Flag")
    func testStateChangeInitializationSetFlag() {
        let change = StateChange.setFlag("lightsOut")

        if case .setFlag(let globalID) = change {
            #expect(globalID == "lightsOut")
        } else {
            Issue.record("Expected setFlag case")
        }
    }

    @Test("StateChange Initialization - Game Specific Global State")
    func testStateChangeInitializationGameSpecific() {
        let change = StateChange.setGlobalState(id: "puzzleCounter", value: 6)

        if case .setGlobalState(let globalID, let value) = change {
            #expect(globalID == "puzzleCounter")
            #expect(value == .int(6))
        } else {
            Issue.record("Expected setGlobalState case")
        }
    }

    @Test("SideEffect Initialization - Full")
    func testSideEffectInitializationFull() throws {
        let daemonState = DaemonState()
        let effect = try SideEffect.runDaemon("clock", state: daemonState)

        #expect(effect.type == .runDaemon)
        #expect(effect.targetID == .daemon("clock"))
        #expect(effect.payload != nil)
    }

    @Test("SideEffect Initialization - Defaults")
    func testSideEffectInitializationWithDefaultParameters() throws {
        let effect = try SideEffect.stopDaemon("clock")

        #expect(effect.type == .stopDaemon)
        #expect(effect.targetID == .daemon("clock"))
        #expect(effect.payload == nil)
    }

    // MARK: - Codable Conformance Tests

    @Test("StateValue Codable Conformance")
    func testStateValueCodable() throws {
        let encoder = JSONEncoder.sorted()
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

    @Test("StateChange Codable Conformance")
    func testStateChangeCodable() throws {
        let encoder = JSONEncoder.sorted()
        let decoder = JSONDecoder()

        let changes: [StateChange] = [
            .setItemProperty(id: "lamp", property: .isOn, value: .bool(true)),
            .moveItem(id: "key", to: .player),
            .setPlayerScore(to: 100),
            .setFlag("lightsOut"),
            .setGlobalInt(id: "score", value: 42),
            .movePlayer(to: .startRoom),
            .addActiveFuse(fuseID: "bomb", state: FuseState(turns: 5)),
        ]

        for change in changes {
            let encodedData = try encoder.encode(change)
            let decodedChange = try decoder.decode(StateChange.self, from: encodedData)
            #expect(decodedChange == change, "Failed for \(change)")
        }
    }

    // MARK: - Helper Methods for Testing

    // Helper to create a simple item change for testing ActionResult merging
    private func createTestItemChange(
        id: ItemID,
        propertyID: ItemPropertyID,
        newValue: StateValue
    ) -> StateChange {
        StateChange.setItemProperty(id: id, property: propertyID, value: newValue)
    }

    // Helper to create a simple location change for testing ActionResult merging
    private func createTestLocationChange(
        id: LocationID,
        propertyID: LocationPropertyID,
        newValue: StateValue
    ) -> StateChange {
        StateChange.setLocationProperty(id: id, property: propertyID, value: newValue)
    }

    // Helper to create a simple global change
    private func createGlobalIntChange(
        globalID: GlobalID,
        value: Int
    ) -> StateChange {
        StateChange.setGlobalInt(id: globalID, value: value)
    }

    // Helper to create a flag change
    private func createFlagChange(globalID: GlobalID) -> StateChange {
        StateChange.setFlag(globalID)
    }

    // Corrected SideEffect initialization:
    let sideEffect1 = try? SideEffect.startFuse("fuse", turns: 5)

    @Test("ActionResult Initialization - Previous Structure Style")
    func testInitializationFromPreviousStyle() {
        // Initialize here where self.change1, self.change2 etc. are accessible
        let resultWithChangesAndEffects = ActionResult(
            message: "Action succeeded.",
            changes: [change1, change2],  // Using the corrected change1/change2
            effects: [sideEffect1]  // Using the corrected sideEffect1
        )

        #expect(resultWithChangesAndEffects.message == "Action succeeded.")
        #expect(resultWithChangesAndEffects.changes.count == 2)
        #expect(resultWithChangesAndEffects.changes.contains(change1))
        #expect(resultWithChangesAndEffects.changes.contains(change2))
        #expect(resultWithChangesAndEffects.effects.count == 1)

        // Check if the side effect is the correct type and has params
        let effect = resultWithChangesAndEffects.effects.first
        #expect(effect?.type == .startFuse)
        #expect(effect?.targetID == .fuse("fuse"))
        #expect(effect?.payload != nil)
    }

    // MARK: - StateChange Pattern Matching Tests

    @Test("StateChange pattern matching - moveItem")
    func testStateChangePatternMatchingMoveItem() {
        let change = StateChange.moveItem(id: "sword", to: .location("treasury"))

        if case .moveItem(let itemID, let parent) = change {
            #expect(itemID == "sword")
            #expect(parent == .location("treasury"))
        } else {
            Issue.record("Expected moveItem case")
        }
    }

    @Test("StateChange pattern matching - addActiveFuse")
    func testStateChangePatternMatchingAddActiveFuse() {
        let change = StateChange.addActiveFuse(
            fuseID: "timeBomb",
            state: FuseState(turns: 10)
        )

        if case .addActiveFuse(let fuseID, let fuseState) = change {
            #expect(fuseID == "timeBomb")
            #expect(fuseState.turns == 10)
        } else {
            Issue.record("Expected addActiveFuse case")
        }
    }

    @Test("StateChange pattern matching - clearFlag")
    func testStateChangePatternMatchingClearFlag() {
        let change = StateChange.clearFlag("lightsOut")

        if case .clearFlag(let globalID) = change {
            #expect(globalID == "lightsOut")
        } else {
            Issue.record("Expected clearFlag case")
        }
    }

    // MARK: - Yield Functionality Tests

    @Test("ActionResult.yield has correct properties")
    func testYield() {
        let result = ActionResult.yield

        #expect(result.shouldYieldToEngine == true)
        #expect(result.message == nil)
        #expect(result.changes.isEmpty)
        #expect(result.effects.isEmpty)
    }

    @Test("ActionResult with shouldYieldToEngine set manually")
    func testYieldToEngineProperty() {
        let result = ActionResult(
            message: "Test message",
            changes: [simpleChange],
            shouldYieldToEngine: true
        )

        #expect(result.shouldYieldToEngine == true)
        #expect(result.message == "Test message")
        #expect(result.changes.count == 1)
        #expect(result.effects.isEmpty)
    }

    @Test("ActionResult with shouldYieldToEngine false by default")
    func testDefaultYieldToEngine() {
        let result = ActionResult("Regular message")

        #expect(result.shouldYieldToEngine == false)
        #expect(result.message == "Regular message")
    }

    // MARK: - StateChange Equality Tests

    @Test("StateChange equality - same content")
    func testStateChangeEquality() {
        let change1 = StateChange.setItemProperty(id: "lamp", property: .isOn, value: .bool(true))
        let change2 = StateChange.setItemProperty(id: "lamp", property: .isOn, value: .bool(true))

        #expect(change1 == change2)
    }

    @Test("StateChange inequality - different values")
    func testStateChangeInequality() {
        let change1 = StateChange.setItemProperty(id: "lamp", property: .isOn, value: .bool(true))
        let change2 = StateChange.setItemProperty(id: "lamp", property: .isOn, value: .bool(false))

        #expect(change1 != change2)
    }

    @Test("StateChange inequality - different items")
    func testStateChangeInequalityDifferentItems() {
        let change1 = StateChange.moveItem(id: "sword", to: .player)
        let change2 = StateChange.moveItem(id: "shield", to: .player)

        #expect(change1 != change2)
    }
}
