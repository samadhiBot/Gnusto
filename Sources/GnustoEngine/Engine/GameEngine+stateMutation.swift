// MARK: - State Mutation Helpers (Public API for Handlers/Hooks)

extension GameEngine {
    /// Sets a global flag to `true` in the game state.
    ///
    /// If the flag is already set to `true`, this method does nothing.
    /// This is a convenience method that creates and applies the necessary `StateChange`.
    ///
    /// - Parameter id: The `GlobalID` of the flag to set.
    public func setFlag(_ id: GlobalID) async {
        // Only apply if the flag isn't already set
        if global(id) != true {
            do {
                try gameState.apply(
                    StateChange(
                        entityID: .global,
                        attributeKey: .setFlag(id),
                        oldValue: global(id),
                        newValue: true,
                    )
                )
            } catch {
                logger.warning("""
                    💥 Failed to apply .setFlag change for '\(id.rawValue)': \
                    \(error)
                    """)
            }
        }
    }

    /// Clears a global flag, setting its value to `false` in the game state.
    ///
    /// If the flag is already `false` or not set, this method does nothing.
    /// This is a convenience method that creates and applies the necessary `StateChange`.
    ///
    /// - Parameter id: The `GlobalID` of the flag to clear.
    public func clearFlag(_ id: GlobalID) async {
        // Only apply if the flag is currently set
        if global(id) != false {
            do {
                try gameState.apply(
                    StateChange(
                        entityID: .global,
                        attributeKey: .clearFlag(id),
                        oldValue: global(id),
                        newValue: false
                    )
                )
            } catch {
                logger.warning("""
                    💥 Failed to apply .clearFlag change for \
                    '\(id.rawValue)': \(error)
                    """)
            }
        }
    }

    /// Updates a pronoun (e.g., "it", "them") to refer to a single specific item.
    ///
    /// This is useful after an action makes an item particularly relevant, so that
    /// subsequent commands using that pronoun correctly target the item.
    /// This method creates and applies the necessary `StateChange`.
    ///
    /// - Parameters:
    ///   - pronoun: The pronoun string (e.g., "it").
    ///   - itemID: The `ItemID` the pronoun should now refer to.
    public func applyPronounChange(pronoun: String, itemID: ItemID) async {
        let newSet: Set<EntityReference> = [.item(itemID)]
        let oldSet = gameState.pronouns[pronoun]

        if oldSet != newSet {
            do {
                try gameState.apply(
                    StateChange(
                        entityID: .global,
                        attributeKey: .pronounReference(pronoun: pronoun),
                        oldValue: oldSet.map { .entityReferenceSet($0) },
                        newValue: .entityReferenceSet(newSet)
                    )
                )
            } catch {
                logger.warning("""
                    💥 Failed to apply pronoun change for '\(pronoun)': \
                    \(error)
                    """)
            }
        }
    }

    /// Moves an item to a new parent entity (e.g., a location, the player, or a container item).
    ///
    /// This method first attempts to validate the move. Validation includes:
    /// - Ensuring the target item exists.
    /// - If the new parent is a location, ensuring that location exists.
    /// - If the new parent is another item (a container):
    ///   - Ensuring the container item exists.
    ///   - Checking if the item to be moved can fit into the container based on the item's
    ///     `size` and the container's `capacity` and current load. (Note: Current capacity
    ///     check logic is basic and may need to be more robust, considering total load.)
    ///
    /// If validation passes and the new parent is different from the old parent, this method
    /// creates (using the `move` factory) and applies the `StateChange` to update the item's parent.
    ///
    /// - Parameters:
    ///   - itemID: The `ItemID` of the item to move.
    ///   - newParent: The `ParentEntity` representing the new container or location.
    /// - Throws: An `ActionResponse` if the item or target parent does not exist, or if the move
    ///           is invalid (e.g., `itemTooLargeForContainer`).
    public func applyItemMove(itemID: ItemID, newParent: ParentEntity) async throws {
        let moveItem = try item(itemID)
        let oldParent = moveItem.parent

        guard newParent != oldParent else { return } // No change needed if parents are the same.

        // Validate the new parent and conditions for moving.
        if case .location(let locationID) = newParent {
            _ = try location(locationID) // Ensures the location exists.
        } else if case .item(let containerID) = newParent {
            let container = try item(containerID) // Ensures the container item exists.

            // TODO: Enhance capacity check to consider the container's current load accurately.
            // The current check is basic: `container.capacity > moveItem.size`
            // A more robust check would be:
            // `(currentLoadOfContainer + moveItem.size) <= container.capacity`
            // where `currentLoadOfContainer` is the sum of sizes of items already in the container.
            // A capacity of -1 typically means infinite capacity.
            guard container.capacity == -1 || container.capacity >= moveItem.size else { // Basic check for now
                throw ActionResponse.itemTooLargeForContainer(
                    item: itemID,
                    container: containerID
                )
            }
        }

        // If validation passed, apply the state change.
        try gameState.apply(
            move(moveItem, to: newParent) // Uses the StateChange factory `move`
        )
    }

