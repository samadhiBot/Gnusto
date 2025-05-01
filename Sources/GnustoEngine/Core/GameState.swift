import Foundation

/// Represents the complete, mutable state of the game world at a given point in time.
///
/// This struct is the single source of truth for all dynamic game data. All modifications
/// to the game state *must* go through the `apply(_:)` method to ensure changes are
/// tracked and validated.
public struct GameState: Codable, Equatable, Sendable {
    /// Unique identifier for the game instance.
    // public let gameID: String // Removed - See previous implementation in read_file

    /// All items currently existing in the game world, indexed by their `ItemID`.
    public internal(set) var items: [ItemID: Item]

    /// All locations defined in the game, indexed by their `LocationID`.
    public internal(set) var locations: [LocationID: Location]

    /// Global boolean flags, indexed by String key.
    public internal(set) var flags: [String: Bool]

    /// The current state of the player.
    public internal(set) var player: Player

    /// Active fuses (timed events), indexed by their `FuseID`. Value is remaining turns.
    public internal(set) var activeFuses: [Fuse.ID: Int]

    /// Active daemons (background processes), indexed by their `DaemonID`. Value is irrelevant (presence indicates active).
    public internal(set) var activeDaemons: Set<DaemonID> // Use Set for simple presence check

    /// Pronoun references, mapping String pronouns ("it", "them") to specific item ID sets.
    public internal(set) var pronouns: [String: Set<ItemID>]

    /// Game-specific key-value storage for miscellaneous state. Uses String keys.
    public internal(set) var gameSpecificState: [GameStateKey: StateValue]

    /// A history of all state changes applied to this game state instance.
    public internal(set) var changeHistory: [StateChange]

    /// The game's vocabulary (assumed immutable after init).
    public let vocabulary: Vocabulary

