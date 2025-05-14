import Foundation
import Testing

@testable import GnustoEngine

@Suite("GameState Struct Tests")
struct GameStateTests {
    // Define IDs for clarity
    static let locWOH: LocationID = "westOfHouse"
    static let locNorth: LocationID = "northOfHouse"
    static let locClearing: LocationID = "clearing"

    static let itemLantern: ItemID = "lantern"
    static let itemMailbox: ItemID = "mailbox"
    static let itemLeaflet: ItemID = "leaflet"
    static let itemSword: ItemID = "sword"

    // 1. Define all potential Items
    func createSampleItems() -> [Item] {
        [
            Item(
                id: Self.itemLantern,
                .isTakable,
                .isLightSource
            ),
            Item(
                id: Self.itemMailbox,
                .in(.location(Self.locWOH)),
                .isContainer,
                .isOpenable
            ),
            Item(
                id: Self.itemLeaflet,
                .in(.item(Self.itemMailbox)),
                .isTakable,
                .isReadable
            ),
            Item(
                id: Self.itemSword,
                .in(.player),
                .isTakable
            )
        ]
    }

    // 2. Define all Locations (without items initially)
    func createSampleLocations() -> [Location] {
        return [
            Location(
                id: Self.locWOH,
                .name("West of House"),
                .description("You are standing west of a white house."),
                .exits([.north: Exit(destination: Self.locNorth)])
            ),
            Location(
                id: Self.locNorth,
                .name("North of House"),
                .description("You are north of the house."),
                .exits([.south: Exit(destination: Self.locWOH)])
            )
        ]
    }

    // 3. Define initial Player
    func createSamplePlayer() -> Player {
        Player(in: Self.locWOH)
    }

    // 4. Helper to create the GameState with defined placements
    func createSampleGameState(
        activeFuses: [FuseID: Int] = [:]
    ) async -> GameState {
        GameState(
            locations: createSampleLocations(),
            items: createSampleItems(),
            player: createSamplePlayer(),
            pronouns: ["it": [.item(Self.itemMailbox)]],
            activeFuses: activeFuses,
            globalState: ["gameStarted": true]
        )
    }

    // Helper to create a consistent initial state for tests
    func createInitialState() -> GameState {
        let startRoom = Location(
            id: .startRoom,
            .name("Starting Room"),
            .description("A dark, dark room.")
        )
        let testItem = Item(
            id: "testItem",
            .name("Test Item"),
            .in(.location(.startRoom))
        )
        let player = Player(in: .startRoom)
        let vocab = Vocabulary.build(items: [testItem]) // Build basic vocab

        var state = GameState(
            locations: [startRoom],
            items: [testItem],
            player: player,
            vocabulary: vocab
        )
        // Add some initial values if needed by tests
        state.pronouns["it"] = [.item("testItem")]
        state.globalState["counter"] = .int(0)
        state.globalState["gameStarted"] = true
        state.activeFuses = ["testFuse": 10]
        state.activeDaemons = ["testDaemon"]
        state.changeHistory = [] // Start with empty history for most tests

        return state
    }

    // MARK: - Initialization Tests

    @Test("Initial State Properties")
    func testInitialStateProperties() {
        let state = createInitialState()

        #expect(state.items.count == 1)
        #expect(state.items["testItem"]?.name == "Test Item")
        #expect(state.locations.count == 1)
        #expect(state.locations[.startRoom]?.name == "Starting Room")
        #expect(state.player.currentLocationID == .startRoom)
        #expect(state.globalState["gameStarted"] == true)
        #expect(state.globalState["testFlag"] == nil)
        #expect(state.pronouns["it"] == [.item("testItem")])
        #expect(state.activeFuses.count == 1)
        #expect(state.activeDaemons.count == 1)
        #expect(state.changeHistory.isEmpty)
        #expect(state.globalState["counter"] == .int(0))

        #expect(!state.vocabulary.verbDefinitions.isEmpty || !state.vocabulary.items.isEmpty)
    }

