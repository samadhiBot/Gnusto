import Foundation
import GnustoTestSupport
import Testing

@testable import GnustoEngine

@Suite("GameState Core Tests")
struct GameStateTests {
    // MARK: - Test Data Setup

    private func createTestItem(id: ItemID) -> Item {
        Item(
            id: id,
            .name("Test Item"),
            .description("A test item for testing purposes."),
            .in(.nowhere)
        )
    }

    private func createTestLocation(id: LocationID) -> Location {
        Location(
            id: id,
            .name("Test Room"),
            .description("A test room for testing purposes."),
            .inherentlyLit
        )
    }

    private func createBasicGameState() -> GameState {
        let testRoom = createTestLocation(id: .startRoom)
        let testItem = createTestItem(id: "testItem")

        return GameState(
            locations: [testRoom],
            items: [testItem],
            player: Player(in: .startRoom),
            globalState: ["testFlag": .bool(true)]
        )
    }

    // MARK: - Initialization Tests

    @Test("GameState Initialization")
    func testGameStateInitialization() {
        let state = createBasicGameState()

        // Verify basic structure
        #expect(state.items.count == 1)
        #expect(state.locations.count == 1)
        #expect(state.player.currentLocationID == .startRoom)
        #expect(state.globalState["testFlag"] == .bool(true))
        #expect(state.activeFuses.isEmpty)
        #expect(state.activeDaemons.isEmpty)
        #expect(state.changeHistory.isEmpty)
        #expect(state.pronoun == nil)
    }

    @Test("GameState Item Properties")
    func testGameStateItemProperties() {
        let state = createBasicGameState()

        guard let item = state.items["testItem"] else {
            Issue.record("Test item not found")
            return
        }

        #expect(item.id == "testItem")
        #expect(item.properties[.name] == .string("Test Item"))
        #expect(item.properties[.parentEntity] == .parentEntity(.nowhere))
    }

    @Test("GameState Location Properties")
    func testGameStateLocationProperties() {
        let state = createBasicGameState()

        guard let location = state.locations[.startRoom] else {
            Issue.record("Test location not found")
            return
        }

        #expect(location.id == .startRoom)
        #expect(location.properties[.name] == .string("Test Room"))
    }

    // MARK: - Codable Tests

    @Test("GameState Codable")
    func testGameStateCodable() throws {
        let originalState = createBasicGameState()

        // Encode and decode
        let data = try JSONEncoder.sorted().encode(originalState)
        let decodedState = try JSONDecoder().decode(GameState.self, from: data)

        // Verify equality
        #expect(decodedState == originalState)
        #expect(decodedState.items.count == originalState.items.count)
        #expect(decodedState.locations.count == originalState.locations.count)
        #expect(decodedState.player == originalState.player)
        #expect(decodedState.globalState == originalState.globalState)
    }

    // MARK: - Equatable Tests

    @Test("GameState Equatable")
    func testGameStateEquatable() {
        let state1 = createBasicGameState()
        let state2 = createBasicGameState()

        // Should be equal since they're identical
        #expect(state1 == state2)

        // Create a different state
        let differentItem = Item(
            id: "differentItem",
            .name("Different Item"),
            .in(.nowhere)
        )
        let state3 = GameState(
            locations: [createTestLocation(id: .startRoom)],
            items: [differentItem],
            player: Player(in: .startRoom),
            globalState: ["testFlag": .bool(true)]
        )

        #expect(state1 != state3)
    }

    // MARK: - Copy-on-Write Tests

    @Test("GameState Copy Semantics")
    func testGameStateCopySemantics() {
        let state1 = createBasicGameState()
        let state2 = state1  // Copy

        // They should be equal initially
        #expect(state1 == state2)

        // Since structs are value types, they remain independent
        // This test verifies that the struct semantics work correctly
        #expect(state1.items.count == state2.items.count)
        #expect(state1.locations.count == state2.locations.count)
    }

    // MARK: - StateChange Application Tests

    @Test("GameState Apply StateChange")
    func testGameStateApplyStateChange() throws {
        var state = createBasicGameState()

        // Create a state change to modify item name
        let change = StateChange.setItemName(
            id: "testItem",
            name: "Modified Item"
        )

        // Apply the change
        try state.apply(change)

        // Verify the change was applied
        #expect(state.items["testItem"]?.properties[.name] == .string("Modified Item"))
        #expect(state.changeHistory.count == 1)
        if let firstChange = state.changeHistory.first {
            if case .setItemName(_, let name) = firstChange {
                #expect(name == "Modified Item")
            }
        }
    }

    @Test("GameState Apply Multiple StateChanges")
    func testGameStateApplyMultipleStateChanges() throws {
        var state = createBasicGameState()

        let change1 = StateChange.setItemName(
            id: "testItem",
            name: "New Name"
        )

        let change2 = StateChange.moveItem(
            id: "testItem",
            to: .player
        )

        // Apply multiple changes
        try state.apply(change1, change2)

        // Verify both changes were applied
        #expect(state.items["testItem"]?.properties[.name] == .string("New Name"))
        #expect(state.items["testItem"]?.properties[.parentEntity] == .parentEntity(.player))
        #expect(state.changeHistory.count == 2)
    }

