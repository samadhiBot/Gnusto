import CustomDump
import Foundation
import Testing

@testable import GnustoEngine

@Suite("GameState.apply Tests")
struct GameStateApplyTests {
    // Use the helper from the main struct
    let helper = GameStateTests()

    // MARK: - Item Properties Tests

    @Test("Apply valid item property change")
    func testApplyValidItemPropertyChange() async throws {
        // Given
        var gameState = await helper.createSampleGameState()
        let itemID = GameStateTests.itemLantern
        guard let initialItem = gameState.items[itemID] else {
            Issue.record("Test setup failure: Lantern item not found.")
            return
        }
        let attributeID: AttributeID = .isOn // Assume AttributeID.isOn exists
        let oldAttributeValue = initialItem.attributes[attributeID]
        let newAttributeValue: StateValue = true

        let change = StateChange(
            entityID: .item(itemID),
            attributeKey: .itemAttribute(attributeID), // Use new key
            oldValue: oldAttributeValue, // Use actual or .absent
            newValue: newAttributeValue // Use direct StateValue
        )

        // When
        try gameState.apply(change)

        // Then
        let finalItem = gameState.items[itemID]
        #expect(finalItem?.attributes[attributeID] == newAttributeValue, "Item attribute should be updated")

        #expect(gameState.changeHistory.count == 1, "Change history should contain one entry")
        #expect(gameState.changeHistory.first == change, "Change history should contain the applied change")
    }

