import Foundation

/// Represents a single, atomic proposed or applied modification to the game state.
///
/// `StateChange` is now an enum that precisely captures each type of state modification
/// with type-safe associated values. This eliminates the need for `PropertyKey` and
/// `StateValue` wrappers while providing a cleaner, more maintainable API.
///
/// Each change type embeds its creation timestamp for chronological ordering in the
/// game state history.
public enum StateChange: Codable, Sendable {

    // MARK: - Item State Changes

    /// Moves an item to a new parent entity (location, player, or container).
    case moveItem(
        id: ItemID,
        to: ParentEntity
    )

    /// Sets a dynamic property on an item.
    case setItemProperty(
        id: ItemID,
        property: ItemPropertyID,
        value: StateValue
    )

    /// Updates an item's primary name.
    case setItemName(
        id: ItemID,
        name: String
    )

    /// Updates the descriptive adjectives associated with an item.
    case setItemAdjectives(
        id: ItemID,
        adjectives: [String]
    )

    /// Sets the carrying capacity of a container item.
    case setItemCapacity(
        id: ItemID,
        capacity: Int
    )

    /// Updates an item's size or weight value.
    case setItemSize(
        id: ItemID,
        size: Int
    )

    /// Updates alternative nouns by which an item can be referenced.
    case setItemSynonyms(
        id: ItemID,
        synonyms: [String]
    )

    /// Sets the numerical value of an item (for scoring or economy).
    case setItemValue(
        id: ItemID,
        value: Int
    )

    // MARK: - Location State Changes

    /// Sets a dynamic property on a location.
    case setLocationProperty(
        id: LocationID,
        property: LocationPropertyID,
        value: StateValue
    )

    /// Updates a location's description text.
    case setLocationDescription(
        id: LocationID,
        description: String
    )

    /// Updates a location's primary name.
    case setLocationName(
        id: LocationID,
        name: String
    )

    /// Updates the available exits from a location.
    case setLocationExits(
        id: LocationID,
        exits: Set<Exit>
    )

    // MARK: - Player State Changes

    /// Moves the player to a specific location.
    case movePlayer(to: LocationID)

    /// Moves the player to a parent entity (typically a location, but supports containers).
    case movePlayerTo(parent: ParentEntity)

    /// Sets the player's score to a specific value.
    case setPlayerScore(to: Int)

    /// Updates the player's character attributes (health, stats, etc.).
    case setPlayerAttributes(attributes: CharacterSheet)

    /// Increments the player's move counter by one.
    case incrementPlayerMoves

    // MARK: - Global State Changes

    /// Sets a global boolean flag to `true`.
    case setFlag(GlobalID)

    /// Sets a global boolean flag to `false`.
    case clearFlag(GlobalID)

    /// Sets a global boolean value.
    case setGlobalBool(
        id: GlobalID,
        value: Bool
    )

    /// Sets a global integer value.
    case setGlobalInt(
        id: GlobalID,
        value: Int
    )

    /// Sets a global string value.
    case setGlobalString(
        id: GlobalID,
        value: String
    )

    /// Sets a global ItemID reference.
    case setGlobalItemID(
        id: GlobalID,
        value: ItemID
    )

    /// Sets a global LocationID reference.
    case setGlobalLocationID(
        id: GlobalID,
        value: LocationID
    )

    /// Sets a global state value of any supported type.
    case setGlobalState(
        id: GlobalID,
        value: StateValue
    )

    /// Removes a global state value entirely.
    case clearGlobalState(id: GlobalID)

    /// Updates the current combat state.
    case setCombatState(CombatState?)

    // MARK: - Timed Events (Fuses & Daemons)

    /// Activates a daemon for periodic background processing.
    case addActiveDaemon(daemonID: DaemonID)

    /// Deactivates a currently running daemon.
    case removeActiveDaemon(daemonID: DaemonID)

    /// Starts a fuse with the specified initial state.
    case addActiveFuse(fuseID: FuseID, state: FuseState)

    /// Stops and removes an active fuse.
    case removeActiveFuse(fuseID: FuseID)

    /// Updates the remaining turns for an active fuse.
    case updateFuseTurns(fuseID: FuseID, turns: Int)
}

