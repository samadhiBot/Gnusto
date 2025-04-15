import Foundation // Needed for Codable

/// Represents the complete state of the game world at a given point in time.
public struct GameState: Codable {

    // --- Stored Properties (Alphabetical) ---

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
    public var gameSpecificState: [String: AnyCodable]? // Using AnyCodable for Codable conformance

    // --- Initialization ---

    /// Internal initializer for Codable and factory method.
    /// Keeping this internal, use the static `initial` factory externally.
    init(locations: [LocationID: Location], items: [ItemID: Item], player: Player, flags: [String: Bool] = [:], pronouns: [String: Set<ItemID>] = [:], vocabulary: Vocabulary, gameSpecificState: [String: AnyCodable]? = nil) { // Added gameSpecificState
        self.locations = locations
        self.items = items
        self.player = player
        self.flags = flags
        self.pronouns = pronouns
        self.vocabulary = vocabulary
        self.gameSpecificState = gameSpecificState // Added assignment
    }

    /// Creates an initial game state, typically loaded from game data files.
    /// Sets the initial parent for each item based on starting locations and inventory.
    /// - Parameters:
    ///   - initialLocations: An array of initial `Location` objects.
    ///   - initialItems: An array of initial `Item` objects (their `parent` property will be overwritten).
    ///   - initialPlayer: The initial `Player` state, including starting location.
    ///   - vocabulary: The game's vocabulary.
    ///   - initialInventoryIDs: IDs of items the player starts holding directly.
    ///   - initialItemLocations: A dictionary mapping ItemID to the LocationID where it starts.
    ///   - initialItemContainers: A dictionary mapping ItemID to the ItemID of the container/surface it starts in/on.
    ///   - flags: Optional initial game flags.
    ///   - pronouns: Optional initial pronoun states.
    ///   - gameSpecificState: Optional initial game-specific state data.
    /// - Returns: A new `GameState` instance.
    public static func initial(
        initialLocations: [Location],
        initialItems: [Item],
        initialPlayer: Player,
        vocabulary: Vocabulary,
        initialInventoryIDs: Set<ItemID> = [],
        initialItemLocations: [ItemID: LocationID] = [:],
        initialItemContainers: [ItemID: ItemID] = [:],
        flags: [String: Bool] = [:],
        pronouns: [String: Set<ItemID>] = [:],
        gameSpecificState: [String: AnyCodable]? = nil) -> GameState
    {
        let locationDict = Dictionary(uniqueKeysWithValues: initialLocations.map { ($0.id, $0) })
        let itemDict = Dictionary(uniqueKeysWithValues: initialItems.map { ($0.id, $0) })

        // Set initial parent for each item
        for itemID in itemDict.keys {
            if initialInventoryIDs.contains(itemID) {
                itemDict[itemID]?.parent = .player
            } else if let locationID = initialItemLocations[itemID] {
                itemDict[itemID]?.parent = .location(locationID)
            } else if let containerID = initialItemContainers[itemID] {
                itemDict[itemID]?.parent = .item(containerID)
            } else {
                // Item doesn't start in inventory, a location, or a container.
                // It defaults to .nowhere (set by Item initializer)
                // We could optionally check if it's a global in a location here, but
                // globals might not have a parent in the same way.
                // Let's assume globals are defined in Location.globals and don't need parent set here.
            }
        }

        return GameState(locations: locationDict, items: itemDict, player: initialPlayer, flags: flags, pronouns: pronouns, vocabulary: vocabulary, gameSpecificState: gameSpecificState)
    }

    // --- Codable Conformance ---
    // Explicit implementation needed due to dictionaries of classes

    enum CodingKeys: String, CodingKey {
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

        flags = try container.decode([String: Bool].self, forKey: .flags)
        player = try container.decode(Player.self, forKey: .player)
        pronouns = try container.decode([String: Set<ItemID>].self, forKey: .pronouns)
        vocabulary = try container.decode(Vocabulary.self, forKey: .vocabulary)
        gameSpecificState = try container.decodeIfPresent([String: AnyCodable].self, forKey: .gameSpecificState) // Decode

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

        try container.encode(flags, forKey: .flags)
        try container.encode(player, forKey: .player)
        try container.encode(pronouns, forKey: .pronouns)
        try container.encode(vocabulary, forKey: .vocabulary)
        try container.encodeIfPresent(gameSpecificState, forKey: .gameSpecificState) // Encode

        // Encode locations and items as arrays
        try container.encode(Array(locations.values), forKey: .locations)
        try container.encode(Array(items.values), forKey: .items)
    }

    // MARK: - Computed Properties & Helpers

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
}