    @Test("Initialization with Multiple Areas")
    func testInitWithAreas() {
        // Define mock AreaContents with *instance* properties
        struct Area1: AreaContents {
            let loc1 = Location(
                id: "loc1",
                .name("Area 1 Room"),
                .description("A dark, dark room.")
            )
            let item1 = Item(
                id: "item1",
                .name("Area 1 Item"),
                .in(.location("loc1"))
            )
        }
        struct Area2: AreaContents {
            let loc2 = Location(
                id: "loc2",
                .name("Area 2 Room"),
                .description("A dark, dark room.")
            )
            let loc3 = Location(
                id: "loc3",
                .name("Area 3 Room"),
                .description("A dark, dark room.")
            )
            let item2 = Item(
                id: "item2",
                .name("Area 2 Item"),
                .in(.location("loc2"))
            )
            let item3 = Item(
                id: "item3",
                .name("Area 3 Item"),
                .in(.location("loc2"))
            )
        }

        let player = Player(in: "loc1")
        let state = GameState(areas: [Area1.self, Area2.self], player: player)

        #expect(state.locations.count == 3)
        #expect(state.locations.keys.map(\.rawValue).sorted() == ["loc1", "loc2", "loc3"])

        #expect(state.items.count == 3)
        #expect(state.items.keys.map(\.rawValue).sorted() == ["item1", "item2", "item3"])

        #expect(state.items["item1"]?.parent == .location("loc1"))
        #expect(!state.vocabulary.items.isEmpty)
    }

    // MARK: - Helper Methods Tests

    @Test("Items in Inventory Test")
    func testItemsInInventory() {
        var state = createInitialState() // Make mutable to modify items
        let item1 = Item(
            id: "item1",
            .name("Item 1"),
            .in(.player)
        )
        let item2 = Item(
            id: "item2",
            .name("Item 2"),
            .in(.location(.startRoom))
        )
        let item3 = Item(
            id: "item3",
            .name("Item 3"),
            .in(.player)
        )
        state.items = ["item1": item1, "item2": item2, "item3": item3, "testItem": state.items["testItem"]!] // Add items

        // Replace itemsInInventory() call
        let inventoryItems = state.items.values.filter { $0.parent == .player }.map(\.id)
        let inventoryItemSet = Set(inventoryItems)
        #expect(inventoryItemSet == ["item1", "item3"])
        #expect(inventoryItems.count == 2)
    }

    @Test("Items in Location Test")
    func testItemsInLocation() {
        var state = createInitialState() // Make mutable to modify items
        let locID: LocationID = .startRoom
        let item1 = Item(
            id: "item1",
            .name("Item 1"),
            .in(.location(locID))
        )
        let item2 = Item(
            id: "item2",
            .name("Item 2"),
            .in(.player)
        )
        let item3 = Item(
            id: "item3",
            .name("Item 3"),
            .in(.location(locID))
        )
        let originalTestItem = state.items["testItem"]! // Keep original item in startRoom
        state.items = ["item1": item1, "item2": item2, "item3": item3, "testItem": originalTestItem] // Add/replace items

        let locationItems = state.items.values.filter { $0.parent == .location(locID) }.map(\.id)
        let locationItemSet = Set(locationItems)
        #expect(locationItemSet == ["item1", "item3", "testItem"])
        #expect(locationItems.count == 3)
    }

    @Test("Item Parent Test") // Renamed from Item Location
    func testItemParent() {
        var state = createInitialState() // Make mutable
        let item1 = Item(
            id: "item1",
            .name("Item 1"),
            .in(.player)
        )
        let item2 = Item(
            id: "item2",
            .name("Item 2"),
            .in(.location(.startRoom))
        )
        state.items["item1"] = item1 // Add items
        state.items["item2"] = item2

        #expect(state.items["item1"]?.parent == .player)
        #expect(state.items["item2"]?.parent == .location(.startRoom))
        #expect(state.items["testItem"]?.parent == .location(.startRoom)) // Check original
        #expect(state.items["nonExistentItem"]?.parent == nil)
    }

    // MARK: - Codable Tests

    @Test("GameState Basic Codable Conformance")
    func testGameStateBasicCodable() throws {
        var originalState = createInitialState() // Make mutable for change history
        // Add some history for encoding
        let change1 = StateChange(entityID: .player, attributeKey: .playerScore, newValue: .int(10))
        try originalState.apply(change1)

        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(originalState)

        let decoder = JSONDecoder()
        let decodedState = try decoder.decode(GameState.self, from: data)

        // Use equality (==) for structs
        #expect(decodedState == originalState)
    }