extension StateChange: CustomStringConvertible {
    public var description: String {
        switch self {
        case .moveItem(let id, let parent):
            ".moveItem(id: \(id), to: \(parent))"
        case .setItemProperty(let id, let property, let value):
            ".setItemProperty(id: \(id), property: \(property), value: \(value))"
        case .setItemName(let id, let name):
            ".setItemName(id: \(id), name: \"\(name)\")"
        case .setItemAdjectives(let id, let adjectives):
            ".setItemAdjectives(id: \(id), adjectives: \(adjectives))"
        case .setItemCapacity(let id, let capacity):
            ".setItemCapacity(id: \(id), capacity: \(capacity))"
        case .setItemSize(let id, let size):
            ".setItemSize(id: \(id), size: \(size))"
        case .setItemSynonyms(let id, let synonyms):
            ".setItemSynonyms(id: \(id), synonyms: \(synonyms))"
        case .setItemValue(let id, let value):
            ".setItemValue(id: \(id), value: \(value))"
        case .setLocationProperty(let id, let property, let value):
            ".setLocationProperty(id: \(id), property: \(property), value: \(value))"
        case .setLocationDescription(let id, let description):
            ".setLocationDescription(id: \(id), description: \"\(description)\")"
        case .setLocationName(let id, let name):
            ".setLocationName(id: \(id), name: \"\(name)\")"
        case .setLocationExits(let id, let exits):
            ".setLocationExits(id: \(id), exits: \(exits))"
        case .movePlayer(let locationID):
            ".movePlayer(to: \(locationID))"
        case .movePlayerTo(let parent):
            ".movePlayerTo(parent: \(parent))"
        case .setPlayerScore(let score):
            ".setPlayerScore(to: \(score))"
        case .setPlayerAttributes(let attributes):
            ".setPlayerAttributes(\(attributes))"
        case .incrementPlayerMoves:
            ".incrementPlayerMoves()"
        case .setFlag(let id):
            ".setFlag(\(id))"
        case .clearFlag(let id):
            ".clearFlag(\(id))"
        case .setGlobalBool(let id, let value):
            ".setGlobalBool(id: \(id), value: \(value))"
        case .setGlobalInt(let id, let value):
            ".setGlobalInt(id: \(id), value: \(value))"
        case .setGlobalString(let id, let value):
            ".setGlobalString(id: \(id), value: \"\(value)\")"
        case .setGlobalItemID(let id, let value):
            ".setGlobalItemID(id: \(id), value: \(value))"
        case .setGlobalLocationID(let id, let value):
            ".setGlobalLocationID(id: \(id), value: \(value))"
        case .setGlobalState(let id, let value):
            ".setGlobalState(id: \(id), value: \(value))"
        case .clearGlobalState(let id):
            ".clearGlobalState(id: \(id))"
        case .setCombatState(let state):
            ".setCombatState(\(String(describing: state)))"
        case .addActiveDaemon(let daemonID):
            ".addActiveDaemon(daemonID: \(daemonID))"
        case .removeActiveDaemon(let daemonID):
            ".removeActiveDaemon(daemonID: \(daemonID))"
        case .addActiveFuse(let fuseID, let fuseState):
            ".addActiveFuse(fuseID: \(fuseID), state: \(fuseState))"
        case .removeActiveFuse(let fuseID):
            ".removeActiveFuse(fuseID: \(fuseID))"
        case .updateFuseTurns(let fuseID, let turns):
            ".updateFuseTurns(fuseID: \(fuseID), turns: \(turns))"
        }
    }
}

