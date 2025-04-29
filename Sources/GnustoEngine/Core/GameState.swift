import Foundation

/// Represents the complete state of the game world at a given point in time.
public struct GameState: Codable {
    /// Active fuses and their remaining turns.
    public private(set) var activeFuses: [Fuse.ID: Int]

    /// Set tracking the IDs of currently active daemons.
    public private(set) var activeDaemons: Set<DaemonID>

    /// A log of state changes that have occurred, potentially turn-by-turn or action-by-action.
    /// This could be used for debugging, undo functionality, or complex event triggers.
    public private(set) var changeHistory: [StateChange]

    /// Current value of global variables or flags (e.g., [FlagID: FlagValue]).
    /// Using String for key flexibility, might refine later (e.g., `FlagID` type).
    public private(set) var flags: [String: Bool]

    /// A dictionary mapping item IDs to their current state (references to Item instances).
    /// This is the single source of truth for all item data, including their parentage.
    public private(set) var items: [ItemID: Item]

    /// A dictionary mapping location IDs to their current state (references to Location instances).
    public private(set) var locations: [LocationID: Location]

    /// The current state of the player.
    public private(set) var player: Player

    /// Pronoun resolution state (e.g., what does "it" or "them" currently refer to?).
    /// Maps pronoun string (lowercase) to the set of ItemIDs it represents.
    public private(set) var pronouns: [String: Set<ItemID>]

    /// The game's vocabulary.
    public let vocabulary: Vocabulary

    /// Optional dictionary for storing arbitrary game-specific state (counters, quest flags, etc.).
    /// Use keys prefixed with game ID (e.g., "cod_counter") to avoid collisions if engine supports multiple games.
    public private(set) var gameSpecificState: [String: AnyCodable]
}

extension GameState {
    @MainActor
    public init(
        locations: [Location],
        items: [Item],
        player: Player,
        vocabulary: Vocabulary? = nil,
        flags: [String: Bool] = [:],
        pronouns: [String: Set<ItemID>] = [:],
        activeFuses: [Fuse.ID: Int] = [:],
        activeDaemons: Set<DaemonID> = [],
        gameSpecificState: [String: AnyCodable] = [:],
        changeHistory: [StateChange] = []
    ) {
        self.activeDaemons = activeDaemons
        self.activeFuses = activeFuses
        self.changeHistory = changeHistory
        self.flags = flags
        self.gameSpecificState = gameSpecificState
        self.items = Dictionary(uniqueKeysWithValues: items.map { ($0.id, $0) })
        self.locations = Dictionary(uniqueKeysWithValues: locations.map { ($0.id, $0) })
        self.player = player
        self.pronouns = pronouns
        self.vocabulary = vocabulary ?? .build(items: items)
    }

    @MainActor
    public init(
        areas: [AreaContents.Type],
        player: Player,
        vocabulary: Vocabulary? = nil,
        flags: [String: Bool] = [:],
        pronouns: [String: Set<ItemID>] = [:],
        activeFuses: [Fuse.ID: Int] = [:],
        activeDaemons: Set<DaemonID> = [],
        gameSpecificState: [String: AnyCodable] = [:],
        changeHistory: [StateChange] = []
    ) {
        var allItems: [Item] = []
        var allLocations: [Location] = []
        var seenItemIds = Set<ItemID>()
        var seenLocationIds = Set<LocationID>()

        // Iterate through each provided AreaContents type
        for areaType in areas {
            // Collect items from this area type
            let currentItems = areaType.items
            for item in currentItems {
                // Validate for duplicate ItemIDs across all areas
                guard !seenItemIds.contains(item.id) else {
                    fatalError("Duplicate ItemID '\(item.id)' found across multiple AreaContents types (detected in \(areaType)).")
                }
                seenItemIds.insert(item.id)
                allItems.append(item)
            }

            // Collect locations from this area type
            let currentLocations = areaType.locations
            for location in currentLocations {
                // Validate for duplicate LocationIDs across all areas
                guard !seenLocationIds.contains(location.id) else {
                    fatalError("Duplicate LocationID '\(location.id)' found across multiple AreaContents types (detected in \(areaType)).")
                }
                seenLocationIds.insert(location.id)
                allLocations.append(location)
            }
        }

        // Initialize GameState properties using collected data
        self.activeDaemons = activeDaemons
        self.activeFuses = activeFuses
        self.changeHistory = changeHistory
        self.flags = flags
        self.gameSpecificState = gameSpecificState
        // Create dictionaries from the validated, unique items and locations
        self.items = Dictionary(uniqueKeysWithValues: allItems.map { ($0.id, $0) })
        self.locations = Dictionary(uniqueKeysWithValues: allLocations.map { ($0.id, $0) })
        self.player = player
        self.pronouns = pronouns
        // Build vocabulary from all collected items if not provided
        self.vocabulary = vocabulary ?? .build(items: allItems)
    }
}

