import CustomDump
import GnustoTestSupport
import Testing

@testable import GnustoEngine

@Suite("GameState Apply StateChange Tests")
struct GameStateApplyTests {

    // MARK: - Test Helpers

    private func createTestGameState() -> GameState {
        let testRoom = Location(
            id: .startRoom,
            .name("Test Room"),
            .description("A test room for testing purposes."),
            .inherentlyLit
        )

        let secondRoom = Location(
            id: "secondRoom",
            .name("Second Room"),
            .description("Another test room."),
            .inherentlyLit
        )

        let testItem = Item(
            id: "testItem",
            .name("test item"),
            .description("A test item."),
            .isTakable,
            .size(5),
            .in(.startRoom)
        )

        let containerItem = Item(
            id: "container",
            .name("test container"),
            .description("A test container."),
            .isContainer,
            .capacity(10),
            .in(.startRoom)
        )

        return GameState(
            locations: [testRoom, secondRoom],
            items: [testItem, containerItem],
            player: Player(in: .startRoom),
            activeFuses: ["testFuse": FuseState(turns: 5)],
            activeDaemons: ["testDaemon"],
            globalState: [
                "testFlag": .bool(true),
                "testCounter": .int(42),
            ]
        )
    }

    // MARK: - Item State Change Tests

    @Test("Apply valid item name change")
    func testApplyValidItemNameChange() throws {
        var state = createTestGameState()

        let change = StateChange.setItemName(
            id: "testItem",
            name: "new test item"
        )

        try state.apply(change)

        #expect(state.items["testItem"]?.properties[.name] == .string("new test item"))
        #expect(state.changeHistory.count == 1)
        #expect(state.changeHistory.first == change)
    }

    @Test("Apply valid item parent change")
    func testApplyValidItemParentChange() throws {
        var state = createTestGameState()

        let change = StateChange.moveItem(
            id: "testItem",
            to: .player
        )

        try state.apply(change)

        #expect(state.items["testItem"]?.properties[.parentEntity] == .parentEntity(.player))
        #expect(state.changeHistory.count == 1)
        #expect(state.changeHistory.first == change)
    }

    @Test("Apply valid item size change")
    func testApplyValidItemSizeChange() throws {
        var state = createTestGameState()

        let change = StateChange.setItemSize(
            id: "testItem",
            size: 10
        )

        try state.apply(change)

        #expect(state.items["testItem"]?.properties[.size] == .int(10))
        #expect(state.changeHistory.count == 1)
        #expect(state.changeHistory.first == change)
    }

    @Test("Apply valid item capacity change")
    func testApplyValidItemCapacityChange() throws {
        var state = createTestGameState()

        let change = StateChange.setItemCapacity(
            id: "container",
            capacity: 20
        )

        try state.apply(change)

        #expect(state.items["container"]?.properties[.capacity] == .int(20))
        #expect(state.changeHistory.count == 1)
        #expect(state.changeHistory.first == change)
    }

    @Test("Apply valid item property change")
    func testApplyValidItemPropertyChange() throws {
        var state = createTestGameState()

        let change = StateChange.setItemProperty(
            id: "testItem",
            property: .isOn,
            value: .bool(true)
        )

        try state.apply(change)

        #expect(state.items["testItem"]?.properties[.isOn] == .bool(true))
        #expect(state.changeHistory.count == 1)
        #expect(state.changeHistory.first == change)
    }

