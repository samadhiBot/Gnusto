import Foundation

// swiftlint:disable file_length

// MARK: - Convenience Accessors

extension ItemProxy {
    /// A set of adjectives that can be used to describe or refer to the item.
    /// Corresponds to the ZIL `ADJECTIVE` property.
    public var adjectives: [String] {
        get async {
            await property(.adjectives)?.toStrings?.sorted() ?? []
        }
    }

    /// A randomly generated alias for the item using its adjectives and synonyms.
    ///
    /// Returns a string combining a random adjective from the item's adjectives property
    /// with a random synonym from the item's synonyms property. If either adjectives
    /// or synonyms are empty, or if no random elements can be selected, falls back
    /// to the item's name.
    ///
    /// This property is useful for generating varied descriptions of the same item
    /// or for creating alternative references in dynamic text generation.
    ///
    /// - Returns: A string in the format "{adjective} {synonym}" or the item's name if
    ///   adjectives or synonyms are unavailable.
    /// - Throws: Rethrows any errors from accessing the item's properties.
    public func alias(_ nameVariant: NameVariant? = nil) async -> String {
        let adjectives = await property(.adjectives)?.toStrings ?? []
        let synonyms = await property(.synonyms)?.toStrings ?? []
        let adjective = await engine.randomElement(in: adjectives)
        let synonym = await engine.randomElement(in: synonyms)
        let name = await name
        let aliasName =
            if let adjective, let synonym {
                await engine.randomElement(
                    in: ["\(adjective) \(synonym)", synonym, synonym]
                ) ?? name
            } else if synonyms.count > 1, let synonym {
                synonym
            } else {
                name
            }
        return if await hasFlag(.omitArticle) {
            aliasName
        } else {
            switch nameVariant {
            case .withDefiniteArticle:
                engine.messenger.the(aliasName)
            case .withIndefiniteArticle:
                aliasName.withIndefiniteArticle
            case .withPossessiveAdjective(for: let other):
                if let other {
                    "\(await other.classification.possessiveAdjective) \(aliasName)"
                } else {
                    engine.messenger.your(aliasName)
                }
            case nil: aliasName
            }
        }
    }

    /// Returns all items contained within this item, recursively.
    ///
    /// This includes items inside containers, and items inside containers within those containers, etc.
    public var allContents: [ItemProxy] {
        get async {
            var allItems = [ItemProxy]()
            let directContents = await contents
            for item in directContents {
                allItems.append(item)
                await allItems.append(contentsOf: item.allContents)
            }
            return allItems
        }
    }

    /// Calculates all exits available to this NPC based on the specified movement behavior.
    ///
    /// This method evaluates each exit from the NPC's current location and determines whether
    /// the NPC can pass through based on the movement behavior. Different behaviors allow
    /// varying levels of door and obstacle bypassing capabilities.
    ///
    /// - Parameter behavior: The movement behavior that determines accessibility:
    ///   - `.normal`: Standard door interactions (requires open doors)
    ///   - `.any`: Can pass through any exit, ignoring all obstacles
    ///   - `.closedDoors`: Can pass through closed but unlocked doors
    ///   - `.lockedDoors`: Can pass through any locked doors
    ///   - `.lockedDoorsUnlockedByKeys([ItemID])`: Can pass through locked doors
    ///     that can be unlocked by the specified keys
    /// - Returns: An array of `Exit` objects that the NPC can currently traverse.
    /// - Throws: An error if exit evaluation fails.
    public func availableExits(
        behavior: Exit.MovementBehavior = .normal
    ) async -> [Exit] {
        guard let currentLocation = await location else { return [] }

        return await currentLocation.exits.asyncFilter { exit in
            // Exits without destinations are permanently blocked
            guard let destinationID = exit.destinationID else {
                return behavior == .any
            }
            // Check if NPC is restricted to specific locations
            if let validLocations = await property(.validLocations)?.toLocationIDs {
                guard validLocations.contains(destinationID) else {
                    return false  // Destination not in valid locations
                }
            }
            // Handle exits without doors
            guard let doorID = exit.doorID else {
                // For exits without doors, check if there's a blocked message
                // unless movement behavior is .any (which ignores all obstacles)
                return behavior == .any || exit.blockedMessage == nil
            }
            // Handle exits with doors based on movement behavior
            let door = await engine.item(doorID)
            switch behavior {
            case .any:  // Can pass through any exit regardless of door state
                return true
            case .normal:  // Standard behavior: door must be open
                return await door.isOpen
            case .closedDoors:  // Can pass through closed doors if they're unlocked
                return await !door.hasFlag(.isLocked)
            case .lockedDoors:  // Can pass through any door, locked or unlocked
                return true
            case .lockedDoorsUnlockedByKeys(let keys):
                // Can pass through doors if open, or if locked and we have the right key
                if await door.isOpen { return true }
                if await door.hasFlag(.isLocked),
                    let lockKey = await door.property(.lockKey)?.toItemID
                {
                    return keys.contains(lockKey)
                }
                // If door is closed but not locked, can pass through
                return await !door.hasFlag(.isLocked)
            }
        }.sorted()
    }

    /// Whether this container can accept the given item (capacity check).
    ///
    /// This method checks if the container has enough remaining capacity to hold the specified item
    /// by comparing the container's current load plus the item's size against the container's capacity.
    /// A capacity of -1 indicates unlimited capacity.
    ///
    /// - Parameter otherItemID: The ID of the item to check if this container can hold.
    /// - Returns: `true` if the container can hold the item, `false` otherwise.
    public func canHold(_ otherItemID: ItemID) async -> Bool {
        let currentLoad = await self.currentLoad
        let capacity = await self.capacity
        let otherItemSize = await engine.item(otherItemID).size

        return capacity < 0 || (currentLoad + otherItemSize <= capacity)
    }

