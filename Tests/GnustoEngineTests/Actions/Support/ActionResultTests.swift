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
            oldValue: .itemPropertySet([.lightSource]),
            newValue: .itemPropertySet([.lightSource, .on])
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
            propertyKey: .itemDynamicValue(key: .isOpen),
            oldValue: false,
            newValue: true
        )

        #expect(change.entityId == .item("door"))
        #expect(change.propertyKey == .itemDynamicValue(key: .isOpen))
        #expect(change.oldValue == false)
        #expect(change.newValue == true)
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
            propertyKey: .setFlag("lightsOut"),
            oldValue: StateValue.bool(false),
            newValue: StateValue.bool(true)
        )

        #expect(change.propertyKey == StatePropertyKey.setFlag("lightsOut"))
        #expect(change.newValue == StateValue.bool(true))
        #expect(change.oldValue == StateValue.bool(false))
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
            .itemPropertySet([.takable, .lightSource]),
            .locationPropertySet([.inherentlyLit]),
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
            .setFlag("testFlag"),
            .gameSpecificState(key: "testCounter")
        ]

        for key in keys {
            let encodedData = try encoder.encode(key)
            let decodedKey = try decoder.decode(StatePropertyKey.self, from: encodedData)
            #expect(decodedKey == key)
        }
    }

    // Example StateChanges for testing
    private let change1 = StateChange(
        entityId: .item(id: "lamp"),
        propertyKey: .itemDynamicValue(key: .isOn),
        oldValue: .bool(false),
        newValue: .bool(true)
    )
    private let change2 = StateChange(
        entityId: .item(id: "lamp"),
        propertyKey: .itemDynamicValue(key: .itemTouched),
        oldValue: .bool(false),
        newValue: .bool(true)
    )
    private let change3 = StateChange(
        entityId: .location(id: "cave"),
        propertyKey: .locationDynamicValue(key: .locationVisited),
        oldValue: .bool(false),
        newValue: .bool(true)
    )

    // Example ActionResult for testing
    private let testResult = ActionResult(
        message: .init(text: "Test message"),
        changes: [change1, change2, change3]
    )

    @Test func testMergingActionResults() {
        // ... existing code ...
        #expect(mergedResult.changes.count == 5)

        // Check specific merged changes (adjust based on what change1, change2 etc. represent)
        #expect(
            mergedResult.changes.contains {
                $0.entityId == .item(id: "lamp") &&
                $0.propertyKey == .itemDynamicValue(key: .isOn) &&
                $0.oldValue == .bool(false) && // From result1
                $0.newValue == .bool(true)     // From result2 (no change for this specific prop)
            }
        )
        #expect(
            mergedResult.changes.contains {
                $0.entityId == .item(id: "lamp") &&
                $0.propertyKey == .itemDynamicValue(key: .itemTouched) &&
                $0.oldValue == .bool(false) && // From result1
                $0.newValue == .bool(true)     // From result2
            }
        )
        #expect(
            mergedResult.changes.contains {
                $0.entityId == .location(id: "cave") &&
                $0.propertyKey == .locationDynamicValue(key: .locationVisited) &&
                $0.oldValue == .bool(false) && // From result1
                $0.newValue == .bool(true)     // From result2
            }
        )
        #expect(
            mergedResult.changes.contains {
                $0.entityId == .item(id: "key") &&
                $0.propertyKey == .itemParent &&
                $0.oldValue == .parent(.player) &&
                $0.newValue == .parent(.location(id: "hall"))
            }
        )
        #expect(
            mergedResult.changes.contains {
                $0.entityId == .global &&
                $0.propertyKey == .playerLocation &&
                $0.oldValue == .locationID("hall") &&
                $0.newValue == .locationID("chamber")
            }
        )
    }

    @Test func testValidationSuccess() async throws {
        // ... existing code ...
        // Setup initial state
        engine.state.items["lamp"] = Item(
            id: "lamp",
            name: "Brass Lamp",
            dynamicValues: [.isOn: .bool(false)] // Start with lamp off
        )
        engine.state.locations["cave"] = Location(
            id: "cave",
            name: "Dark Cave",
            dynamicValues: [.locationVisited: .bool(false)] // Start unvisited
        )

        let result = ActionResult(
            message: .init(text: "Turned on lamp and noted visit."),
            changes: [
                StateChange( // Turn lamp on
                    entityId: .item(id: "lamp"),
                    propertyKey: .itemDynamicValue(key: .isOn),
                    oldValue: .bool(false),
                    newValue: .bool(true)
                ),
                StateChange( // Mark cave visited
                    entityId: .location(id: "cave"),
                    propertyKey: .locationDynamicValue(key: .locationVisited),
                    oldValue: .bool(false),
                    newValue: .bool(true)
                ),
            ]
        )
        // ... existing code ...
    }

    @Test func testValidationFailureWrongOldValue() async throws {
        // ... existing code ...
        engine.state.items["lamp"] = Item(
            id: "lamp",
            name: "Brass Lamp",
            dynamicValues: [.isOn: .bool(true)] // Lamp is ALREADY on
        )

        let result = ActionResult(
            message: .init(text: "Turned on lamp."),
            changes: [
                StateChange(
                    entityId: .item(id: "lamp"),
                    propertyKey: .itemDynamicValue(key: .isOn),
                    oldValue: .bool(false), // Expects lamp to be off
                    newValue: .bool(true)
                )
            ]
        )
        // ... existing code ...
    }

    @Test func testValidationFailureNoSuchEntity() async throws {
        // ... existing code ...
        // Ensure "lamp" does NOT exist in the initial state

        let result = ActionResult(
            message: .init(text: "Turned on non-existent lamp."),
            changes: [
                StateChange(
                    entityId: .item(id: "lamp"), // Refers to non-existent item
                    propertyKey: .itemDynamicValue(key: .isOn),
                    oldValue: .bool(false),
                    newValue: .bool(true)
                )
            ]
        )
        // ... existing code ...
    }

    @Test func testValidationFailureWrongPropertyKeyType() async throws {
        // ... existing code ...
        engine.state.items["lamp"] = Item(id: "lamp", name: "Brass Lamp")

        let result = ActionResult(
            message: .init(text: "Incorrect property key."),
            changes: [
                StateChange(
                    entityId: .item(id: "lamp"),
                    propertyKey: .locationDynamicValue(key: .locationVisited), // Wrong key type for item
                    oldValue: .bool(false),
                    newValue: .bool(true)
                )
            ]
        )
        // ... existing code ...
    }

    @Test func testApplyChangesSuccess() async throws {
        // ... existing code ...
        engine.state.items["lamp"] = Item(
            id: "lamp",
            name: "Brass Lamp",
            dynamicValues: [
                .isOn: .bool(false),
                .isLightSource: .bool(true) // Mark as light source
            ]
        )
        engine.state.locations["cave"] = Location(
            id: "cave",
            name: "Dark Cave",
            dynamicValues: [
                .locationInherentlyLit: .bool(false) // Not lit initially
            ]
        )

        let result = ActionResult(
            message: .init(text: "Applied changes."),
            changes: [
                // Turn lamp on
                StateChange(
                    entityId: .item(id: "lamp"),
                    propertyKey: .itemDynamicValue(key: .isOn),
                    oldValue: .bool(false),
                    newValue: .bool(true)
                ),
                // Mark cave as lit (perhaps by an action)
                StateChange(
                    entityId: .location(id: "cave"),
                    propertyKey: .locationDynamicValue(key: .locationIsLit), // Use the isLit flag
                    oldValue: .bool(false),
                    newValue: .bool(true)
                ),
                // Change player location
                StateChange(
                    entityId: .global,
                    propertyKey: .playerLocation,
                    oldValue: .locationID("start"),
                    newValue: .locationID("cave")
                ),
                // Set a game-specific flag
                StateChange(
                    entityId: .global,
                    propertyKey: .gameSpecificState(key: "puzzleSolved"),
                    oldValue: .bool(false),
                    newValue: .bool(true)
                ),
            ]
        )
        // ... existing code ...
        // Validate applied state
        #expect(await engine.item(with: "lamp")?.hasFlag(.isOn) == true)
        #expect(await engine.location(with: "cave")?.hasFlag(.locationIsLit) == true)
        #expect(engine.state.playerLocation == "cave")
        #expect(engine.state.gameSpecificState["puzzleSolved"] == .bool(true))
    }

    @Test func testApplyChangesFailure() async throws {
        // ... existing code ...
        // Setup initial state where validation would fail (e.g., lamp already on)
        engine.state.items["lamp"] = Item(
            id: "lamp",
            name: "Brass Lamp",
            dynamicValues: [.isOn: .bool(true)] // Lamp starts 'on'
        )

        let result = ActionResult(
            message: .init(text: "Failed to apply."),
            changes: [
                StateChange(
                    entityId: .item(id: "lamp"),
                    propertyKey: .itemDynamicValue(key: .isOn),
                    oldValue: .bool(false), // This validation will fail
                    newValue: .bool(true)
                )
            ]
        )
        // ... existing code ...
        // Validate state hasn't changed
        #expect(await engine.item(with: "lamp")?.hasFlag(.isOn) == true)
    }

    // Helper to create a simple item for testing ActionResult merging
    private func createTestItemChange(
        id: ItemID,
        key: PropertyID,
        oldValue: StateValue,
        newValue: StateValue
    ) -> StateChange {
        StateChange(
            entityId: .item(id: id),
            propertyKey: .itemDynamicValue(key: key),
            oldValue: oldValue,
            newValue: newValue
        )
    }

    // Helper to create a simple location change for testing ActionResult merging
    private func createTestLocationChange(
        id: LocationID,
        key: PropertyID,
        oldValue: StateValue,
        newValue: StateValue
    ) -> StateChange {
        StateChange(
            entityId: .location(id: id),
            propertyKey: .locationDynamicValue(key: key),
            oldValue: oldValue,
            newValue: newValue
        )
    }

    // Helper to create a simple global change
    private func createGlobalChange(
        key: StatePropertyKey,
        oldValue: StateValue,
        newValue: StateValue
    ) -> StateChange {
        StateChange(entityId: .global, propertyKey: key, oldValue: oldValue, newValue: newValue)
    }

    // MARK: - ActionResult Merging Tests

    @Test func testMergeSimpleResults() throws {
        let result1 = ActionResult(
            message: .init(text: "First action."),
            changes: [
                createTestItemChange(id: "lamp", key: .isOn, oldValue: .bool(false), newValue: .bool(true))
            ]
        )
        let result2 = ActionResult(
            message: .init(text: "Second action."),
            changes: [
                createTestLocationChange(id: "room", key: .locationVisited, oldValue: .bool(false), newValue: .bool(true))
            ]
        )
        // ... existing code ...
        #expect(mergedResult.changes.count == 2)
        #expect(mergedResult.changes.contains { $0.propertyKey == .itemDynamicValue(key: .isOn) })
        #expect(mergedResult.changes.contains { $0.propertyKey == .locationDynamicValue(key: .locationVisited) })
    }

    @Test func testMergeOverlappingChanges_DifferentEntities() throws {
        let result1 = ActionResult(
            message: .init(text: "Action 1."),
            changes: [
                createTestItemChange(id: "lamp", key: .isOn, oldValue: .bool(false), newValue: .bool(true))
            ]
        )
        let result2 = ActionResult(
            message: .init(text: "Action 2."),
            changes: [
                createTestItemChange(id: "torch", key: .isOn, oldValue: .bool(false), newValue: .bool(true)) // Different item
            ]
        )
        // ... existing code ...
        #expect(mergedResult.changes.count == 2)
        #expect(mergedResult.changes.contains { $0.entityId == .item(id: "lamp") && $0.propertyKey == .itemDynamicValue(key: .isOn) })
        #expect(mergedResult.changes.contains { $0.entityId == .item(id: "torch") && $0.propertyKey == .itemDynamicValue(key: .isOn) })
    }

    @Test func testMergeOverlappingChanges_SameEntityDifferentProperty() throws {
        let result1 = ActionResult(
            message: .init(text: "Action 1."),
            changes: [
                createTestItemChange(id: "lamp", key: .isOn, oldValue: .bool(false), newValue: .bool(true))
            ]
        )
        let result2 = ActionResult(
            message: .init(text: "Action 2."),
            changes: [
                createTestItemChange(id: "lamp", key: .itemValue, oldValue: .int(0), newValue: .int(10)) // Same item, different property
            ]
        )
        // ... existing code ...
        #expect(mergedResult.changes.count == 2)
        #expect(mergedResult.changes.contains { $0.entityId == .item(id: "lamp") && $0.propertyKey == .itemDynamicValue(key: .isOn) })
        #expect(mergedResult.changes.contains { $0.entityId == .item(id: "lamp") && $0.propertyKey == .itemDynamicValue(key: .itemValue) })
    }

    @Test func testMergeOverlappingChanges_SameEntitySameProperty() throws {
        let result1 = ActionResult(
            message: .init(text: "Action 1."),
            changes: [
                createTestItemChange(id: "lamp", key: .isOn, oldValue: .bool(false), newValue: .bool(true)) // Lamp Off -> On
            ]
        )
        let result2 = ActionResult(
            message: .init(text: "Action 2."),
            changes: [
                createTestItemChange(id: "lamp", key: .isOn, oldValue: .bool(true), newValue: .bool(false)) // Lamp On -> Off
            ]
        )
        // ... existing code ...
        #expect(mergedResult.changes.count == 1) // Should coalesce
        let finalChange = try #require(mergedResult.changes.first)
        #expect(finalChange.entityId == .item(id: "lamp"))
        #expect(finalChange.propertyKey == .itemDynamicValue(key: .isOn))
        #expect(finalChange.oldValue == .bool(false)) // Original old value from result1
        #expect(finalChange.newValue == .bool(false)) // Final new value from result2
    }

    @Test func testMergeComplexSequence() throws {
        let result1 = ActionResult(
            message: .init(text: "Take lamp."),
            changes: [
                createTestItemChange(id: "lamp", key: .itemParent, oldValue: .parent(.location(id: "room")), newValue: .parent(.player)),
                createTestItemChange(id: "lamp", key: .itemTouched, oldValue: .bool(false), newValue: .bool(true)),
            ]
        )
        let result2 = ActionResult(
            message: .init(text: "Turn on lamp."),
            changes: [
                createTestItemChange(id: "lamp", key: .isOn, oldValue: .bool(false), newValue: .bool(true)),
                // Touched again, but should coalesce with the previous touched change
                createTestItemChange(id: "lamp", key: .itemTouched, oldValue: .bool(true), newValue: .bool(true)),
            ]
        )
        let result3 = ActionResult(
            message: .init(text: "Drop lamp."),
            changes: [
                createTestItemChange(id: "lamp", key: .itemParent, oldValue: .parent(.player), newValue: .parent(.location(id: "floor"))),
                // Touched again
                createTestItemChange(id: "lamp", key: .itemTouched, oldValue: .bool(true), newValue: .bool(true)),
            ]
        )
        // ... existing code ...
        #expect(mergedResult.changes.count == 3) // Parent, Touched, IsOn

        let parentChange = try #require(mergedResult.changes.first { $0.propertyKey == .itemParent })
        #expect(parentChange.oldValue == .parent(.location(id: "room")))
        #expect(parentChange.newValue == .parent(.location(id: "floor")))

        let touchedChange = try #require(mergedResult.changes.first { $0.propertyKey == .itemDynamicValue(key: .itemTouched) })
        #expect(touchedChange.oldValue == .bool(false))
        #expect(touchedChange.newValue == .bool(true)) // Ends up true

        let isOnChange = try #require(mergedResult.changes.first { $0.propertyKey == .itemDynamicValue(key: .isOn) })
        #expect(isOnChange.oldValue == .bool(false))
        #expect(isOnChange.newValue == .bool(true))
    }

    @Test func testMergeWithEmptyResult() throws {
        let result1 = ActionResult(
            message: .init(text: "Action 1."),
            changes: [
                createTestItemChange(id: "lamp", key: .isOn, oldValue: .bool(false), newValue: .bool(true))
            ]
        )
        let emptyResult = ActionResult.empty // Or ActionResult(message: .empty, changes: [])
        // ... existing code ...
        #expect(mergedResult.changes.count == 1)
        #expect(mergedResult.messages == result1.messages)

        let mergedResult2 = try emptyResult.merged(with: result1)
        #expect(mergedResult2.changes.count == 1)
        #expect(mergedResult2.messages == result1.messages)
    }

}