extension StateChange: Equatable {
    public static func == (lhs: StateChange, rhs: StateChange) -> Bool {
        switch (lhs, rhs) {
        case (.moveItem(let lhsId, let lhsParent), .moveItem(let rhsId, let rhsParent)):
            return lhsId == rhsId && lhsParent == rhsParent
        case (
            .setItemProperty(let lhsId, let lhsProp, let lhsValue),
            .setItemProperty(let rhsId, let rhsProp, let rhsValue)
        ):
            return lhsId == rhsId && lhsProp == rhsProp && lhsValue == rhsValue
        case (.setItemName(let lhsId, let lhsName), .setItemName(let rhsId, let rhsName)):
            return lhsId == rhsId && lhsName == rhsName
        case (
            .setItemAdjectives(let lhsId, let lhsAdj),
            .setItemAdjectives(let rhsId, let rhsAdj)
        ):
            return lhsId == rhsId && lhsAdj == rhsAdj
        case (
            .setItemCapacity(let lhsId, let lhsCap), .setItemCapacity(let rhsId, let rhsCap)
        ):
            return lhsId == rhsId && lhsCap == rhsCap
        case (.setItemSize(let lhsId, let lhsSize), .setItemSize(let rhsId, let rhsSize)):
            return lhsId == rhsId && lhsSize == rhsSize
        case (
            .setItemSynonyms(let lhsId, let lhsSyn), .setItemSynonyms(let rhsId, let rhsSyn)
        ):
            return lhsId == rhsId && lhsSyn == rhsSyn
        case (.setItemValue(let lhsId, let lhsValue), .setItemValue(let rhsId, let rhsValue)):
            return lhsId == rhsId && lhsValue == rhsValue
        case (
            .setLocationProperty(let lhsId, let lhsProp, let lhsValue),
            .setLocationProperty(let rhsId, let rhsProp, let rhsValue)
        ):
            return lhsId == rhsId && lhsProp == rhsProp && lhsValue == rhsValue
        case (
            .setLocationDescription(let lhsId, let lhsDesc),
            .setLocationDescription(let rhsId, let rhsDesc)
        ):
            return lhsId == rhsId && lhsDesc == rhsDesc
        case (
            .setLocationName(let lhsId, let lhsName), .setLocationName(let rhsId, let rhsName)
        ):
            return lhsId == rhsId && lhsName == rhsName
        case (
            .setLocationExits(let lhsId, let lhsExits),
            .setLocationExits(let rhsId, let rhsExits)
        ):
            return lhsId == rhsId && lhsExits == rhsExits
        case (.movePlayer(let lhsLoc), .movePlayer(let rhsLoc)):
            return lhsLoc == rhsLoc
        case (.movePlayerTo(let lhsParent), .movePlayerTo(let rhsParent)):
            return lhsParent == rhsParent
        case (.setPlayerScore(let lhsScore), .setPlayerScore(let rhsScore)):
            return lhsScore == rhsScore
        case (.setPlayerAttributes(let lhsAttrs), .setPlayerAttributes(let rhsAttrs)):
            return lhsAttrs == rhsAttrs
        case (.incrementPlayerMoves, .incrementPlayerMoves):
            return true
        case (.setFlag(let lhsId), .setFlag(let rhsId)):
            return lhsId == rhsId
        case (.clearFlag(let lhsId), .clearFlag(let rhsId)):
            return lhsId == rhsId
        case (
            .setGlobalBool(let lhsId, let lhsValue), .setGlobalBool(let rhsId, let rhsValue)
        ):
            return lhsId == rhsId && lhsValue == rhsValue
        case (.setGlobalInt(let lhsId, let lhsValue), .setGlobalInt(let rhsId, let rhsValue)):
            return lhsId == rhsId && lhsValue == rhsValue
        case (
            .setGlobalString(let lhsId, let lhsValue),
            .setGlobalString(let rhsId, let rhsValue)
        ):
            return lhsId == rhsId && lhsValue == rhsValue
        case (
            .setGlobalItemID(let lhsId, let lhsValue),
            .setGlobalItemID(let rhsId, let rhsValue)
        ):
            return lhsId == rhsId && lhsValue == rhsValue
        case (
            .setGlobalLocationID(let lhsId, let lhsValue),
            .setGlobalLocationID(let rhsId, let rhsValue)
        ):
            return lhsId == rhsId && lhsValue == rhsValue
        case (
            .setGlobalState(let lhsId, let lhsValue), .setGlobalState(let rhsId, let rhsValue)
        ):
            return lhsId == rhsId && lhsValue == rhsValue
        case (.clearGlobalState(let lhsId), .clearGlobalState(let rhsId)):
            return lhsId == rhsId
        case (.setCombatState(let lhsState), .setCombatState(let rhsState)):
            return lhsState == rhsState
        case (.addActiveDaemon(let lhsId), .addActiveDaemon(let rhsId)):
            return lhsId == rhsId
        case (.removeActiveDaemon(let lhsId), .removeActiveDaemon(let rhsId)):
            return lhsId == rhsId
        case (
            .addActiveFuse(let lhsId, let lhsState), .addActiveFuse(let rhsId, let rhsState)
        ):
            return lhsId == rhsId && lhsState == rhsState
        case (.removeActiveFuse(let lhsId), .removeActiveFuse(let rhsId)):
            return lhsId == rhsId
        case (
            .updateFuseTurns(let lhsId, let lhsTurns),
            .updateFuseTurns(let rhsId, let rhsTurns)
        ):
            return lhsId == rhsId && lhsTurns == rhsTurns

        default:
            return false
        }
    }
}
