import Foundation

/// Represents the complete, mutable state of the game world at a given point in time.
///
/// This struct is the single source of truth for all dynamic game data. All modifications
/// to the game state *must* go through the `apply(_:)` method to ensure changes are
/// tracked and validated.
public struct GameState: Codable, Equatable, Sendable {
    /// All items currently existing in the game world, indexed by their `ItemID`.
    public private(set) var items: [ItemID: Item]

    /// All locations defined in the game, indexed by their `LocationID`.
    public private(set) var locations: [LocationID: Location]

    /// The current state of the player.
    public private(set) var player: Player

    /// Active fuses (timed events), indexed by their `FuseID`.
    ///
    /// Value is remaining turns.
    public private(set) var activeFuses: [FuseID: Int]

    /// Active daemons (background processes), indexed by their `DaemonID`.
    ///
    /// Value is irrelevant (presence indicates active).
    public private(set) var activeDaemons: Set<DaemonID>

    /// Pronoun references, mapping String pronouns ("it", "them") to specific entity references.
    public private(set) var pronouns: [String: Set<EntityReference>]

    /// Game-specific key-value storage for miscellaneous state.
    public private(set) var globalState: [GlobalID: StateValue]

    /// A history of all state changes applied to this game state instance.
    public private(set) var changeHistory: [StateChange]

    /// The game's vocabulary (assumed immutable after init).
    public let vocabulary: Vocabulary

    // --- Initializers (Using structure from read_file output) ---
    public init(
        locations: [Location],
        items: [Item],
        player: Player,
        vocabulary: Vocabulary? = nil,
        pronouns: [String: Set<EntityReference>] = [:],
        activeFuses: [FuseID: Int] = [:],
        activeDaemons: Set<DaemonID> = [],
        globalState: [GlobalID: StateValue] = [:], // Keep AnyCodable
        changeHistory: [StateChange] = []
    ) {
        self.items = Dictionary(uniqueKeysWithValues: items.map { ($0.id, $0) })
        self.locations = Dictionary(uniqueKeysWithValues: locations.map { ($0.id, $0) })
        self.player = player
        self.activeFuses = activeFuses
        self.activeDaemons = activeDaemons
        self.pronouns = pronouns
        self.globalState = globalState
        self.changeHistory = changeHistory
        self.vocabulary = vocabulary ?? .build(items: items, locations: locations)
    }

    public init(
        areas: AreaContents.Type...,
        player: Player,
        vocabulary: Vocabulary? = nil,
        activeFuses: [FuseID: Int] = [:],
        activeDaemons: DaemonID...
    ) {
        var allItems: [Item] = []
        var allLocations: [Location] = []
        var knownItems = Set<ItemID>()
        var knownLocations = Set<LocationID>()

        for areaType in areas {
            for item in areaType.items {
                assert(!knownItems.contains(item.id), """
                    Duplicate ItemID '\(item.id)' found across multiple AreaContents \
                    types (detected in \(areaType)).
                    """)
                knownItems.insert(item.id)
                allItems.append(item)
            }

            for location in areaType.locations {
                assert(!knownLocations.contains(location.id), """
                    Duplicate LocationID '\(location.id)' found across multiple AreaContents \
                    types (detected in \(areaType)).
                    """)
                knownLocations.insert(location.id)
                allLocations.append(location)
            }
        }

        self.init(
            locations: allLocations,
            items: allItems,
            player: player,
            vocabulary: vocabulary,
            pronouns: [:],
            activeFuses: activeFuses,
            activeDaemons: Set(activeDaemons),
            globalState: [:],
            changeHistory: []
        )
    }

    var snapshot: GameState {
        GameState(
            locations: Array(locations.values),
            items: Array(items.values),
            player: player,
            vocabulary: vocabulary,
            pronouns: pronouns,
            activeFuses: activeFuses,
            activeDaemons: activeDaemons,
            globalState: globalState
        )
    }

    // MARK: - State Mutation