    /// The item's capacity for containing other items.
    ///
    /// This property determines the maximum total size of items that can be stored
    /// within this container. A capacity of -1 indicates unlimited capacity.
    /// Individual item sizes are summed against this capacity when determining
    /// if new items can be added to the container.
    ///
    /// Corresponds to the ZIL `CAPACITY` property. Defaults to 1000 if not specified.
    public var capacity: Int {
        get async {
            await property(.capacity)?.toInt ?? 1_000
        }
    }

    /// Returns all items contained directly within this container item.
    ///
    /// This does not include items inside containers within this container.
    /// Use `allContents` to get all items recursively.
    public var contents: [ItemProxy] {
        get async {
            await engine.gameState.items.values.asyncCompactMap { item -> ItemProxy? in
                let proxy = await engine.item(item.id)
                guard await proxy.parent.entity == .item(self.id) else { return nil }
                return proxy
            }
            .sorted()
        }
    }

    /// Whether the contents of this container are visible to observers.
    ///
    /// Contents are considered visible when players and other systems can see what's
    /// inside without having to explicitly open the container. This occurs when:
    /// - The item is a surface (items on surfaces are always visible)
    /// - The item is an open container (`.isOpen` flag is set)
    /// - The item is a transparent container (`.isTransparent` flag is set)
    /// - The container itself is not invisible (`.isInvisible` flag is not set)
    ///
    /// This property is used by room descriptions, inventory listings, and the `visibleContents`
    /// property to determine which contained items should be automatically described or listed.
    /// Non-container items always return `false`.
    public var contentsAreVisible: Bool {
        get async {
            if await isSurface { return true }
            guard await isContainer else { return false }
            return await hasFlags(any: .isOpen, .isTransparent, none: .isInvisible)
        }
    }

    /// The current load (total size of all contents) in this container.
    ///
    /// This calculates the sum of the `size` property of all items directly contained
    /// within this container. Used for capacity checking when adding new items.
    public var currentLoad: Int {
        get async {
            var load = 0
            for item in await self.contents {
                load += await item.size
            }
            return load
        }
    }

    /// Gets the item's description text.
    ///
    /// Returns the item's description property if set, otherwise returns a default
    /// "nothing special" message about the item. This is the text shown when the
    /// player examines the item.
    public var description: String {
        get async {
            if let description = await property(.description)?.toString {
                description
            } else {
                engine.messenger.nothingSpecialAbout(await withDefiniteArticle)
            }
        }
    }

    /// Gets the item's first description text.
    ///
    /// The first description is shown the first time the player encounters an item,
    /// before it has been touched or manipulated. Returns `nil` if the item has been
    /// touched, making the first description no longer applicable.
    public var firstDescription: String? {
        get async {
            guard
                await !isTouched,
                let firstDescription = await property(.firstDescription)?.toString,
                firstDescription.isNotEmpty
            else {
                return nil
            }
            return firstDescription
        }
    }

    /// Checks if a specific boolean property (flag) is set to `true` on this item.
    ///
    /// - Parameter itemPropertyID: The `ItemPropertyID` of the flag to check.
    /// - Returns: `true` if the flag is set to `true`, `false` otherwise.
    public func hasFlag(_ itemPropertyID: ItemPropertyID) async -> Bool {
        await property(itemPropertyID)?.toBool == true
    }

    /// Checks if this item meets all of the specified flag requirements.
    ///
    /// This is a convenience method for checking complex flag requirements with AND, OR,
    /// and NOT logic.
    ///
    /// - Parameters:
    ///   - anyPropertyIDs: Flags to check with OR logic - at least one must be `true`.
    ///   - allPropertyIDs: Flags to check with AND logic - all must be set to `true`.
    ///   - nonePropertyIDs: Flags to check with NOT logic - all must be `false` or unset.
    /// - Returns: `true` if all conditions are met (all `allPropertyIDs` are true,
    ///            none of `nonePropertyIDs` are true, and at least one of `anyPropertyIDs`
    ///            is true if any are specified), `false` otherwise.
    public func hasFlags(
        any anyPropertyIDs: ItemPropertyID...,
        all allPropertyIDs: ItemPropertyID...,
        none nonePropertyIDs: ItemPropertyID...
    ) async -> Bool {
        for itemPropertyID in allPropertyIDs where await !hasFlag(itemPropertyID) {
            return false
        }
        for itemPropertyID in nonePropertyIDs where await hasFlag(itemPropertyID) {
            return false
        }
        for itemPropertyID in anyPropertyIDs where await hasFlag(itemPropertyID) {
            return true
        }
        return anyPropertyIDs.isEmpty
    }

    /// Whether this item is in the same location as the player.
    ///
    /// Returns `true` if both the item and the player are currently in the same location.
    /// This is useful for determining if items are accessible to the player or for
    /// location-based game logic. Returns `false` if either the item or player has
    /// no location, or if they're in different locations.
    ///
    /// This check considers:
    /// - Direct location placement (item's parent is the location)
    /// - Local globals (item is listed in the location's scenery)
    /// - Items inside containers that are in the player's location will return `false`
    ///   unless the container itself is being checked.
    public var hasSameLocationAsPlayer: Bool {
        get async {
            if await playerIsHolding {
                return true
            }
            let playerLocation = await engine.player.location
            let itemLocation = await location

            // Check direct location match
            if itemLocation == playerLocation {
                return true
            }

            // Check if item is a local global of the player's location
            return await playerLocation.scenery.contains(id)
        }
    }

    /// Checks if this item is allowed to be in the specified location.
    ///
    /// This method determines whether the item can be placed in or moved to a given location
    /// based on the item's location restrictions. If the item has no location restrictions
    /// (no `.validLocations` property), it can be placed anywhere and returns `true`.
    ///
    /// Location restrictions are commonly used for NPCs that should only appear in certain
    /// areas, quest items that belong in specific locations, or environmental objects that
    /// have logical placement constraints.
    ///
    /// - Parameter locationID: The ID of the location to check accessibility for.
    /// - Returns: `true` if the item is allowed in the location, `false` if restricted.
    /// - Throws: Re-throws any errors from accessing the item's properties.
    public func isAllowed(in locationID: LocationID) async -> Bool {
        guard let restrictedLocations = await property(.validLocations)?.toLocationIDs else {
            return true  // No restrictions
        }
        return restrictedLocations.contains(locationID)
    }