    // --- Initializers (Using structure from read_file output) ---
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
        gameSpecificState: [GameStateKey: StateValue] = [:], // Keep AnyCodable
        changeHistory: [StateChange] = []
    ) {
        self.items = Dictionary(uniqueKeysWithValues: items.map { ($0.id, $0) })
        self.locations = Dictionary(uniqueKeysWithValues: locations.map { ($0.id, $0) })
        self.flags = flags
        self.player = player
        self.activeFuses = activeFuses
        self.activeDaemons = activeDaemons
        self.pronouns = pronouns
        self.gameSpecificState = gameSpecificState
        self.changeHistory = changeHistory
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
        gameSpecificState: [GameStateKey: StateValue] = [:],
        changeHistory: [StateChange] = []
    ) {
        var allItems: [Item] = []
        var allLocations: [Location] = []
        var seenItemIds = Set<ItemID>()
        var seenLocationIds = Set<LocationID>()

        for areaType in areas {
            let currentItems = areaType.items
            for item in currentItems {
                guard !seenItemIds.contains(item.id) else {
                    fatalError("Duplicate ItemID '\(item.id)' found across multiple AreaContents types (detected in \(areaType)).")
                }
                seenItemIds.insert(item.id)
                allItems.append(item)
            }

            let currentLocations = areaType.locations
            for location in currentLocations {
                 guard !seenLocationIds.contains(location.id) else {
                    fatalError("Duplicate LocationID '\(location.id)' found across multiple AreaContents types (detected in \(areaType)).")
                }
                seenLocationIds.insert(location.id)
                allLocations.append(location)
            }
        }

        self.init(
            locations: allLocations,
            items: allItems,
            player: player,
            vocabulary: vocabulary,
            flags: flags,
            pronouns: pronouns,
            activeFuses: activeFuses,
            activeDaemons: activeDaemons,
            gameSpecificState: gameSpecificState,
            changeHistory: changeHistory
        )
    }

    // MARK: - State Mutation

    /// Applies a `StateChange` to the game state, modifying the relevant property and recording the change.
    public mutating func apply(_ change: StateChange) throws {
        // --- Validation Phase ---
        try validateOldValue(for: change)

        // --- Mutation Phase ---
        switch change.propertyKey {
        // MARK: Item Properties
        case .itemParent:
            guard case .parentEntity(let newParent) = change.newValue else { throw ActionError.internalEngineError("...") }
            guard case .item(let itemID) = change.entityId else { throw ActionError.internalEngineError("...") }
            guard items[itemID] != nil else { throw ActionError.internalEngineError("...") }
            items[itemID]?.parent = newParent

        case .itemProperties:
            break // TODO: implement

        case .itemSize:
            guard case .int(let newSize) = change.newValue else { throw ActionError.internalEngineError("...") }
            guard case .item(let itemID) = change.entityId else { throw ActionError.internalEngineError("...") }
            guard items[itemID] != nil else { throw ActionError.internalEngineError("...") }
            items[itemID]?.size = newSize

        case .itemValue:
            guard case .int(let newValue) = change.newValue else { throw ActionError.internalEngineError("...") }
            guard case .item(let itemID) = change.entityId else { throw ActionError.internalEngineError("...") }
            guard items[itemID] != nil else { throw ActionError.internalEngineError("...") }
            print("WARN: Item value setting not yet implemented in Item struct.") // Placeholder

        // MARK: Location Properties
        case .locationName:
            guard case .string(let newName) = change.newValue else { throw ActionError.internalEngineError("...") }
            guard case .location(let locationID) = change.entityId else { throw ActionError.internalEngineError("...") }
            guard locations[locationID] != nil else { throw ActionError.internalEngineError("...") }
            locations[locationID]?.name = newName

        case .locationDescription: // REMOVED - Cannot change description via StateChange
             throw ActionError.internalEngineError("Attempted to apply StateChange to location description. Use DescriptionHandlerRegistry for dynamic descriptions.")

        case .locationProperties:
            guard case .locationProperties(let newProperties) = change.newValue else { throw ActionError.internalEngineError("newValue type mismatch for locationProperties") }
            guard case .location(let locationID) = change.entityId else { throw ActionError.internalEngineError("entityId type mismatch for locationProperties") }
            guard locations[locationID] != nil else { throw ActionError.internalEngineError("Location \(locationID.rawValue) not found for locationProperties change") }
            locations[locationID]?.properties = newProperties

        case .locationExits:
            guard case .locationExits(let newExits) = change.newValue else { throw ActionError.internalEngineError("newValue type mismatch for locationExits") }
            guard case .location(let locationID) = change.entityId else { throw ActionError.internalEngineError("entityId type mismatch for locationExits") }
            guard locations[locationID] != nil else { throw ActionError.internalEngineError("Location \(locationID.rawValue) not found for locationExits change") }
            locations[locationID]?.exits = newExits

        // MARK: Player Properties
        case .playerScore:
            guard case .int(let newScore) = change.newValue else { throw ActionError.internalEngineError("...") }
            guard change.entityId == .player else { throw ActionError.internalEngineError("...") }
            player.score = newScore

        case .playerMoves:
            guard case .int(let newMoves) = change.newValue else { throw ActionError.internalEngineError("...") }
            guard change.entityId == .player else { throw ActionError.internalEngineError("...") }
            player.moves = newMoves

        case .playerInventoryLimit:
            guard case .int(let newLimit) = change.newValue else { throw ActionError.internalEngineError("...") }
            guard change.entityId == .player else { throw ActionError.internalEngineError("...") }
            player.carryingCapacity = newLimit // Use correct property name

        case .playerLocation:
            guard case .locationID(let newLocationID) = change.newValue else { throw ActionError.internalEngineError("...") }
            guard change.entityId == .player else { throw ActionError.internalEngineError("...") }
            // Ensure destination exists before moving player
            guard locations[newLocationID] != nil else {
                 throw ActionError.internalEngineError("Attempted to move player to non-existent location: \(newLocationID.rawValue)")
            }
            player.currentLocationID = newLocationID // Use correct property name

        case .playerStrength, .playerHealth:
            print("WARN: Player strength/health state changes not yet implemented.")

        // MARK: Global/Misc Properties
        case .flag(let key):
            guard case .bool(let newValue) = change.newValue else { throw ActionError.internalEngineError("...") }
            guard change.entityId == .global else { throw ActionError.internalEngineError("...") }
            flags[key] = newValue // Use String key

//        case .pronounIt:
//            guard case .itemIDSet(let newItemIDSet) = change.newValue else { throw ActionError.internalEngineError("Type mismatch for pronounIt: expected .itemIDSet, got \(change.newValue)") }
//            guard change.entityId == .global else { throw ActionError.internalEngineError("EntityID mismatch for pronounIt...") }
//            pronouns["it"] = newItemIDSet // Use String key "it" and expect itemIDSet
//
//        case .pronounThem:
//            guard case .itemIDSet(let newItemIDSet) = change.newValue else { throw ActionError.internalEngineError("Type mismatch for pronounThem: expected .itemIDSet, got \(change.newValue)") }
//            guard change.entityId == .global else { throw ActionError.internalEngineError("EntityID mismatch for pronounThem...") }
//            pronouns["them"] = newItemIDSet // Use String key "them" and expect itemIDSet

        case .gameSpecificState(let key):
            guard change.entityId == .global else {
                throw ActionError.internalEngineError("EntityID mismatch for gameSpecificState...")
            }
             gameSpecificState[key] = change.newValue

        case .pronounReference(let pronoun):
            guard change.entityId == .global else {
                throw ActionError.internalEngineError("EntityID mismatch for pronounReference: expected .global, got \(change.entityId)")
            }
            guard case .itemIDSet(let newItemIDSet) = change.newValue else {
                throw ActionError.internalEngineError("Type mismatch for pronounReference: expected .itemIDSet, got \(change.newValue)")
            }
            pronouns[pronoun] = newItemIDSet

        case .addActiveDaemon(let daemonId):
            guard change.entityId == .global else {
                throw ActionError.internalEngineError("EntityID mismatch for addActiveDaemon: expected .global, got \(change.entityId)")
            }
            guard case .bool(true) = change.newValue else {
                 print("WARN: addActiveDaemon StateChange newValue was not .bool(true), was \(change.newValue). Proceeding anyway.")
                 return
             }
            activeDaemons.insert(daemonId)

        case .addActiveFuse(let fuseId, let initialTurns):
            guard change.entityId == .global else {
                throw ActionError.internalEngineError("EntityID mismatch for addActiveFuse: expected .global, got \(change.entityId)")
            }
            guard case .int(let turnsValue) = change.newValue, turnsValue == initialTurns else {
                throw ActionError.internalEngineError("StateChange newValue (\(change.newValue)) does not match initialTurns (\(initialTurns)) in addActiveFuse key.")
            }
            activeFuses[fuseId] = initialTurns

        case .removeActiveDaemon(let daemonId):
            guard change.entityId == .global else {
                throw ActionError.internalEngineError("EntityID mismatch for removeActiveDaemon: expected .global, got \(change.entityId)")
            }
            activeDaemons.remove(daemonId)

        case .removeActiveFuse(let fuseId):
            guard change.entityId == .global else {
                throw ActionError.internalEngineError("EntityID mismatch for removeActiveFuse: expected .global, got \(change.entityId)")
            }
            activeFuses.removeValue(forKey: fuseId)

        case .updateFuseTurns(let fuseId):
            guard change.entityId == .global else {
                throw ActionError.internalEngineError("EntityID mismatch for updateFuseTurns: expected .global, got \(change.entityId)")
            }
            guard case .int(let newTurns) = change.newValue else {
                throw ActionError.internalEngineError("Type mismatch for updateFuseTurns: expected .int, got \(change.newValue)")
            }
            guard activeFuses[fuseId] != nil else {
                throw ActionError.internalEngineError("Attempted to update turns for non-existent active fuse: \(fuseId)")
            }
            activeFuses[fuseId] = newTurns
        }

        changeHistory.append(change)
    }

    /// Validates that the `oldValue` in a `StateChange` matches the current state.
    private func validateOldValue(for change: StateChange) throws {
        guard let expectedOldValue = change.oldValue else { return }
        let currentValue: StateValue?

        switch change.propertyKey {
        // Item Properties
        case .itemParent:
            guard case .item(let id) = change.entityId else { throw ActionError.internalEngineError("Validation: Invalid entity ID for itemParent") }
            currentValue = items[id].map { .parentEntity($0.parent) }
        case .itemProperties:
             guard case .item(let id) = change.entityId else { throw ActionError.internalEngineError("Validation: Invalid entity ID for itemProperties") }
             currentValue = items[id].map { .itemProperties($0.properties) } // Added back
        case .itemSize:
            guard case .item(let id) = change.entityId else { throw ActionError.internalEngineError("Validation: Invalid entity ID for itemSize") }
            currentValue = items[id].map { .int($0.size) }
        case .itemValue:
             guard case .item(let id) = change.entityId else { throw ActionError.internalEngineError("Validation: Invalid entity ID for itemValue") }
             print("WARN: Old value validation skipped for itemValue (property not implemented)."); currentValue = nil

        // Location Properties
        case .locationName:
            guard case .location(let id) = change.entityId else { throw ActionError.internalEngineError("Validation: Invalid entity ID for locationName") }
            currentValue = locations[id].map { .string($0.name) }
        case .locationDescription:
             // Cannot validate description as it's handler-based
             currentValue = nil
        case .locationProperties:
            guard case .location(let id) = change.entityId else { throw ActionError.internalEngineError("Validation: Invalid entity ID for locationProperties") }
            currentValue = locations[id].map { .locationPropertySet($0.properties) }
        case .locationExits:
            guard case .location(let id) = change.entityId else { throw ActionError.internalEngineError("Validation: Invalid entity ID for locationExits") }
            currentValue = locations[id].map { .exitMap($0.exits) }

        // Player Properties
        case .playerScore:
            guard change.entityId == .player else { throw ActionError.internalEngineError("Validation: Invalid entity ID for playerScore") }
            currentValue = .int(player.score)
        case .playerMoves:
            guard change.entityId == .player else { throw ActionError.internalEngineError("Validation: Invalid entity ID for playerMoves") }
            currentValue = .int(player.moves)
        case .playerInventoryLimit:
            guard change.entityId == .player else { throw ActionError.internalEngineError("Validation: Invalid entity ID for playerInventoryLimit") }
            currentValue = .int(player.carryingCapacity)
        case .playerLocation:
            guard change.entityId == .player else { throw ActionError.internalEngineError("Validation: Invalid entity ID for playerLocation") }
            currentValue = .locationID(player.currentLocationID)
        case .playerStrength, .playerHealth:
             print("WARN: Old value validation skipped..."); currentValue = nil

        // Global/Misc Properties
        case .flag(let key):
            guard change.entityId == .global else { throw ActionError.internalEngineError("Validation: Invalid entity ID for flag") }
            currentValue = flags[key].map { .bool($0) } ?? .bool(false)
        case .pronounReference:
            // This key is primarily for GameEngine helpers; direct validation might be complex.
            // Assume GameEngine handles it correctly for now.
            print("WARN: Old value validation skipped for pronounReference."); currentValue = nil
        case .gameSpecificState(let key):
            guard change.entityId == .global else { throw ActionError.internalEngineError("Validation: Invalid entity ID for gameSpecificState") }
            currentValue = gameSpecificState[key]

        // Fuse & Daemon cases - These are typically managed via GameEngine helpers,
        // direct validation here might be redundant or overly complex.
        // If needed, they would require checking activeFuses/activeDaemons dictionaries.
        // If needed, they would require checking activeFuses/activeDaemons dictionaries.
        case .addActiveFuse, .removeActiveFuse, .updateFuseTurns, .addActiveDaemon, .removeActiveDaemon:
             print("WARN: Old value validation skipped for Fuse/Daemon StatePropertyKeys.")
             currentValue = nil
        }

        if currentValue != expectedOldValue {
            throw ActionError.stateValidationFailed(change: change, actualOldValue: currentValue)
        }
    }

    // MARK: - Codable Conformance (Ensure it matches actual property types)

    enum CodingKeys: String, CodingKey {
        case items, locations, flags, player, activeFuses, activeDaemons, pronouns, gameSpecificState, changeHistory, vocabulary
        // Removed gameID as it wasn't in the read_file output's property list
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        items = try container.decode([ItemID: Item].self, forKey: .items)
        locations = try container.decode([LocationID: Location].self, forKey: .locations)
        flags = try container.decodeIfPresent([String: Bool].self, forKey: .flags) ?? [:]
        player = try container.decode(Player.self, forKey: .player)
        activeFuses = try container.decodeIfPresent([Fuse.ID: Int].self, forKey: .activeFuses) ?? [:]
        activeDaemons = try container.decodeIfPresent(Set<DaemonID>.self, forKey: .activeDaemons) ?? []
        pronouns = try container.decodeIfPresent([String: Set<ItemID>].self, forKey: .pronouns) ?? [:]
        gameSpecificState = try container.decodeIfPresent([GameStateKey: StateValue].self, forKey: .gameSpecificState) ?? [:] // Keep AnyCodable
        changeHistory = try container.decodeIfPresent([StateChange].self, forKey: .changeHistory) ?? []
        vocabulary = try container.decode(Vocabulary.self, forKey: .vocabulary)
        // Removed gameID decoding
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(items, forKey: .items)
        try container.encode(locations, forKey: .locations)
        try container.encodeIfPresent(flags.isEmpty ? nil : flags, forKey: .flags)
        try container.encode(player, forKey: .player)
        try container.encodeIfPresent(activeFuses.isEmpty ? nil : activeFuses, forKey: .activeFuses)
        try container.encodeIfPresent(activeDaemons.isEmpty ? nil : activeDaemons, forKey: .activeDaemons)
        try container.encodeIfPresent(pronouns.isEmpty ? nil : pronouns, forKey: .pronouns)
        try container.encodeIfPresent(gameSpecificState.isEmpty ? nil : gameSpecificState, forKey: .gameSpecificState) // Keep AnyCodable
        try container.encodeIfPresent(changeHistory.isEmpty ? nil : changeHistory, forKey: .changeHistory)
        try container.encode(vocabulary, forKey: .vocabulary)
        // Removed gameID encoding
    }
}