// MARK: - Computed Properties & Helpers

extension GameState {
    /// Returns the parent entity of a specific item.
    public func itemLocation(id: ItemID) -> ParentEntity? {
        items[id]?.parent
    }

    /// Returns an array of ItemIDs for items currently held directly by the player.
    public func itemsInInventory() -> [ItemID] {
        items.values.filter { $0.parent == .player }.map { $0.id }
    }

    /// Returns an array of ItemIDs for items currently directly within a specific location.
    public func itemsInLocation(id: LocationID) -> [ItemID] {
        items.values.filter { $0.parent == .location(id) }.map { $0.id }
    }

    // TODO: Add helpers for items in container, etc. as needed.

    // MARK: - Centralized State Mutation

    /// Validates the old value specified in a StateChange against the actual current value.
    /// - Parameters:
    ///   - change: The StateChange being applied.
    ///   - actualOldValue: The actual value currently in the game state, or nil if not applicable/found.
    /// - Throws: `ActionError.internalEngineError` if `change.oldValue` is non-nil and doesn't match `actualOldValue`.
    private func validateOldValue(
        _ change: StateChange,
        actualOldValue: StateValue?
    ) throws {
        guard let expectedOldValue = change.oldValue else {
            return // No validation needed if oldValue wasn't provided in the change record
        }
        // If expectedOldValue was provided, the actual value must match.
        // Treats nil actual value as a mismatch if an old value was expected.
        guard actualOldValue == expectedOldValue else {
            let actualDesc = actualOldValue != nil ? "\(actualOldValue!)" : "nil"
            // Use entityId in the error message
            throw ActionError.internalEngineError(
                "StateChange oldValue mismatch for \(change.propertyKey) on \(change.entityId). " +
                "Expected: \(expectedOldValue), Actual: \(actualDesc)"
            )
        }
    }

