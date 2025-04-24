import Foundation

/// Represents the complete state of the game world at a given point in time.
public struct GameState: Codable {
    /// Active fuses and their remaining turns.
    public var activeFuses: [Fuse.ID: Int]

    /// Set tracking the IDs of currently active daemons.
    public var activeDaemons: Set<DaemonID>

    /// Current value of global variables or flags (e.g., [FlagID: FlagValue]).
    /// Using String for key flexibility, might refine later (e.g., `FlagID` type).
    public var flags: [String: Bool]

    /// A dictionary mapping item IDs to their current state (references to Item instances).
    /// This is the single source of truth for all item data, including their parentage.
    public var items: [ItemID: Item]

    /// A dictionary mapping location IDs to their current state (references to Location instances).
    public var locations: [LocationID: Location]

    /// The current state of the player.
    public var player: Player

    /// Pronoun resolution state (e.g., what does "it" or "them" currently refer to?).
    /// Maps pronoun string (lowercase) to the set of ItemIDs it represents.
    public var pronouns: [String: Set<ItemID>]

    /// The game's vocabulary.
    public let vocabulary: Vocabulary

    /// Optional dictionary for storing arbitrary game-specific state (counters, quest flags, etc.).
    /// Use keys prefixed with game ID (e.g., "cod_counter") to avoid collisions if engine supports multiple games.
    public var gameSpecificState: [String: AnyCodable]
}

extension GameState {
    //    // --- Initialization ---
    //
    //    /// Internal initializer for Codable and factory method.
    //    init(
    //        locations: [LocationID: Location],
    //        items: [ItemID: Item],
    //        player: Player,
    //        vocabulary: Vocabulary,
    //        flags: [String: Bool] = [:],
    //        pronouns: [String: Set<ItemID>] = [:],
    //        activeFuses: [Fuse.ID: Int] = [:],
    //        activeDaemons: Set<DaemonID> = [],
    //        gameSpecificState: [String: AnyCodable] = [:]
    //    ) {
    //        self.activeDaemons = activeDaemons
    //        self.activeFuses = activeFuses
    //        self.flags = flags
    //        self.gameSpecificState = gameSpecificState
    //        self.items = items
    //        self.locations = locations
    //        self.player = player
    //        self.pronouns = pronouns
    //        self.vocabulary = vocabulary
    //    }

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
        gameSpecificState: [String: AnyCodable] = [:]
    ) {
        self.activeDaemons = activeDaemons
        self.activeFuses = activeFuses
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
        gameSpecificState: [String: AnyCodable] = [:]
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

//    /// Creates an initial game state, typically loaded from game data files.
//    /// Sets the initial parent for each item based on starting locations and inventory.
//    /// - Parameters:
//    ///   - locations: An array of initial `Location` objects.
//    ///   - items: An array of initial `Item` objects (their `parent` property will be overwritten).
//    ///   - player: The initial `Player` state, including starting location.
//    ///   - vocabulary: The game's vocabulary.
//    ///   - inventory: IDs of items the player starts holding directly.
//    ///   - itemLocations: A dictionary mapping ItemID to the LocationID where it starts.
//    ///   - itemContainers: A dictionary mapping ItemID to the ItemID of the container/surface it starts in/on.
//    ///   - flags: Optional initial game flags.
//    ///   - pronouns: Optional initial pronoun states.
//    ///   - activeFuses: Optional initial active fuses.
//    ///   - activeDaemons: Optional initial active daemons.
//    ///   - gameSpecificState: Optional initial game-specific state data.
//    /// - Returns: A new `GameState` instance.
//    public static func initial(
//        locations: [Location],
//        items: [Item],
//        player: Player,
//        vocabulary: Vocabulary,
//        inventory: Set<ItemID> = [],
//        itemLocations: [ItemID: LocationID] = [:],
//        itemContainers: [ItemID: ItemID] = [:],
//        flags: [String: Bool] = [:],
//        pronouns: [String: Set<ItemID>] = [:],
//        activeFuses: [Fuse.ID: Int] = [:],
//        activeDaemons: Set<DaemonID> = [],
//        gameSpecificState: [String: AnyCodable]? = nil) -> GameState
//    {
//        let locationDict = Dictionary(uniqueKeysWithValues: locations.map { ($0.id, $0) })
//        let itemDict = Dictionary(uniqueKeysWithValues: items.map { ($0.id, $0) })
//
//        // Set initial parent for each item
//        for itemID in itemDict.keys {
//            if inventory.contains(itemID) {
//                itemDict[itemID]?.parent = .player
//            } else if let locationID = itemLocations[itemID] {
//                itemDict[itemID]?.parent = .location(locationID)
//            } else if let containerID = itemContainers[itemID] {
//                itemDict[itemID]?.parent = .item(containerID)
//            } else {
//                // Item doesn't start in inventory, a location, or a container.
//                // It defaults to .nowhere (set by Item initializer)
//                // We could optionally check if it's a global in a location here, but
//                // globals might not have a parent in the same way.
//                // Let's assume globals are defined in Location.globals and don't need parent set here.
//            }
//        }
//
//        return GameState(
//            locations: locationDict,
//            items: itemDict,
//            player: player,
//            flags: flags,
//            pronouns: pronouns,
//            vocabulary: vocabulary,
//            activeFuses: activeFuses,
//            activeDaemons: activeDaemons,
//            gameSpecificState: gameSpecificState
//        )
//    }

// MARK: - Codable Conformance

extension GameState {
    // --- Codable Conformance ---
    // Explicit implementation needed due to dictionaries of classes

    enum CodingKeys: String, CodingKey {
        case activeFuses
        case activeDaemons
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

    // MARK: - State Mutation

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

    // MARK: - Convenience Accessors

    // ... existing accessors ...
}