    public mutating func apply(_ changes: StateChange...) throws {
        for change in changes {
            try apply(change)
        }
    }

    /// Applies a `StateChange` to the game state, modifying the relevant property and recording the change.
    private mutating func apply(_ change: StateChange) throws {
        // --- Validation Phase ---
        try validateOldValue(for: change)

        // --- Mutation Phase ---
        switch change.attributeKey {

        // MARK: Item Properties

        case .itemAdjectives:
            // Expecting a .stringSet for itemAdjectives
            guard case .stringSet(let newAdjectives) = change.newValue else {
                throw ActionResponse.internalEngineError("Type mismatch for itemAdjectives: expected .stringSet, got \(change.newValue)")
            }
            guard case .item(let itemID) = change.entityID else {
                throw ActionResponse.internalEngineError("EntityID mismatch for itemAdjectives: expected .item, got \(change.entityID)")
            }
            guard items[itemID] != nil else {
                throw ActionResponse.internalEngineError("Item \(itemID.rawValue) not found for itemAdjectives change")
            }
            items[itemID]?.attributes[.adjectives] = .stringSet(newAdjectives)

        case .itemCapacity:
            // Expecting an .int for itemCapacity
            guard case .int(let newCapacity) = change.newValue else {
                throw ActionResponse.internalEngineError("Type mismatch for itemCapacity: expected .int, got \(change.newValue)")
            }
            guard case .item(let itemID) = change.entityID else {
                throw ActionResponse.internalEngineError("EntityID mismatch for itemCapacity: expected .item, got \(change.entityID)")
            }
            guard items[itemID] != nil else {
                throw ActionResponse.internalEngineError("Item \(itemID.rawValue) not found for itemCapacity change")
            }
            items[itemID]?.attributes[.capacity] = .int(newCapacity)

        case .itemName:
            // Expecting a .string for itemName
            guard case .string(let newName) = change.newValue else {
                throw ActionResponse.internalEngineError("Type mismatch for itemName: expected .string, got \(change.newValue)")
            }
            guard case .item(let itemID) = change.entityID else {
                throw ActionResponse.internalEngineError("EntityID mismatch for itemName: expected .item, got \(change.entityID)")
            }
            guard items[itemID] != nil else {
                throw ActionResponse.internalEngineError("Item \(itemID.rawValue) not found for itemName change")
            }
            items[itemID]?.attributes[.name] = .string(newName)

        case .itemParent:
            // Expecting a .parentEntity for itemParent
            guard case .parentEntity(let newParent) = change.newValue else {
                throw ActionResponse.internalEngineError("Type mismatch for itemParent: expected .parentEntity, got \(change.newValue)")
            }
            guard case .item(let itemID) = change.entityID else {
                throw ActionResponse.internalEngineError("EntityID mismatch for itemParent: expected .item, got \(change.entityID)")
            }
            guard items[itemID] != nil else {
                throw ActionResponse.internalEngineError("Item \(itemID.rawValue) not found for itemParent change")
            }
            items[itemID]?.attributes[.parentEntity] = .parentEntity(newParent)

        case .itemSize:
            // Expecting an .int for itemSize
            guard case .int(let newSize) = change.newValue else {
                throw ActionResponse.internalEngineError("Type mismatch for itemSize: expected .int, got \(change.newValue)")
            }
            guard case .item(let itemID) = change.entityID else {
                throw ActionResponse.internalEngineError("EntityID mismatch for itemSize: expected .item, got \(change.entityID)")
            }
            guard items[itemID] != nil else {
                throw ActionResponse.internalEngineError("Item \(itemID.rawValue) not found for itemSize change")
            }
            items[itemID]?.attributes[.size] = .int(newSize)

        case .itemSynonyms:
            // Expecting a .stringSet for itemSynonyms
            guard case .stringSet(let newSynonyms) = change.newValue else {
                throw ActionResponse.internalEngineError("Type mismatch for itemSynonyms: expected .stringSet, got \(change.newValue)")
            }
            guard case .item(let itemID) = change.entityID else {
                throw ActionResponse.internalEngineError("EntityID mismatch for itemSynonyms: expected .item, got \(change.entityID)")
            }
            guard items[itemID] != nil else {
                throw ActionResponse.internalEngineError("Item \(itemID.rawValue) not found for itemSynonyms change")
            }
            items[itemID]?.attributes[.synonyms] = .stringSet(newSynonyms)

        case .itemValue:
            // Expecting an .int for itemValue
            guard case .int = change.newValue else { // Ignore newValue for now
                throw ActionResponse.internalEngineError("Type mismatch for itemValue: expected .int, got \(change.newValue)")
            }
            guard case .item(let itemID) = change.entityID else {
                throw ActionResponse.internalEngineError("EntityID mismatch for itemValue: expected .item, got \(change.entityID)")
            }
            guard items[itemID] != nil else {
                throw ActionResponse.internalEngineError("Item \(itemID.rawValue) not found for itemValue change")
            }
            print("WARN: Item value setting not yet implemented in Item struct.") // Placeholder

        // MARK: Location Properties

        case .locationName:
            // Expecting a .string for locationName
            guard case .string(let newName) = change.newValue else {
                throw ActionResponse.internalEngineError("Type mismatch for locationName: expected .string, got \(change.newValue)")
            }
            guard case .location(let locationID) = change.entityID else {
                throw ActionResponse.internalEngineError("EntityID mismatch for locationName: expected .location, got \(change.entityID)")
            }
            guard locations[locationID] != nil else {
                throw ActionResponse.internalEngineError("Location \(locationID.rawValue) not found for locationName change")
            }
            locations[locationID]?.attributes[.name] = .string(newName)

        case .locationDescription: // REMOVED - Cannot change description via StateChange
             throw ActionResponse.internalEngineError("Attempted to apply StateChange to location description. Use DescriptionHandlerRegistry for dynamic descriptions.")

        case .exits:
            // Expecting .exits
            guard case .exits(let newExits) = change.newValue else {
                throw ActionResponse.internalEngineError("Type mismatch for exits: expected .exits, got \(change.newValue)")
            }
            guard case .location(let locationID) = change.entityID else {
                throw ActionResponse.internalEngineError("EntityID mismatch for exits: expected .location, got \(change.entityID)")
            }
            guard locations[locationID] != nil else {
                throw ActionResponse.internalEngineError("Location \(locationID.rawValue) not found for exits change")
            }
            locations[locationID]?.attributes[.exits] = .exits(newExits)

        // MARK: Attributes (Item or Location)

        case .itemAttribute(let key):
            guard case .item(let itemID) = change.entityID else {
                throw ActionResponse.internalEngineError("EntityID mismatch for itemAttribute: expected .item, got \(change.entityID)")
            }
            guard items[itemID] != nil else {
                throw ActionResponse.internalEngineError("Item \(itemID.rawValue) not found for itemAttribute change ('\(key.rawValue)')")
            }
            // Directly update the StateValue in the dictionary.
            // Assumes validation happened *before* StateChange creation.
            items[itemID]?.attributes[key] = change.newValue

        case .locationAttribute(let key):
             guard case .location(let locationID) = change.entityID else {
                throw ActionResponse.internalEngineError("EntityID mismatch for locationAttribute: expected .location, got \(change.entityID)")
            }
            guard locations[locationID] != nil else {
                throw ActionResponse.internalEngineError("Location \(locationID.rawValue) not found for locationAttribute change ('\(key.rawValue)')")
            }
            locations[locationID]?.attributes[key] = change.newValue

        // MARK: Player Properties

        case .playerScore:
            // Expecting .int
            guard case .int(let newScore) = change.newValue else {
                throw ActionResponse.internalEngineError("Type mismatch for playerScore: expected .int, got \(change.newValue)")
            }
            guard change.entityID == .player else {
                throw ActionResponse.internalEngineError("EntityID mismatch for playerScore: expected .player, got \(change.entityID)")
            }
            player.score = newScore

        case .playerMoves:
            // Expecting .int
            guard case .int(let newMoves) = change.newValue else {
                throw ActionResponse.internalEngineError("Type mismatch for playerMoves: expected .int, got \(change.newValue)")
            }
            guard change.entityID == .player else {
                throw ActionResponse.internalEngineError("EntityID mismatch for playerMoves: expected .player, got \(change.entityID)")
            }
            player.moves = newMoves

        case .playerInventoryLimit:
            // Expecting .int
            guard case .int(let newLimit) = change.newValue else {
                throw ActionResponse.internalEngineError("Type mismatch for playerInventoryLimit: expected .int, got \(change.newValue)")
            }
            guard change.entityID == .player else {
                throw ActionResponse.internalEngineError("EntityID mismatch for playerInventoryLimit: expected .player, got \(change.entityID)")
            }
            player.carryingCapacity = newLimit // Use correct property name

        case .playerLocation:
            // Expecting .locationID
            guard case .locationID(let newLocationID) = change.newValue else {
                throw ActionResponse.internalEngineError("Type mismatch for playerLocation: expected .locationID, got \(change.newValue)")
            }
            guard change.entityID == .player else {
                throw ActionResponse.internalEngineError("EntityID mismatch for playerLocation: expected .player, got \(change.entityID)")
            }
            // Ensure destination exists before moving player
            guard locations[newLocationID] != nil else {
                 throw ActionResponse.internalEngineError("Attempted to move player to non-existent location: \(newLocationID.rawValue)")
            }
            player.currentLocationID = newLocationID // Use correct property name

        case .playerStrength, .playerHealth:
            print("WARN: Player strength/health state changes not yet implemented.")

        // MARK: Global/Misc Properties

        case .setFlag(let key):
            // The convention is that setting a flag corresponds to a newValue of true
            guard change.newValue == true else {
                 print("Warning: setFlag StateChange newValue was not true, was \(String(describing: change.newValue)). Proceeding anyway.")
                 return // Exit scope if newValue is not as expected
             }
             guard change.entityID == .global else {
                 throw ActionResponse.internalEngineError("EntityID mismatch for setFlag: expected .global, got \(change.entityID)")
             }
            globalState[key] = change.newValue

        case .clearFlag(let key):
            // The convention is that clearing a flag corresponds to a newValue of false
            guard change.newValue == false else {
                 print("Warning: clearFlag StateChange newValue was not false, was \(String(describing: change.newValue)). Proceeding anyway.")
                 return // Exit scope if newValue is not as expected
             }
             guard change.entityID == .global else {
                 throw ActionResponse.internalEngineError("EntityID mismatch for clearFlag: expected .global, got \(change.entityID)")
             }
            globalState[key] = change.newValue

        case .globalState(let key):
            guard change.entityID == .global else {
                throw ActionResponse.internalEngineError("EntityID mismatch for globalState: expected .global, got \(change.entityID)")
            }
             globalState[key] = change.newValue

        case .pronounReference(let pronoun):
            // Expecting .entityReferenceSet
            guard case .entityReferenceSet(let newEntityReferenceSet) = change.newValue else {
                throw ActionResponse.internalEngineError("Type mismatch for pronounReference \(pronoun): expected .entityReferenceSet, got \(change.newValue)")
            }
            guard change.entityID == .global else {
                throw ActionResponse.internalEngineError("EntityID mismatch for pronounReference: expected .global, got \(change.entityID)")
            }
            // Ensure newEntityReferenceSet is not nil before assignment, or assign an empty set.
            pronouns[pronoun] = newEntityReferenceSet ?? []

        case .addActiveDaemon(let daemonID):
            guard change.entityID == .global else {
                throw ActionResponse.internalEngineError("EntityID mismatch for addActiveDaemon: expected .global, got \(change.entityID)")
            }
            guard case true = change.newValue else {
                 print("WARN: addActiveDaemon StateChange newValue was not true, was \(change.newValue). Proceeding anyway.")
                 return
             }
            activeDaemons.insert(daemonID)

        case .addActiveFuse(let fuseID, let initialTurns):
            guard change.entityID == .global else {
                throw ActionResponse.internalEngineError("EntityID mismatch for addActiveFuse: expected .global, got \(change.entityID)")
            }
            guard case .int(let turnsValue) = change.newValue, turnsValue == initialTurns else {
                throw ActionResponse.internalEngineError("StateChange newValue (\(change.newValue)) does not match initialTurns (\(initialTurns)) in addActiveFuse key.")
            }
            activeFuses[fuseID] = initialTurns

        case .removeActiveDaemon(let daemonID):
            guard change.entityID == .global else {
                throw ActionResponse.internalEngineError("EntityID mismatch for removeActiveDaemon: expected .global, got \(change.entityID)")
            }
            activeDaemons.remove(daemonID)

        case .removeActiveFuse(let fuseID):
            guard change.entityID == .global else {
                throw ActionResponse.internalEngineError("EntityID mismatch for removeActiveFuse: expected .global, got \(change.entityID)")
            }
            activeFuses.removeValue(forKey: fuseID)

        case .updateFuseTurns(let fuseID):
            guard change.entityID == .global else {
                throw ActionResponse.internalEngineError("EntityID mismatch for updateFuseTurns: expected .global, got \(change.entityID)")
            }
            guard case .int(let newTurns) = change.newValue else {
                throw ActionResponse.internalEngineError("Type mismatch for updateFuseTurns: expected .int, got \(change.newValue)")
            }
            guard activeFuses[fuseID] != nil else {
                throw ActionResponse.internalEngineError("Attempted to update turns for non-existent active fuse: \(fuseID)")
            }
            activeFuses[fuseID] = newTurns
        }

        changeHistory.append(change)
    }