    /// Applies a validated state change to the game state and records it.
    /// This is the single point of truth for modifying the game state after initialization.
    /// Ensures that the provided `oldValue` matches the current state before applying the change.
    ///
    /// - Parameter change: The `StateChange` to apply.
    /// - Throws: `ActionError.internalEngineError` if the `oldValue` in the change
    ///           does not match the current state, or if the change is invalid (e.g., wrong entity type,
    ///           invalid value type).
    public mutating func apply(_ change: StateChange) throws {
        // Switch on the property key enum to determine how to apply the change.
        switch change.propertyKey {

        // MARK: Item Changes
        case .itemParent, .itemProperties, .itemSize, .itemCapacity, .itemName, .itemAdjectives, .itemSynonyms, .itemDescription:
            guard case .item(let itemID) = change.entityId else {
                throw ActionError.internalEngineError("Invalid entity type for item property key \(change.propertyKey): \(change.entityId)")
            }
            guard let item = self.items[itemID] else {
                throw ActionError.internalEngineError("Cannot apply change to unknown item ID: \(itemID)")
            }

            // Remove inner switch, handle directly based on propertyKey
            switch change.propertyKey {
            case .itemParent:
                try validateOldValue(change, actualOldValue: .parentEntity(item.parent))
                guard case .parentEntity(let newParent) = change.newValue else {
                    throw ActionError.internalEngineError("Invalid StateValue type for .itemParent: \(change.newValue)")
                }
                item.parent = newParent // Direct mutation of class instance

            case .itemProperties:
                try validateOldValue(change, actualOldValue: .itemProperties(item.properties))
                guard case .itemProperties(let newProps) = change.newValue else {
                    throw ActionError.internalEngineError("Invalid StateValue type for .itemProperties: \(change.newValue)")
                }
                item.properties = newProps // Direct mutation of class instance

            case .itemSize:
                try validateOldValue(change, actualOldValue: .int(item.size))
                guard case .int(let newSize) = change.newValue else { throw ActionError.internalEngineError("Invalid StateValue type for .itemSize: \(change.newValue)") }
                item.size = newSize // Direct mutation of class instance

            case .itemCapacity:
                try validateOldValue(change, actualOldValue: .int(item.capacity))
                guard case .int(let newCapacity) = change.newValue else { throw ActionError.internalEngineError("Invalid StateValue type for .itemCapacity: \(change.newValue)") }
                item.capacity = newCapacity // Direct mutation of class instance

            case .itemName:
                try validateOldValue(change, actualOldValue: .string(item.name))
                guard case .string(let newName) = change.newValue else { throw ActionError.internalEngineError("Invalid StateValue type for .itemName: \(change.newValue)") }
                item.name = newName // Direct mutation of class instance

            case .itemAdjectives:
                try validateOldValue(change, actualOldValue: .itemAdjectives(item.adjectives))
                guard case .itemAdjectives(let newAdjectives) = change.newValue else { throw ActionError.internalEngineError("Invalid StateValue type for .itemAdjectives: \(change.newValue)") }
                item.adjectives = newAdjectives // Direct mutation of class instance

            case .itemSynonyms:
                try validateOldValue(change, actualOldValue: .itemSynonyms(item.synonyms))
                guard case .itemSynonyms(let newSynonyms) = change.newValue else { throw ActionError.internalEngineError("Invalid StateValue type for .itemSynonyms: \(change.newValue)") }
                item.synonyms = newSynonyms // Direct mutation of class instance

            case .itemDescription:
                 // Descriptions are closures (DescriptionHandler?) and cannot be set via StateChange.
                 // This case should ideally not be reached if StateChanges are created correctly.
                 throw ActionError.internalEngineError("Attempted to apply StateChange to immutable item description for \(itemID). Use DescriptionHandlerRegistry for dynamic descriptions.")

            // Default case for any other keys that might fall into this outer group (shouldn't happen)
            default: fatalError("Mismatched item property key processing: \(change.propertyKey)")
            }

        // MARK: Location Changes
        case .locationProperties, .locationName, .locationExits, .locationDescription:
            guard case .location(let locationID) = change.entityId else {
                throw ActionError.internalEngineError("Invalid entity type for location property key \(change.propertyKey): \(change.entityId)")
            }
            guard let location = self.locations[locationID] else {
                throw ActionError.internalEngineError("Cannot apply change to unknown location ID: \(locationID)")
            }

            // Remove inner switch, handle directly based on propertyKey
            switch change.propertyKey {
            case .locationProperties:
                try validateOldValue(change, actualOldValue: .locationProperties(location.properties))
                guard case .locationProperties(let newProps) = change.newValue else { throw ActionError.internalEngineError("Invalid StateValue type for .locationProperties: \(change.newValue)") }
                location.properties = newProps // Direct mutation of class instance

            case .locationName:
                try validateOldValue(change, actualOldValue: .string(location.name))
                guard case .string(let newName) = change.newValue else { throw ActionError.internalEngineError("Invalid StateValue type for .locationName: \(change.newValue)") }
                location.name = newName // Direct mutation of class instance

            case .locationExits:
                try validateOldValue(change, actualOldValue: .locationExits(location.exits))
                guard case .locationExits(let newExits) = change.newValue else { throw ActionError.internalEngineError("Invalid StateValue type for .locationExits: \(change.newValue)") }
                location.exits = newExits // Direct mutation of class instance

            case .locationDescription:
                // Descriptions are closures (DescriptionHandler?) and cannot be set via StateChange.
                throw ActionError.internalEngineError("Attempted to apply StateChange to immutable location description for \(locationID). Use DescriptionHandlerRegistry for dynamic descriptions.")

            // Default case for any other keys that might fall into this outer group (shouldn't happen)
            default: fatalError("Mismatched location property key processing: \(change.propertyKey)")
            }

        // MARK: Player Changes
        case .playerScore, .playerMoves, .playerCapacity, .playerLocation:
            guard case .player = change.entityId else {
                throw ActionError.internalEngineError("Invalid entity type for player property key \(change.propertyKey): \(change.entityId)")
            }

            // Remove inner switch, handle directly based on propertyKey
            switch change.propertyKey {
            case .playerScore:
                try validateOldValue(change, actualOldValue: .int(self.player.score))
                guard case .int(let newScore) = change.newValue else { throw ActionError.internalEngineError("Invalid StateValue type for .playerScore: \(change.newValue)") }
                self.player.score = newScore

            case .playerMoves:
                try validateOldValue(change, actualOldValue: .int(self.player.moves))
                guard case .int(let newMoves) = change.newValue else { throw ActionError.internalEngineError("Invalid StateValue type for .playerMoves: \(change.newValue)") }
                self.player.moves = newMoves

            case .playerCapacity:
                try validateOldValue(change, actualOldValue: .int(self.player.carryingCapacity))
                guard case .int(let newCapacity) = change.newValue else { throw ActionError.internalEngineError("Invalid StateValue type for .playerCapacity: \(change.newValue)") }
                self.player.carryingCapacity = newCapacity

            case .playerLocation:
                try validateOldValue(change, actualOldValue: .locationID(self.player.currentLocationID))
                guard case .locationID(let newLocationID) = change.newValue else { throw ActionError.internalEngineError("Invalid StateValue type for .playerLocation: \(change.newValue)") }
                // Ensure the destination location actually exists before setting
                guard self.locations[newLocationID] != nil else {
                    throw ActionError.internalEngineError("Attempted to move player to invalid location ID: \(newLocationID)")
                }
                self.player.currentLocationID = newLocationID

            // Default case for any other keys that might fall into this outer group (shouldn't happen)
            default: fatalError("Mismatched player property key processing: \(change.propertyKey)")
            }

        // MARK: Global Changes
        case .globalFlag(let actualFlagKey):
            guard case .global = change.entityId else {
                throw ActionError.internalEngineError("Invalid entity type for global property key \(change.propertyKey): \(change.entityId)")
            }
            let actualValue = self.flags[actualFlagKey]
            try validateOldValue(change, actualOldValue: actualValue != nil ? .bool(actualValue!) : nil)
            guard case .bool(let flagValue) = change.newValue else { throw ActionError.internalEngineError("Invalid StateValue type for .globalFlag(\(actualFlagKey)): \(change.newValue)") }
            self.flags[actualFlagKey] = flagValue

        case .pronounReference(let pronoun):
            guard case .global = change.entityId else {
                throw ActionError.internalEngineError("Invalid entity type for global property key \(change.propertyKey): \(change.entityId)")
            }
            let actualValue = self.pronouns[pronoun]
            try validateOldValue(change, actualOldValue: actualValue != nil ? .itemIDSet(actualValue!) : nil)
            guard case .itemIDSet(let itemIDSet) = change.newValue else {
                throw ActionError.internalEngineError("Invalid StateValue type for .pronounReference(\(pronoun)): \(change.newValue)")
            }
            self.pronouns[pronoun] = itemIDSet

        case .gameSpecificState(let key):
            guard case .global = change.entityId else {
                throw ActionError.internalEngineError("Invalid entity type for global property key \(change.propertyKey): \(change.entityId)")
            }
            // Skipping oldValue validation for gameSpecificState due to AnyCodable complexity/uncertainty.
            let anyCodableValue: AnyCodable
            switch change.newValue {
            case .bool(let v): anyCodableValue = AnyCodable(v)
            case .int(let v): anyCodableValue = AnyCodable(v)
            case .string(let v): anyCodableValue = AnyCodable(v)
            default:
                 throw ActionError.internalEngineError("Cannot convert complex StateValue type '\(change.newValue.self)' for gameSpecificState key '\(key)'. Only Bool, Int, String supported.")
            }
            self.gameSpecificState[key] = anyCodableValue

        // MARK: Fuse & Daemon Changes
        case .addActiveFuse(let fuseId, let initialTurns):
            guard case .global = change.entityId else { throw ActionError.internalEngineError("Invalid entity type for .addActiveFuse: \(change.entityId)") }
            // oldValue validation doesn't make sense for add
            // Ensure newValue matches the expected type (implicitly Int from initialTurns)
            guard case .int(let turnsValue) = change.newValue, turnsValue == initialTurns else {
                throw ActionError.internalEngineError("Invalid StateValue type or value mismatch for .addActiveFuse: \(change.newValue) vs initialTurns \(initialTurns)")
            }
            // Check if already active? Overwrite or throw? Let's overwrite for simplicity.
            self.activeFuses[fuseId] = initialTurns

        case .removeActiveFuse(let fuseId):
            guard case .global = change.entityId else { throw ActionError.internalEngineError("Invalid entity type for .removeActiveFuse: \(change.entityId)") }
            let actualOldValue = self.activeFuses[fuseId]
            // Validate oldValue if provided (expected Int turns remaining)
            try validateOldValue(change, actualOldValue: actualOldValue != nil ? .int(actualOldValue!) : nil)
            // newValue validation doesn't make sense for remove

            // Attempt to remove the value
            let didRemove = self.activeFuses.removeValue(forKey: fuseId) != nil

            // If it wasn't present, only throw an error if oldValue *wasn't* provided to confirm expectation
            if !didRemove, change.oldValue == nil {
                throw ActionError.internalEngineError("Attempted to remove non-existent active fuse: \(fuseId)")
            }
            // If oldValue was provided and matched nil (validation passed), or if remove succeeded, we are good.

        case .updateFuseTurns(let fuseId):
            guard case .global = change.entityId else { throw ActionError.internalEngineError("Invalid entity type for .updateFuseTurns: \(change.entityId)") }
            let actualOldValue = self.activeFuses[fuseId]
            // Validate oldValue if provided (expected Int turns remaining)
            try validateOldValue(change, actualOldValue: actualOldValue != nil ? .int(actualOldValue!) : nil)
            // Ensure newValue is Int
            guard case .int(let newTurns) = change.newValue else {
                 throw ActionError.internalEngineError("Invalid StateValue type for .updateFuseTurns: \(change.newValue)")
            }
            // Ensure fuse exists before updating
            guard self.activeFuses[fuseId] != nil else {
                throw ActionError.internalEngineError("Attempted to update turns for non-existent active fuse: \(fuseId)")
            }
            self.activeFuses[fuseId] = newTurns

        case .addActiveDaemon(let daemonId):
            guard case .global = change.entityId else { throw ActionError.internalEngineError("Invalid entity type for .addActiveDaemon: \(change.entityId)") }
            // Validate oldValue if provided (expecting .bool(true) if present, .bool(false) if not)
            let wasPresent = self.activeDaemons.contains(daemonId)
            try validateOldValue(change, actualOldValue: .bool(wasPresent))
            // newValue should be .bool(true) representing the desired active state
            guard change.newValue == .bool(true) else {
                throw ActionError.internalEngineError("Invalid StateValue newValue for .addActiveDaemon: \(change.newValue), expected .bool(true)")
            }
            self.activeDaemons.insert(daemonId)

        case .removeActiveDaemon(let daemonId):
            guard case .global = change.entityId else { throw ActionError.internalEngineError("Invalid entity type for .removeActiveDaemon: \(change.entityId)") }
            let wasPresent = self.activeDaemons.contains(daemonId)
            // Validate oldValue if provided (expecting .bool(true) if present, .bool(false) if not)
            try validateOldValue(change, actualOldValue: .bool(wasPresent))
            // newValue validation doesn't make sense for remove
            guard self.activeDaemons.remove(daemonId) != nil else {
                 // Only throw if oldValue wasn't provided to validate existence
                 if change.oldValue == nil {
                     throw ActionError.internalEngineError("Attempted to remove non-existent active daemon: \(daemonId)")
                 }
                 // If oldValue was provided and matched .bool(false), removal is technically successful (idempotent)
                 break
            }
        }

        // If we reached here without throwing, the change was applied successfully.
        // Record the change in the history.
        self.changeHistory.append(change)
    }