    /// Moves the player to a new location.
    ///
    /// This method validates that the destination `LocationID` exists, applies the
    /// `StateChange` to update the player's current location, and then triggers the
    /// `onEnterRoom` hook (if defined in the `GameBlueprint`).
    ///
    /// - Parameter newLocationID: The `LocationID` of the destination.
    /// - Throws: An `ActionResponse` if the `newLocationID` does not correspond to an existing location.
    public func applyPlayerMove(to newLocationID: LocationID) async throws {
        let oldLocationID = playerLocationID

        // Check if destination is valid
        let _ = try location(newLocationID)

        if oldLocationID != newLocationID {
            do {
                try gameState.apply(
                    StateChange(
                        entityID: .player,
                        attributeKey: .playerLocation,
                        oldValue: .locationID(oldLocationID),
                        newValue: .locationID(newLocationID)
                    )
                )

                // --- Trigger onEnterRoom Hook --- (Moved from changePlayerLocation)
                if let hook = onEnterRoom {
                    if await hook(self, newLocationID) {
                        // Hook handled everything, potentially quit game.
                        return
                    }
                }

            } catch {
                logger.warning("""
                    💥 Failed to apply player move to \
                    '\(newLocationID.rawValue)': \(error)
                    """)
            }
        }
    }

    /// Retrieves the complete history of all `StateChange`s applied to the `gameState`
    /// since the game started or the state was last loaded.
    ///
    /// This can be useful for debugging or advanced game mechanics that need to inspect
    /// past state transitions.
    ///
    /// - Returns: An array of `StateChange` objects, in the order they were applied.
    public func getChangeHistory() -> [StateChange] {
        gameState.changeHistory
    }

    /// Signals the engine to stop the main game loop and end the game after the
    /// current turn has been fully processed.
    ///
    /// This is the standard way to programmatically quit the game from within an
    /// action handler or game hook.
    public func requestQuit() {
        self.shouldQuit = true
    }

    /// Retrieves the current set of entity references (usually items) that a specific
    /// pronoun (e.g., "it", "them") refers to.
    ///
    /// - Parameter pronoun: The pronoun string (e.g., "it", "them").
    /// - Returns: A set of `EntityReference` objects, or `nil` if the pronoun is not currently set.
    public func getPronounReference(pronoun: String) -> Set<EntityReference>? {
        gameState.pronouns[pronoun.lowercased()]
    }

    /// Retrieves the value of a game-specific global variable stored in `gameState.globalState`.
    ///
    /// Global variables can store any custom data your game might need, keyed by a `GlobalID`.
    ///
    /// - Parameter key: The `GlobalID` for the global variable.
    /// - Returns: The `StateValue` if found, otherwise `nil`.
    public func getStateValue(key: GlobalID) -> StateValue? {
        gameState.globalState[key]
    }

    /// Applies a change to a game-specific global variable in `gameState.globalState`.
    ///
    /// If the new value is different from the current value, this method creates and
    /// applies the necessary `StateChange`.
    ///
    /// - Parameters:
    ///   - key: The `GlobalID` for the global variable.
    ///   - value: The new `StateValue` to set.
    public func applyGameSpecificStateChange(key: GlobalID, value: StateValue) async {
        let oldValue = gameState.globalState[key] // Read using GameStateKey

        // Only apply if the value is changing
        if value != oldValue {
            do {
                try gameState.apply(
                    StateChange(
                        entityID: .global,
                        attributeKey: .globalState(key: key), // Use GameStateKey
                        oldValue: oldValue, // Pass the existing StateValue? as oldValue
                        newValue: value
                    )
                )
            } catch {
                logger.warning("""
                    💥 Failed to apply game specific state change for key \
                    '\(key.rawValue)': \(error)
                    """)
            }
        }
    }

    /// Checks if a specific global flag is currently set to `true`.
    ///
    /// This is a convenience accessor for global boolean flags.
    ///
    /// - Parameter id: The `GlobalID` of the flag to check.
    /// - Returns: `true` if the flag is set to `true`, `false` otherwise (including if not set).
    public func isFlagSet(_ id: GlobalID) -> Bool {
        global(id) == true
    }
}