    /// Validates that the `oldValue` in a `StateChange` matches the current state.
    private func validateOldValue(for change: StateChange) throws {
        // Old value validation only occurs if an expectedOldValue is provided in the change.
        guard let expectedOldValue = change.oldValue else { return }

        // Determine the actual current value based on the property key.
        let actualCurrentValue: StateValue?
        switch change.attributeKey {
        // Item Properties
        case .itemAdjectives:
            guard case .item(let itemID) = change.entityID else {
                throw ActionResponse.internalEngineError("Validation: Invalid entity ID for itemAdjectives")
            }
            // Map item's adjectives Set<String> to .stringSet
            actualCurrentValue = items[itemID].map { .stringSet($0.adjectives) }

        case .itemCapacity:
            guard case .item(let itemID) = change.entityID else {
                throw ActionResponse.internalEngineError("Validation: Invalid entity ID for itemCapacity")
            }
            // Map item's optional capacity Int? to .int, defaulting to 0
            actualCurrentValue = items[itemID].map { .int($0.capacity) }

        case .itemName:
            guard case .item(let itemID) = change.entityID else {
                throw ActionResponse.internalEngineError("Validation: Invalid entity ID for itemName")
            }
            // Map item's name String to .string
            actualCurrentValue = items[itemID].map { .string($0.name) }

        case .itemSynonyms:
            guard case .item(let itemID) = change.entityID else {
                throw ActionResponse.internalEngineError("Validation: Invalid entity ID for itemSynonyms")
            }
            // Map item's synonyms Set<String> to .stringSet
            actualCurrentValue = items[itemID].map { .stringSet($0.synonyms) }

        case .itemParent:
            guard case .item(let itemID) = change.entityID else {
                throw ActionResponse.internalEngineError("Validation: Invalid entity ID for itemParent")
            }
            // Map item's parent ParentEntity to .parentEntity
            actualCurrentValue = items[itemID].map { .parentEntity($0.parent) }

        case .itemSize:
            guard case .item(let id) = change.entityID else {
                throw ActionResponse.internalEngineError("Validation: Invalid entity ID for itemSize")
            }
            // Map item's size Int to .int
            actualCurrentValue = items[id].map { .int($0.size) }
        case .itemValue:
            guard case .item = change.entityID else {
                throw ActionResponse.internalEngineError("Validation: Invalid entity ID for itemValue")
            }
            print("WARN: Old value validation skipped for itemValue (property not implemented).")
            actualCurrentValue = nil // Skip validation for unimplemented property

        // Location Properties
        case .locationName:
            guard case .location(let id) = change.entityID else {
                throw ActionResponse.internalEngineError("Validation: Invalid entity ID for locationName")
            }
            // Map location's name String to .string
            actualCurrentValue = locations[id].map { .string($0.name) }

        case .locationDescription:
             throw ActionResponse.internalEngineError("Old value validation cannot be performed on locationDescription.")

        case .exits:
            guard case .location(let locationID) = change.entityID else {
                throw ActionResponse.internalEngineError("Validation: Invalid entity ID for exits")
            }
            // Map location's exits [Direction: Exit] to .exits
            actualCurrentValue = if let exits = locations[locationID]?.exits {
                .exits(exits)
            } else {
                nil
            }

        // Player Properties
        case .playerScore:
            actualCurrentValue = .int(player.score)
        case .playerMoves:
            actualCurrentValue = .int(player.moves)
        case .playerInventoryLimit:
            actualCurrentValue = .int(player.carryingCapacity)
        case .playerLocation:
            actualCurrentValue = .locationID(player.currentLocationID)
        case .playerStrength, .playerHealth:
            print("WARN: Old value validation skipped for player strength/health (properties not implemented).")
            actualCurrentValue = nil // Skip validation

        // Global/Misc Properties
        case .setFlag(let key):
            // Before setting, the flag should *not* have been present.
            // The expected old value should be false or nil.
            let flagWasSet = globalState[key] != true
            actualCurrentValue = .bool(flagWasSet)

        case .clearFlag(let key):
            // Before clearing, the flag *should* have been present.
            // The expected old value should be true.
            let flagWasSet = globalState[key] != false
            actualCurrentValue = .bool(flagWasSet)

        case .globalState(let key):
             actualCurrentValue = globalState[key]

        case .pronounReference(let pronoun):
            actualCurrentValue = pronouns[pronoun].map { StateValue.entityReferenceSet($0) }

        // Fuses & Daemons
        case .addActiveDaemon, .addActiveFuse:
            // Add actions do not validate oldValue, so we skip the final check.
            // This could be adjusted if strict validation on 'add' is desired (e.g., ensuring it *wasn't* present).
            print("INFO: Old value validation skipped for addActiveDaemon/addActiveFuse.")
            return // Skip the final comparison

        case .removeActiveDaemon(let daemonID):
            let currentlyActive = activeDaemons.contains(daemonID)
            actualCurrentValue = StateValue.bool(currentlyActive)

        case .removeActiveFuse(let fuseID):
            actualCurrentValue = activeFuses[fuseID].map { StateValue.int($0) }

        case .updateFuseTurns(let fuseID):
            // If fuse doesn't exist, current value is nil
            actualCurrentValue = activeFuses[fuseID].map { StateValue.int($0) }

        case .itemAttribute(let key):
             guard case .item(let itemID) = change.entityID else {
                throw ActionResponse.internalEngineError("Validation: Invalid entity ID for itemAttribute")
             }
             actualCurrentValue = items[itemID]?.attributes[key]

        case .locationAttribute(let key):
             guard case .location(let locationID) = change.entityID else {
                throw ActionResponse.internalEngineError("Validation: Invalid entity ID for locationAttribute")
             }
             actualCurrentValue = locations[locationID]?.attributes[key]
        }

        // Perform the validation
        guard
            actualCurrentValue == expectedOldValue ||
            (actualCurrentValue == nil && expectedOldValue == false)
        else {
            throw ActionResponse.stateValidationFailed(change: change, actualOldValue: actualCurrentValue)
        }
    }
}