    @Test("GameState Equatable Conformance")
    func testGameStateEquatable() throws {
        let state1 = createInitialState()
        let state2 = createInitialState() // Create identical state
        var state3 = createInitialState() // Make mutable for modification

        #expect(state1 == state2)

        // Modify state3 slightly
        let change = StateChange(entityID: .player, attributeKey: .playerScore, newValue: .int(5))
        try state3.apply(change)

        #expect(state1 != state3)
    }

    // MARK: - Copy-on-Write (Implicit for Structs)

    @Test("GameState Copy-on-Write Behavior")
    func testCopyOnWrite() throws {
        var state1 = createInitialState() // Must be var to allow mutation
        let state2 = state1 // Create a copy (structs are value types)

        // Modify state1
        let change = StateChange(
            entityID: .player,
            attributeKey: .playerScore,
            newValue: .int(10)
        )
        try state1.apply(change)

        // Verify state2 remains unchanged
        #expect(state1.player.score == 10)
        #expect(state2.player.score == 0) // Initial score

        // Verify internal dictionaries were copied (check count or a specific item)
        #expect(state1.items.count == state2.items.count)
        // Use equality (==) not identity (===) for struct comparison
        #expect(state1.items["testItem"] == state2.items["testItem"])

        // Check location dictionaries too
        #expect(state1.locations.count == state2.locations.count)
        #expect(state1.locations[.startRoom] == state2.locations[.startRoom])
    }

    // --- Tests ---

    @Test("GameState Initial Factory and Parent Setting")
    func testGameStateInitialFactory() async throws {
        let state = await createSampleGameState()

        // Check locations exist
        #expect(state.locations.count == 2)
        #expect(state.locations[Self.locWOH] != nil)
        #expect(state.locations[Self.locNorth] != nil)
        // #expect(state.locations[locWOH]?.items == [itemMailbox]) // Removed: Location no longer stores items directly

        // Check items exist
        #expect(state.items.count == 4) // Now 4 items
        #expect(state.items[Self.itemLantern] != nil) // Exists but parent is .nowhere
        #expect(state.items[Self.itemMailbox] != nil)
        #expect(state.items[Self.itemLeaflet] != nil)
        #expect(state.items[Self.itemSword] != nil)

        // Check item parents were set correctly by GameState.initial
        #expect(state.items[Self.itemLantern]?.parent == .nowhere) // Default
        #expect(state.items[Self.itemMailbox]?.parent == .location(Self.locWOH))
        #expect(state.items[Self.itemLeaflet]?.parent == .item(Self.itemMailbox))
        #expect(state.items[Self.itemSword]?.parent == .player)

        // Check player state
        #expect(state.player.currentLocationID == Self.locWOH)

        // Check other state properties
        #expect(state.globalState == ["gameStarted": true])
        #expect(state.pronouns == ["it": [.item(Self.itemMailbox)]])

        // Check derived inventory
        let inventoryIDs = state.items.values.filter { $0.parent == .player }.map(\.id)
        #expect(Set(inventoryIDs) == [Self.itemSword])
    }

    @Test("GameState Property Modification")
    func testGameStatePropertyModification() async throws {
        var state = await createSampleGameState() // Use var for mutation

        // Valid: Modify properties of reference types (Location, Item)
        // Note: Since Item/Location are structs, direct modification like this
        // modifies a *copy*. To persist, reassign to the dictionary.
        var woh = state.locations[Self.locWOH]!
        woh.attributes[.description] = .string("A new description.")
        state.locations[Self.locWOH] = woh

        // Create new lantern with updated name
        let updatedLantern = Item(
            id: Self.itemLantern,
            .name("Magic Lantern"),
            .isTakable,
            .isLightSource
        )
        state.items[Self.itemLantern] = updatedLantern

        // Create new lantern with updated parent
        let lanternWithNewParent = Item(
            id: "heldLantern",
            .in(.player),
            .isTakable,
            .isLightSource
        )
        state.items["heldLantern"] = lanternWithNewParent

        // Create new sword with updated parent
        let swordWithNewParent = Item(
            id: Self.itemSword,
            .in(.location(state.player.currentLocationID)),
            .isTakable
        )
        state.items[Self.itemSword] = swordWithNewParent

        // Assertions for the valid modifications:
        #expect(
            state.locations[Self.locWOH]?.attributes[.description] == .string("A new description.")
        )
        #expect(state.items[Self.itemLantern]?.name == "Magic Lantern")

