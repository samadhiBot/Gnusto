import Foundation

/// Uniquely identifies a specific piece of game state that can be dynamically read or modified.
///
/// You'll encounter `AttributeKey` when working with game logic that needs to query or
/// change the state of items, locations, the player, or global game properties. It acts as a
/// typed key to ensure that state modifications are precise and targeted.
///
/// For example, when an action results in an item changing its parent (e.g., the player picking
/// it up), an `AttributeKey.itemParent` would be used along with the new parent value.
public enum AttributeKey: Codable, Sendable, Hashable {
    // MARK: - Item Properties

    /// The set of descriptive adjectives associated with an item (e.g., "small", "brass").
    /// Modifying this affects how the item is described and can be referred to.
    case itemAdjectives

    /// The carrying capacity of an item, typically a container. This determines how much
    /// (e.g., by size or weight) the item can hold.
    case itemCapacity

    /// The primary name of an item (e.g., "lantern", "key").
    case itemName

    /// The current parent entity of an item, indicating where it is located (e.g., in a
    /// location, held by the player, or inside another item).
    case itemParent

    /// The size or weight of an item. This can be used in conjunction with `.itemCapacity`
    /// to determine if an item can fit into a container or be carried.
    case itemSize

    /// Alternative nouns or names by which an item can be referred.
    case itemSynonyms

    /// A numerical value associated with an item, which could represent its worth for scoring
    /// or its monetary value in a game with an economy.
    case itemValue

    // MARK: - Location Properties

    /// The textual description of a location that is shown to the player upon entering or
    /// looking around.
    case locationDescription

    /// The defined exits from a location, mapping `Direction`s to `Exit` information
    /// (like destination `LocationID`).
    case exits

    /// The primary name of a location (e.g., "West of House", "Forest Path").
    case locationName

    // MARK: - Custom Game-Defined Attributes

    /// A custom, game-defined attribute for an item.
    /// `AttributeID` is a unique identifier you define for game-specific item properties
    /// (e.g., an item's "magicCharge" or "fuelLevel").
    case itemAttribute(AttributeID)

    /// A custom, game-defined attribute for a location.
    /// `AttributeID` is a unique identifier you define for game-specific location properties
    /// (e.g., a location's "ambientLightLevel" or "hasMagicAura").
    case locationAttribute(AttributeID)

    // MARK: - Player Properties

    /// The player character's current health or hit points.
    case playerHealth

    /// The maximum number of items, or total size/weight of items, that the player
    /// can carry.
    case playerInventoryLimit

    /// The player character's current `LocationID`.
    case playerLocation

    /// The number of game turns or moves the player has taken.
    case playerMoves

    /// The player character's current score.
    case playerScore

    /// A numerical value representing the player character's strength, which might
    /// affect combat, carrying capacity, or other actions.
    case playerStrength

    // MARK: - Global Game State & Flags

    /// Sets a global boolean flag to `true`.
    /// `GlobalID` is a unique identifier you define for game-wide boolean states
    /// (e.g., "grueDefeated", "powerIsOn").
    case setFlag(_ id: GlobalID)

    /// Clears a global boolean flag, setting it to `false`.
    /// `GlobalID` is a unique identifier you define for game-wide boolean states.
    case clearFlag(_ id: GlobalID)

    /// A generic key for storing or retrieving a custom, game-defined global state value.
    /// `GlobalID` is a unique identifier you define for various global data points that
    /// don't fit the simple flag model. The associated value can be of any `Codable` type.
    case globalState(key: GlobalID)

    /// The `EntityReference` (e.g., an item, location, or the player) that a given
    /// pronoun (like "it", "them") currently refers to. This is managed by the parser
    /// and game engine.
    case pronounReference(pronoun: String)

    // MARK: - Timed Events (Fuses & Daemons)

    /// Activates a "daemon" – a piece of game logic that runs periodically in the background.
    /// `DaemonID` is a unique identifier you define for a specific daemon.
    case addActiveDaemon(daemonID: DaemonID)

    /// Starts a "fuse" – a timed event that triggers an action after a specific number of turns.
    /// `FuseID` is a unique identifier you define for a specific fuse.
    /// `initialTurns` is the number of game turns until the fuse "burns out".
    case addActiveFuse(fuseID: FuseID, initialTurns: Int)

    /// Deactivates a currently running daemon.
    /// `DaemonID` is the unique identifier of the daemon to remove.
    case removeActiveDaemon(daemonID: DaemonID)

    /// Stops and removes an active fuse before it naturally "burns out".
    /// `FuseID` is the unique identifier of the fuse to remove.
    case removeActiveFuse(fuseID: FuseID)

    /// Updates the remaining turns for an active fuse. This can be used to extend or
    /// shorten its duration. `FuseID` is the unique identifier of the fuse to update.
    /// The associated value should be the new number of turns remaining.
    case updateFuseTurns(fuseID: FuseID)
}

// MARK: - CustomStringConvertible
extension AttributeKey: CustomStringConvertible {
    public var description: String {
        switch self {
        case .addActiveDaemon(let id): "addActiveDaemon(\(id))"
        case .addActiveFuse(let id, _): "addActiveFuse(\(id))"
        case .itemAttribute(let key): "itemAttribute(\(key.rawValue))"
        case .setFlag(let id): "setFlag(\(id.rawValue))"
        case .clearFlag(let id): "clearFlag(\(id.rawValue))"
        case .globalState(let key): "globalState(\(key.rawValue))"
        case .itemAdjectives: "itemAdjectives"
        case .itemCapacity: "itemCapacity"
        case .itemName: "itemName"
        case .itemParent: "itemParent"
        case .itemSize: "itemSize"
        case .itemSynonyms: "itemSynonyms"
        case .itemValue: "itemValue"
        case .locationDescription: "locationDescription"
        case .exits: "exits"
        case .locationName: "locationName"
        case .locationAttribute(let key): "locationAttribute(\(key.rawValue))"
        case .playerHealth: "playerHealth"
        case .playerInventoryLimit: "playerInventoryLimit"
        case .playerLocation: "playerLocation"
        case .playerMoves: "playerMoves"
        case .playerScore: "playerScore"
        case .playerStrength: "playerStrength"
        case .pronounReference(let p): "pronounReference(\(p))"
        case .removeActiveDaemon(let id): "removeActiveDaemon(\(id))"
        case .removeActiveFuse(let id): "removeActiveFuse(\(id))"
        case .updateFuseTurns(let id): "updateFuseTurns(\(id))"
        }
    }
}
