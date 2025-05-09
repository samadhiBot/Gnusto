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
                name: "lantern",
                attributes: [.isTakable: true, .isLightSource: true]
            ),
            Item(
                id: Self.itemMailbox,
                name: "mailbox",
                parent: .location(Self.locWOH),
                attributes: [.isContainer: true, .isOpenable: true]
            ),
            Item(
                id: Self.itemLeaflet,
                name: "leaflet",
                parent: .item(Self.itemMailbox),
                attributes: [.isTakable: true, .isReadable: true]
            ),
            Item(
                id: Self.itemSword,
                name: "sword",
                parent: .player,
                attributes: [.isTakable: true]
            )
        ]
    }

    // 2. Define all Locations (without items initially)
    func createSampleLocations() -> [Location] {
        return [
            Location(
                id: Self.locWOH,
                name: "West of House",
                description: "You are standing west of a white house.",
                exits: [.north: Exit(destination: Self.locNorth)]
                // items: // Removed
            ),
            Location(
                id: Self.locNorth,
                name: "North of House",
                description: "You are north of the house.",
                exits: [.south: Exit(destination: Self.locWOH)]
            )
        ]
    }

    // 3. Define initial Player
    func createSamplePlayer() -> Player {
        Player(in: Self.locWOH)
    }

    // 4. Helper to create the GameState with defined placements
    func createSampleGameState(
        activeFuses: [FuseID: Int] = [:] // Add optional parameter
    ) async -> GameState {
        let items = createSampleItems()
        let locations = createSampleLocations()
        let player = createSamplePlayer()
        let flags: Set<FlagID> = ["gameStarted"]
        let pronouns: [String: Set<ItemID>] = ["it": [Self.itemMailbox]]

        return GameState(
            locations: locations,
            items: items,
            player: player,
            flags: flags,
            pronouns: pronouns,
            activeFuses: activeFuses // Pass parameter to initializer
        )
    }

    // Helper to create a consistent initial state for tests
    func createInitialState() -> GameState {
        let startRoom = Location(
            id: "startRoom",
            name: "Starting Room",
            description: "A dark, dark room."
        )
        let testItem = Item(
            id: "testItem",
            name: "Test Item",
            parent: .location("startRoom"),
            attributes: [:] // Assuming default is empty
        )
        let player = Player(in: "startRoom")
        let vocab = Vocabulary.build(items: [testItem]) // Build basic vocab

        var state = GameState(
            locations: [startRoom],
            items: [testItem],
            player: player,
            vocabulary: vocab
        )
        // Add some initial values if needed by tests
        state.flags.insert("gameStarted") // Example: Add a starting flag
        state.pronouns["it"] = ["testItem"]
        state.gameSpecificState["counter"] = .int(0)
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
        #expect(state.locations["startRoom"]?.name == "Starting Room")
        #expect(state.player.currentLocationID == "startRoom")
        #expect(state.flags.contains(FlagID("gameStarted")))
        #expect(!state.flags.contains(FlagID("testFlag")))
        #expect(state.pronouns["it"] == ["testItem"])
        #expect(state.activeFuses.count == 1)
        #expect(state.activeDaemons.count == 1)
        #expect(state.changeHistory.isEmpty)
        #expect(state.gameSpecificState["counter"] == .int(0))

        #expect(!state.vocabulary.verbDefinitions.isEmpty || !state.vocabulary.items.isEmpty)
    }

    @Test("Initialization with Multiple Areas")
    func testInitWithAreas() {
        // Define mock AreaContents with *instance* properties
        struct Area1: AreaContents {
            let locations: [Location] = [Location(
                id: "loc1",
                name: "Area 1 Room",
                description: "A dark, dark room."
            )]
            let items: [Item] = [Item(
                id: "item1",
                name: "Area 1 Item",
                parent: .location("loc1"),
                attributes: [:]
            )]
        }
        struct Area2: AreaContents {
            let locations: [Location] = [Location(
                id: "loc2",
                name: "Area 2 Room",
                description: "A dark, dark room."
            )]
            let items: [Item] = [Item(
                id: "item2",
                name: "Area 2 Item",
                parent: .location("loc2"),
                attributes: [:]
            )]
        }

        let player = Player(in: "loc1")
        let state = GameState(areas: [Area1.self, Area2.self], player: player)

        #expect(state.locations.count == 2)
        #expect(state.locations["loc1"] != nil)
        #expect(state.locations["loc2"] != nil)
        #expect(state.items.count == 2)
        #expect(state.items["item1"] != nil)
        #expect(state.items["item2"] != nil)
        #expect(state.items["item1"]?.parent == .location("loc1"))
        #expect(!state.vocabulary.items.isEmpty)
    }

    // MARK: - Helper Methods Tests

    @Test("Items in Inventory Test")
    func testItemsInInventory() {
        var state = createInitialState() // Make mutable to modify items
        let item1 = Item(
            id: "item1",
            name: "Item 1",
            parent: .player,
            attributes: [:]
        )
        let item2 = Item(
            id: "item2",
            name: "Item 2",
            parent: .location("startRoom"),
            attributes: [:]
        )
        let item3 = Item(
            id: "item3",
            name: "Item 3",
            parent: .player,
            attributes: [:]
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
        let locID: LocationID = "startRoom"
        let item1 = Item(
            id: "item1",
            name: "Item 1",
            parent: .location(locID),
            attributes: [:]
        )
        let item2 = Item(
            id: "item2",
            name: "Item 2",
            parent: .player,
            attributes: [:]
        )
        let item3 = Item(
            id: "item3",
            name: "Item 3",
            parent: .location(locID),
            attributes: [:]
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
            name: "Item 1",
            parent: .player,
            attributes: [:]
        )
        let item2 = Item(
            id: "item2",
            name: "Item 2",
            parent: .location("startRoom"),
            attributes: [:]
        )
        state.items["item1"] = item1 // Add items
        state.items["item2"] = item2

        #expect(state.items["item1"]?.parent == .player)
        #expect(state.items["item2"]?.parent == .location("startRoom"))
        #expect(state.items["testItem"]?.parent == .location("startRoom")) // Check original
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
        let change = StateChange(entityID: .player, attributeKey: .playerScore, newValue: .int(10))
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
        #expect(state1.locations["startRoom"] == state2.locations["startRoom"])
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
        #expect(state.flags == Set([FlagID("gameStarted")]))
        #expect(state.pronouns == ["it": [Self.itemMailbox]])

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
        // This test might need rethinking if direct mutation isn't the goal.
        var woh = state.locations[Self.locWOH]!
        woh.attributes[.description] = .string("A new description.")
        state.locations[Self.locWOH] = woh

        var lantern = state.items[Self.itemLantern]!
        lantern.name = "Magic Lantern"
        state.items[Self.itemLantern] = lantern

        // Valid: Simulate state changes by modifying Item parents
        // Again, modify copy and reassign
        var lanternForParent = state.items[Self.itemLantern]!
        lanternForParent.parent = .player
        state.items[Self.itemLantern] = lanternForParent

        var swordForParent = state.items[Self.itemSword]!
        swordForParent.parent = .location(state.player.currentLocationID)
        state.items[Self.itemSword] = swordForParent

        // Assertions for the valid modifications:
        #expect(
            state.locations[Self.locWOH]?.attributes[.description] == .string("A new description.")
        )
        #expect(state.items[Self.itemLantern]?.name == "Magic Lantern")

        // Check derived inventory reflects parent changes
        let inventoryIDs = state.items.values.filter { $0.parent == .player }.map(\.id)
        #expect(Set(inventoryIDs) == [Self.itemLantern]) // Sword dropped, Lantern taken

        // Check sword is now in the location
        #expect(state.items[Self.itemSword]?.parent == .location(Self.locWOH))
    }

    @Test("GameState Codable Conformance")
    func testGameStateCodable() async throws {
        var originalState = await createSampleGameState()

        // Modify an item *before* encoding
        var lantern = originalState.items[Self.itemLantern]!
        lantern.attributes[.isOn] = true
        lantern.parent = .player // Put lantern in inventory
        originalState.items[Self.itemLantern] = lantern

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let decoder = JSONDecoder()

        let jsonData = try encoder.encode(originalState)
        let decodedState = try decoder.decode(GameState.self, from: jsonData)

        // Basic properties
        #expect(decodedState.flags == originalState.flags)
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
        #expect(state1.flags == state2.flags)
        #expect(state1.pronouns == state2.pronouns)
        #expect(state1.items == state2.items) // Items dict should be equal initially
        #expect(state1.locations == state2.locations) // Locations dict should be equal

        // Modify value type (Player) *in* state2
        state2.player.moves = 5

        // Modify reference type contained within struct (Item dict value) *in* state2
        var lantern2 = state2.items[Self.itemLantern]!
        lantern2.name = "Shiny Lantern"
        lantern2.parent = .player // Also move it for state2
        state2.items[Self.itemLantern] = lantern2 // Reassign modified copy back

        // Verify state1's value types remain unchanged
        let initialPlayer = state1.player // Capture initial player state from state1
        #expect(state1.player == initialPlayer) // state1 player unchanged
        #expect(state2.player != initialPlayer) // state2 player changed
        let initialFlags = state1.flags
        #expect(state1.flags == initialFlags)
        #expect(state2.flags == initialFlags)
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
        // let expectedError = ActionError.internalEngineError("StateChange oldValue mismatch for removeActiveFuse(fuseID: \"existingFuse\") on global. Expected: int(1), Actual: int(5)")
        do {
            try gameState.apply(change)
            Issue.record("Expected apply to throw ActionError.stateValidationFailed, but it did not throw.")
        } catch let error as ActionError {
            if case .stateValidationFailed = error {
                // Correct error type thrown, continue verification
            } else {
                Issue.record("Expected ActionError.stateValidationFailed, but got \(error)")
            }
        } catch {
            Issue.record("Expected ActionError, but got unexpected error type: \(error)")
        }

        // Verify state hasn't changed unexpectedly
        #expect(gameState.activeFuses == ["existingFuse": 5]) // Fuse should still be present
        #expect(gameState.changeHistory.isEmpty) // Apply should fail before adding to history
    }

    @Test("apply - Modify Location Properties - Set")
    func testApplyModifyLocationPropertiesSet() {
        var state = createInitialState()
        // Add the location explicitly before applying the change
        let testLoc = Location(id: "testLoc", name: "Test Location", attributes: [.description: .string("Original Desc")])
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
        let testLoc = Location(id: "testLoc", name: "Test Location", attributes: [.description: .string("Original Desc"), .isLit: true])
        state.locations["testLoc"] = testLoc

        let change = StateChange(
            entityID: .location("testLoc"),
            attributeKey: .locationAttribute(.isLit),
            oldValue: true,
            newValue: false
        )
        try? state.apply(change)

        #expect(change.entityID == .location("testLoc"))
        #expect(change.attributeKey == .locationAttribute(.isLit))
        #expect(change.oldValue == true)
        #expect(change.newValue == false)
        // Verify description remains untouched
        #expect(state.locations["testLoc"]?.attributes[.isLit] == false)
        #expect(state.locations["testLoc"]?.attributes[.description] == .string("Original Desc"))
    }

    @Test("apply - Modify Location Dynamic Value")
    func testApplyModifyLocationAttribute() {
        var state = createInitialState()
        // Add the location explicitly before applying the change
        let testLoc = Location(id: "testLoc", name: "Test Location", attributes: [.description: .string("Original Desc")])
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
        if var startRoom = state.locations["startRoom"] {
            startRoom.attributes[.description] = .string("Initial Room Desc")
            state.locations["startRoom"] = startRoom
        }

        // Try to change a property, but provide the wrong oldValue
        let incorrectChange = StateChange(
            entityID: .location("startRoom"),
            attributeKey: .locationAttribute(.description),
            oldValue: .string("Wrong Old Description"), // Incorrect old value
            newValue: .string("New Description")
        )
        let correctChange = StateChange(
            entityID: .location("startRoom"),
            attributeKey: .locationAttribute(.description),
            oldValue: state.locations["startRoom"]?.attributes[.description],
            newValue: .string("New Description")
        )

        do {
            try state.apply(incorrectChange)
            Issue.record("Expected apply to throw ActionError.stateValidationFailed, but it did not throw.")
        } catch let error as ActionError {
            if case .stateValidationFailed = error {
                // Correct error type thrown, test passes this part
            } else {
                Issue.record("Expected ActionError.stateValidationFailed, but got \(error)")
            }
        } catch {
            Issue.record("Expected ActionError, but got unexpected error type: \(error)")
        }

        // Verify the state hasn't changed
        #expect(state.locations["startRoom"]?.attributes[.description] == correctChange.oldValue)
        #expect(state.changeHistory.isEmpty) // No change should be recorded

        // Now apply the correct change
        try? state.apply(correctChange) // Use try? as we don't care about the error here
        #expect(state.locations["startRoom"]?.attributes[.description] == correctChange.newValue)
        #expect(state.changeHistory.count == 1)
    }
}
