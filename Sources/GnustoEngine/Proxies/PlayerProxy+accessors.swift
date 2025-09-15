import Foundation

extension PlayerProxy {
    /// Whether the player can take actions.
    public var canAct: Bool {
        get async {
            let canAct = await characterSheet.canAct
            let impaired = await characterSheet.generalCondition.impairsFreeWill
            return canAct && !impaired
        }
    }

    /// Determines if the player can carry the specified item without exceeding carrying capacity.
    ///
    /// This method calculates the total weight that would result from adding the specified item
    /// to the player's complete inventory (including contents of containers) and compares it
    /// against the player's carrying capacity.
    ///
    /// - Parameter item: The item to check if the player can carry.
    /// - Returns: `true` if the player can carry the item without exceeding capacity, `false` otherwise.
    /// - Throws: An error if there's an issue accessing the player's inventory or item properties.
    public func canCarry(_ itemID: ItemID) async throws -> Bool {
        let item = try await engine.item(itemID)
        var totalWeight = await item.size
        for item in try await completeInventory {
            let size = await item.size
            totalWeight += size
        }
        return carryingCapacity >= totalWeight
    }

    /// The maximum total `size` of items the player can carry in their inventory.
    ///
    /// If the `currentInventoryWeight` exceeds this, the player is prevented from picking up
    /// more items.
    public var carryingCapacity: Int {
        10 * player.characterSheet.strength
    }

    /// The player's character sheet containing all attributes, properties, and states.
    ///
    /// Returns the comprehensive character sheet including D&D attributes, combat settings,
    /// and character states. This is the single source of truth for all player character data.
    public var characterSheet: CharacterSheet {
        get async {
            player.characterSheet
        }
    }

    /// The player's current inventory, including contents of containers.
    public var completeInventory: [ItemProxy] {
        get async throws {
            var allItems = [ItemProxy]()
            let directInventory = try await inventory
            for item in directInventory {
                allItems.append(item)
                allItems.append(contentsOf: try await item.allContents)
            }
            return allItems
        }
    }

    /// A representation of the player's current health or well-being.
    public var health: Int {
        player.characterSheet.health
    }

    /// The player's current health or well-being as a percentage of maximum health.
    public var healthPercent: Int {
        player.characterSheet.healthPercent
    }

    /// The player's current inventory.
    ///
    /// This inventory does not include the contents of any containers the player is holding.
    /// Use `completeInventory` for a full player inventory list.
    public var inventory: [ItemProxy] {
        get async throws {
            try await engine.gameState.items.values.asyncCompactMap { item -> ItemProxy? in
                let proxy = try await engine.item(item.id)
                guard try await proxy.parent == .player else { return nil }
                return proxy
            }
        }
    }

    /// Determines if the player is currently carrying the specified item in their inventory.
    ///
    /// - Parameter itemID: The item identifier to check for in the player's inventory.
    /// - Returns: `true` if the player is carrying the item, `false` otherwise.
    /// - Throws: An error if there's an issue accessing the player's inventory.
    public func isHolding(_ itemID: ItemID) async throws -> Bool {
        try await completeInventory.contains { $0.id == itemID }
    }

    /// The player's current location.
    public var location: LocationProxy {
        get async throws {
            try await engine.location(player.currentLocationID)
        }
    }

    /// The player's maximum health points.
    public var maxHealth: Int {
        player.characterSheet.maxHealth
    }

    /// The number of turns that have elapsed since the game began.
    public var moves: Int {
        player.moves
    }

    /// Selects the player's best weapon in their inventory.
    public var preferredWeapon: ItemProxy? {
        get async throws {
            try await inventory.sortedByWeaponDamage.first
        }
    }

    /// The player's current score.
    public var score: Int {
        player.score
    }
}
