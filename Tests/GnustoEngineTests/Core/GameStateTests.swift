import Testing
import Foundation // For JSONEncoder/Decoder
@testable import GnustoEngine

@MainActor
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
                properties: .takable, .lightSource
            ),
            Item(
                id: Self.itemMailbox,
                name: "mailbox",
                properties: .container, .openable,
                parent: .location(Self.locWOH)
            ),
            Item(
                id: Self.itemLeaflet,
                name: "leaflet",
                properties: .takable, .read,
                parent: .item(Self.itemMailbox)
            ),
            Item(
                id: Self.itemSword,
                name: "sword",
                properties: .takable,
                parent: .player
            )
        ]
    }

    // 2. Define all Locations (without items initially)
    func createSampleLocations() -> [Location] {
        return [
            Location(
                id: Self.locWOH,
                name: "West of House",
                longDescription: "You are standing west of a white house.",
                exits: [.north: Exit(destination: Self.locNorth)]
                // items: // Removed
            ),
            Location(
                id: Self.locNorth,
                name: "North of House",
                longDescription: "You are north of the house.",
                exits: [.south: Exit(destination: Self.locWOH)]
            )
        ]
    }

    // 3. Define initial Player
    func createSamplePlayer() -> Player {
        Player(in: Self.locWOH)
    }

    // 4. Helper to create the GameState with defined placements
    func createSampleGameState() async -> GameState {
        let items = createSampleItems()
        let locations = createSampleLocations()
        let player = createSamplePlayer()
        let flags = ["gameStarted": true]
        let pronouns: [String: Set<ItemID>] = ["it": [Self.itemMailbox]]

        return GameState(
            locations: locations,
            items: items,
            player: player,
            flags: flags,
            pronouns: pronouns
        )
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
        #expect(state.flags == ["gameStarted": true])
        #expect(state.pronouns == ["it": [Self.itemMailbox]])

        // Check derived inventory
        #expect(Set(state.itemsInInventory()) == [Self.itemSword])
    }

    @Test("GameState Property Modification")
    func testGameStatePropertyModification() async throws {
        let state = await createSampleGameState() // Use let, as direct mutation of struct props is removed

        // Valid: Modify properties of reference types (Location, Item)
        state.locations[Self.locWOH]?.longDescription = "A new description."
        state.items[Self.itemLantern]?.name = "Magic Lantern"

        // Valid: Simulate state changes by modifying Item parents (reference type)
        state.items[Self.itemLantern]?.parent = .player
        state.items[Self.itemSword]?.parent = .location(state.player.currentLocationID)

        // Assertions for the valid modifications:
        #expect(
            state.locations[Self.locWOH]?.longDescription?
                .rawStaticDescription == "A new description."
        )
        #expect(state.items[Self.itemLantern]?.name == "Magic Lantern")

        // Check derived inventory reflects parent changes
        #expect(Set(state.itemsInInventory()) == [Self.itemLantern]) // Sword dropped, Lantern taken

        // Check sword is now in the location
        #expect(state.items[Self.itemSword]?.parent == .location(Self.locWOH))

        // Removed assertions for disallowed mutations:
        // #expect(state.player.score == 10)
        // #expect(state.flags["lightSeen"] == true)
        // #expect(state.pronouns["it"] == [Self.itemLantern])
    }

    @Test("GameState Codable Conformance")
    func testGameStateCodable() async throws {
        let originalState = await createSampleGameState()

        // Modify an item *before* encoding to check reference persistence & parent encoding
        originalState.items[Self.itemLantern]?.addProperty(.on)
        originalState.items[Self.itemLantern]?.parent = .player // Put lantern in inventory

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys] // Easier debugging
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
        // #expect(decodedState.locations[locWOH]?.items == originalState.locations[locWOH]?.items) // Removed
        #expect(decodedState.locations[Self.locNorth]?.longDescription == originalState.locations[Self.locNorth]?.longDescription)

        // Check content of items (comparing key properties, including parent)
        #expect(decodedState.items[Self.itemLantern]?.name == originalState.items[Self.itemLantern]?.name)
        #expect(decodedState.items[Self.itemLantern]?.properties == originalState.items[Self.itemLantern]?.properties)
        #expect(decodedState.items[Self.itemLantern]?.parent == originalState.items[Self.itemLantern]?.parent) // Should be .player
        #expect(decodedState.items[Self.itemMailbox]?.parent == originalState.items[Self.itemMailbox]?.parent) // Should be .location
        #expect(decodedState.items[Self.itemLeaflet]?.parent == originalState.items[Self.itemLeaflet]?.parent) // Should be .item

        // IMPORTANT: Check that decoded objects are NEW instances
        #expect(decodedState.locations[Self.locWOH] !== originalState.locations[Self.locWOH])
        #expect(decodedState.items[Self.itemLantern] !== originalState.items[Self.itemLantern])
    }

    @Test("GameState Value Semantics (Mixed with Reference)")
    func testGameStateValueSemantics() async throws {
        let state1 = await createSampleGameState()
        let state2 = state1 // Creates a copy of the struct

        // Check initial equality of value types
        #expect(state1.player == state2.player)
        #expect(state1.flags == state2.flags)
        #expect(state1.pronouns == state2.pronouns)

        // Modify reference type (Item) *through* state2
        state2.items[Self.itemLantern]?.name = "Shiny Lantern"
        state2.items[Self.itemLantern]?.parent = .player // Also move it for state2

        // Verify state1's value types remain equal to state2's initial values (confirming copy)
        let initialPlayer = state1.player // Capture initial player state from state1
        #expect(state1.player == initialPlayer) // state1 player unchanged
        #expect(state2.player == initialPlayer) // state2 player also initially unchanged
        let initialFlags = state1.flags
        #expect(state1.flags == initialFlags)
        #expect(state2.flags == initialFlags)
        let initialPronouns = state1.pronouns
        #expect(state1.pronouns == initialPronouns)
        #expect(state2.pronouns == initialPronouns)

        // Verify state1's reference type *is* CHANGED (because Item is a class)
        #expect(state1.items[Self.itemLantern]?.name == "Shiny Lantern")
        // Also verify parent change propagated
        #expect(state1.items[Self.itemLantern]?.parent == .player)

        // Check derived inventories reflect the change in both states (due to shared Item instance)
        #expect(Set(state1.itemsInInventory()) == [Self.itemSword, Self.itemLantern]) // Sword was initial, lantern got moved
        #expect(Set(state2.itemsInInventory()) == [Self.itemSword, Self.itemLantern]) // Same items, parent change propagated

        // Further check: state1 and state2 are distinct structs
        // Check their internal dictionaries point to the same item objects initially
        #expect(state1.items[Self.itemLantern] === state2.items[Self.itemLantern])

        // Removed disallowed mutations from state2:
        // state2.player.moves = 5
        // state2.flags["mailboxOpened"] = true
        // state2.pronouns["it"] = [Self.itemLantern]
    }
}

// MARK: - GameState.apply Tests

@MainActor
@Suite("GameState.apply Tests")
struct GameStateApplyTests {
    // Use the helper from the main struct
    let helper = GameStateTests()

    // MARK: - Item Properties Tests

    @Test("Apply valid item property change")
    func testApplyValidItemPropertyChange() async throws {
        // Given
        var gameState = await helper.createSampleGameState()
        let initialItem = gameState.items[GameStateTests.itemLantern]
        #expect(initialItem != nil)
        let oldProperties = initialItem!.properties
        var newProperties = oldProperties
        newProperties.insert(.on) // Add .on property

        let change = StateChange(
            entityId: .item(GameStateTests.itemLantern),
            propertyKey: .itemProperties,
            oldValue: .itemProperties(oldProperties),
            newValue: .itemProperties(newProperties)
        )

        // When
        try gameState.apply(change)

        // Then
        let finalItem = gameState.items[GameStateTests.itemLantern]
        #expect(finalItem?.properties == newProperties, "Item properties should be updated")
        #expect(finalItem?.hasProperty(.on) == true)

        #expect(gameState.changeHistory.count == 1, "Change history should contain one entry")
        #expect(gameState.changeHistory.first == change, "Change history should contain the applied change")
    }