    /// Whether this item is a container that can hold other items.
    ///
    /// Containers can have items placed inside them and have capacity limits.
    /// Use `isOpenable` or `isOpen` to check if the container can be opened/closed.
    public var isContainer: Bool {
        get async {
            await hasFlag(.isContainer)
        }
    }

    /// Whether this item is a door or door-like object.
    ///
    /// Returns `true` if the item has any door-related flags such as `.isOpen`,
    /// `.isOpenable`, `.isLocked`, or `.isLockable`. Doors typically connect
    /// locations and can be opened, closed, locked, or unlocked.
    public var isDoor: Bool {
        get async {
            await hasFlags(any: .isOpen, .isOpenable, .isLocked, .isLockable)
        }
    }

    /// Whether this container is empty (has no contents).
    ///
    /// Returns `true` if the container has no items inside it. Returns `true`
    /// for non-containers or if there's an error accessing contents.
    public var isEmpty: Bool {
        get async {
            await contents.isEmpty
        }
    }

    /// Checks if this container is currently holding the specified item.
    ///
    /// This method determines whether the given item is contained within this
    /// container or any of its sub-containers.
    ///
    /// - Parameter itemID: The `Item` identifier to check for containment.
    /// - Returns: `true` if this container is holding the item, `false` otherwise.
    public func isHolding(_ itemID: ItemID) async -> Bool {
        await allContents.contains { $0.id == itemID }
    }

    /// Whether this item can be included in ALL commands.
    ///
    /// Returns `true` if the item is takable and doesn't have the `.omitDescription` flag.
    /// Items that are not takable, not reachable, or are scenery are typically excluded
    /// from commands like "take all" or "drop all".
    public var isIncludableInAllCommands: Bool {
        get async {
            await hasFlags(all: .isTakable, none: .omitDescription)
        }
    }

    /// Whether this container is not empty (has contents).
    ///
    /// This is a convenience property that returns the opposite of `isEmpty`.
    /// Useful for checking if a container has items without the double negative.
    public var isNotEmpty: Bool {
        get async {
            await !isEmpty
        }
    }

    /// Whether this container or door is currently open.
    ///
    /// Returns `true` if the item has the `.isOpen` flag set. Open containers
    /// and doors allow access to their contents or passage through them.
    public var isOpen: Bool {
        get async {
            await hasFlag(.isOpen)
        }
    }

    /// Whether this item can be opened or closed.
    ///
    /// Returns `true` if the item has either the `.isOpenable` flag or is currently
    /// open (has the `.isOpen` flag). Openable items can be manipulated with
    /// "open" and "close" commands.
    public var isOpenable: Bool {
        get async {
            await hasFlags(any: .isOpenable, .isOpen)
        }
    }

    /// Whether this item is currently providing light to its surroundings.
    ///
    /// Returns `true` if the item is both a light source (has `.isLightSource` flag)
    /// and is currently turned on (has `.isOn` flag). Light-providing items can
    /// illuminate dark locations.
    public var isProvidingLight: Bool {
        get async {
            if await hasFlag(.isBurning) {
                true
            } else if await hasFlags(all: .isLightSource, .isOn) {
                true
            } else {
                false
            }
        }
    }

    /// Whether this item is a surface that can hold other items.
    ///
    /// Surfaces are like containers but their contents are always visible.
    /// Items on surfaces are typically described as being "on" rather than "in" them.
    public var isSurface: Bool {
        get async {
            await hasFlag(.isSurface)
        }
    }

    /// Whether this item can be taken by the player.
    ///
    /// Returns `true` if the item has the `.isTakable` flag set. Takable items
    /// can be picked up and added to the player's inventory.
    public var isTakable: Bool {
        get async {
            await hasFlag(.isTakable)
        }
    }

    /// Whether this item has ever been touched or manipulated by the player.
    ///
    /// The `.isTouched` flag is typically set when the player first interacts with
    /// an item. This affects whether first descriptions are shown and can trigger
    /// certain game behaviors.
    public var isTouched: Bool {
        get async {
            await hasFlag(.isTouched)
        }
    }

    /// Whether this item is visible to the player.
    ///
    /// Returns `true` if the item does not have the `.isInvisible` flag set.
    /// Invisible items are present in the game world but cannot be seen or
    /// interacted with by the player.
    public var isVisible: Bool {
        get async {
            await !hasFlag(.isInvisible)
        }
    }

    /// Whether this item is a weapon, or can be used as an improvised weapon.
    ///
    /// Returns `true` if the item has any of `.isWeapon`, `.isBurning` or `.isTool` flags set.
    /// Weapons and tools may have special combat or utility behaviors.
    public var isWeapon: Bool {
        get async {
            if await hasFlags(any: .isWeapon, .isBurning, .isTool) {
                return true
            }
            return await property(.damage)?.toInt != nil
        }
    }

    /// The ultimate location where this item resides, computed recursively.
    ///
    /// This property traverses the containment hierarchy to find the final location
    /// where this item exists. For example:
    /// - If a sandwich is directly in a kitchen, returns the kitchen location
    /// - If a sandwich is in a bag in a kitchen, still returns the kitchen location
    /// - If a sandwich is in a bag held by the player in a kitchen, returns the kitchen location
    /// - Returns `nil` if the item is nowhere or in an unresolvable containment chain
    ///
    /// This is useful for determining lighting, accessibility, and spatial relationships
    /// regardless of how deeply nested an item is within containers.
    ///
    /// Corresponds to the ZIL `LOC` function which recursively finds an object's location.
    public var location: LocationProxy? {
        get async {
            var currentParent = await parent

            // Traverse up the containment chain until we find a location or reach the end
            while true {
                switch currentParent {
                case .location(let locationProxy):
                    return locationProxy
                case .item(let itemProxy):
                    // Continue searching up the chain through this item's parent
                    currentParent = await itemProxy.parent
                case .player:
                    // Player is in a location, so get the player's location
                    return await engine.player.location
                case .nowhere:
                    return nil
                }
            }
        }
    }

