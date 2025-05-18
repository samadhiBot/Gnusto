/// Identifies the specific entity whose state is being changed.
public enum EntityID: Codable, Sendable, Hashable {
    /// Refers to a daemon via its unique ID.
    case daemon(DaemonID)

    /// Refers to a fuse via its unique ID.
    case fuse(FuseID)

    /// Refers to an item via its unique ID.
    case item(ItemID)

    /// Refers to a location via its unique ID.
    case location(LocationID)

    /// Refers to the player entity.
    case player

    /// Refers to global state not tied to a specific item or location (e.g., flags, pronouns).
    case global
}

extension EntityID {
    func daemonID() throws -> DaemonID {
        guard case .daemon(let daemonID) = self else {
            throw ActionResponse.internalEngineError("EntityID expected to be DaemonID, got: \(self)")
        }
        return daemonID
    }

    func fuseID() throws -> FuseID {
        guard case .fuse(let fuseID) = self else {
            throw ActionResponse.internalEngineError("EntityID expected to be FuseID, got: \(self)")
        }
        return fuseID
    }

    func itemID() throws -> ItemID {
        guard case .item(let itemID) = self else {
            throw ActionResponse.internalEngineError("EntityID expected to be ItemID, got: \(self)")
        }
        return itemID
    }

    func locationID() throws -> LocationID {
        guard case .location(let locationID) = self else {
            throw ActionResponse.internalEngineError("EntityID expected to be LocationID, got: \(self)")
        }
        return locationID
    }
}
