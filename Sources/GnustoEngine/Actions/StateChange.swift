import Foundation

/// Represents a single, atomic proposed or applied modification to the game state.
///
/// `StateChange` is now an enum that precisely captures each type of state modification
/// with type-safe associated values. This eliminates the need for `PropertyKey` and
/// `StateValue` wrappers while providing a cleaner, more maintainable API.
///
/// Each change type embeds its creation timestamp for chronological ordering in the
/// game state history.
public enum StateChange: Codable, Equatable, Sendable {
    /// Activates a daemon for periodic background processing with initial state.
    case addActiveDaemon(daemonID: DaemonID, daemonState: DaemonState)

    /// Starts a fuse with the specified initial state.
    case addActiveFuse(fuseID: FuseID, state: FuseState)

    /// Sets a global boolean flag to `false`.
    case clearFlag(GlobalID)

    /// Removes a global state value entirely.
    case clearGlobalState(id: GlobalID)

    /// Increments the player's move counter by one.
    case incrementPlayerMoves

    /// Moves an item to a new parent entity (location, player, or container).
    case moveItem(id: ItemID, to: ParentEntity)

    /// Moves the player to a specific location.
    case movePlayer(to: LocationID)

    /// Moves the player to a parent entity (typically a location, but supports containers).
    case movePlayerTo(parent: ParentEntity)

    /// Deactivates a currently running daemon.
    case removeActiveDaemon(daemonID: DaemonID)

    /// Stops and removes an active fuse.
    case removeActiveFuse(fuseID: FuseID)

    /// Requests the GameEngine to quit the game.
    case requestGameQuit

    /// Requests the GameEngine to restart the game.
    case requestGameRestart

    /// Updates the current combat state.
    case setCombatState(CombatState?)

    /// Sets a global boolean flag to `true`.
    case setFlag(GlobalID)

    /// Sets a global boolean value.
    case setGlobalBool(id: GlobalID, value: Bool)

    /// Sets a global codable value.
    case setGlobalCodable(id: GlobalID, value: AnyCodableSendable)

    /// Sets a global integer value.
    case setGlobalInt(id: GlobalID, value: Int)

    /// Sets a global ItemID reference.
    case setGlobalItemID(id: GlobalID, value: ItemID)

    /// Sets a global LocationID reference.
    case setGlobalLocationID(id: GlobalID, value: LocationID)

    /// Sets a global state value of any supported type.
    case setGlobalState(id: GlobalID, value: StateValue)

    /// Sets a global string value.
    case setGlobalString(id: GlobalID, value: String)

    /// Updates the descriptive adjectives associated with an item.
    case setItemAdjectives(id: ItemID, adjectives: [String])

    /// Sets the carrying capacity of a container item.
    case setItemCapacity(id: ItemID, capacity: Int)

    /// Updates an item's primary name.
    case setItemName(id: ItemID, name: String)

    /// Sets a dynamic property on an item.
    case setItemProperty(id: ItemID, property: ItemPropertyID, value: StateValue)

    /// Updates an item's size or weight value.
    case setItemSize(id: ItemID, size: Int)

    /// Updates alternative nouns by which an item can be referenced.
    case setItemSynonyms(id: ItemID, synonyms: [String])

    /// Sets the numerical value of an item (for scoring or economy).
    case setItemValue(id: ItemID, value: Int)

    /// Updates a location's description text.
    case setLocationDescription(id: LocationID, description: String)

    /// Updates the available exits from a location.
    case setLocationExits(id: LocationID, exits: Set<Exit>)

    /// Updates a location's primary name.
    case setLocationName(id: LocationID, name: String)

    /// Sets a dynamic property on a location.
    case setLocationProperty(id: LocationID, property: LocationPropertyID, value: StateValue)

    /// Updates the player's character attributes (health, stats, etc.).
    case setPlayerAttributes(attributes: CharacterSheet)

    /// Sets the player's score to a specific value.
    case setPlayerScore(to: Int)

    /// Updates the state of an active daemon.
    case updateDaemonState(daemonID: DaemonID, daemonState: DaemonState)

    /// Updates the remaining turns for an active fuse.
    case updateFuseTurns(fuseID: FuseID, turns: Int)
}