    // MARK: - State Mutation (Legacy/Internal - To Be Removed/Refactored)

    /// Changes the parent of a specified item.
    /// Ensures the item exists before attempting mutation.
    /// - Parameters:
    ///   - id: The ID of the item to move.
    ///   - to: The new parent entity for the item.
    /// - Returns: True if the move was successful, false if the item was not found.
    @discardableResult
    public mutating func moveItem(id: ItemID, to: ParentEntity) -> Bool {
        guard items[id] != nil else {
            // Consider logging a warning here in a real scenario
            print("Warning: Attempted to move non-existent item \(id)")
            return false
        }
        items[id]?.parent = to
        return true
    }

    /// Records a state change in the history.
    /// Typically called by the engine after applying a change derived from an `ActionResult`.
    public mutating func recordStateChange(_ change: StateChange) {
        changeHistory.append(change)
    }

    // TODO: Add other state mutation helpers (e.g., setFlag, addProperty).

    // MARK: - State Mutation Helpers

    /// Updates the referent(s) for a given pronoun.
    /// - Parameters:
    ///   - pronoun: The pronoun string (e.g., "it", "them").
    ///   - referringTo: A single ItemID the pronoun should now refer to.
    public mutating func updatePronoun(_ pronoun: String, referringTo itemID: ItemID) {
        // For singular pronouns like "it", overwrite the existing set.
        self.pronouns[pronoun.lowercased()] = [itemID]
        // TODO: Handle plural pronouns ("them")? Append or replace?
    }

