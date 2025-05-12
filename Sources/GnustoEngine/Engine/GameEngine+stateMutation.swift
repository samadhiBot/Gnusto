// MARK: - State Mutation Helpers (Public API for Handlers/Hooks)

extension GameEngine {
    /// Sets a global flag by applying a `.setFlag` state change.
    /// Logs a warning and returns if the state change application fails.
    /// Does nothing if the flag is already set.
    ///
    /// - Parameter id: The `GlobalID` of the flag to set.
    public func setFlag(_ id: GlobalID) async {
        // Only apply if the flag isn't already set
        if gameState.globalState[id] != true {
            do {
                try gameState.apply(
                    StateChange(
                        entityID: .global,
                        attributeKey: .setFlag(id),
                        oldValue: gameState.globalState[id],
                        newValue: true,
                    )
                )
            } catch {
                logger.warning("""
                    💥 Failed to apply .setFlag change for '\(id.rawValue, privacy: .public)': \
                    \(error, privacy: .public)
                    """)
            }
        }
    }

    /// Clears a global flag by applying a `.clearFlag` state change.
    /// Logs a warning and returns if the state change application fails.
    /// Does nothing if the flag is already clear.
    ///
    /// - Parameter id: The `GameStateID` of the flag to clear.
    public func clearFlag(_ id: GlobalID) async {
        // Only apply if the flag is currently set
        if gameState.globalState[id] != false {
            do {
                try gameState.apply(
                    StateChange(
                        entityID: .global,
                        attributeKey: .clearFlag(id),
                        oldValue: gameState.globalState[id],
                        newValue: false
                    )
                )
            } catch {
                logger.warning("""
                    💥 Failed to apply .clearFlag change for \
                    '\(id.rawValue, privacy: .public)': \(error, privacy: .public)
                    """)
            }
        }
    }

    /// Updates the pronoun reference (e.g., "it") to point to a specific item.
    ///
    /// - Parameters:
    ///   - pronoun: The pronoun (e.g., "it").
    ///   - itemID: The ItemID the pronoun should refer to.
    public func applyPronounChange(pronoun: String, itemID: ItemID) async {
        let newSet: Set<ItemID> = [itemID]
        let oldSet = gameState.pronouns[pronoun]

        if oldSet != newSet {
            do {
                try gameState.apply(
                    StateChange(
                        entityID: .global,
                        attributeKey: .pronounReference(pronoun: pronoun),
                        oldValue: oldSet.map { .itemIDSet($0) },
                        newValue: .itemIDSet(newSet)
                    )
                )
            } catch {
                logger.warning("""
                    💥 Failed to apply pronoun change for '\(pronoun, privacy: .public)': \
                    \(error, privacy: .public)
                    """)
            }
        }
    }

    /// Moves an item to a new parent entity.
    ///
    /// - Parameters:
    ///   - itemID: The unique identifier of the item to move.
    ///   - newParent: The target parent entity.
    public func applyItemMove(itemID: ItemID, newParent: ParentEntity) async {
        guard let moveItem = item(itemID) else {
            logger.warning(
                "💥 Cannot move non-existent item '\(itemID.rawValue, privacy: .public)'."
            )
            return
        }
        let oldParent = moveItem.parent

        // Check if destination is valid (e.g., Location exists)
        if case .location(let locationID) = newParent {
            guard location(with: locationID) != nil else {
                logger.warning("""
                    💥 Cannot move item '\(itemID.rawValue, privacy: .public)' to \
                    non-existent location '\(locationID.rawValue, privacy: .public)'.
                    """)
                return
            }
        } else if case .item(let containerID) = newParent {
             guard item(containerID) != nil else {
                 logger
                     .warning("""
                        💥 Cannot move item '\(itemID.rawValue, privacy: .public)' into \
                        non-existent container '\(containerID.rawValue, privacy: .public)'.
                        """)
                return
            }
            // TODO: Add container capacity check?
        }

        if oldParent != newParent {
            do {
                try gameState.apply(
                    StateChange(
                        entityID: .item(itemID),
                        attributeKey: .itemParent,
                        oldValue: .parentEntity(oldParent),
                        newValue: .parentEntity(newParent)
                    )
                )
            } catch {
                logger.warning("""
                    💥 Failed to apply item move for '\(itemID.rawValue, privacy: .public)': \
                    \(error, privacy: .public)
                    """)
            }
        }
    }

    /// Moves the player to a new location.
    ///
    /// - Parameter newLocationID: The unique identifier of the destination location.
    public func applyPlayerMove(to newLocationID: LocationID) async {
        let oldLocationID = gameState.player.currentLocationID

        // Check if destination is valid
        guard location(with: newLocationID) != nil else {
            logger
                .warning("""
                    💥 Cannot move player to non-existent location \
                    '\(newLocationID.rawValue, privacy: .public)'.
                    """)
            return
        }

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
                    '\(newLocationID.rawValue, privacy: .public)': \(error, privacy: .public)
                    """)
            }
        }
    }

    /// Retrieves the full change history.
    ///
    /// - Returns: An array of `StateChange` objects.
    public func getChangeHistory() -> [StateChange] {
        gameState.changeHistory
    }

    /// Signals the engine to stop the main game loop after the current turn.
    public func requestQuit() {
        self.shouldQuit = true
    }

    /// Retrieves the current set of item IDs referenced by a pronoun.
    ///
    /// - Parameter pronoun: The pronoun string (e.g., "it").
    /// - Returns: The set of `ItemID`s the pronoun refers to, or `nil` if not set.
    public func getPronounReference(pronoun: String) -> Set<ItemID>? {
        gameState.pronouns[pronoun.lowercased()]
    }

    /// Retrieves the value of a game-specific state variable.
    ///
    /// - Parameter key: The key (`GameStateKey`) for the game-specific state variable.
    /// - Returns: The `StateValue` if found, otherwise `nil`.
    public func getStateValue(key: GlobalID) -> StateValue? {
        gameState.globalState[key]
    }

    /// Applies a change to a game-specific state variable.
    ///
    /// - Parameters:
    ///   - key: The key (`GameStateKey`) for the game-specific state.
    ///   - value: The new `StateValue`.
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
                    '\(key.rawValue, privacy: .public)': \(error, privacy: .public)
                    """)
            }
        }
    }

    /// Checks if a specific global flag is currently set.
    ///
    /// - Parameter id: The `GlobalID` to check.
    /// - Returns: `true` if the flag is present in the `GameState.flags` set, `false` otherwise.
    public func isFlagSet(_ id: GlobalID) -> Bool {
        gameState.globalState[id] == true
    }
}