    @Test("Apply valid item adjectives change")
    func testApplyValidItemAdjectivesChange() throws {
        var state = createTestGameState()

        let change = StateChange.setItemAdjectives(
            id: "testItem",
            adjectives: ["shiny", "metal"]
        )

        try state.apply(change)

        #expect(
            state.items["testItem"]?.properties[.adjectives] == .stringSet(["shiny", "metal"]))
        #expect(state.changeHistory.count == 1)
        #expect(state.changeHistory.first == change)
    }

    @Test("Apply valid item synonyms change")
    func testApplyValidItemSynonymsChange() throws {
        var state = createTestGameState()

        let change = StateChange.setItemSynonyms(
            id: "testItem",
            synonyms: ["object", "thing"]
        )

        try state.apply(change)

        #expect(
            state.items["testItem"]?.properties[.synonyms] == .stringSet(["object", "thing"]))
        #expect(state.changeHistory.count == 1)
        #expect(state.changeHistory.first == change)
    }

    @Test("Apply valid item value change")
    func testApplyValidItemValueChange() throws {
        var state = createTestGameState()

        let change = StateChange.setItemValue(
            id: "testItem",
            value: 100
        )

        try state.apply(change)

        #expect(state.items["testItem"]?.properties[.value] == .int(100))
        #expect(state.changeHistory.count == 1)
        #expect(state.changeHistory.first == change)
    }

    // MARK: - Location State Change Tests

    @Test("Apply valid location name change")
    func testApplyValidLocationNameChange() throws {
        var state = createTestGameState()

        let change = StateChange.setLocationName(
            id: .startRoom,
            name: "New Room Name"
        )

        try state.apply(change)

        #expect(state.locations[.startRoom]?.properties[.name] == .string("New Room Name"))
        #expect(state.changeHistory.count == 1)
        #expect(state.changeHistory.first == change)
    }

    @Test("Apply valid location description change")
    func testApplyValidLocationDescriptionChange() throws {
        var state = createTestGameState()

        let change = StateChange.setLocationDescription(
            id: .startRoom,
            description: "A newly described room."
        )

        try state.apply(change)

        #expect(
            state.locations[.startRoom]?.properties[.description]
                == .string("A newly described room."))
        #expect(state.changeHistory.count == 1)
        #expect(state.changeHistory.first == change)
    }

    @Test("Apply valid location property change")
    func testApplyValidLocationPropertyChange() throws {
        var state = createTestGameState()

        let change = StateChange.setLocationProperty(
            id: .startRoom,
            property: .isVisited,
            value: .bool(true)
        )

        try state.apply(change)

        #expect(state.locations[.startRoom]?.properties[.isVisited] == .bool(true))
        #expect(state.changeHistory.count == 1)
        #expect(state.changeHistory.first == change)
    }

    @Test("Apply valid location exits change")
    func testApplyValidLocationExitsChange() throws {
        var state = createTestGameState()

        let newExits: Set<Exit> = [
            .north("secondRoom"),
            .south("thirdRoom"),
        ]

        let change = StateChange.setLocationExits(
            id: .startRoom,
            exits: newExits
        )

        try state.apply(change)

        #expect(state.locations[.startRoom]?.properties[.exits] == .exits(newExits))
        #expect(state.changeHistory.count == 1)
        #expect(state.changeHistory.first == change)
    }

    // MARK: - Player State Change Tests

    @Test("Apply valid player move change")
    func testApplyValidPlayerMoveChange() throws {
        var state = createTestGameState()

        let change = StateChange.movePlayer(to: "secondRoom")

        try state.apply(change)

        #expect(state.player.currentLocationID == "secondRoom")
        #expect(state.changeHistory.count == 1)
        #expect(state.changeHistory.first == change)
    }

    @Test("Apply valid player move to parent entity change")
    func testApplyValidPlayerMoveToParentEntityChange() throws {
        var state = createTestGameState()

        let change = StateChange.movePlayerTo(parent: .location("secondRoom"))

        try state.apply(change)

        #expect(state.player.currentLocationID == "secondRoom")
        #expect(state.changeHistory.count == 1)
        #expect(state.changeHistory.first == change)
    }

    @Test("Apply valid player score change")
    func testApplyValidPlayerScoreChange() throws {
        var state = createTestGameState()

        let change = StateChange.setPlayerScore(to: 150)

        try state.apply(change)

        #expect(state.player.score == 150)
        #expect(state.changeHistory.count == 1)
        #expect(state.changeHistory.first == change)
    }

    @Test("Apply valid player attributes change")
    func testApplyValidPlayerAttributesChange() throws {
        var state = createTestGameState()

        let newAttributes = CharacterSheet(
            strength: 18,
            dexterity: 15,
            constitution: 16,
            intelligence: 12,
            wisdom: 14,
            charisma: 13,
            health: 100,
            maxHealth: 100
        )

        let change = StateChange.setPlayerAttributes(attributes: newAttributes)

        try state.apply(change)

        #expect(state.player.characterSheet == newAttributes)
        #expect(state.changeHistory.count == 1)
        #expect(state.changeHistory.first == change)
    }

    @Test("Apply valid player moves increment")
    func testApplyValidPlayerMovesIncrement() throws {
        var state = createTestGameState()
        let originalMoves = state.player.moves

        let change = StateChange.incrementPlayerMoves

        try state.apply(change)

        #expect(state.player.moves == originalMoves + 1)
        #expect(state.changeHistory.count == 1)
        #expect(state.changeHistory.first == change)
    }

    // MARK: - Global State Change Tests

    @Test("Apply valid set flag change")
    func testApplyValidSetFlagChange() throws {
        var state = createTestGameState()

        let change = StateChange.setFlag("newFlag")

        try state.apply(change)

        #expect(state.globalState["newFlag"] == .bool(true))
        #expect(state.changeHistory.count == 1)
        #expect(state.changeHistory.first == change)
    }

    @Test("Apply valid clear flag change")
    func testApplyValidClearFlagChange() throws {
        var state = createTestGameState()

        let change = StateChange.clearFlag("testFlag")

        try state.apply(change)

        #expect(state.globalState["testFlag"] == .bool(false))
        #expect(state.changeHistory.count == 1)
        #expect(state.changeHistory.first == change)
    }

    @Test("Apply valid set global bool change")
    func testApplyValidSetGlobalBoolChange() throws {
        var state = createTestGameState()

        let change = StateChange.setGlobalBool(
            id: "gameStarted",
            value: true
        )

        try state.apply(change)

        #expect(state.globalState["gameStarted"] == .bool(true))
        #expect(state.changeHistory.count == 1)
        #expect(state.changeHistory.first == change)
    }

    @Test("Apply valid set global int change")
    func testApplyValidSetGlobalIntChange() throws {
        var state = createTestGameState()

        let change = StateChange.setGlobalInt(
            id: "playerLevel",
            value: 5
        )

        try state.apply(change)

        #expect(state.globalState["playerLevel"] == .int(5))
        #expect(state.changeHistory.count == 1)
        #expect(state.changeHistory.first == change)
    }

    @Test("Apply valid set global string change")
    func testApplyValidSetGlobalStringChange() throws {
        var state = createTestGameState()

        let change = StateChange.setGlobalString(
            id: "playerName",
            value: "Adventurer"
        )

        try state.apply(change)

        #expect(state.globalState["playerName"] == .string("Adventurer"))
        #expect(state.changeHistory.count == 1)
        #expect(state.changeHistory.first == change)
    }

    @Test("Apply valid set global item ID change")
    func testApplyValidSetGlobalItemIDChange() throws {
        var state = createTestGameState()

        let change = StateChange.setGlobalItemID(
            id: "specialItem",
            value: "testItem"
        )

        try state.apply(change)

        #expect(state.globalState["specialItem"] == .itemID("testItem"))
        #expect(state.changeHistory.count == 1)
        #expect(state.changeHistory.first == change)
    }

    @Test("Apply valid set global location ID change")
    func testApplyValidSetGlobalLocationIDChange() throws {
        var state = createTestGameState()

        let change = StateChange.setGlobalLocationID(
            id: "homeLocation",
            value: .startRoom
        )

        try state.apply(change)

        #expect(state.globalState["homeLocation"] == .locationID(.startRoom))
        #expect(state.changeHistory.count == 1)
        #expect(state.changeHistory.first == change)
    }

    @Test("Apply valid set global state change")
    func testApplyValidSetGlobalStateChange() throws {
        var state = createTestGameState()

        let change = StateChange.setGlobalState(
            id: "customValue",
            value: .string("custom data")
        )

        try state.apply(change)

        #expect(state.globalState["customValue"] == .string("custom data"))
        #expect(state.changeHistory.count == 1)
        #expect(state.changeHistory.first == change)
    }

    @Test("Apply valid clear global state change")
    func testApplyValidClearGlobalStateChange() throws {
        var state = createTestGameState()

        let change = StateChange.clearGlobalState(id: "testCounter")

        try state.apply(change)

        #expect(state.globalState["testCounter"] == nil)
        #expect(state.changeHistory.count == 1)
        #expect(state.changeHistory.first == change)
    }

    // MARK: - Timed Events Tests

    @Test("Apply valid add active fuse change")
    func testApplyValidAddActiveFuseChange() throws {
        var state = createTestGameState()

        let change = StateChange.addActiveFuse(
            fuseID: "newFuse",
            state: FuseState(turns: 10)
        )

        try state.apply(change)

        #expect(state.activeFuses["newFuse"]?.turns == 10)
        #expect(state.changeHistory.count == 1)
        #expect(state.changeHistory.first == change)
    }

    @Test("Apply valid remove active fuse change")
    func testApplyValidRemoveActiveFuseChange() throws {
        var state = createTestGameState()

        let change = StateChange.removeActiveFuse(fuseID: "testFuse")

        try state.apply(change)

        #expect(state.activeFuses["testFuse"] == nil)
        #expect(state.changeHistory.count == 1)
        #expect(state.changeHistory.first == change)
    }

    @Test("Apply valid update fuse turns change")
    func testApplyValidUpdateFuseTurnsChange() throws {
        var state = createTestGameState()

        let change = StateChange.updateFuseTurns(
            fuseID: "testFuse",
            turns: 3
        )

        try state.apply(change)

        #expect(state.activeFuses["testFuse"]?.turns == 3)
        #expect(state.changeHistory.count == 1)
        #expect(state.changeHistory.first == change)
    }

    @Test("Apply valid add active daemon change")
    func testApplyValidAddActiveDaemonChange() throws {
        var state = createTestGameState()

        let change = StateChange.addActiveDaemon(daemonID: "newDaemon")

        try state.apply(change)

        #expect(state.activeDaemons.contains("newDaemon"))
        #expect(state.changeHistory.count == 1)
        #expect(state.changeHistory.first == change)
    }

    @Test("Apply valid remove active daemon change")
    func testApplyValidRemoveActiveDaemonChange() throws {
        var state = createTestGameState()

        let change = StateChange.removeActiveDaemon(daemonID: "testDaemon")

        try state.apply(change)

        #expect(!state.activeDaemons.contains("testDaemon"))
        #expect(state.changeHistory.count == 1)
        #expect(state.changeHistory.first == change)
    }

    // MARK: - Combat State Tests

    @Test("Apply valid set combat state change")
    func testApplyValidSetCombatStateChange() throws {
        var state = createTestGameState()

        let combatState = CombatState(enemyID: "troll")
        let change = StateChange.setCombatState(combatState)
        try state.apply(change)

        #expect(state.globalState[.combatState] == .combatState(combatState))
        #expect(state.changeHistory.count == 1)
        #expect(state.changeHistory.first == change)
    }

    @Test("Apply valid clear combat state change")
    func testApplyValidClearCombatStateChange() throws {
        var state = createTestGameState()

        let startTrollCombat = StateChange.setCombatState(
            CombatState(enemyID: "troll")
        )
        try state.apply(startTrollCombat)

        let change = StateChange.setCombatState(nil)
        try state.apply(change)

        #expect(state.globalState[.combatState] == nil)
        expectNoDifference(
            state.changeHistory,
            [
                startTrollCombat,
                .setCombatState(nil),
            ])
    }

    // MARK: - Change History Tests

    @Test("Multiple changes accumulate in history")
    func testMultipleChangesAccumulateInHistory() throws {
        var state = createTestGameState()

        let change1 = StateChange.setItemName(id: "testItem", name: "first name")
        let change2 = StateChange.setItemName(id: "testItem", name: "second name")
        let change3 = StateChange.setFlag("testFlag2")

        try state.apply(change1)
        try state.apply(change2)
        try state.apply(change3)

        #expect(state.changeHistory.count == 3)
        #expect(state.changeHistory[0] == change1)
        #expect(state.changeHistory[1] == change2)
        #expect(state.changeHistory[2] == change3)
    }

    @Test("Changes are applied in order")
    func testChangesAreAppliedInOrder() throws {
        var state = createTestGameState()

        let change1 = StateChange.setGlobalInt(id: "counter", value: 1)
        let change2 = StateChange.setGlobalInt(id: "counter", value: 2)
        let change3 = StateChange.setGlobalInt(id: "counter", value: 3)

        try state.apply(change1)
        try state.apply(change2)
        try state.apply(change3)

        #expect(state.globalState["counter"] == .int(3))
        #expect(state.changeHistory.count == 3)
    }
}
