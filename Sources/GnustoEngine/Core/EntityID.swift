/// Uniquely identifies a specific game entity (like an item, location, player, or a
/// timed event) whose state is being referenced or modified.
///
/// When a game action results in a change, `EntityID` is used within a `StateChange`
/// to specify exactly which entity is affected.
public enum EntityID: Codable, Sendable, Hashable {
    /// Refers to a daemon (a periodically executing game logic component) via its unique `DaemonID`.
    case daemon(DaemonID)

    /// Refers to a fuse (a timed event that triggers after a set number of turns) via its unique `FuseID`.
    case fuse(FuseID)

    /// Refers to an item in the game world via its unique `ItemID`.
    case item(ItemID)

    /// Refers to a location in the game world via its unique `LocationID`.
    case location(LocationID)

    /// Refers to the player character.
    case player

    /// Refers to global game state that isn't tied to a specific item, location, or character.
    /// This can include things like global flags, counters, or pronoun references.
    case global
}

extension EntityID {
    /// Attempts to retrieve the `DaemonID` if this `EntityID` is a `.daemon` case.
    ///
    /// - Returns: The `DaemonID` if the case matches.
    /// - Throws: `ActionResponse.internalEngineError` if this `EntityID` is not `.daemon`.
    ///   Handle this error appropriately if you are not certain of the `EntityID` type.
    func daemonID() throws -> DaemonID {
        guard case .daemon(let daemonID) = self else {
            throw ActionResponse.internalEngineError("EntityID expected to be DaemonID, got: \(self)")
        }
        return daemonID
    }

    /// Attempts to retrieve the `FuseID` if this `EntityID` is a `.fuse` case.
    ///
    /// - Returns: The `FuseID` if the case matches.
    /// - Throws: `ActionResponse.internalEngineError` if this `EntityID` is not `.fuse`.
    ///   Handle this error appropriately if you are not certain of the `EntityID` type.
    func fuseID() throws -> FuseID {
        guard case .fuse(let fuseID) = self else {
            throw ActionResponse.internalEngineError("EntityID expected to be FuseID, got: \(self)")
        }
        return fuseID
    }

    /// Attempts to retrieve the `ItemID` if this `EntityID` is an `.item` case.
    ///
    /// - Returns: The `ItemID` if the case matches.
    /// - Throws: `ActionResponse.internalEngineError` if this `EntityID` is not `.item`.
    ///   Handle this error appropriately if you are not certain of the `EntityID` type.
    func itemID() throws -> ItemID {
        guard case .item(let itemID) = self else {
            throw ActionResponse.internalEngineError("EntityID expected to be ItemID, got: \(self)")
        }
        return itemID
    }

    /// Attempts to retrieve the `LocationID` if this `EntityID` is a `.location` case.
    ///
    /// - Returns: The `LocationID` if the case matches.
    /// - Throws: `ActionResponse.internalEngineError` if this `EntityID` is not `.location`.
    ///   Handle this error appropriately if you are not certain of the `EntityID` type.
    func locationID() throws -> LocationID {
        guard case .location(let locationID) = self else {
            throw ActionResponse.internalEngineError("EntityID expected to be LocationID, got: \(self)")
        }
        return locationID
    }
}