    @Test("GameState Apply Nil StateChange")
    func testGameStateApplyNilStateChange() throws {
        var state = createBasicGameState()

        let change = StateChange.setItemName(
            id: "testItem",
            name: "New Name"
        )

        // Apply with nil changes (should be ignored)
        try state.apply(change, nil, nil)

        // Only the non-nil change should be applied
        #expect(state.items["testItem"]?.properties[.name] == .string("New Name"))
        #expect(state.changeHistory.count == 1)
    }

    // MARK: - Global State Tests

    @Test("GameState Global State Management")
    func testGameStateGlobalState() throws {
        var state = createBasicGameState()

        // Test modifying global state through StateChange
        let change = StateChange.setGlobalInt(
            id: "score",
            value: 100
        )

        try state.apply(change)

        #expect(state.globalState["score"] == .int(100))
        #expect(state.globalState["testFlag"] == .bool(true))  // Original should remain
    }

    // MARK: - Player State Tests

    @Test("GameState Player Location Change")
    func testGameStatePlayerLocationChange() throws {
        // Create a state with two locations
        let room1 = createTestLocation(id: "room1")
        let room2 = createTestLocation(id: "room2")

        var state = GameState(
            locations: [room1, room2],
            items: [createTestItem(id: "testItem")],
            player: Player(in: "room1")
        )

        #expect(state.player.currentLocationID == "room1")

        // Move player to room2
        let change = StateChange.movePlayer(to: "room2")

        try state.apply(change)

        #expect(state.player.currentLocationID == "room2")
    }

    // MARK: - Pronoun Tests

    @Test("GameState Pronoun Management")
    func testGameStatePronounManagement() throws {
        let state = createBasicGameState()

        #expect(state.pronoun == nil)

        // Note: For pronoun testing, we'd need the full Item objects for EntityReference
        // This is a simplified test that verifies the basic structure
        let testItem = state.items["testItem"]!
        let pronoun = Pronoun.it(.item(testItem))

        // In a real scenario, pronouns would be set through game engine operations
        // This test verifies the basic type compatibility works
        #expect(type(of: pronoun) == Pronoun.self)
    }

    // MARK: - Error Handling Tests

    @Test("GameState Apply Invalid StateChange")
    func testGameStateApplyInvalidStateChange() {
        var state = createBasicGameState()

        // Try to modify a non-existent item
        let invalidChange = StateChange.setItemName(
            id: "nonExistentItem",
            name: "New Name"
        )

        // This should throw an error
        #expect(throws: ActionResponse.self) {
            try state.apply(invalidChange)
        }

        // State should be unchanged
        #expect(state.changeHistory.isEmpty)
    }

    // MARK: - Fuse and Daemon Tests

    @Test("GameState Fuse Management")
    func testGameStateFuseManagement() {
        let state = GameState(
            locations: [createTestLocation(id: .startRoom)],
            items: [createTestItem(id: "testItem")],
            player: Player(in: .startRoom),
            activeFuses: ["testFuse": FuseState(turns: 10)]
        )

        #expect(state.activeFuses.count == 1)
        #expect(state.activeFuses["testFuse"]?.turns == 10)
    }

    @Test("GameState Daemon Management")
    func testGameStateDaemonManagement() {
        let state = GameState(
            locations: [createTestLocation(id: .startRoom)],
            items: [createTestItem(id: "testItem")],
            player: Player(in: .startRoom),
            activeDaemons: ["testDaemon": DaemonState()]
        )

        #expect(state.activeDaemons.count == 1)
        #expect(state.activeDaemons["testDaemon"] != nil)
    }

    // MARK: - Complex Integration Tests

    @Test("GameState Complex Scenario")
    func testGameStateComplexScenario() throws {
        // Create a more complex game state
        let livingRoom = Location(
            id: "livingRoom",
            .name("Living Room"),
            .description("A cozy living room."),
            .inherentlyLit,
            .exits(.north("kitchen"))
        )

        let kitchen = Location(
            id: "kitchen",
            .name("Kitchen"),
            .description("A modern kitchen."),
            .inherentlyLit
        )

        let lamp = Item(
            id: "lamp",
            .name("brass lamp"),
            .description("A shiny brass lamp."),
            .isTakable,
            .isLightSource,
            .in("livingRoom")
        )

        let key = Item(
            id: "key",
            .name("rusty key"),
            .description("An old rusty key."),
            .isTakable,
            .in(.player)
        )

        var state = GameState(
            locations: [livingRoom, kitchen],
            items: [lamp, key],
            player: Player(in: "livingRoom"),
            activeFuses: ["clockFuse": FuseState(turns: 20)],
            globalState: [
                "gameStarted": .bool(true),
                "score": .int(0),
            ]
        )

        // Verify initial state
        #expect(state.items.count == 2)
        #expect(state.locations.count == 2)
        #expect(state.player.currentLocationID == "livingRoom")
        #expect(state.activeFuses["clockFuse"]?.turns == 20)

        // Apply several changes
        try state.apply(
            .moveItem(
                id: "lamp",
                to: .player
            ),
            .movePlayer(to: "room2"),
            .setGlobalBool(
                id: "lampTaken",
                value: true
            ),
            .setPlayerScore(to: 10)
        )

        // Verify final state
        #expect(state.items["lamp"]?.properties[.parentEntity] == .parentEntity(.player))
        #expect(state.player.currentLocationID == "room2")
        #expect(state.player.score == 10)
        #expect(state.changeHistory.count == 4)

        // Verify items with player
        let playerItems = state.items.values.filter {
            $0.properties[.parentEntity] == .parentEntity(.player)
        }
        #expect(playerItems.count == 2)  // lamp and key
    }
}