    /// The primary name used to refer to the item.
    ///
    /// This is the main identifier string used in descriptions and when matching
    /// player commands. It should be a short, descriptive phrase like "brass lamp"
    /// or "leather bag". The parser uses this name along with synonyms and adjectives
    /// to recognize when the player is referring to this item.
    ///
    /// Corresponds to the ZIL `DESC` property. Falls back to the item's ID if no name is set.
    public var name: String {
        get async {
            await property(.name)?.toString ?? id.rawValue
        }
    }

    /// The parent proxy that currently holds or contains this item.
    ///
    /// Returns a `ParentProxy` representing where this item is located:
    /// - `.player`: The item is in the player's direct inventory
    /// - `.location(LocationProxy)`: The item is in a specific location
    /// - `.item(ItemProxy)`: The item is inside another item (container/surface)
    /// - `.nowhere`: The item is not currently placed anywhere in the game world
    ///
    /// This property is fundamental to the game's spatial model and affects whether
    /// the item can be seen, reached, or interacted with by the player.
    ///
    /// Corresponds to the ZIL `IN` property.
    public var parent: ParentProxy {
        get async {
            guard let parentEntity = await property(.parentEntity)?.toParentEntity else {
                return .nowhere
            }
            return await engine.parent(from: parentEntity)
        }
    }

    /// Whether the player can carry this item without exceeding carrying capacity.
    ///
    /// This checks if adding this item to the player's inventory would exceed
    /// the player's carrying capacity based on the item's size and the player's
    /// current load. Takes into account both the item's size property and any
    /// capacity limits the player may have.
    ///
    /// - Returns: `true` if the player can carry this item, `false` if it would exceed capacity
    /// - Throws: Re-throws any errors from accessing player or item properties
    public var playerCanCarry: Bool {
        get async {
            await engine.player.canCarry(id)
        }
    }

    /// Whether the player can reach and interact with this item.
    ///
    /// Returns `true` if the item is in the player's current scope - either
    /// in their inventory, in the current location, or in accessible containers
    /// and surfaces. Items that cannot be reached cannot be targeted by most
    /// commands and will result in "not here" type error messages.
    ///
    /// This considers line-of-sight, accessibility through open containers,
    /// and other factors that determine whether an item is within the player's
    /// interactive reach.
    public var playerCanReach: Bool {
        get async {
            await engine.itemsReachableByPlayer().contains(self)
        }
    }

    /// Whether this item is currently held by the player.
    ///
    /// Returns `true` if the item's parent is the player, meaning it's in
    /// the player's direct inventory. This doesn't include items inside
    /// containers that the player is holding - only items directly in
    /// the player's possession.
    ///
    /// - Returns: `true` if the player is directly holding this item, `false` otherwise
    /// - Throws: Re-throws any errors from accessing the item's parent property
    public var playerIsHolding: Bool {
        get async {
            await parent == .player
        }
    }

    /// Selects a random available exit from this NPC's current location.
    ///
    /// This method retrieves all exits that the NPC can traverse based on the specified
    /// movement behavior, then randomly selects one. This is commonly used for NPC
    /// wandering behaviors and AI movement systems.
    ///
    /// - Parameter behavior: The movement behavior that determines which exits are available:
    ///   - `.normal`: Standard door interactions (requires open doors)
    ///   - `.any`: Can pass through any exit, ignoring all obstacles
    ///   - `.closedDoors`: Can pass through closed but unlocked doors
    ///   - `.lockedDoors`: Can pass through any locked doors
    ///   - `.lockedDoorsUnlockedByKeys([ItemID])`: Can pass through locked doors
    ///     that can be unlocked by the specified keys
    /// - Returns: A randomly selected `Exit` that the NPC can traverse, or `nil` if no exits are available.
    /// - Throws: Re-throws any errors from `availableExits(behavior:)`.
    public func randomExit(
        behavior: Exit.MovementBehavior = .normal
    ) async -> Exit? {
        let availableExits = await availableExits(behavior: behavior)
        return await engine.randomElement(in: availableExits)
    }

    /// The text displayed when this item is read.
    ///
    /// Returns the item's specific readable content if it has the `.readText` property set,
    /// such as text on a sign, book, or inscription. If the item has no readable content,
    /// returns a default message indicating there's nothing written on the item.
    ///
    /// This property is used by the "read" command and similar text-examination actions.
    /// Items like books, letters, signs, and inscriptions typically have custom read text.
    public var readText: String? {
        get async {
            if let readText = await property(.readText)?.toString {
                readText
            } else {
                engine.messenger.nothingWrittenOn(await withDefiniteArticle)
            }
        }
    }

    /// The text displayed when this item is read while held by the player.
    ///
    /// Some items reveal different or additional information when examined
    /// closely while held - for example, a letter might show fine print only
    /// visible when held close, or a magic item might reveal hidden text when
    /// in the player's possession.
    ///
    /// Returns the special held-read text if available via the `.readWhileHeldText` property,
    /// otherwise returns a default message indicating that close examination reveals
    /// nothing special about the item.
    public var readWhileHeldText: String? {
        get async {
            if let readWhileHeldText = await property(.readWhileHeldText)?.toString {
                readWhileHeldText
            } else {
                engine.messenger.holdingRevealsNothingSpecial(await withDefiniteArticle)
            }
        }
    }