    /// Updates the referent(s) for a given pronoun.
    /// - Parameters:
    ///   - pronoun: The pronoun string (e.g., "it", "them").
    ///   - referringTo: A set of ItemIDs the pronoun should now refer to.
    public mutating func updatePronoun(_ pronoun: String, referringTo itemIDs: Set<ItemID>) {
        self.pronouns[pronoun.lowercased()] = itemIDs
    }

    /// Removes all references for a given pronoun.
    /// - Parameter pronoun: The pronoun string to clear.
    public mutating func clearPronoun(_ pronoun: String) {
        self.pronouns.removeValue(forKey: pronoun.lowercased())
    }
}

// MARK: - Codable Conformance

extension GameState {
    // --- Codable Conformance ---
    // Explicit implementation needed due to dictionaries of classes

    enum CodingKeys: String, CodingKey {
        case activeFuses
        case activeDaemons
        case changeHistory
        case flags
        case items // Store items as an array for simpler encoding/decoding
        case locations // Store locations as an array
        case player
        case pronouns
        case vocabulary
        case gameSpecificState // Added for encoding/decoding
    }

    // Required init for Codable needs to be public if the struct is public
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        activeFuses = try container.decodeIfPresent([Fuse.ID: Int].self, forKey: .activeFuses) ?? [:]
        activeDaemons = try container.decodeIfPresent(Set<DaemonID>.self, forKey: .activeDaemons) ?? []
        changeHistory = try container.decode([StateChange].self, forKey: .changeHistory)
        flags = try container.decode([String: Bool].self, forKey: .flags)
        player = try container.decode(Player.self, forKey: .player)
        pronouns = try container.decode([String: Set<ItemID>].self, forKey: .pronouns)
        vocabulary = try container.decode(Vocabulary.self, forKey: .vocabulary)
        gameSpecificState = try container.decode([String: AnyCodable].self, forKey: .gameSpecificState)

        // Decode locations and items from arrays and rebuild dictionaries
        let locationArray = try container.decode([Location].self, forKey: .locations)
        locations = Dictionary(uniqueKeysWithValues: locationArray.map { ($0.id, $0) })

        let itemArray = try container.decode([Item].self, forKey: .items)
        items = Dictionary(uniqueKeysWithValues: itemArray.map { ($0.id, $0) })

        // Consistency check: Ensure decoded item parents align with decoded structure
        // This is complex to verify fully here, relies on game data being consistent.
    }

    // Encode func needs to be public if the struct is public
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(activeFuses, forKey: .activeFuses)
        try container.encode(activeDaemons, forKey: .activeDaemons)
        try container.encode(changeHistory, forKey: .changeHistory)
        try container.encode(flags, forKey: .flags)
        try container.encode(player, forKey: .player)
        try container.encode(pronouns, forKey: .pronouns)
        try container.encode(vocabulary, forKey: .vocabulary)
        try container.encodeIfPresent(gameSpecificState, forKey: .gameSpecificState)

        // Encode locations and items as arrays
        try container.encode(Array(locations.values), forKey: .locations)
        try container.encode(Array(items.values), forKey: .items)
    }
}