        // Check derived inventory reflects parent changes
        let inventoryIDs = state.items.values.filter { $0.parent == .player }.map(\.id)
        #expect(Set(inventoryIDs) == ["heldLantern"]) // Sword dropped, Lantern taken

        // Check sword is now in the location
        #expect(state.items[Self.itemSword]?.parent == .location(Self.locWOH))
    }

    @Test("GameState Codable Conformance")
    func testGameStateCodable() async throws {
        var originalState = await createSampleGameState()

        // Create new lantern with updated attributes
        let updatedLantern = Item(
            id: Self.itemLantern,
            .in(.player),
            .isLightSource,
            .isOn
        )
        originalState.items[Self.itemLantern] = updatedLantern

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let decoder = JSONDecoder()

        let jsonData = try encoder.encode(originalState)
        let decodedState = try decoder.decode(GameState.self, from: jsonData)

        // Basic properties
        #expect(decodedState.globalState == originalState.globalState)
        #expect(decodedState.pronouns == originalState.pronouns)
        #expect(decodedState.player == originalState.player)

        // Check dictionaries counts
        #expect(decodedState.locations.count == originalState.locations.count)
        #expect(decodedState.items.count == originalState.items.count)

        // Check content of locations (comparing key properties)
        #expect(decodedState.locations[Self.locWOH]?.name == originalState.locations[Self.locWOH]?.name)
        #expect(decodedState.locations[Self.locNorth]?.attributes[.description] == originalState.locations[Self.locNorth]?.attributes[.description])

        // Check content of items (comparing key properties, including parent)
        #expect(decodedState.items[Self.itemLantern]?.name == originalState.items[Self.itemLantern]?.name)
        #expect(decodedState.items[Self.itemLantern]?.attributes == originalState.items[Self.itemLantern]?.attributes)
        #expect(decodedState.items[Self.itemLantern]?.parent == originalState.items[Self.itemLantern]?.parent)
        #expect(decodedState.items[Self.itemMailbox]?.parent == originalState.items[Self.itemMailbox]?.parent)
        #expect(decodedState.items[Self.itemLeaflet]?.parent == originalState.items[Self.itemLeaflet]?.parent)

        // IMPORTANT: Check that decoded objects are EQUAL, not identical instances (structs)
        #expect(decodedState.locations[Self.locWOH] == originalState.locations[Self.locWOH])
        #expect(decodedState.items[Self.itemLantern] == originalState.items[Self.itemLantern])
    }

    @Test("GameState Value Semantics (Struct Behavior)") // Updated name
    func testGameSemantics() async throws {
        let state1 = await createSampleGameState()
        var state2 = state1 // Creates a copy of the struct

        // Check initial equality of value types
        #expect(state1.player == state2.player)
        #expect(state1.globalState == state2.globalState)
        #expect(state1.pronouns == state2.pronouns)
        #expect(state1.items == state2.items) // Items dict should be equal initially
        #expect(state1.locations == state2.locations) // Locations dict should be equal

        // Modify value type (Player) *in* state2
        state2.player.moves = 5

        // Create new lantern with updated properties
        let updatedLantern = Item(
            id: Self.itemLantern,
            .name("Shiny Lantern"),
            .in(.player),
            .isTakable,
            .isLightSource
        )
        state2.items[Self.itemLantern] = updatedLantern

        // Verify state1's value types remain unchanged
        let initialPlayer = state1.player // Capture initial player state from state1
        #expect(state1.player == initialPlayer) // state1 player unchanged
        #expect(state2.player != initialPlayer) // state2 player changed
        let initialFlags = state1.globalState
        #expect(state1.globalState == initialFlags)
        #expect(state2.globalState == initialFlags)
        let initialPronouns = state1.pronouns
        #expect(state1.pronouns == initialPronouns)
        #expect(state2.pronouns == initialPronouns)

        // Verify state1's Item struct is UNCHANGED (because Item is a struct)
        #expect(state1.items[Self.itemLantern]?.name == "lantern") // Original name
        #expect(state1.items[Self.itemLantern]?.parent == .nowhere) // Original parent

        // Verify state2's Item struct *is* changed
        #expect(state2.items[Self.itemLantern]?.name == "Shiny Lantern")
        #expect(state2.items[Self.itemLantern]?.parent == .player)

        // Check derived inventories reflect the *separate* changes
        let inventory1 = state1.items.values.filter { $0.parent == .player }.map(\.id)
        #expect(Set(inventory1) == [Self.itemSword]) // Only sword originally
        let inventory2 = state2.items.values.filter { $0.parent == .player }.map(\.id)
        #expect(Set(inventory2) == [Self.itemSword, Self.itemLantern]) // Sword and moved lantern

        // Check equality of the states and dictionaries
        #expect(state1 != state2)
        #expect(state1.items != state2.items)
        #expect(state1.locations == state2.locations) // Locations were not modified

        // Check specific items are not equal after modification
        #expect(state1.items[Self.itemLantern] != state2.items[Self.itemLantern])
    }

    @Test("Apply remove non-existent fuse with explicit nil oldValue (Idempotent Success)")
    func testApplyRemoveNonExistentFuseNilOldValue() async throws {
        // Given: Initial state without the fuse
        var gameState = await createSampleGameState()
        let fuseID: FuseID = "nonExistentFuse"
        #expect(gameState.activeFuses[fuseID] == nil)

        // When: Applying a change to remove the non-existent fuse with oldValue: nil
        let change = StateChange(
            entityID: .global,
            attributeKey: .removeActiveFuse(fuseID: fuseID),
            oldValue: nil, // Explicitly stating we expect it to be nil (non-existent)
            newValue: .int(0) // newValue is often ignored for removals
        )

        // Then: Apply should succeed without throwing
        try gameState.apply(change)

        // Assert final state: Fuse should still be absent
        #expect(gameState.activeFuses[fuseID] == nil)

        // Assert history: The change *should* be recorded
        #expect(gameState.changeHistory.count == 1)
        #expect(gameState.changeHistory.first == change)
    }

    @Test("Apply remove non-existent fuse with wrong non-nil oldValue (Error)")
    func testApplyRemoveNonExistentFuseWrongOldValue() async throws {
        // Create state with the fuse already active
        var gameState = await createSampleGameState(activeFuses: ["existingFuse": 5])
        // REMOVED: gameState.activeFuses["existingFuse"] = 5

        let change = StateChange(
            entityID: .global,
            attributeKey: .removeActiveFuse(fuseID: "existingFuse"),
            oldValue: .int(1), // Providing the wrong oldValue
            newValue: .int(0) // newValue is ignored for remove
        )

        // Expect an error because the oldValue is wrong
        // Expect stateValidationFailed because the validation should catch the mismatch
        // let expectedError = ActionResponse.internalEngineError("StateChange oldValue mismatch for removeActiveFuse(fuseID: \"existingFuse\") on global. Expected: int(1), Actual: int(5)")
        do {
            try gameState.apply(change)
            Issue.record("Expected apply to throw ActionResponse.stateValidationFailed, but it did not throw.")
        } catch let error as ActionResponse {
            if case .stateValidationFailed = error {
                // Correct error type thrown, continue verification
            } else {
                Issue.record("Expected ActionResponse.stateValidationFailed, but got \(error)")
            }
        } catch {
            Issue.record("Expected ActionResponse, but got unexpected error type: \(error)")
        }

        // Verify state hasn't changed unexpectedly
        #expect(gameState.activeFuses == ["existingFuse": 5]) // Fuse should still be present
        #expect(gameState.changeHistory.isEmpty) // Apply should fail before adding to history
    }

    @Test("apply - Modify Location Properties - Set")
    func testApplyModifyLocationPropertiesSet() {
        var state = createInitialState()
        // Add the location explicitly before applying the change
        let testLoc = Location(
            id: "testLoc",
            .name("Test Location"),
            .description("Original Desc")
        )
        state.locations["testLoc"] = testLoc

        let change = StateChange(
            entityID: .location("testLoc"),
            attributeKey: .locationAttribute(.isLit),
            oldValue: state.locations["testLoc"]?.attributes[.isLit],
            newValue: true
        )
        try? state.apply(change)

        #expect(change.entityID == EntityID.location("testLoc"))
        #expect(change.attributeKey == AttributeKey.locationAttribute(AttributeID.isLit))
        #expect(change.oldValue == nil || change.oldValue == false)
        #expect(change.newValue == true)
        // Verify description remains untouched initially
        #expect(state.locations["testLoc"]?.attributes[.isLit] == true)
        #expect(state.locations["testLoc"]?.attributes[.description] == .string("Original Desc"))
    }

    @Test("apply - Modify Location Properties - Remove")
    func testApplyModifyLocationPropertiesRemove() {
        var state = createInitialState()
        // Add the location explicitly before applying the change
        let testLoc = Location(
            id: "testLoc",
            .name("Test Location"),
            .description("Original Desc"),
            .inherentlyLit
        )
        state.locations["testLoc"] = testLoc

        let change = StateChange(
            entityID: .location("testLoc"),
            attributeKey: .locationAttribute(.inherentlyLit),
            oldValue: true,
            newValue: false
        )
        try? state.apply(change)

        // Verify description remains untouched
        #expect(state.locations["testLoc"]?.attributes[.inherentlyLit] == false)
        #expect(state.locations["testLoc"]?.attributes[.description] == .string("Original Desc"))
    }

    @Test("apply - Modify Location Dynamic Value")
    func testApplyModifyLocationAttribute() {
        var state = createInitialState()
        // Add the location explicitly before applying the change
        let testLoc = Location(
            id: "testLoc",
            .name("Test Location"),
            .description("Original Desc")
        )
        state.locations["testLoc"] = testLoc

        let change = StateChange(
            entityID: .location("testLoc"),
            attributeKey: .locationAttribute(.description),
            oldValue: .string("Original Desc"),
            newValue: .string("Updated Desc")
        )
        try? state.apply(change)

        #expect(change.entityID == .location("testLoc"))
        #expect(change.attributeKey == .locationAttribute(.description))
        #expect(change.oldValue == .string("Original Desc"))
        #expect(change.newValue == .string("Updated Desc"))
        // Ensure properties are untouched
        #expect(state.locations["testLoc"]?.attributes[.description] == .string("Updated Desc"))
        #expect(state.locations["testLoc"]?.attributes[.isLit] == nil)
    }

    @Test("apply - Validation Failure - OldValue Mismatch")
    func testApplyValidationFailureOldValueMismatch() {
        var state = createInitialState()
        // Ensure startRoom has a description attribute for the test
        let updatedStartRoom = Location(
            id: .startRoom,
            .name("Starting Room"),
            .description("Initial Room Desc")
        )
        state.locations[.startRoom] = updatedStartRoom

        // Try to change a property, but provide the wrong oldValue
        let incorrectChange = StateChange(
            entityID: .location(.startRoom),
            attributeKey: .locationAttribute(.description),
            oldValue: .string("Wrong Old Description"), // Incorrect old value
            newValue: .string("New Description")
        )
        let correctChange = StateChange(
            entityID: .location(.startRoom),
            attributeKey: .locationAttribute(.description),
            oldValue: state.locations[.startRoom]?.attributes[.description],
            newValue: .string("New Description")
        )

        do {
            try state.apply(incorrectChange)
            Issue.record("Expected apply to throw ActionResponse.stateValidationFailed, but it did not throw.")
        } catch let error as ActionResponse {
            if case .stateValidationFailed = error {
                // Correct error type thrown, test passes this part
            } else {
                Issue.record("Expected ActionResponse.stateValidationFailed, but got \(error)")
            }
        } catch {
            Issue.record("Expected ActionResponse, but got unexpected error type: \(error)")
        }

        // Verify the state hasn't changed
        #expect(state.locations[.startRoom]?.attributes[.description] == correctChange.oldValue)
        #expect(state.changeHistory.isEmpty) // No change should be recorded

        // Now apply the correct change
        try? state.apply(correctChange) // Use try? as we don't care about the error here
        #expect(state.locations[.startRoom]?.attributes[.description] == correctChange.newValue)
        #expect(state.changeHistory.count == 1)
    }
}