    /// Calculates this item's value relative to all other items in the game.
    /// Returns a value from 0.0 to 1.0 based on smart distribution analysis, filtering out extreme outliers.
    /// Similar values cluster around 0.4-0.6 to avoid artificial extremes. Worthless (0-0.2) and
    /// priceless (0.8-1.0) are reserved for genuine outliers with significant value differences.
    public var relativeValue: Double {
        get async {
            var allValues: [Int] = []
            let gameState = await engine.gameState
            for item in gameState.items.values {
                await allValues.append(
                    item.proxy(engine).value
                )
            }
            guard !allValues.isEmpty else { return 0.5 }

            // Filter out extreme outliers using IQR method
            let filteredValues = Self.filterOutliers(allValues)
            guard !filteredValues.isEmpty else { return 0.5 }

            let sortedValues = filteredValues.sorted()
            let currentValue = await self.value

            // Handle edge cases
            guard sortedValues.count > 1 else { return 0.5 }
            guard let minValue = sortedValues.first, let maxValue = sortedValues.last else {
                return 0.5
            }
            guard minValue != maxValue else { return 0.5 }

            return Self.calculateRelativePosition(
                currentValue: currentValue,
                minValue: minValue,
                maxValue: maxValue,
                sortedValues: sortedValues,
                isDamageCalculation: false
            )
        }
    }

    /// Calculates this item's weapon damage relative to all other items in the game.
    /// Returns a value from 0.0 to 1.0 based on smart distribution analysis, filtering out extreme outliers.
    public var relativeWeaponDamage: Double {
        get async {
            var allValues: [Int] = []
            let gameState = await engine.gameState
            for item in gameState.items.values {
                await allValues.append(
                    item.proxy(engine).weaponDamage
                )
            }
            guard !allValues.isEmpty else { return 0.5 }

            // Filter out extreme outliers using IQR method
            let filteredValues = Self.filterOutliers(allValues)
            guard !filteredValues.isEmpty else { return 0.5 }

            let sortedValues = filteredValues.sorted()
            let currentValue = await self.weaponDamage

            // Handle edge cases
            guard sortedValues.count > 1 else { return 0.5 }
            guard let minValue = sortedValues.first, let maxValue = sortedValues.last else {
                return 0.5
            }
            guard minValue != maxValue else { return 0.5 }

            return Self.calculateRelativePosition(
                currentValue: currentValue,
                minValue: minValue,
                maxValue: maxValue,
                sortedValues: sortedValues,
                isDamageCalculation: true
            )
        }
    }

    /// Converts the relative value to a categorical assessment.
    ///
    /// Maps the item's relative value (0.0-1.0) to one of five categories:
    /// - `.worthless`: Items in the bottom 20% of values (0.0-0.2)
    /// - `.low`: Items in the 20-40% range (0.2-0.4)
    /// - `.medium`: Items in the 40-60% range (0.4-0.6)
    /// - `.high`: Items in the 60-80% range (0.6-0.8)
    /// - `.priceless`: Items in the top 20% of values (0.8-1.0)
    public var relativeValueCategory: Item.RoughValue {
        get async {
            let ratio = await relativeValue
            switch ratio {
            case 0..<0.2:
                return .worthless
            case 0.2..<0.4:
                return .low
            case 0.4..<0.6:
                return .medium
            case 0.6..<0.8:
                return .high
            default:
                return .priceless
            }
        }
    }

    /// Converts the relative weapon damage to a categorical assessment.
    /// Returns low/medium/high based on the relative weapon damage percentile.
    public var relativeWeaponDamageCategory: Item.RoughValue {
        get async {
            let ratio = await relativeWeaponDamage
            switch ratio {
            case 0..<0.2:
                return .worthless
            case 0.2..<0.4:
                return .low
            case 0.4..<0.6:
                return .medium
            case 0.6..<0.8:
                return .high
            default:
                return .priceless
            }
        }
    }

    /// Returns a response string based on the item's type and state.
    ///
    /// This method determines whether the item is a character, enemy, or regular object,
    /// then calls the appropriate closure with the item's name (with definite article).
    ///
    /// - Parameters:
    ///   - object: Closure called for regular objects, receives the item name with definite article
    ///   - character: Closure called for non-fighting characters, receives the item name with definite article
    ///   - enemy: Closure called for fighting characters, receives the item name with definite article
    /// - Returns: The response string generated by the appropriate closure
    public func response(
        object: (String) -> String,
        character: (String) -> String,
        enemy: ((String) -> String)? = nil
    ) async -> String {
        if await isCharacter {
            if let enemy, await isHostileEnemy == true {
                await enemy(withDefiniteArticle)
            } else {
                await character(withDefiniteArticle)
            }
        } else {
            await object(withDefiniteArticle)
        }
    }

    /// The item's overall value category based on both monetary value and weapon damage.
    ///
    /// Returns the highest category between the item's relative value and relative weapon damage,
    /// providing a single assessment of the item's overall worth. Uses adjusted thresholds that
    /// cluster more items toward the center categories to avoid overuse of "worthless" and "priceless".
    ///
    /// The categories are:
    /// - `.worthless`: Items with very low value/damage (0-10% range)
    /// - `.low`: Items with below-average value/damage (10-35% range)
    /// - `.medium`: Items with average value/damage (35-65% range)
    /// - `.high`: Items with above-average value/damage (65-90% range)
    /// - `.priceless`: Items with exceptional value/damage (90-100% range)
    public var roughValue: Item.RoughValue {
        get async {
            let valueRatio = await relativeValue
            let damageRatio = await relativeWeaponDamage
            let maxRatio = max(valueRatio, damageRatio)

            // Convert ratio to rough categorization
            switch maxRatio {
            case 0..<0.1:
                return .worthless
            case 0.1..<0.35:
                return .low
            case 0.35..<0.65:
                return .medium
            case 0.65..<0.9:
                return .high
            default:
                return .priceless
            }
        }
    }

    /// Gets the item's short description for listing in inventories or containers.
    ///
    /// Returns a brief description suitable for listing contexts, such as inventory
    /// displays or container contents. Falls back to the item name with indefinite
    /// article if no short description is set.
    public var shortDescription: String? {
        get async {
            if let shortDescription = await property(.shortDescription)?.toString {
                shortDescription
            } else {
                "\(await withIndefiniteArticle.capitalizedFirst)."
            }
        }
    }

