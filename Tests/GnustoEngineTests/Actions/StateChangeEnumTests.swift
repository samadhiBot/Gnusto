import Testing

@testable import GnustoEngine

@Suite("StateChange Enum Tests")
struct StateChangeEnumTests {

    // MARK: - Basic StateChange Creation Tests

    @Test("StateChange.moveItem creation and properties")
    func testMoveItemCreation() {
        let change = StateChange.moveItem(id: "lamp", to: .player)

        if case .moveItem(let itemID, let parent) = change {
            #expect(itemID == "lamp")
            #expect(parent == .player)
        } else {
            Issue.record("Expected moveItem case")
        }
    }

    @Test("StateChange.setItemProperty creation")
    func testSetItemPropertyCreation() {
        let change = StateChange.setItemProperty(
            id: "lamp",
            property: .isOn,
            value: .bool(true)
        )

        if case .setItemProperty(let itemID, let property, let value) = change {
            #expect(itemID == "lamp")
            #expect(property == .isOn)
            #expect(value == .bool(true))
        } else {
            Issue.record("Expected setItemProperty case")
        }
    }

    @Test("StateChange.setFlag creation")
    func testSetFlagCreation() {
        let change = StateChange.setFlag(.isNoOp)

        if case .setFlag(let globalID) = change {
            #expect(globalID == .isNoOp)
        } else {
            Issue.record("Expected setFlag case")
        }
    }

    @Test("StateChange.movePlayer creation")
    func testMovePlayerCreation() {
        let change = StateChange.movePlayer(to: .startRoom)

        if case .movePlayer(let locationID) = change {
            #expect(locationID == .startRoom)
        } else {
            Issue.record("Expected movePlayer case")
        }
    }

    @Test("StateChange.addActiveFuse creation")
    func testAddActiveFuseCreation() {
        let change = StateChange.addActiveFuse(fuseID: "bomb", state: FuseState(turns: 5))

        if case .addActiveFuse(let fuseID, let state) = change {
            #expect(fuseID == "bomb")
            #expect(state.turns == 5)
        } else {
            Issue.record("Expected addActiveFuse case")
        }
    }

    // MARK: - StateChange Equality Tests

    @Test("StateChange equality - same values")
    func testStateChangeEquality() {
        let change1 = StateChange.moveItem(id: "lamp", to: .player)
        let change2 = StateChange.moveItem(id: "lamp", to: .player)

        // Note: Timestamps will be different, but equality ignores timestamps
        #expect(change1 == change2)
    }

    @Test("StateChange equality - different values")
    func testStateChangeInequality() {
        let change1 = StateChange.moveItem(id: "lamp", to: .player)
        let change2 = StateChange.moveItem(id: "lamp", to: .location(.startRoom))

        #expect(change1 != change2)
    }

    @Test("StateChange equality - different types")
    func testStateChangeDifferentTypes() {
        let change1 = StateChange.moveItem(id: "lamp", to: .player)
        let change2 = StateChange.setFlag(.isNoOp)

        #expect(change1 != change2)
    }

    // MARK: - StateChange Description Tests

    @Test("StateChange.moveItem description")
    func testMoveItemDescription() {
        let change = StateChange.moveItem(id: "lamp", to: .player)
        let description = change.description

        #expect(description.contains("moveItem"))
        #expect(description.contains("lamp"))
        #expect(description.contains("player"))
    }

    @Test("StateChange.setFlag description")
    func testSetFlagDescription() {
        let change = StateChange.setFlag(.isNoOp)
        let description = change.description

        #expect(description.contains("setFlag"))
        #expect(description.contains("isNoOp"))
    }

    // MARK: - Complex StateChange Tests

    @Test("StateChange.setGlobalInt creation and properties")
    func testSetGlobalIntCreation() {
        let change = StateChange.setGlobalInt(id: "score", value: 100)

        if case .setGlobalInt(let globalID, let value) = change {
            #expect(globalID == "score")
            #expect(value == 100)
        } else {
            Issue.record("Expected setGlobalInt case")
        }
    }

    @Test("StateChange.setPlayerScore creation")
    func testSetPlayerScoreCreation() {
        let change = StateChange.setPlayerScore(to: 42)

        if case .setPlayerScore(let score) = change {
            #expect(score == 42)
        } else {
            Issue.record("Expected setPlayerScore case")
        }
    }

    @Test("StateChange.removeActiveFuse creation")
    func testRemoveActiveFuseCreation() {
        let change = StateChange.removeActiveFuse(fuseID: "bomb")

        if case .removeActiveFuse(let fuseID) = change {
            #expect(fuseID == "bomb")
        } else {
            Issue.record("Expected removeActiveFuse case")
        }
    }

    // MARK: - Comparative Tests (Old vs New API)

    @Test("StateChange factory methods produce consistent results")
    func testFactoryMethodConsistency() {
        // Test that calling the same factory method multiple times produces equal changes
        let change1 = StateChange.setItemProperty(id: "lamp", property: .isOn, value: .bool(true))
        let change2 = StateChange.setItemProperty(id: "lamp", property: .isOn, value: .bool(true))

        #expect(change1 == change2)
    }

    // MARK: - Edge Cases

    @Test("StateChange with nil combat state")
    func testSetCombatStateWithNil() {
        let change = StateChange.setCombatState(nil)

        if case .setCombatState(let state) = change {
            #expect(state == nil)
        } else {
            Issue.record("Expected setCombatState case")
        }
    }

    @Test("StateChange.clearGlobalState creation")
    func testClearGlobalStateCreation() {
        let change = StateChange.clearGlobalState(id: "score")

        if case .clearGlobalState(let globalID) = change {
            #expect(globalID == "score")
        } else {
            Issue.record("Expected clearGlobalState case")
        }
    }
}
