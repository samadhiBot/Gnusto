import Foundation

// MARK: - Convenience Accessors

extension LocationProxy {
    /// Retrieves all items that are physically in a location, regardless of lighting or visibility.
    ///
    /// This method is used when you need to know about all items that exist in a location,
    /// regardless of whether the player can see them (due to darkness, invisibility, etc.).
    /// This is useful for systems like the sword glow daemon that need to detect monsters
    /// even in dark locations.
    public var allItems: [ItemProxy] {
        get async {
            var allItems = [ItemProxy]()
            let directContents = await items
            for item in directContents {
                allItems.append(item)
                await allItems.append(contentsOf: item.allContents)
            }
            return allItems
        }
    }

    /// Gets the location's description text.
    ///
    /// Returns the location's description property if set, otherwise returns a default
    /// "undescribed location" message. This is the main descriptive text shown when
    /// the player looks around or enters the location.
    public var description: String {
        get async {
            if let description = await property(.description)?.toString {
                description
            } else {
                engine.messenger.undescribedLocation()
            }
        }
    }

    /// Gets the location's first description text.
    ///
    /// The first description is shown the first time the player visits a location,
    /// typically providing more detailed or atmospheric text than the standard description.
    /// Returns `nil` if no first description is set.
    public var firstDescription: String? {
        get async {
            await property(.firstDescription)?.toString
        }
    }

    /// A dictionary mapping directions to their corresponding exits from this location.
    ///
    /// Each direction (north, south, east, west, etc.) maps to an `Exit` object that
    /// describes where that direction leads and any travel conditions. Empty dictionary
    /// indicates no exits are available from this location.
    public var exits: Set<Exit> {
        get async {
            await property(.exits)?.toExits ?? []
        }
    }

    /// Checks if a specific boolean property (flag) is set to `true` on this location.
    ///
    /// - Parameter locationPropertyID: The `LocationPropertyID` of the flag to check.
    /// - Returns: `true` if the flag is set to `true`, `false` otherwise.
    public func hasFlag(_ locationPropertyID: LocationPropertyID) async -> Bool {
        await property(locationPropertyID)?.toBool ?? false
    }

    /// Checks if this location has any of the specified flags set to `true`.
    ///
    /// This is a convenience method for checking if at least one of multiple flags is set.
    ///
    /// - Parameter locationPropertyIDs: Flags to check, at least one must be `true`.
    /// - Returns: `true` if any of the specified flags are set, `false` if none are set.
    public func hasFlags(any locationPropertyIDs: LocationPropertyID...) async -> Bool {
        for locationPropertyID in locationPropertyIDs where await hasFlag(locationPropertyID) {
            return true
        }
        return false
    }

    /// Whether this location is currently lit (considering both inherent lighting and items).
    public var isLit: Bool {
        get async {
            if await hasFlags(any: .inherentlyLit, .isLit) { return true }

            let locationItems = await items
            let playerInventory = await engine.player.inventory

            return await (playerInventory + locationItems).asyncContains {
                await $0.isProvidingLight
            }
        }
    }

    /// Retrieves all items that are directly present in this location.
    ///
    /// Returns all items whose parent is this location, without considering lighting
    /// or visibility. This includes items that may be invisible or in darkness.
    /// Does not include items inside containers within the location.
    public var items: [ItemProxy] {
        get async {
            await engine.gameState.items.values.asyncCompactMap { item -> ItemProxy? in
                let proxy = await engine.item(item.id)
                let parent = await proxy.parent
                guard
                    case .location(let itemLocation) = parent,
                    itemLocation.id == location.id
                else {
                    return nil
                }
                return proxy
            }
        }
    }

    /// A set of item IDs that are considered "globally" present or relevant to this location.
    /// Corresponds to ZIL's `GLOBAL` objects scoped to rooms.
    public var localGlobals: Set<ItemID> {
        get async {
            await property(.localGlobals)?.toItemIDs ?? []
        }
    }

    /// The display name of the location.
    /// Corresponds to the ZIL `DESC` or room name property.
    public var name: String {
        get async {
            await property(.name)?.toString ?? id.rawValue
        }
    }

    /// Retrieves all items that can be seen in a location, ignoring darkness.
    ///
    /// This method is used when you need to know which items can be seen in a location,
    /// regardless of whether there is adequate light.
    public var visibleItems: [ItemProxy] {
        get async {
            var allItems = [ItemProxy]()
            let directContents = await items
            for item in directContents {
                if await item.hasFlags(any: .isInvisible, .omitDescription) { continue }
                allItems.append(item)
                if await item.contentsAreVisible {
                    allItems.append(
                        contentsOf: await item.visibleItems
                    )
                }
            }
            return allItems.sorted()
        }
    }

    /// The location's name with a definite article ("the") prepended.
    ///
    /// Returns the location name with "the" prepended, unless the location has the
    /// `.omitArticle` flag set. Used for natural language output when referring
    /// to the location in descriptions and messages.
    public var withDefiniteArticle: String {
        get async {
            let locationName = await name
            let omitArticle = await hasFlag(.omitArticle)

            return omitArticle ? locationName : engine.messenger.the(locationName)
        }
    }
}