    /// Whether this item should be described in room descriptions and similar contexts.
    ///
    /// Returns `true` if the item should be mentioned when describing locations
    /// or container contents. Items with `.isInvisible` or `.omitDescription` flags
    /// are typically not described.
    public var shouldDescribe: Bool {
        get async {
            await !hasFlags(any: .isInvisible, .omitDescription)
        }
    }

    /// Whether this item should be taken first before performing actions on it.
    ///
    /// Returns `true` if the item is takable but not currently held by the player.
    /// Some actions may automatically take an item first if this property is `true`.
    public var shouldTakeFirst: Bool {
        get async {
            let itemParent = await parent
            let isTakable = await isTakable

            return itemParent != .player && isTakable
        }
    }

    /// The item's size for capacity calculations.
    ///
    /// This property represents how much space the item takes up when stored
    /// in containers. Container capacity checks sum the sizes of all contained
    /// items against the container's capacity limit. Larger items take up more
    /// space and may not fit in smaller containers.
    ///
    /// Corresponds to the ZIL `SIZE` property. Defaults to 1 if not specified.
    public var size: Int {
        get async {
            await property(.size)?.toInt ?? 1
        }
    }

    /// A set of alternative names that can be used to refer to the item.
    ///
    /// Synonyms provide additional ways for players to reference the item in commands.
    /// For example, a "sword" might have synonyms like "blade", "weapon", or "steel".
    /// The parser uses both the primary name and all synonyms when matching player input.
    ///
    /// Corresponds to the ZIL `SYNONYM` property. Returns an empty set if no synonyms are defined.
    public var synonyms: [String] {
        get async {
            await property(.synonyms)?.toStrings?.sorted() ?? []
        }
    }

    /// The item's value, typically its monetary worth or general importance.
    ///
    /// This property represents the item's inherent worth, which may be monetary,
    /// magical, or based on rarity and usefulness. Higher values generally indicate
    /// more valuable or important items. Used in treasure scoring systems and
    /// relative value calculations for categorizing items.
    ///
    /// Corresponds to the ZIL `VALUE` property. Defaults to 0 if not specified.
    public var value: Int {
        get async {
            await property(.value)?.toInt ?? 0
        }
    }

    /// Retrieves all items that can be seen in this item, ignoring darkness.
    ///
    /// This method is used when you need to know which items can be seen in a container,
    /// regardless of whether there is adequate light.
    public var visibleItems: [ItemProxy] {
        get async {
            var allItems = [ItemProxy]()
            let directContents = await contents
            for item in directContents {
                if await item.hasFlags(any: .isInvisible, .omitDescription) { continue }
                allItems.append(item)
                if await item.hasFlags(any: .isOpen, .isTransparent) {
                    allItems.append(
                        contentsOf: await item.visibleItems
                    )
                }
            }
            return allItems.sorted()
        }
    }

    /// The damage this item deals when used as a weapon.
    ///
    /// Returns the item's damage value if explicitly set, otherwise calculates
    /// damage based on the item's weapon-related flags:
    /// - Items that are both weapons and burning deal 12 damage
    /// - Regular weapons deal 9 damage
    /// - Burning items (torches, etc.) deal 6 damage
    /// - Tools used as improvised weapons deal 3 damage
    /// - All other items deal 1 damage (fists, rocks, etc.)
    ///
    /// This property is used in combat calculations to determine how much
    /// damage an item inflicts when used to attack.
    public var weaponDamage: Int {
        get async {
            if let damage = await property(.damage)?.toInt {
                damage
            } else if await hasFlags(all: .isWeapon, .isBurning) {
                12
            } else if await hasFlag(.isWeapon) {
                9
            } else if await hasFlag(.isBurning) {
                6
            } else if await hasFlag(.isTool) {
                3
            } else {
                1
            }
        }
    }

    /// The item's name with a definite article ("the") prepended.
    ///
    /// Returns the item name with "the" prepended, unless the item has the
    /// `.omitArticle` flag set. Used for natural language output in descriptions
    /// and messages.
    public var withDefiniteArticle: String {
        get async {
            let itemName = await name
            let omitArticle = await hasFlag(.omitArticle)

            return omitArticle ? itemName : engine.messenger.the(itemName)
        }
    }

    /// The item's name with a possessive adjective ("your") prepended.
    ///
    /// Returns the item name with "your" prepended, creating a possessive form
    /// suitable for describing items owned or held by the player. Used for
    /// natural language output in contexts where ownership is emphasized.
    public var withPossessiveAdjective: String {
        get async {
            await engine.messenger.your(name)
        }
    }

    /// The item's name with a possessive adjective prepended based on another item's gender.
    ///
    /// Returns the item name with the appropriate possessive adjective ("his", "her", "its", "their")
    /// based on the gender of the specified other item. This is useful for describing items in
    /// relation to characters or other gendered entities.
    ///
    /// - Parameter other: The ItemProxy whose gender determines the possessive adjective
    /// - Returns: The item name with the appropriate possessive adjective prepended
    /// - Throws: Re-throws any errors from accessing the other item's gender property
    /// - Example: If `other` has masculine gender, returns "his sword" for a sword item
    public func withPossessiveAdjective(for other: ItemProxy) async -> String {
        await "\(other.classification.possessiveAdjective) \(name)"
    }

    /// The item's name with an appropriate indefinite article ("a" or "an") prepended.
    ///
    /// Returns the item name with the grammatically correct indefinite article.
    /// Uses "some" for plural items (items with `.isPlural` flag), omits articles
    /// for items with `.omitArticle` flag, and chooses "a" or "an" based on the
    /// first letter for singular items.
    public var withIndefiniteArticle: String {
        get async {
            let itemName = await name
            let omitArticle = await hasFlag(.omitArticle)

            return if await hasFlag(.isPlural) {
                engine.messenger.some(itemName)
            } else if omitArticle {
                itemName
            } else {
                itemName.withIndefiniteArticle
            }
        }
    }
}

// MARK: - ItemProxy Array Convenience Accessors