    @Test("Apply item property change with invalid oldValue")
    func testApplyInvalidItemPropertyChangeOldValue() async throws {
        // Given
        var gameState = await helper.createSampleGameState()
        let itemID = GameStateTests.itemLantern
        guard let initialItem = gameState.items[itemID] else {
            Issue.record("Test setup failure: Lantern item not found.")
            return
        }
        let attributeID: AttributeID = .isOn
        let actualOldValue = initialItem.attributes[attributeID]
        // Ensure incorrectOldValue is different from actualOldValue
        let incorrectOldValue: StateValue = (actualOldValue == true) ? false : true
        let newValue: StateValue = true

        let change = StateChange(
            entityID: .item(itemID),
            attributeKey: .itemAttribute(attributeID), // Use new key
            oldValue: incorrectOldValue, // Use incorrect old value
            newValue: newValue // Use direct StateValue
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
            if case .stateValidationFailed = actionError { } else {
                Issue.record("Expected .stateValidationFailed case, got \(actionError)")
            }
        } else {
            Issue.record("Thrown error was not an ActionError: \(thrownError?.localizedDescription ?? "nil")")
        }

        // Verify state was not changed
        let finalItem = gameState.items[itemID]
        #expect(
            finalItem?.attributes[attributeID] == actualOldValue,
            "Item attribute should not be updated on error"
        )
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
            entityID: .item(itemToMove),
            attributeKey: .itemParent,
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
        let inventoryItemsAfterMove = gameState.items.values.filter { $0.parent == ParentEntity.player }.map(\.id)
        #expect(inventoryItemsAfterMove.contains(itemToMove), "Item should now be in inventory")
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
            entityID: .item(itemToMove),
            attributeKey: .itemParent,
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
            if case .stateValidationFailed = actionError { } else {
                Issue.record("Expected .stateValidationFailed case, got \(actionError)")
            }
        } else {
            Issue.record("Thrown error was not an ActionError: \(thrownError?.localizedDescription ?? "nil")")
        }

        // Verify state was not changed
        let finalItem = gameState.items[itemToMove]
        #expect(finalItem?.parent == actualOldParent, "Item parent should not be updated on error")
        #expect(gameState.changeHistory.isEmpty, "Change history should be empty on error")
        let inventoryItemsAfterError = gameState.items.values.filter { $0.parent == ParentEntity.player }.map(\.id)
        #expect(inventoryItemsAfterError.contains(itemToMove) == false, "Item should not be in inventory")
    }

    @Test("Apply Item Parent Change - Move to Player")
    func testApplyItemParentPlayer() throws {
        var state = helper.createInitialState()
        let itemID: ItemID = "testItem"
        let change = StateChange(
            entityID: .item(itemID),
            attributeKey: .itemParent,
            oldValue: .parentEntity(.location("startRoom")),
            newValue: .parentEntity(.player)
        )

        try state.apply(change)

        #expect(state.items[itemID]?.parent == .player)
        let inventoryItems = state.items.values.filter { $0.parent == ParentEntity.player }.map(\.id)
        #expect(inventoryItems.contains(itemID))
        #expect(state.changeHistory.last == change)
    }

    @Test("Apply Item Parent Change - Move from Player")
    func testApplyItemParentFromPlayer() throws {
        var state = helper.createInitialState()
        let itemID: ItemID = "testItem"
        // Pre-move item to player
        state.items[itemID]?.attributes[.parentEntity] = .parentEntity(.player) 
        #expect(state.items[itemID]?.parent == .player)
        state.changeHistory = [] // Clear history

        let newLocationID: LocationID = "anotherRoom"
        state.locations[newLocationID] = Location(
            id: newLocationID,
            .name("Another Room"),
            .description("A dark, dark room.")
        ) // Ensure location exists

        let change = StateChange(
            entityID: .item(itemID),
            attributeKey: .itemParent,
            oldValue: .parentEntity(.player),
            newValue: .parentEntity(.location(newLocationID))
        )

        try state.apply(change)

        #expect(state.items[itemID]?.parent == .location(newLocationID))
        let inventoryItems = state.items.values.filter { $0.parent == ParentEntity.player }.map(\.id)
        #expect(!inventoryItems.contains(itemID))
        #expect(state.changeHistory.last == change)
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
            entityID: .item(itemID),
            attributeKey: .itemSize,
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
            entityID: .item(itemID),
            attributeKey: .itemSize,
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
            if case .stateValidationFailed = actionError { } else {
                Issue.record("Expected .stateValidationFailed case, got \(actionError)")
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
            entityID: .item(itemID),
            attributeKey: .itemCapacity,
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
            entityID: .item(itemID),
            attributeKey: .itemCapacity,
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
            if case .stateValidationFailed = actionError { } else {
                Issue.record("Expected .stateValidationFailed case, got \(actionError)")
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
            entityID: .item(itemID),
            attributeKey: .itemName,
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
            entityID: .item(itemID),
            attributeKey: .itemName,
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
            if case .stateValidationFailed = actionError { } else {
                Issue.record("Expected .stateValidationFailed case, got \(actionError)")
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
            entityID: .item(itemID),
            attributeKey: .itemAdjectives,
            oldValue: .stringSet(initialAdjectives),
            newValue: .stringSet(newAdjectives)
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
            entityID: .item(itemID),
            attributeKey: .itemAdjectives,
            oldValue: .stringSet(incorrectOldAdjectives),
            newValue: .stringSet(newAdjectives)
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
            if case .stateValidationFailed = actionError { } else {
                Issue.record("Expected .stateValidationFailed case, got \(actionError)")
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
            entityID: .item(itemID),
            attributeKey: .itemSynonyms,
            oldValue: .stringSet(initialSynonyms),
            newValue: .stringSet(newSynonyms)
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
            entityID: .item(itemID),
            attributeKey: .itemSynonyms,
            oldValue: .stringSet(incorrectOldSynonyms),
            newValue: .stringSet(newSynonyms)
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
            if case .stateValidationFailed = actionError { } else {
                Issue.record("Expected .stateValidationFailed case, got \(actionError)")
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
        guard let initialLocation = gameState.locations[locationID] else {
            Issue.record("Test setup failure: WOH location not found.")
            return
        }
        // Let's change the .isLit attribute (assuming it exists)
        let attributeID: AttributeID = .isLit
        let oldAttributeValue = initialLocation.attributes[attributeID]
        let newAttributeValue: StateValue = true

        let change = StateChange(
            entityID: .location(locationID),
            attributeKey: .locationAttribute(attributeID), // Use new key
            oldValue: oldAttributeValue,
            newValue: newAttributeValue
        )

        // When
        try gameState.apply(change)

        // Then
        #expect(gameState.locations[locationID]?.attributes[attributeID] == newAttributeValue)
        #expect(gameState.changeHistory.last == change)
    }

    @Test("Apply location properties change with invalid oldValue")
    func testApplyInvalidLocationPropertiesChangeOldValue() async throws {
        // Given
        var gameState = await helper.createSampleGameState()
        let locationID = GameStateTests.locWOH
        guard let initialLocation = gameState.locations[locationID] else {
            Issue.record("Test setup failure: WOH location not found.")
            return
        }
        // Let's try to change the .isLit attribute
        let attributeID: AttributeID = .isLit
        let actualOldValue = initialLocation.attributes[attributeID]
        // Ensure incorrectOldValue is different
        let incorrectOldValue: StateValue = (actualOldValue == true) ? false : true
        let newValue: StateValue = true

        let change = StateChange(
            entityID: .location(locationID),
            attributeKey: .locationAttribute(attributeID), // Use new key
            oldValue: incorrectOldValue, // Incorrect old value
            newValue: newValue
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
            if case .stateValidationFailed = actionError { } else {
                Issue.record("Expected .stateValidationFailed case, got \(actionError)")
            }
        } else {
            Issue.record("Thrown error was not an ActionError: \(thrownError?.localizedDescription ?? "nil")")
        }

        // Verify state unchanged
        #expect(gameState.locations[locationID]?.attributes[attributeID] == actualOldValue)
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
            entityID: .location(locationID),
            attributeKey: .locationName,
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
            entityID: .location(locationID),
            attributeKey: .locationName,
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
            if case .stateValidationFailed = actionError { } else {
                Issue.record("Expected .stateValidationFailed case, got \(actionError)")
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
            entityID: .location(locationID),
            attributeKey: .exits,
            oldValue: .exits(initialExits),
            newValue: .exits(newExits)
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
            entityID: .location(locationID),
            attributeKey: .exits,
            oldValue: .exits(incorrectOldExits),
            newValue: .exits(newExits)
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
            if case .stateValidationFailed = actionError { } else {
                Issue.record("Expected .stateValidationFailed case, got \(actionError)")
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
            entityID: .player,
            attributeKey: .playerScore,
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
            entityID: .player,
            attributeKey: .playerScore,
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
            if case .stateValidationFailed = actionError { } else {
                Issue.record("Expected .stateValidationFailed case, got \(actionError)")
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
            entityID: .player,
            attributeKey: .playerMoves,
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
            entityID: .player,
            attributeKey: .playerMoves,
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
            if case .stateValidationFailed = actionError { } else {
                Issue.record("Expected .stateValidationFailed case, got \(actionError)")
            }
        } else {
            Issue.record("Thrown error was not an ActionError: \(thrownError?.localizedDescription ?? "nil")")
        }

        // Verify state unchanged
        #expect(gameState.player.moves == actualOldMoves)
        #expect(gameState.changeHistory.isEmpty)
    }

    // MARK: - Player Inventory Limit Tests (Was Player Capacity)

    @Test("Apply valid player inventory limit change") // Corrected name and key
    func testApplyValidPlayerInventoryLimitChange() async throws { // Corrected name
        // Given
        var gameState = await helper.createSampleGameState()
        let initialCapacity = gameState.player.carryingCapacity
        let newCapacity = initialCapacity + 50

        let change = StateChange(
            entityID: .player,
            attributeKey: .playerInventoryLimit, // Corrected key
            oldValue: .int(initialCapacity),
            newValue: .int(newCapacity)
        )

        // When
        try gameState.apply(change)

        // Then
        #expect(gameState.player.carryingCapacity == newCapacity)
        #expect(gameState.changeHistory.last == change)
    }

    @Test("Apply player inventory limit change with invalid oldValue") // Corrected name and key
    func testApplyInvalidPlayerInventoryLimitChangeOldValue() async throws { // Corrected name
        // Given
        var gameState = await helper.createSampleGameState()
        let actualOldCapacity = gameState.player.carryingCapacity
        let incorrectOldCapacity = actualOldCapacity - 10 // Incorrect
        let newCapacity = actualOldCapacity + 50

        let change = StateChange(
            entityID: .player,
            attributeKey: .playerInventoryLimit, // Corrected key
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
            if case .stateValidationFailed = actionError { } else {
                Issue.record("Expected .stateValidationFailed case, got \(actionError)")
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
            entityID: .player,
            attributeKey: .playerLocation,
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
            entityID: .player,
            attributeKey: .playerLocation,
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
            if case .stateValidationFailed = actionError { } else {
                Issue.record("Expected .stateValidationFailed case, got \(actionError)")
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
            entityID: .player,
            attributeKey: .playerLocation,
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

    @Test("Apply valid flag change (set true)")
    func testApplyValidFlagSet() async throws {
        var gameState = await helper.createSampleGameState()
        let flagID: GlobalID = "testFlag"

        // Initial state check
        #expect(gameState.globalState[flagID] == false)

        let change = StateChange(
            entityID: .global,
            attributeKey: .setFlag(flagID),
            oldValue: nil, // Or false
            newValue: true,
        )

        try gameState.apply(change)

        // Assert final state
        #expect(gameState.globalState[flagID] == true)
        #expect(gameState.changeHistory.count == 1)
        #expect(gameState.changeHistory.first == change)
    }

    @Test("Apply valid flag change (set false)")
    func testApplyValidFlagClear() async throws {
        var gameState = await helper.createSampleGameState()
        let flagID: GlobalID = "testFlagInitiallyTrue"
        gameState.globalState[flagID] = true // Pre-set the flag

        // Initial state check
        #expect(gameState.globalState[flagID] == true)

        let change = StateChange(
            entityID: .global,
            attributeKey: .clearFlag(flagID),
            oldValue: true, // Expecting it was true
            newValue: false
        )

        try gameState.apply(change)

        // Assert final state
        #expect(gameState.globalState[flagID] == false)
        #expect(gameState.changeHistory.count == 1)
        #expect(gameState.changeHistory.first == change)
    }

    @Test("Apply flag change with invalid old value fails")
    func testApplyFlagChangeInvalidOldValue() async throws {
        var gameState = await helper.createSampleGameState()
        let flagID: GlobalID = "testFlag"
        let actualOldValue = gameState.globalState[flagID]
        #expect(actualOldValue == false)

        let change = StateChange(
            entityID: .global,
            attributeKey: .setFlag(flagID), // Attempt to set
            oldValue: true, // INCORRECT: Expecting true, but it's false
            newValue: true,
        )

        var validationErrorThrown = false
        do {
            try gameState.apply(change)
        } catch ActionError.stateValidationFailed(let failedChange, let reportedActualValue) {
            validationErrorThrown = true
            expectNoDifference(failedChange, change)
            #expect(reportedActualValue == false) // actual value was false
        } catch {
            Issue.record("Threw unexpected error type: \(error)")
        }
        #expect(validationErrorThrown)
        // Assert state unchanged
        #expect(gameState.globalState[flagID] == actualOldValue)
        #expect(gameState.changeHistory.isEmpty)
    }

    @Test("Apply flag change with nil old value succeeds")
    func testApplyFlagChangeNilOldValue() async throws {
        var gameState = await helper.createSampleGameState()
        let flagID: GlobalID = "testFlag"
        #expect(gameState.globalState[flagID] == false)

        let change = StateChange(
            entityID: .global,
            attributeKey: .setFlag(flagID),
            oldValue: nil, // No validation expected
            newValue: true,
        )

        try gameState.apply(change)

        // Assert final state
        #expect(gameState.globalState[flagID] == true)
        #expect(gameState.changeHistory.count == 1)
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
            entityID: .global,
            attributeKey: .pronounReference(pronoun: pronoun),
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
            entityID: .global,
            attributeKey: .pronounReference(pronoun: pronoun),
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
            entityID: .global,
            attributeKey: .pronounReference(pronoun: pronoun),
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
            if case .stateValidationFailed = actionError { } else {
                Issue.record("Expected .stateValidationFailed case, got \(actionError)")
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
            entityID: .global,
            attributeKey: .addActiveFuse(fuseID: fuseID, initialTurns: initialTurns),
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
            entityID: .global,
            attributeKey: .addActiveFuse(fuseID: fuseID, initialTurns: initialTurns),
            newValue: .int(initialTurns)
        )
        try gameState.apply(setupChange)
        #expect(gameState.activeFuses[fuseID] == initialTurns)

        let newInitialTurns = 20 // New turns value for the 'add'
        let change = StateChange(
            entityID: .global,
            attributeKey: .addActiveFuse(fuseID: fuseID, initialTurns: newInitialTurns),
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
            entityID: .global,
            attributeKey: .addActiveFuse(fuseID: fuseID, initialTurns: initialTurns),
            newValue: .int(initialTurns)
        )
        try gameState.apply(setupChange)
        #expect(gameState.activeFuses[fuseID] == initialTurns)

        let change = StateChange(
            entityID: .global,
            attributeKey: .removeActiveFuse(fuseID: fuseID),
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
            entityID: .global,
            attributeKey: .addActiveFuse(fuseID: fuseID, initialTurns: actualTurns),
            newValue: .int(actualTurns)
        )
        try gameState.apply(setupChange)
        let incorrectOldTurns = 10 // Incorrect

        let change = StateChange(
            entityID: .global,
            attributeKey: .removeActiveFuse(fuseID: fuseID),
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
            if case .stateValidationFailed = actionError { } else {
                Issue.record("Expected .stateValidationFailed case, got \(actionError)")
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
            entityID: .global,
            attributeKey: .removeActiveFuse(fuseID: fuseID),
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

    @Test("Apply Player Inventory Limit Change") // Already using correct key
    func testApplyPlayerInventoryLimit() throws {
        // Use helper.createInitialState()
        var state = helper.createInitialState()
        let originalLimit = state.player.carryingCapacity
        let newLimit = originalLimit + 50
        let change = StateChange(
            entityID: .player,
            attributeKey: .playerInventoryLimit, // Already correct
            oldValue: .int(originalLimit),
            newValue: .int(newLimit)
        )

        try state.apply(change)

        #expect(state.player.carryingCapacity == newLimit)
        #expect(state.changeHistory.last == change)
    }

    @Test("Apply Player Inventory Limit Change - Validation Failure") // Already using correct key
    func testApplyPlayerInventoryLimitValidationFailure() throws {
        // Use helper.createInitialState()
        var state = helper.createInitialState()
        let wrongOldLimit = state.player.carryingCapacity + 10
        let newLimit = state.player.carryingCapacity + 50
        let change = StateChange(
            entityID: .player,
            attributeKey: .playerInventoryLimit, // Already correct
            oldValue: .int(wrongOldLimit), // Incorrect oldValue
            newValue: .int(newLimit)
        )

        #expect(throws: ActionError.self) {
            try state.apply(change)
        }
        do {
            try state.apply(change)
            Issue.record("Expected apply to throw an error, but it succeeded.")
        } catch let error as ActionError {
            #expect(error == ActionError.stateValidationFailed(change: change, actualOldValue: .int(state.player.carryingCapacity)))
        } catch {
            Issue.record("Thrown error was not an ActionError: \(error)")
        }
        #expect(state.changeHistory.isEmpty)
    }
}