    @Test("Apply item property change with invalid oldValue")
    func testApplyInvalidItemPropertyChangeOldValue() async throws {
        // Given
        var gameState = await helper.createSampleGameState()
        let initialItem = gameState.items[GameStateTests.itemLantern]
        #expect(initialItem != nil)
        let actualOldProperties = initialItem!.properties
        let incorrectOldProperties: Set<ItemProperty> = [.fixed] // Incorrect old value
        var newProperties = actualOldProperties
        newProperties.insert(.on)

        let change = StateChange(
            entityId: .item(GameStateTests.itemLantern),
            propertyKey: .itemProperties,
            oldValue: .itemProperties(incorrectOldProperties), // Use incorrect old value
            newValue: .itemProperties(newProperties)
        )

        // When & Then
        var thrownError: Error? = nil
        do {
            try gameState.apply(change)
            Issue.record("Expected apply to throw an error, but it succeeded.")
        } catch {
            thrownError = error
        }

        #expect(thrownError != nil, "An error should have been thrown.")
        if let actionError = thrownError as? ActionError {
            // Check only the error case, not the associated message
            if case .internalEngineError = actionError { } else {
                Issue.record("Expected .internalEngineError case, got \(actionError)")
            }
        } else {
            Issue.record("Thrown error was not an ActionError: \(thrownError?.localizedDescription ?? "nil")")
        }

        // Verify state was not changed
        let finalItem = gameState.items[GameStateTests.itemLantern]
        #expect(
            finalItem?.properties == actualOldProperties,
            "Item properties should not be updated on error"
        )
        #expect(finalItem?.hasProperty(.on) == false)
        #expect(gameState.changeHistory.isEmpty, "Change history should be empty on error")
    }

    // MARK: - Item Parent Tests

    @Test("Apply valid item parent change")
    func testApplyValidItemParentChange() async throws {
        // Given
        var gameState = await helper.createSampleGameState()
        let itemToMove = GameStateTests.itemLantern // Starts at .nowhere
        let initialParent = gameState.items[itemToMove]?.parent
        #expect(initialParent == .nowhere)
        let newParent: ParentEntity = .player

        let change = StateChange(
            entityId: .item(itemToMove),
            propertyKey: .itemParent,
            oldValue: .parentEntity(.nowhere), // Correct old value
            newValue: .parentEntity(newParent)
        )

        // When
        try gameState.apply(change)

        // Then
        let finalItem = gameState.items[itemToMove]
        #expect(finalItem?.parent == newParent, "Item parent should be updated")
        #expect(gameState.changeHistory.count == 1, "Change history should contain one entry")
        #expect(gameState.changeHistory.first == change, "Change history should contain the applied change")
        #expect(gameState.itemsInInventory().contains(itemToMove), "Item should now be in inventory")
    }

    @Test("Apply item parent change with invalid oldValue")
    func testApplyInvalidItemParentChangeOldValue() async throws {
        // Given
        var gameState = await helper.createSampleGameState()
        let itemToMove = GameStateTests.itemLantern // Starts at .nowhere
        let actualOldParent = gameState.items[itemToMove]?.parent
        #expect(actualOldParent == .nowhere)
        let incorrectOldParent: ParentEntity = .location("someOtherPlace")
        let newParent: ParentEntity = .player

        let change = StateChange(
            entityId: .item(itemToMove),
            propertyKey: .itemParent,
            oldValue: .parentEntity(incorrectOldParent), // Incorrect old value
            newValue: .parentEntity(newParent)
        )

        // When & Then
        var thrownError: Error? = nil
        do {
            try gameState.apply(change)
            Issue.record("Expected apply to throw an error, but it succeeded.")
        } catch {
            thrownError = error
        }

        #expect(thrownError != nil, "An error should have been thrown.")
        if let actionError = thrownError as? ActionError {
            // Check only the error case, not the associated message
            if case .internalEngineError = actionError { } else {
                Issue.record("Expected .internalEngineError case, got \(actionError)")
            }
        } else {
            Issue.record("Thrown error was not an ActionError: \(thrownError?.localizedDescription ?? "nil")")
        }

        // Verify state was not changed
        let finalItem = gameState.items[itemToMove]
        #expect(finalItem?.parent == actualOldParent, "Item parent should not be updated on error")
        #expect(gameState.changeHistory.isEmpty, "Change history should be empty on error")
        #expect(gameState.itemsInInventory().contains(itemToMove) == false, "Item should not be in inventory")
    }

    // MARK: - Item Size Tests

    @Test("Apply valid item size change")
    func testApplyValidItemSizeChange() async throws {
        // Given
        var gameState = await helper.createSampleGameState()
        let itemID = GameStateTests.itemLantern
        let initialSize = gameState.items[itemID]?.size ?? 0 // Default to 0 if nil
        let newSize = initialSize + 5

        let change = StateChange(
            entityId: .item(itemID),
            propertyKey: .itemSize,
            oldValue: .int(initialSize),
            newValue: .int(newSize)
        )

        // When
        try gameState.apply(change)

        // Then
        #expect(gameState.items[itemID]?.size == newSize)
        #expect(gameState.changeHistory.last == change)
    }

    @Test("Apply item size change with invalid oldValue")
    func testApplyInvalidItemSizeChangeOldValue() async throws {
        // Given
        var gameState = await helper.createSampleGameState()
        let itemID = GameStateTests.itemLantern
        let actualOldSize = gameState.items[itemID]?.size ?? 0
        let incorrectOldSize = actualOldSize - 1 // Incorrect
        let newSize = actualOldSize + 5

        let change = StateChange(
            entityId: .item(itemID),
            propertyKey: .itemSize,
            oldValue: .int(incorrectOldSize),
            newValue: .int(newSize)
        )

        // When & Then
        var thrownError: Error? = nil
        do {
            try gameState.apply(change)
            Issue.record("Expected apply to throw an error, but it succeeded.")
        } catch {
            thrownError = error
        }
        #expect(thrownError != nil, "An error should have been thrown.")
        if let actionError = thrownError as? ActionError {
            // Check only the error case, not the associated message
            if case .internalEngineError = actionError { } else {
                Issue.record("Expected .internalEngineError case, got \(actionError)")
            }
        } else {
            Issue.record("Thrown error was not an ActionError: \(thrownError?.localizedDescription ?? "nil")")
        }

        // Verify state unchanged
        #expect(gameState.items[itemID]?.size == actualOldSize)
        #expect(gameState.changeHistory.isEmpty)
    }

    // MARK: - Item Capacity Tests

    @Test("Apply valid item capacity change")
    func testApplyValidItemCapacityChange() async throws {
        // Given
        var gameState = await helper.createSampleGameState()
        let itemID = GameStateTests.itemMailbox // Mailbox is a container
        let initialCapacity = gameState.items[itemID]?.capacity ?? 0
        let newCapacity = initialCapacity + 10

        let change = StateChange(
            entityId: .item(itemID),
            propertyKey: .itemCapacity,
            oldValue: .int(initialCapacity),
            newValue: .int(newCapacity)
        )

        // When
        try gameState.apply(change)

        // Then
        #expect(gameState.items[itemID]?.capacity == newCapacity)
        #expect(gameState.changeHistory.last == change)
    }

    @Test("Apply item capacity change with invalid oldValue")
    func testApplyInvalidItemCapacityChangeOldValue() async throws {
        // Given
        var gameState = await helper.createSampleGameState()
        let itemID = GameStateTests.itemMailbox
        let actualOldCapacity = gameState.items[itemID]?.capacity ?? 0
        let incorrectOldCapacity = actualOldCapacity + 1 // Incorrect
        let newCapacity = actualOldCapacity + 10

        let change = StateChange(
            entityId: .item(itemID),
            propertyKey: .itemCapacity,
            oldValue: .int(incorrectOldCapacity),
            newValue: .int(newCapacity)
        )

        // When & Then
        var thrownError: Error? = nil
        do {
            try gameState.apply(change)
            Issue.record("Expected apply to throw an error, but it succeeded.")
        } catch {
            thrownError = error
        }
        #expect(thrownError != nil, "An error should have been thrown.")
        if let actionError = thrownError as? ActionError {
            // Check only the error case, not the associated message
            if case .internalEngineError = actionError { } else {
                Issue.record("Expected .internalEngineError case, got \(actionError)")
            }
        } else {
            Issue.record("Thrown error was not an ActionError: \(thrownError?.localizedDescription ?? "nil")")
        }

        // Verify state unchanged
        #expect(gameState.items[itemID]?.capacity == actualOldCapacity)
        #expect(gameState.changeHistory.isEmpty)
    }

    // MARK: - Item Name Tests

    @Test("Apply valid item name change")
    func testApplyValidItemNameChange() async throws {
        // Given
        var gameState = await helper.createSampleGameState()
        let itemID = GameStateTests.itemLantern
        let initialName = gameState.items[itemID]?.name ?? ""
        let newName = "Magic Brass Lantern"

        let change = StateChange(
            entityId: .item(itemID),
            propertyKey: .itemName,
            oldValue: .string(initialName),
            newValue: .string(newName)
        )

        // When
        try gameState.apply(change)

        // Then
        #expect(gameState.items[itemID]?.name == newName)
        #expect(gameState.changeHistory.last == change)
    }

    @Test("Apply item name change with invalid oldValue")
    func testApplyInvalidItemNameChangeOldValue() async throws {
        // Given
        var gameState = await helper.createSampleGameState()
        let itemID = GameStateTests.itemLantern
        let actualOldName = gameState.items[itemID]?.name ?? ""
        let incorrectOldName = "rusty lantern" // Incorrect
        let newName = "Magic Brass Lantern"

        let change = StateChange(
            entityId: .item(itemID),
            propertyKey: .itemName,
            oldValue: .string(incorrectOldName),
            newValue: .string(newName)
        )

        // When & Then
        var thrownError: Error? = nil
        do {
            try gameState.apply(change)
            Issue.record("Expected apply to throw an error, but it succeeded.")
        } catch {
            thrownError = error
        }
        #expect(thrownError != nil, "An error should have been thrown.")
        if let actionError = thrownError as? ActionError {
            // Check only the error case, not the associated message
            if case .internalEngineError = actionError { } else {
                Issue.record("Expected .internalEngineError case, got \(actionError)")
            }
        } else {
            Issue.record("Thrown error was not an ActionError: \(thrownError?.localizedDescription ?? "nil")")
        }

        // Verify state unchanged
        #expect(gameState.items[itemID]?.name == actualOldName)
        #expect(gameState.changeHistory.isEmpty)
    }

    // MARK: - Item Adjectives Tests

    @Test("Apply valid item adjectives change")
    func testApplyValidItemAdjectivesChange() async throws {
        // Given
        var gameState = await helper.createSampleGameState()
        let itemID = GameStateTests.itemLantern
        let initialAdjectives = gameState.items[itemID]?.adjectives ?? []
        let newAdjectives: Set<String> = ["brass", "magic"]

        let change = StateChange(
            entityId: .item(itemID),
            propertyKey: .itemAdjectives,
            oldValue: .itemAdjectives(initialAdjectives),
            newValue: .itemAdjectives(newAdjectives)
        )

        // When
        try gameState.apply(change)

        // Then
        #expect(gameState.items[itemID]?.adjectives == newAdjectives)
        #expect(gameState.changeHistory.last == change)
    }

    @Test("Apply item adjectives change with invalid oldValue")
    func testApplyInvalidItemAdjectivesChangeOldValue() async throws {
        // Given
        var gameState = await helper.createSampleGameState()
        let itemID = GameStateTests.itemLantern
        let actualOldAdjectives = gameState.items[itemID]?.adjectives ?? []
        let incorrectOldAdjectives: Set<String> = ["rusty"] // Incorrect
        let newAdjectives: Set<String> = ["brass", "magic"]

        let change = StateChange(
            entityId: .item(itemID),
            propertyKey: .itemAdjectives,
            oldValue: .itemAdjectives(incorrectOldAdjectives),
            newValue: .itemAdjectives(newAdjectives)
        )

        // When & Then
        var thrownError: Error? = nil
        do {
            try gameState.apply(change)
            Issue.record("Expected apply to throw an error, but it succeeded.")
        } catch {
            thrownError = error
        }
        #expect(thrownError != nil, "An error should have been thrown.")
        if let actionError = thrownError as? ActionError {
            // Check only the error case, not the associated message
            if case .internalEngineError = actionError { } else {
                Issue.record("Expected .internalEngineError case, got \(actionError)")
            }
        } else {
            Issue.record("Thrown error was not an ActionError: \(thrownError?.localizedDescription ?? "nil")")
        }

        // Verify state unchanged
        #expect(gameState.items[itemID]?.adjectives == actualOldAdjectives)
        #expect(gameState.changeHistory.isEmpty)
    }

    // MARK: - Item Synonyms Tests

    @Test("Apply valid item synonyms change")
    func testApplyValidItemSynonymsChange() async throws {
        // Given
        var gameState = await helper.createSampleGameState()
        let itemID = GameStateTests.itemLantern
        let initialSynonyms = gameState.items[itemID]?.synonyms ?? []
        let newSynonyms: Set<String> = ["light", "lamp"]

        let change = StateChange(
            entityId: .item(itemID),
            propertyKey: .itemSynonyms,
            oldValue: .itemSynonyms(initialSynonyms),
            newValue: .itemSynonyms(newSynonyms)
        )

        // When
        try gameState.apply(change)

        // Then
        #expect(gameState.items[itemID]?.synonyms == newSynonyms)
        #expect(gameState.changeHistory.last == change)
    }

    @Test("Apply item synonyms change with invalid oldValue")
    func testApplyInvalidItemSynonymsChangeOldValue() async throws {
        // Given
        var gameState = await helper.createSampleGameState()
        let itemID = GameStateTests.itemLantern
        let actualOldSynonyms = gameState.items[itemID]?.synonyms ?? []
        let incorrectOldSynonyms: Set<String> = ["torch"] // Incorrect
        let newSynonyms: Set<String> = ["light", "lamp"]

        let change = StateChange(
            entityId: .item(itemID),
            propertyKey: .itemSynonyms,
            oldValue: .itemSynonyms(incorrectOldSynonyms),
            newValue: .itemSynonyms(newSynonyms)
        )

        // When & Then
        var thrownError: Error? = nil
        do {
            try gameState.apply(change)
            Issue.record("Expected apply to throw an error, but it succeeded.")
        } catch {
            thrownError = error
        }
        #expect(thrownError != nil, "An error should have been thrown.")
        if let actionError = thrownError as? ActionError {
            // Check only the error case, not the associated message
            if case .internalEngineError = actionError { } else {
                Issue.record("Expected .internalEngineError case, got \(actionError)")
            }
        } else {
            Issue.record("Thrown error was not an ActionError: \(thrownError?.localizedDescription ?? "nil")")
        }

        // Verify state unchanged
        #expect(gameState.items[itemID]?.synonyms == actualOldSynonyms)
        #expect(gameState.changeHistory.isEmpty)
    }

    // MARK: - Location Properties Tests

    @Test("Apply valid location properties change")
    func testApplyValidLocationPropertiesChange() async throws {
        // Given
        var gameState = await helper.createSampleGameState()
        let locationID = GameStateTests.locWOH
        let initialProperties = gameState.locations[locationID]?.properties ?? []
        let newProperties: Set<LocationProperty> = [.visited, .inherentlyLit]

        let change = StateChange(
            entityId: .location(locationID),
            propertyKey: .locationProperties,
            oldValue: .locationProperties(initialProperties),
            newValue: .locationProperties(newProperties)
        )

        // When
        try gameState.apply(change)

        // Then
        #expect(gameState.locations[locationID]?.properties == newProperties)
        #expect(gameState.changeHistory.last == change)
    }

    @Test("Apply location properties change with invalid oldValue")
    func testApplyInvalidLocationPropertiesChangeOldValue() async throws {
        // Given
        var gameState = await helper.createSampleGameState()
        let locationID = GameStateTests.locWOH
        let actualOldProperties = gameState.locations[locationID]?.properties ?? []
        let incorrectOldProperties: Set<LocationProperty> = [.sacred] // Incorrect
        let newProperties: Set<LocationProperty> = [.visited, .inherentlyLit]

        let change = StateChange(
            entityId: .location(locationID),
            propertyKey: .locationProperties,
            oldValue: .locationProperties(incorrectOldProperties),
            newValue: .locationProperties(newProperties)
        )

        // When & Then
        var thrownError: Error? = nil
        do {
            try gameState.apply(change)
            Issue.record("Expected apply to throw an error, but it succeeded.")
        } catch {
            thrownError = error
        }
        #expect(thrownError != nil, "An error should have been thrown.")
        if let actionError = thrownError as? ActionError {
            // Check only the error case, not the associated message
            if case .internalEngineError = actionError { } else {
                Issue.record("Expected .internalEngineError case, got \(actionError)")
            }
        } else {
            Issue.record("Thrown error was not an ActionError: \(thrownError?.localizedDescription ?? "nil")")
        }

        // Verify state unchanged
        #expect(gameState.locations[locationID]?.properties == actualOldProperties)
        #expect(gameState.changeHistory.isEmpty)
    }

    // MARK: - Location Name Tests

    @Test("Apply valid location name change")
    func testApplyValidLocationNameChange() async throws {
        // Given
        var gameState = await helper.createSampleGameState()
        let locationID = GameStateTests.locWOH
        let initialName = gameState.locations[locationID]?.name ?? ""
        let newName = "West End of White House"

        let change = StateChange(
            entityId: .location(locationID),
            propertyKey: .locationName,
            oldValue: .string(initialName),
            newValue: .string(newName)
        )

        // When
        try gameState.apply(change)

        // Then
        #expect(gameState.locations[locationID]?.name == newName)
        #expect(gameState.changeHistory.last == change)
    }

    @Test("Apply location name change with invalid oldValue")
    func testApplyInvalidLocationNameChangeOldValue() async throws {
        // Given
        var gameState = await helper.createSampleGameState()
        let locationID = GameStateTests.locWOH
        let actualOldName = gameState.locations[locationID]?.name ?? ""
        let incorrectOldName = "East of House" // Incorrect
        let newName = "West End of White House"

        let change = StateChange(
            entityId: .location(locationID),
            propertyKey: .locationName,
            oldValue: .string(incorrectOldName),
            newValue: .string(newName)
        )

        // When & Then
        var thrownError: Error? = nil
        do {
            try gameState.apply(change)
            Issue.record("Expected apply to throw an error, but it succeeded.")
        } catch {
            thrownError = error
        }
        #expect(thrownError != nil, "An error should have been thrown.")
        if let actionError = thrownError as? ActionError {
            // Check only the error case, not the associated message
            if case .internalEngineError = actionError { } else {
                Issue.record("Expected .internalEngineError case, got \(actionError)")
            }
        } else {
            Issue.record("Thrown error was not an ActionError: \(thrownError?.localizedDescription ?? "nil")")
        }

        // Verify state unchanged
        #expect(gameState.locations[locationID]?.name == actualOldName)
        #expect(gameState.changeHistory.isEmpty)
    }

    // MARK: - Location Exits Tests

    @Test("Apply valid location exits change")
    func testApplyValidLocationExitsChange() async throws {
        // Given
        var gameState = await helper.createSampleGameState()
        let locationID = GameStateTests.locWOH
        let initialExits = gameState.locations[locationID]?.exits ?? [:]
        var newExits = initialExits
        newExits[.south] = Exit(destination: GameStateTests.locClearing)

        let change = StateChange(
            entityId: .location(locationID),
            propertyKey: .locationExits,
            oldValue: .locationExits(initialExits),
            newValue: .locationExits(newExits)
        )

        // When
        try gameState.apply(change)

        // Then
        #expect(gameState.locations[locationID]?.exits == newExits)
        #expect(gameState.changeHistory.last == change)
    }

    @Test("Apply location exits change with invalid oldValue")
    func testApplyInvalidLocationExitsChangeOldValue() async throws {
        // Given
        var gameState = await helper.createSampleGameState()
        let locationID = GameStateTests.locWOH
        let actualOldExits = gameState.locations[locationID]?.exits ?? [:]
        let incorrectOldExits: [Direction: Exit] = [.east: Exit(destination: "nowhere")] // Incorrect
        var newExits = actualOldExits
        newExits[.south] = Exit(destination: GameStateTests.locClearing)

        let change = StateChange(
            entityId: .location(locationID),
            propertyKey: .locationExits,
            oldValue: .locationExits(incorrectOldExits),
            newValue: .locationExits(newExits)
        )

        // When & Then
        var thrownError: Error? = nil
        do {
            try gameState.apply(change)
            Issue.record("Expected apply to throw an error, but it succeeded.")
        } catch {
            thrownError = error
        }
        #expect(thrownError != nil, "An error should have been thrown.")
        if let actionError = thrownError as? ActionError {
            // Check only the error case, not the associated message
            if case .internalEngineError = actionError { } else {
                Issue.record("Expected .internalEngineError case, got \(actionError)")
            }
        } else {
            Issue.record("Thrown error was not an ActionError: \(thrownError?.localizedDescription ?? "nil")")
        }

        // Verify state unchanged
        #expect(gameState.locations[locationID]?.exits == actualOldExits)
        #expect(gameState.changeHistory.isEmpty)
    }

    // MARK: - Player Score Tests

    @Test("Apply valid player score change")
    func testApplyValidPlayerScoreChange() async throws {
        // Given
        var gameState = await helper.createSampleGameState()
        let initialScore = gameState.player.score
        let newScore = initialScore + 10

        let change = StateChange(
            entityId: .player,
            propertyKey: .playerScore,
            oldValue: .int(initialScore),
            newValue: .int(newScore)
        )

        // When
        try gameState.apply(change)

        // Then
        #expect(gameState.player.score == newScore)
        #expect(gameState.changeHistory.last == change)
    }

    @Test("Apply player score change with invalid oldValue")
    func testApplyInvalidPlayerScoreChangeOldValue() async throws {
        // Given
        var gameState = await helper.createSampleGameState()
        let actualOldScore = gameState.player.score
        let incorrectOldScore = actualOldScore + 1 // Incorrect
        let newScore = actualOldScore + 10

        let change = StateChange(
            entityId: .player,
            propertyKey: .playerScore,
            oldValue: .int(incorrectOldScore),
            newValue: .int(newScore)
        )

        // When & Then
        var thrownError: Error? = nil
        do {
            try gameState.apply(change)
            Issue.record("Expected apply to throw an error, but it succeeded.")
        } catch {
            thrownError = error
        }
        #expect(thrownError != nil, "An error should have been thrown.")
        if let actionError = thrownError as? ActionError {
            // Check only the error case, not the associated message
            if case .internalEngineError = actionError { } else {
                Issue.record("Expected .internalEngineError case, got \(actionError)")
            }
        } else {
            Issue.record("Thrown error was not an ActionError: \(thrownError?.localizedDescription ?? "nil")")
        }

        // Verify state unchanged
        #expect(gameState.player.score == actualOldScore)
        #expect(gameState.changeHistory.isEmpty)
    }

    // MARK: - Player Moves Tests

    @Test("Apply valid player moves change")
    func testApplyValidPlayerMovesChange() async throws {
        // Given
        var gameState = await helper.createSampleGameState()
        let initialMoves = gameState.player.moves
        let newMoves = initialMoves + 1

        let change = StateChange(
            entityId: .player,
            propertyKey: .playerMoves,
            oldValue: .int(initialMoves),
            newValue: .int(newMoves)
        )

        // When
        try gameState.apply(change)

        // Then
        #expect(gameState.player.moves == newMoves)
        #expect(gameState.changeHistory.last == change)
    }

    @Test("Apply player moves change with invalid oldValue")
    func testApplyInvalidPlayerMovesChangeOldValue() async throws {
        // Given
        var gameState = await helper.createSampleGameState()
        let actualOldMoves = gameState.player.moves
        let incorrectOldMoves = actualOldMoves + 5 // Incorrect
        let newMoves = actualOldMoves + 1

        let change = StateChange(
            entityId: .player,
            propertyKey: .playerMoves,
            oldValue: .int(incorrectOldMoves),
            newValue: .int(newMoves)
        )

        // When & Then
        var thrownError: Error? = nil
        do {
            try gameState.apply(change)
            Issue.record("Expected apply to throw an error, but it succeeded.")
        } catch {
            thrownError = error
        }
        #expect(thrownError != nil, "An error should have been thrown.")
        if let actionError = thrownError as? ActionError {
            // Check only the error case, not the associated message
            if case .internalEngineError = actionError { } else {
                Issue.record("Expected .internalEngineError case, got \(actionError)")
            }
        } else {
            Issue.record("Thrown error was not an ActionError: \(thrownError?.localizedDescription ?? "nil")")
        }

        // Verify state unchanged
        #expect(gameState.player.moves == actualOldMoves)
        #expect(gameState.changeHistory.isEmpty)
    }

    // MARK: - Player Capacity Tests

    @Test("Apply valid player capacity change")
    func testApplyValidPlayerCapacityChange() async throws {
        // Given
        var gameState = await helper.createSampleGameState()
        let initialCapacity = gameState.player.carryingCapacity
        let newCapacity = initialCapacity + 50

        let change = StateChange(
            entityId: .player,
            propertyKey: .playerCapacity,
            oldValue: .int(initialCapacity),
            newValue: .int(newCapacity)
        )

        // When
        try gameState.apply(change)

        // Then
        #expect(gameState.player.carryingCapacity == newCapacity)
        #expect(gameState.changeHistory.last == change)
    }

    @Test("Apply player capacity change with invalid oldValue")
    func testApplyInvalidPlayerCapacityChangeOldValue() async throws {
        // Given
        var gameState = await helper.createSampleGameState()
        let actualOldCapacity = gameState.player.carryingCapacity
        let incorrectOldCapacity = actualOldCapacity - 10 // Incorrect
        let newCapacity = actualOldCapacity + 50

        let change = StateChange(
            entityId: .player,
            propertyKey: .playerCapacity,
            oldValue: .int(incorrectOldCapacity),
            newValue: .int(newCapacity)
        )

        // When & Then
        var thrownError: Error? = nil
        do {
            try gameState.apply(change)
            Issue.record("Expected apply to throw an error, but it succeeded.")
        } catch {
            thrownError = error
        }
        #expect(thrownError != nil, "An error should have been thrown.")
        if let actionError = thrownError as? ActionError {
            // Check only the error case, not the associated message
            if case .internalEngineError = actionError { } else {
                Issue.record("Expected .internalEngineError case, got \(actionError)")
            }
        } else {
            Issue.record("Thrown error was not an ActionError: \(thrownError?.localizedDescription ?? "nil")")
        }

        // Verify state unchanged
        #expect(gameState.player.carryingCapacity == actualOldCapacity)
        #expect(gameState.changeHistory.isEmpty)
    }

    // MARK: - Player Location Tests

    @Test("Apply valid player location change")
    func testApplyValidPlayerLocationChange() async throws {
        // Given
        var gameState = await helper.createSampleGameState()
        let initialLocation = gameState.player.currentLocationID
        let newLocation = GameStateTests.locNorth // Should exist in sample state
        #expect(gameState.locations[newLocation] != nil, "Target location must exist")

        let change = StateChange(
            entityId: .player,
            propertyKey: .playerLocation,
            oldValue: .locationID(initialLocation),
            newValue: .locationID(newLocation)
        )

        // When
        try gameState.apply(change)

        // Then
        #expect(gameState.player.currentLocationID == newLocation)
        #expect(gameState.changeHistory.last == change)
    }

    @Test("Apply player location change with invalid oldValue")
    func testApplyInvalidPlayerLocationChangeOldValue() async throws {
        // Given
        var gameState = await helper.createSampleGameState()
        let actualOldLocation = gameState.player.currentLocationID
        let incorrectOldLocation: LocationID = "attic" // Incorrect
        let newLocation = GameStateTests.locNorth

        let change = StateChange(
            entityId: .player,
            propertyKey: .playerLocation,
            oldValue: .locationID(incorrectOldLocation),
            newValue: .locationID(newLocation)
        )

        // When & Then
        var thrownError: Error? = nil
        do {
            try gameState.apply(change)
            Issue.record("Expected apply to throw an error, but it succeeded.")
        } catch {
            thrownError = error
        }
        #expect(thrownError != nil, "An error should have been thrown.")
        if let actionError = thrownError as? ActionError {
            // Check only the error case, not the associated message
            if case .internalEngineError = actionError { } else {
                Issue.record("Expected .internalEngineError case, got \(actionError)")
            }
        } else {
            Issue.record("Thrown error was not an ActionError: \(thrownError?.localizedDescription ?? "nil")")
        }

        // Verify state unchanged
        #expect(gameState.player.currentLocationID == actualOldLocation)
        #expect(gameState.changeHistory.isEmpty)
    }

    @Test("Apply player location change to invalid location ID")
    func testApplyPlayerLocationChangeToInvalidID() async throws {
        // Given
        var gameState = await helper.createSampleGameState()
        let initialLocation = gameState.player.currentLocationID
        let invalidNewLocation: LocationID = "nonExistentRoom"
        #expect(gameState.locations[invalidNewLocation] == nil, "Target location must not exist")

        let change = StateChange(
            entityId: .player,
            propertyKey: .playerLocation,
            oldValue: .locationID(initialLocation),
            newValue: .locationID(invalidNewLocation)
        )

        // When & Then
        var thrownError: Error? = nil
        do {
            try gameState.apply(change)
            Issue.record("Expected apply to throw an error, but it succeeded.")
        } catch {
            thrownError = error
        }
        #expect(thrownError != nil, "An error should have been thrown.")
        if let actionError = thrownError as? ActionError {
            // Check only the error case, not the associated message
            if case .internalEngineError = actionError { } else {
                Issue.record("Expected .internalEngineError case, got \(actionError)")
            }
        } else {
            Issue.record("Thrown error was not an ActionError: \(thrownError?.localizedDescription ?? "nil")")
        }

        // Verify state unchanged
        #expect(gameState.player.currentLocationID == initialLocation)
        #expect(gameState.changeHistory.isEmpty)
    }

    // MARK: - Global Flag Tests

    @Test("Apply valid global flag change (add new)")
    func testApplyValidGlobalFlagChangeAddNew() async throws {
        // Given
        var gameState = await helper.createSampleGameState()
        let flagKey = "newFlag"
        #expect(gameState.flags[flagKey] == nil)

        let change = StateChange(
            entityId: .global,
            propertyKey: .globalFlag(key: flagKey),
            oldValue: nil, // Expecting nil for a new flag
            newValue: .bool(true)
        )

        // When
        try gameState.apply(change)

        // Then
        #expect(gameState.flags[flagKey] == true)
        #expect(gameState.changeHistory.last == change)
    }

    @Test("Apply valid global flag change (modify existing)")
    func testApplyValidGlobalFlagChangeModify() async throws {
        // Given
        var gameState = await helper.createSampleGameState()
        let flagKey = "gameStarted" // Exists in sample state
        let initialValue = gameState.flags[flagKey]
        #expect(initialValue == true)

        let change = StateChange(
            entityId: .global,
            propertyKey: .globalFlag(key: flagKey),
            oldValue: .bool(initialValue!), // Correct old value
            newValue: .bool(false)
        )

        // When
        try gameState.apply(change)

        // Then
        #expect(gameState.flags[flagKey] == false)
        #expect(gameState.changeHistory.last == change)
    }

    @Test("Apply global flag change with invalid oldValue (existing flag)")
    func testApplyInvalidGlobalFlagChangeOldValueExisting() async throws {
        // Given
        var gameState = await helper.createSampleGameState()
        let flagKey = "gameStarted"
        let actualOldValue = gameState.flags[flagKey]
        #expect(actualOldValue == true)
        let incorrectOldValue = false // Incorrect

        let change = StateChange(
            entityId: .global,
            propertyKey: .globalFlag(key: flagKey),
            oldValue: .bool(incorrectOldValue),
            newValue: .bool(false)
        )

        // When & Then
        var thrownError: Error? = nil
        do {
            try gameState.apply(change)
            Issue.record("Expected apply to throw an error, but it succeeded.")
        } catch {
            thrownError = error
        }
        #expect(thrownError != nil, "An error should have been thrown.")
        if let actionError = thrownError as? ActionError {
            // Check only the error case, not the associated message
            if case .internalEngineError = actionError { } else {
                Issue.record("Expected .internalEngineError case, got \(actionError)")
            }
        } else {
            Issue.record("Thrown error was not an ActionError: \(thrownError?.localizedDescription ?? "nil")")
        }

        // Verify state unchanged
        #expect(gameState.flags[flagKey] == actualOldValue)
        #expect(gameState.changeHistory.isEmpty)
    }

    @Test("Apply global flag change with invalid oldValue (new flag)")
    func testApplyInvalidGlobalFlagChangeOldValueNew() async throws {
        // Given
        var gameState = await helper.createSampleGameState()
        let flagKey = "newFlag"
        #expect(gameState.flags[flagKey] == nil)
        let incorrectOldValue = true // Should expect nil

        let change = StateChange(
            entityId: .global,
            propertyKey: .globalFlag(key: flagKey),
            oldValue: .bool(incorrectOldValue),
            newValue: .bool(true)
        )

        // When & Then
        var thrownError: Error? = nil
        do {
            try gameState.apply(change)
            Issue.record("Expected apply to throw an error, but it succeeded.")
        } catch {
            thrownError = error
        }
        #expect(thrownError != nil, "An error should have been thrown.")
        if let actionError = thrownError as? ActionError {
            // Check only the error case, not the associated message
            if case .internalEngineError = actionError { } else {
                Issue.record("Expected .internalEngineError case, got \(actionError)")
            }
        } else {
            Issue.record("Thrown error was not an ActionError: \(thrownError?.localizedDescription ?? "nil")")
        }

        // Verify state unchanged
        #expect(gameState.flags[flagKey] == nil)
        #expect(gameState.changeHistory.isEmpty)
    }

    // MARK: - Pronoun Reference Tests

    @Test("Apply valid pronoun reference change (modify existing)")
    func testApplyValidPronounReferenceChangeModify() async throws {
        // Given
        var gameState = await helper.createSampleGameState()
        let pronoun = "it"
        let initialValue = gameState.pronouns[pronoun]
        #expect(initialValue == [GameStateTests.itemMailbox])
        let newValue: Set<ItemID> = [GameStateTests.itemLantern]

        let change = StateChange(
            entityId: .global,
            propertyKey: .pronounReference(pronoun: pronoun),
            oldValue: .itemIDSet(initialValue!), // Correct old value
            newValue: .itemIDSet(newValue)
        )

        // When
        try gameState.apply(change)

        // Then
        #expect(gameState.pronouns[pronoun] == newValue)
        #expect(gameState.changeHistory.last == change)
    }

    @Test("Apply valid pronoun reference change (add new)")
    func testApplyValidPronounReferenceChangeAdd() async throws {
        // Given
        var gameState = await helper.createSampleGameState()
        let pronoun = "them"
        #expect(gameState.pronouns[pronoun] == nil)
        let newValue: Set<ItemID> = [GameStateTests.itemSword, GameStateTests.itemLeaflet]

        let change = StateChange(
            entityId: .global,
            propertyKey: .pronounReference(pronoun: pronoun),
            oldValue: nil, // Expecting nil
            newValue: .itemIDSet(newValue)
        )

        // When
        try gameState.apply(change)

        // Then
        #expect(gameState.pronouns[pronoun] == newValue)
        #expect(gameState.changeHistory.last == change)
    }

    @Test("Apply pronoun reference change with invalid oldValue")
    func testApplyInvalidPronounReferenceChangeOldValue() async throws {
        // Given
        var gameState = await helper.createSampleGameState()
        let pronoun = "it"
        let actualOldValue = gameState.pronouns[pronoun]
        #expect(actualOldValue == [GameStateTests.itemMailbox])
        let incorrectOldValue: Set<ItemID> = [GameStateTests.itemSword] // Incorrect
        let newValue: Set<ItemID> = [GameStateTests.itemLantern]

        let change = StateChange(
            entityId: .global,
            propertyKey: .pronounReference(pronoun: pronoun),
            oldValue: .itemIDSet(incorrectOldValue),
            newValue: .itemIDSet(newValue)
        )

        // When & Then
        var thrownError: Error? = nil
        do {
            try gameState.apply(change)
            Issue.record("Expected apply to throw an error, but it succeeded.")
        } catch {
            thrownError = error
        }
        #expect(thrownError != nil, "An error should have been thrown.")
        if let actionError = thrownError as? ActionError {
            // Check only the error case, not the associated message
            if case .internalEngineError = actionError { } else {
                Issue.record("Expected .internalEngineError case, got \(actionError)")
            }
        } else {
            Issue.record("Thrown error was not an ActionError: \(thrownError?.localizedDescription ?? "nil")")
        }

        // Verify state unchanged
        #expect(gameState.pronouns[pronoun] == actualOldValue)
        #expect(gameState.changeHistory.isEmpty)
    }

    // MARK: - Fuse Tests

    @Test("Apply valid addActiveFuse")
    func testApplyValidAddActiveFuse() async throws {
        // Given
        var gameState = await helper.createSampleGameState()
        let fuseID: FuseID = "bombFuse"
        let initialTurns = 10
        #expect(gameState.activeFuses[fuseID] == nil)

        let change = StateChange(
            entityId: .global,
            propertyKey: .addActiveFuse(fuseId: fuseID, initialTurns: initialTurns),
            // No oldValue for add
            newValue: .int(initialTurns)
        )

        // When
        try gameState.apply(change)

        // Then
        #expect(gameState.activeFuses[fuseID] == initialTurns)
        #expect(gameState.changeHistory.last == change)
    }

    @Test("Apply addActiveFuse (overwrite existing)")
    func testApplyAddActiveFuseOverwrite() async throws {
        // Given
        var gameState = await helper.createSampleGameState()
        let fuseID: FuseID = "bombFuse"
        let initialTurns = 5
        // Pre-populate using apply
        let setupChange = StateChange(
            entityId: .global,
            propertyKey: .addActiveFuse(fuseId: fuseID, initialTurns: initialTurns),
            newValue: .int(initialTurns)
        )
        try gameState.apply(setupChange)
        #expect(gameState.activeFuses[fuseID] == initialTurns)

        let newInitialTurns = 20 // New turns value for the 'add'
        let change = StateChange(
            entityId: .global,
            propertyKey: .addActiveFuse(fuseId: fuseID, initialTurns: newInitialTurns),
            // No oldValue for add (even when overwriting)
            newValue: .int(newInitialTurns)
        )

        // When
        try gameState.apply(change)

        // Then
        #expect(gameState.activeFuses[fuseID] == newInitialTurns, "Fuse turns should be overwritten")
        #expect(gameState.changeHistory.last == change)
    }

    @Test("Apply valid removeActiveFuse")
    func testApplyValidRemoveActiveFuse() async throws {
        // Given
        var gameState = await helper.createSampleGameState()
        let fuseID: FuseID = "bombFuse"
        let initialTurns = 5
        // Pre-populate using apply
        let setupChange = StateChange(
            entityId: .global,
            propertyKey: .addActiveFuse(fuseId: fuseID, initialTurns: initialTurns),
            newValue: .int(initialTurns)
        )
        try gameState.apply(setupChange)
        #expect(gameState.activeFuses[fuseID] == initialTurns)

        let change = StateChange(
            entityId: .global,
            propertyKey: .removeActiveFuse(fuseId: fuseID),
            oldValue: .int(initialTurns), // Expecting the current value
            newValue: .int(0) // Per convention for remove
        )

        // When
        try gameState.apply(change)

        // Then
        #expect(gameState.activeFuses[fuseID] == nil, "Fuse should be removed")
        #expect(gameState.changeHistory.last == change)
    }

    @Test("Apply removeActiveFuse with invalid oldValue")
    func testApplyInvalidRemoveActiveFuseOldValue() async throws {
        // Given
        var gameState = await helper.createSampleGameState()
        let fuseID: FuseID = "bombFuse"
        let actualTurns = 5
        // Pre-populate using apply
        let setupChange = StateChange(
            entityId: .global,
            propertyKey: .addActiveFuse(fuseId: fuseID, initialTurns: actualTurns),
            newValue: .int(actualTurns)
        )
        try gameState.apply(setupChange)
        let incorrectOldTurns = 10 // Incorrect

        let change = StateChange(
            entityId: .global,
            propertyKey: .removeActiveFuse(fuseId: fuseID),
            oldValue: .int(incorrectOldTurns),
            newValue: .int(0)
        )

        // When & Then
        var thrownError: Error? = nil
        do {
            try gameState.apply(change)
            Issue.record("Expected apply to throw an error, but it succeeded.")
        } catch {
            thrownError = error
        }
        #expect(thrownError != nil, "An error should have been thrown.")
        if let actionError = thrownError as? ActionError {
            // Check only the error case, not the associated message
            if case .internalEngineError = actionError { } else {
                Issue.record("Expected .internalEngineError case, got \(actionError)")
            }
        } else {
            Issue.record("Thrown error was not an ActionError: \(thrownError?.localizedDescription ?? "nil")")
        }

        // Verify state unchanged
        #expect(gameState.activeFuses[fuseID] == actualTurns)
        // History check removed as setup change is present
    }

    @Test("Apply removeActiveFuse for non-existent fuse (with nil oldValue)")
    func testApplyRemoveNonExistentFuseNilOldValue() async throws {
        // Given
        var gameState = await helper.createSampleGameState()
        let fuseID: FuseID = "nonExistentFuse"
        #expect(gameState.activeFuses[fuseID] == nil)

        let change = StateChange(
            entityId: .global,
            propertyKey: .removeActiveFuse(fuseId: fuseID),
            oldValue: nil, // Correctly expecting nil
            newValue: .int(0)
        )

        // When
        // apply should succeed idempotently
        try gameState.apply(change)

        // Then
        #expect(gameState.activeFuses[fuseID] == nil, "Fuse should remain non-existent")
        #expect(gameState.changeHistory.last == change, "Change should still be recorded")
    }

    @Test("Apply removeActiveFuse for non-existent fuse (no oldValue provided)")
    func testApplyRemoveNonExistentFuseNoOldValue() async throws {
        // Given
        var gameState = await helper.createSampleGameState()
        let fuseID: FuseID = "nonExistentFuse"
        #expect(gameState.activeFuses[fuseID] == nil)

        let change = StateChange(
            entityId: .global,
            propertyKey: .removeActiveFuse(fuseId: fuseID),
            // No oldValue provided
            newValue: .int(0)
        )

        // When & Then
        // apply should throw because it tries to remove something not there
        // without confirmation via oldValue that it shouldn't be there.
        var thrownError: Error? = nil
        do {
            try gameState.apply(change)
            Issue.record("Expected apply to throw an error, but it succeeded.")
        } catch {
            thrownError = error
        }
        #expect(thrownError != nil, "An error should have been thrown.")
        if let actionError = thrownError as? ActionError {
            // Check only the error case, not the associated message
            if case .internalEngineError = actionError { } else {
                Issue.record("Expected .internalEngineError case, got \(actionError)")
            }
        } else {
            Issue.record("Thrown error was not an ActionError: \(thrownError?.localizedDescription ?? "nil")")
        }

        // Verify state unchanged
        #expect(gameState.activeFuses[fuseID] == nil)
        #expect(gameState.changeHistory.isEmpty)
    }

    @Test("Apply valid updateFuseTurns")
    func testApplyValidUpdateFuseTurns() async throws {
        // Given
        var gameState = await helper.createSampleGameState()
        let fuseID: FuseID = "bombFuse"
        let initialTurns = 10
        // Pre-populate using apply
        let setupChange = StateChange(
            entityId: .global,
            propertyKey: .addActiveFuse(fuseId: fuseID, initialTurns: initialTurns),
            newValue: .int(initialTurns)
        )
        try gameState.apply(setupChange)
        let newTurns = initialTurns - 1

        let change = StateChange(
            entityId: .global,
            propertyKey: .updateFuseTurns(fuseId: fuseID),
            oldValue: .int(initialTurns),
            newValue: .int(newTurns)
        )

        // When
        try gameState.apply(change)

        // Then
        #expect(gameState.activeFuses[fuseID] == newTurns)
        #expect(gameState.changeHistory.last == change)
    }

    @Test("Apply updateFuseTurns with invalid oldValue")
    func testApplyInvalidUpdateFuseTurnsOldValue() async throws {
        // Given
        var gameState = await helper.createSampleGameState()
        let fuseID: FuseID = "bombFuse"
        let actualTurns = 10
        // Pre-populate using apply
        let setupChange = StateChange(
            entityId: .global,
            propertyKey: .addActiveFuse(fuseId: fuseID, initialTurns: actualTurns),
            newValue: .int(actualTurns)
        )
        try gameState.apply(setupChange)
        let incorrectOldTurns = 5 // Incorrect
        let newTurns = actualTurns - 1

        let change = StateChange(
            entityId: .global,
            propertyKey: .updateFuseTurns(fuseId: fuseID),
            oldValue: .int(incorrectOldTurns),
            newValue: .int(newTurns)
        )

        // When & Then
        var thrownError: Error? = nil
        do {
            try gameState.apply(change)
            Issue.record("Expected apply to throw an error, but it succeeded.")
        } catch {
            thrownError = error
        }
        #expect(thrownError != nil, "An error should have been thrown.")
        if let actionError = thrownError as? ActionError {
            // Check only the error case, not the associated message
            if case .internalEngineError = actionError { } else {
                Issue.record("Expected .internalEngineError case, got \(actionError)")
            }
        } else {
            Issue.record("Thrown error was not an ActionError: \(thrownError?.localizedDescription ?? "nil")")
        }

        // Verify state unchanged
        #expect(gameState.activeFuses[fuseID] == actualTurns)
        // History check removed as setup change is present
    }

    @Test("Apply updateFuseTurns for non-existent fuse")
    func testApplyUpdateNonExistentFuse() async throws {
        // Given
        var gameState = await helper.createSampleGameState()
        let fuseID: FuseID = "nonExistentFuse"
        #expect(gameState.activeFuses[fuseID] == nil)
        let newTurns = 5

        let change = StateChange(
            entityId: .global,
            propertyKey: .updateFuseTurns(fuseId: fuseID),
            oldValue: nil, // Expecting nil
            newValue: .int(newTurns)
        )

        // When & Then
        // Should fail because the fuse doesn't exist to update
        var thrownError: Error? = nil
        do {
            try gameState.apply(change)
            Issue.record("Expected apply to throw an error, but it succeeded.")
        } catch {
            thrownError = error
        }
        #expect(thrownError != nil, "An error should have been thrown.")
        if let actionError = thrownError as? ActionError {
            // Check only the error case, not the associated message
            if case .internalEngineError = actionError { } else {
                Issue.record("Expected .internalEngineError case, got \(actionError)")
            }
        } else {
            Issue.record("Thrown error was not an ActionError: \(thrownError?.localizedDescription ?? "nil")")
        }

        // Verify state unchanged
        #expect(gameState.activeFuses[fuseID] == nil)
        #expect(gameState.changeHistory.isEmpty)
    }

    // MARK: - Daemon Tests

    @Test("Apply valid addActiveDaemon")
    func testApplyValidAddActiveDaemon() async throws {
        // Given
        var gameState = await helper.createSampleGameState()
        let daemonID: DaemonID = "clockDaemon"
        #expect(gameState.activeDaemons.contains(daemonID) == false)

        let change = StateChange(
            entityId: .global,
            propertyKey: .addActiveDaemon(daemonId: daemonID),
            oldValue: .bool(false), // Explicitly stating it wasn't present
            newValue: .bool(true) // Representing the state of being active
        )

        // When
        try gameState.apply(change)

        // Then
        #expect(gameState.activeDaemons.contains(daemonID) == true)
        #expect(gameState.changeHistory.last == change)
    }

    @Test("Apply addActiveDaemon (already active)")
    func testApplyAddActiveDaemonAlreadyActive() async throws {
        // Given
        var gameState = await helper.createSampleGameState()
        let daemonID: DaemonID = "clockDaemon"
        // Pre-populate using apply
        let setupChange = StateChange(
            entityId: .global,
            propertyKey: .addActiveDaemon(daemonId: daemonID),
            oldValue: .bool(false),
            newValue: .bool(true)
        )
        try gameState.apply(setupChange)
        #expect(gameState.activeDaemons.contains(daemonID) == true)

        let change = StateChange(
            entityId: .global,
            propertyKey: .addActiveDaemon(daemonId: daemonID),
            oldValue: .bool(true), // Correctly state it was already active
            newValue: .bool(true)
        )

        // When
        try gameState.apply(change)

        // Then
        #expect(gameState.activeDaemons.contains(daemonID) == true, "Daemon should remain active")
        #expect(gameState.changeHistory.last == change)
    }

    @Test("Apply addActiveDaemon with invalid oldValue (expecting false, got true)")
    func testApplyInvalidAddActiveDaemonOldValueExpectingFalse() async throws {
        // Given
        var gameState = await helper.createSampleGameState()
        let daemonID: DaemonID = "clockDaemon"
        // Pre-populate using apply
        let setupChange = StateChange(
            entityId: .global,
            propertyKey: .addActiveDaemon(daemonId: daemonID),
            oldValue: .bool(false),
            newValue: .bool(true)
        )
        try gameState.apply(setupChange)
        #expect(gameState.activeDaemons.contains(daemonID) == true)

        let change = StateChange(
            entityId: .global,
            propertyKey: .addActiveDaemon(daemonId: daemonID),
            oldValue: .bool(false), // Incorrectly expecting it to be inactive
            newValue: .bool(true)
        )

        // When & Then
        var thrownError: Error? = nil
        do {
            try gameState.apply(change)
            Issue.record("Expected apply to throw an error, but it succeeded.")
        } catch {
            thrownError = error
        }
        #expect(thrownError != nil, "An error should have been thrown.")
        if let actionError = thrownError as? ActionError {
            // Check only the error case, not the associated message
            if case .internalEngineError = actionError { } else {
                Issue.record("Expected .internalEngineError case, got \(actionError)")
            }
        } else {
            Issue.record("Thrown error was not an ActionError: \(thrownError?.localizedDescription ?? "nil")")
        }

        // Verify state unchanged
        #expect(gameState.activeDaemons.contains(daemonID) == true)
        // History check removed as setup change is present
    }

    @Test("Apply addActiveDaemon with invalid oldValue (expecting true, got false)")
    func testApplyInvalidAddActiveDaemonOldValueExpectingTrue() async throws {
        // Given
        var gameState = await helper.createSampleGameState()
        let daemonID: DaemonID = "clockDaemon"
        #expect(gameState.activeDaemons.contains(daemonID) == false) // Daemon is inactive

        let change = StateChange(
            entityId: .global,
            propertyKey: .addActiveDaemon(daemonId: daemonID),
            oldValue: .bool(true), // Incorrectly expecting it to be active
            newValue: .bool(true)
        )

        // When & Then
        var thrownError: Error? = nil
        do {
            try gameState.apply(change)
            Issue.record("Expected apply to throw an error, but it succeeded.")
        } catch {
            thrownError = error
        }
        #expect(thrownError != nil, "An error should have been thrown.")
        if let actionError = thrownError as? ActionError {
            // Check only the error case, not the associated message
            if case .internalEngineError = actionError { } else {
                Issue.record("Expected .internalEngineError case, got \(actionError)")
            }
        } else {
            Issue.record("Thrown error was not an ActionError: \(thrownError?.localizedDescription ?? "nil")")
        }

        // Verify state unchanged
        #expect(gameState.activeDaemons.contains(daemonID) == false)
        #expect(gameState.changeHistory.isEmpty)
    }

    @Test("Apply valid removeActiveDaemon")
    func testApplyValidRemoveActiveDaemon() async throws {
        // Given
        var gameState = await helper.createSampleGameState()
        let daemonID: DaemonID = "clockDaemon"
        // Pre-populate using apply
        let setupChange = StateChange(
            entityId: .global,
            propertyKey: .addActiveDaemon(daemonId: daemonID),
            oldValue: .bool(false),
            newValue: .bool(true)
        )
        try gameState.apply(setupChange)
        #expect(gameState.activeDaemons.contains(daemonID) == true)

        let change = StateChange(
            entityId: .global,
            propertyKey: .removeActiveDaemon(daemonId: daemonID),
            oldValue: .bool(true), // Expecting it was active
            newValue: .bool(false) // Representing inactive state
        )

        // When
        try gameState.apply(change)

        // Then
        #expect(gameState.activeDaemons.contains(daemonID) == false, "Daemon should be removed")
        #expect(gameState.changeHistory.last == change)
    }

    @Test("Apply removeActiveDaemon (already inactive)")
    func testApplyRemoveActiveDaemonAlreadyInactive() async throws {
        // Given
        var gameState = await helper.createSampleGameState()
        let daemonID: DaemonID = "clockDaemon"
        #expect(gameState.activeDaemons.contains(daemonID) == false)

        let change = StateChange(
            entityId: .global,
            propertyKey: .removeActiveDaemon(daemonId: daemonID),
            oldValue: .bool(false), // Correctly state it was inactive
            newValue: .bool(false)
        )

        // When
        try gameState.apply(change)

        // Then
        #expect(gameState.activeDaemons.contains(daemonID) == false, "Daemon should remain inactive")
        #expect(gameState.changeHistory.last == change)
    }

    @Test("Apply removeActiveDaemon with invalid oldValue (expecting true, got false)")
    func testApplyInvalidRemoveActiveDaemonOldValueExpectingTrue() async throws {
        // Given
        var gameState = await helper.createSampleGameState()
        let daemonID: DaemonID = "clockDaemon"
        #expect(gameState.activeDaemons.contains(daemonID) == false) // Daemon is inactive

        let change = StateChange(
            entityId: .global,
            propertyKey: .removeActiveDaemon(daemonId: daemonID),
            oldValue: .bool(true), // Incorrectly expecting it to be active
            newValue: .bool(false)
        )

        // When & Then
        var thrownError: Error? = nil
        do {
            try gameState.apply(change)
            Issue.record("Expected apply to throw an error, but it succeeded.")
        } catch {
            thrownError = error
        }
        #expect(thrownError != nil, "An error should have been thrown.")
        if let actionError = thrownError as? ActionError {
            // Check only the error case, not the associated message
            if case .internalEngineError = actionError { } else {
                Issue.record("Expected .internalEngineError case, got \(actionError)")
            }
        } else {
            Issue.record("Thrown error was not an ActionError: \(thrownError?.localizedDescription ?? "nil")")
        }

        // Verify state unchanged
        #expect(gameState.activeDaemons.contains(daemonID) == false)
        #expect(gameState.changeHistory.isEmpty)
    }

    @Test("Apply removeActiveDaemon with invalid oldValue (expecting false, got true)")
    func testApplyInvalidRemoveActiveDaemonOldValueExpectingFalse() async throws {
        // Given
        var gameState = await helper.createSampleGameState()
        let daemonID: DaemonID = "clockDaemon"
        // Pre-populate using apply
        let setupChange = StateChange(
            entityId: .global,
            propertyKey: .addActiveDaemon(daemonId: daemonID),
            oldValue: .bool(false),
            newValue: .bool(true)
        )
        try gameState.apply(setupChange)
        #expect(gameState.activeDaemons.contains(daemonID) == true)

        let change = StateChange(
            entityId: .global,
            propertyKey: .removeActiveDaemon(daemonId: daemonID),
            oldValue: .bool(false), // Incorrectly expecting it to be inactive
            newValue: .bool(false)
        )

        // When & Then
        var thrownError: Error? = nil
        do {
            try gameState.apply(change)
            Issue.record("Expected apply to throw an error, but it succeeded.")
        } catch {
            thrownError = error
        }
        #expect(thrownError != nil, "An error should have been thrown.")
        if let actionError = thrownError as? ActionError {
            // Check only the error case, not the associated message
            if case .internalEngineError = actionError { } else {
                Issue.record("Expected .internalEngineError case, got \(actionError)")
            }
        } else {
            Issue.record("Thrown error was not an ActionError: \(thrownError?.localizedDescription ?? "nil")")
        }

        // Verify state unchanged
        #expect(gameState.activeDaemons.contains(daemonID) == true)
        // History check removed as setup change is present
    }

    // MARK: - Game Specific State Tests

    @Test("Apply valid gameSpecificState change (add new Bool)")
    func testApplyValidGameSpecificStateChangeAddBool() async throws {
        // Given
        var gameState = await helper.createSampleGameState()
        let key = "puzzleSolved"
        #expect(gameState.gameSpecificState[key] == nil)
        let newValue = StateValue.bool(true)

        let change = StateChange(
            entityId: .global,
            propertyKey: .gameSpecificState(key: key),
            // No oldValue validation for gameSpecificState currently
            newValue: newValue
        )

        // When
        try gameState.apply(change)

        // Then
        #expect(gameState.gameSpecificState[key]?.value as? Bool == true)
        #expect(gameState.changeHistory.last == change)
    }

    @Test("Apply valid gameSpecificState change (modify Int)")
    func testApplyValidGameSpecificStateChangeModifyInt() async throws {
        // Given
        var gameState = await helper.createSampleGameState()
        let key = "counter"
        // Pre-populate using apply
        let setupChange = StateChange(
            entityId: .global,
            propertyKey: .gameSpecificState(key: key),
            newValue: .int(5)
        )
        try gameState.apply(setupChange)
        #expect(gameState.gameSpecificState[key]?.value as? Int == 5)
        let newValue = StateValue.int(10)

        let change = StateChange(
            entityId: .global,
            propertyKey: .gameSpecificState(key: key),
            newValue: newValue
        )

        // When
        try gameState.apply(change)

        // Then
        #expect(gameState.gameSpecificState[key]?.value as? Int == 10)
        #expect(gameState.changeHistory.last == change)
    }

    @Test("Apply valid gameSpecificState change (set String)")
    func testApplyValidGameSpecificStateChangeSetString() async throws {
        // Given
        var gameState = await helper.createSampleGameState()
        let key = "playerName"
        let newValue = StateValue.string("Aisq")

        let change = StateChange(
            entityId: .global,
            propertyKey: .gameSpecificState(key: key),
            newValue: newValue
        )

        // When
        try gameState.apply(change)

        // Then
        #expect(gameState.gameSpecificState[key]?.value as? String == "Aisq")
        #expect(gameState.changeHistory.last == change)
    }

    @Test("Apply gameSpecificState change with unsupported type")
    func testApplyGameSpecificStateUnsupportedType() async throws {
        // Given
        var gameState = await helper.createSampleGameState()
        let key = "complexData"
        // Create a StateValue type that isn't directly supported
        let unsupportedValue = StateValue.itemIDSet(["item1", "item2"])

        let change = StateChange(
            entityId: .global,
            propertyKey: .gameSpecificState(key: key),
            newValue: unsupportedValue
        )

        // When & Then
        var thrownError: Error? = nil
        do {
            try gameState.apply(change)
            Issue.record("Expected apply to throw an error, but it succeeded.")
        } catch {
            thrownError = error
        }
        #expect(thrownError != nil, "An error should have been thrown.")
        if let actionError = thrownError as? ActionError {
            // Check only the error case, not the associated message
            if case .internalEngineError = actionError { } else {
                Issue.record("Expected .internalEngineError case, got \(actionError)")
            }
        } else {
            Issue.record("Thrown error was not an ActionError: \(thrownError?.localizedDescription ?? "nil")")
        }

        // Verify state unchanged
        #expect(gameState.gameSpecificState[key] == nil)
        #expect(gameState.changeHistory.isEmpty)
    }
}