extension Array where Element == ItemProxy {
    /// Returns all items contained within any items in this array, recursively.
    ///
    /// This method traverses the containment hierarchy, collecting all items stored
    /// inside any containers or surfaces in this array, including nested containers.
    /// For example, if this array contains a bag with a box inside it, and the box
    /// contains coins, this method returns both the box and the coins.
    ///
    /// - Returns: Array of all contained items, flattened from the containment hierarchy
    /// - Throws: Re-throws any errors from accessing item contents
    public var allContents: [ItemProxy] {
        get async {
            var allContents: [ItemProxy] = []

            for item in self {
                let itemContents = await item.contents
                allContents.append(contentsOf: itemContents)

                // Recursively get contents of the contents
                let nestedContents = await itemContents.allContents
                allContents.append(contentsOf: nestedContents)
            }

            return allContents.sorted()
        }
    }

    /// Returns a grammatically correct string listing the elements, sorted alphabetically,
    /// with appropriate definite articles prepended.
    ///
    /// The method automatically handles proper English grammar including Oxford commas
    /// for lists of three or more items. Single items are returned with their definite
    /// article, and empty arrays return `nil`.
    ///
    /// - Parameter conjunction: The word used to connect the last item (default: "and")
    /// - Returns: Formatted list string, or `nil` for empty arrays
    /// - Example: `["pear", "apple", "banana"]` becomes `"the apple, the banana, and the pear"`
    public func listWithDefiniteArticles(conjunction: String = "and") async -> String? {
        switch count {
        case 0:
            return nil
        case 1:
            return await self[0].withDefiniteArticle
        default:
            var items = [String]()
            for item in sorted() {
                await items.append(item.withDefiniteArticle)
            }
            let lastItem = items.removeLast()
            let oxfordComma = count == 2 ? "" : ","
            return "\(items.joined(separator: ", "))\(oxfordComma) \(conjunction) \(lastItem)"
        }
    }

    /// Returns a grammatically correct string listing the elements, sorted alphabetically,
    /// with appropriate indefinite articles prepended.
    ///
    /// Similar to `listWithDefiniteArticles` but uses indefinite articles ("a", "an", "some")
    /// instead of definite articles. Automatically chooses the correct indefinite article
    /// based on each item's name and plural status.
    ///
    /// - Parameter conjunction: The word used to connect the last item (default: "and")
    /// - Returns: Formatted list string, or `nil` for empty arrays
    /// - Example: `["pear", "apple", "banana"]` becomes `"an apple, a banana, and a pear"`
    public func listWithIndefiniteArticles(conjunction: String = "and") async -> String? {
        switch count {
        case 0:
            return nil
        case 1:
            return await self[0].withIndefiniteArticle
        default:
            var items = [String]()
            for item in sorted() {
                await items.append(item.withIndefiniteArticle)
            }
            let lastItem = items.removeLast()
            let oxfordComma = count == 2 ? "" : ","
            return "\(items.joined(separator: ", "))\(oxfordComma) \(conjunction) \(lastItem)"
        }
    }

    /// Returns an array of ItemProxy elements sorted by their temporary value in descending order.
    ///
    /// The temporary value is retrieved from the `.tmpValue` property of each item, which
    /// is often used for dynamic calculations, scoring systems, or temporary game state.
    /// Items without a temporary value property are treated as having a value of 0 and
    /// will appear at the end of the sorted array.
    ///
    /// This is particularly useful for treasure scoring systems, combat damage calculations,
    /// or any scenario where items need temporary numerical rankings.
    ///
    /// - Returns: A new array with items sorted by temporary value from highest to lowest
    public var sortedByTempValue: [ItemProxy] {
        get async {
            await asyncSorted {
                let lValue = await $0.property(.tmpValue)?.toInt
                let rValue = await $1.property(.tmpValue)?.toInt
                return lValue ?? 0 > rValue ?? 0
            }
        }
    }

    /// Returns an array of ItemProxy elements sorted by their value in descending order.
    ///
    /// The value is retrieved from the `.value` property of each item, which typically
    /// represents the item's monetary worth, magical power, or general importance in
    /// the game world. Items without a value property are treated as having a value of 0
    /// and will appear at the end of the sorted array.
    ///
    /// This sorting is commonly used for treasure management, inventory displays,
    /// and determining which items are most valuable for scoring or trading systems.
    ///
    /// - Returns: A new array with items sorted by value from highest to lowest
    public var sortedByValue: [ItemProxy] {
        get async {
            await asyncSorted {
                let lValue = await $0.property(.value)?.toInt
                let rValue = await $1.property(.value)?.toInt
                return lValue ?? 0 > rValue ?? 0
            }
        }
    }

    /// Returns an array of ItemProxy elements sorted by their weapon damage in descending order.
    ///
    /// The weapon damage is calculated using each item's `weaponDamage` property, which
    /// considers the item's weapon type, burning state, tool status, and other combat-related
    /// flags to determine the damage it would deal when used as a weapon. Even non-weapon
    /// items receive a damage rating for improvised weapon use.
    ///
    /// This sorting is particularly useful for combat systems, weapon selection AI,
    /// and displaying items in order of combat effectiveness.
    ///
    /// - Returns: A new array with items sorted by weapon damage from highest to lowest
    public var sortedByWeaponDamage: [ItemProxy] {
        get async {
            await asyncSorted {
                let lValue = await $0.weaponDamage
                let rValue = await $1.weaponDamage
                return lValue > rValue
            }
        }
    }

    /// Returns all visible contents within any items in this array, recursively.
    ///
    /// This method traverses containers and surfaces in this array, collecting only
    /// those contents that are visible to observers. Contents are visible when:
    /// - The container is open (has `.isOpen` flag)
    /// - The container is transparent (has `.isTransparent` flag)
    /// - The item is a surface (has `.isSurface` flag)
    /// - The contained items themselves are not invisible
    ///
    /// Used primarily for room descriptions and "look in container" commands
    /// to show what can be seen without explicitly opening closed containers.
    ///
    /// - Returns: Array of all recursively visible contained items
    public var visibleContents: [ItemProxy] {
        get async {
            var allVisibleContents: [ItemProxy] = []

            for item in self {
                guard await item.contentsAreVisible else { continue }

                let itemContents = await item.contents.asyncFilter { await $0.isVisible }
                allVisibleContents.append(contentsOf: itemContents)

                // Recursively get visible contents of the contents
                let nestedVisibleContents = await itemContents.visibleContents
                allVisibleContents.append(contentsOf: nestedVisibleContents)
            }

            return allVisibleContents
        }
    }
}

// MARK: - NameVariant enumeration

extension ItemProxy {
    /// Variants for how an item's name should be presented in text.
    ///
    /// This enum is used with methods like `alias(_:)` to control how an item's name
    /// is formatted when generating text output. Different variants are appropriate
    /// for different grammatical contexts.
    public enum NameVariant {
        /// The item name with a definite article ("the") prepended.
        ///
        /// Example: "the sword" or "the magic ring"
        case withDefiniteArticle

        /// The item name with an indefinite article ("a" or "an") prepended.
        ///
        /// Uses the grammatically correct article based on the first letter.
        /// Example: "a sword" or "an apple"
        case withIndefiniteArticle

        /// The item name with a possessive adjective (e.g. "your" or "her") prepended.
        ///
        /// Used when referring to items owned or held by a character.
        /// Example: "your sword" or "its backpack"
        case withPossessiveAdjective(for: ItemProxy?)

        /// The item name with the player's possessive adjective (e.g. "your") prepended.
        ///
        /// Used when referring to items owned or held by the player.
        /// Example: "your sword" or "your backpack"
        public static var withPossessiveAdjective: NameVariant {
            .withPossessiveAdjective(for: nil)
        }
    }
}

// MARK: - Private helpers

extension ItemProxy {
    /// Filters out extreme outliers using interquartile range (IQR) method.
    ///
    /// This statistical method identifies and removes extreme outliers that would
    /// skew relative value calculations. Uses the IQR to define outlier bounds:
    /// values outside Q1 - 3×IQR and Q3 + 3×IQR are considered extreme outliers.
    /// The aggressive 3×IQR multiplier ensures only truly extreme values are filtered.
    ///
    /// - Parameter values: Array of integer values to filter
    /// - Returns: Filtered array with extreme outliers removed, or original array if fewer than 4 values
    private static func filterOutliers(_ values: [Int]) -> [Int] {
        guard values.count >= 4 else { return values }

        let sortedValues = values.sorted()
        let count = sortedValues.count

        // Calculate quartiles
        let q1Index = count / 4
        let q3Index = (3 * count) / 4

        let q1 = sortedValues[q1Index]
        let q3 = sortedValues[q3Index]
        let iqr = q3 - q1

        // Define outlier bounds (3.0 * IQR for aggressive filtering of extreme outliers)
        let lowerBound = q1 - (3 * iqr)
        let upperBound = q3 + (3 * iqr)

        // Filter values within bounds
        return sortedValues.filter { $0 >= lowerBound && $0 <= upperBound }
    }

    /// Calculates relative position using smart distribution analysis that prevents similar values
    /// from being spread across extremes. Reserves "worthless" for truly low values and "priceless"
    /// for genuine outliers.
    ///
    /// The algorithm uses three strategies based on value distribution:
    /// 1. **Similar values**: When range is small relative to maximum, clusters values in 0.4-0.6 range
    /// 2. **Small damage sets**: Caps maximum damage items at 0.78 to prevent auto-priceless classification
    /// 3. **Smart scaling**: Maps values with meaningful differences while reserving extremes for true outliers
    ///
    /// - Parameters:
    ///   - currentValue: The value to calculate relative position for
    ///   - minValue: Minimum value in the filtered dataset
    ///   - maxValue: Maximum value in the filtered dataset
    ///   - sortedValues: All values in the dataset, sorted ascending
    ///   - isDamageCalculation: Whether this is for damage (true) or value (false) calculation
    /// - Returns: Relative position from 0.0 to 1.0
    private static func calculateRelativePosition(
        currentValue: Int,
        minValue: Int,
        maxValue: Int,
        sortedValues: [Int],
        isDamageCalculation: Bool
    ) -> Double {
        let range = maxValue - minValue

        // If the range is very small (all values are similar), cluster around middle
        let rangeThreshold = max(5, maxValue / 20)  // At least 5 or 5% of max value
        if range <= rangeThreshold {
            // For similar values, return values clustered around 0.4-0.6
            let position = sortedValues.firstIndex { $0 >= currentValue } ?? sortedValues.count - 1
            let simplePercentile = Double(position) / Double(sortedValues.count - 1)
            return 0.4 + (simplePercentile * 0.2)  // Maps to 0.4-0.6 range
        }

        // For values with meaningful range, use smart scaling
        let normalizedValue = Double(currentValue - minValue) / Double(range)

        // Special handling for small damage sets to prevent automatic priceless classification
        // Only applies to damage calculations, not value calculations
        if isDamageCalculation && sortedValues.count <= 5 && currentValue == maxValue {
            // Cap maximum damage items in small sets to high range, not priceless
            let cappedValue = 0.2 + ((normalizedValue - 0.08) / 0.91) * 0.6
            return min(cappedValue, 0.78)  // Cap at 0.78 to stay in high range
        }

        // Reserve extremes for true outliers
        // Worthless: only for values very close to minimum (bottom 8% of range)
        if normalizedValue < 0.08 {
            return normalizedValue * 2.5  // Maps 0-0.08 to 0-0.2
        }

        // Priceless: only for values very close to maximum (top 1% of range)
        if normalizedValue > 0.99 {
            return 0.8 + ((normalizedValue - 0.99) * 20)  // Maps 0.99-1.0 to 0.8-1.0
        }

        // Middle values: compress the 0.08-0.99 range into 0.2-0.8
        return 0.2 + ((normalizedValue - 0.08) / 0.91) * 0.6
    }
}

// swiftlint:enable file_length
