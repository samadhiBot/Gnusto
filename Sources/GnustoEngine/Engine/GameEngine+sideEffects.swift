// MARK: - State Change & Side Effect Application

extension GameEngine {
    /// Applies a single state change to the game state by forwarding to the central `GameState.apply` method.
    /// - Parameter change: The `StateChange` to apply.
    /// - Parameter gameState: The GameState instance to modify (passed as inout).
    /// - Throws: An error if the change cannot be applied (forwarded from `GameState.apply`).
    private func applyStateChange(_ change: StateChange, gameState: inout GameState) throws {
        // Forward directly to GameState's apply method, modifying the inout parameter.
        try gameState.apply(change)
    }

    /// Processes side effects from an ActionResult.
    ///
    /// This method is called by the main action processing pipeline to handle any side effects
    /// that were generated as part of an action's execution.
    ///
    /// - Parameter effects: An array of `SideEffect` objects to process.
    /// - Throws: An error if any side effect cannot be processed.
    func processSideEffects(_ effects: [SideEffect]) async throws {
        for effect in effects {
            try await processSideEffect(effect)
        }
    }

    /// Processes a single side effect, potentially triggering StateChanges.
    /// - Parameter effect: The `SideEffect` to process.
    /// - Throws: An error if processing the side effect fails (e.g., definition not found, apply fails).
    private func processSideEffect(_ effect: SideEffect) async throws {
        switch effect.type {
        case .startFuse:
            let fuseID = try effect.targetID.fuseID()
            guard let definition = fuseDefinitions[fuseID] else {
                throw ActionResponse.internalEngineError("""
                    No FuseDefinition found for fuse ID '\(effect.targetID)' \
                    in startFuse side effect.
                    """)
            }
            let initialTurns = effect.parameters["turns"]?.toInt ?? definition.initialTurns
            let addChange = StateChange(
                entityID: .global,
                attribute: .addActiveFuse(
                    fuseID: fuseID,
                    initialTurns: initialTurns
                ),
                oldValue: gameState.activeFuses[fuseID].map { .int($0) },
                newValue: .int(initialTurns)
            )
            try await applyWithDynamicValidation(addChange)

        case .stopFuse:
            let fuseID = try effect.targetID.fuseID()
            let oldTurns = gameState.activeFuses[fuseID]
            let removeChange = StateChange(
                entityID: .global,
                attribute: .removeActiveFuse(fuseID: fuseID),
                oldValue: oldTurns.map { StateValue.int($0) },
                newValue: .int(0)
            )
            try await applyWithDynamicValidation(removeChange)

        case .runDaemon:
            let daemonID = try effect.targetID.daemonID()
            guard daemonDefinitions[daemonID] != nil else {
                throw ActionResponse.internalEngineError("""
                    No DaemonDefinition found for daemon ID '\(daemonID)' \
                    in runDaemon side effect.
                    """)
            }
            if !gameState.activeDaemons.contains(daemonID) {
                try await applyWithDynamicValidation(
                    StateChange(
                        entityID: .global,
                        attribute: .addActiveDaemon(daemonID: daemonID),
                        oldValue: false,
                        newValue: true
                    )
                )
            }

        case .stopDaemon:
            let daemonID = try effect.targetID.daemonID()
            if gameState.activeDaemons.contains(daemonID) {
                try await applyWithDynamicValidation(
                    StateChange(
                        entityID: .global,
                        attribute: .removeActiveDaemon(daemonID: daemonID),
                        oldValue: true,
                        newValue: false
                    )
                )
            }

        case .scheduleEvent:
            // For now, log that this feature is not yet implemented
            // In the future, this could integrate with a scheduling system
            logWarning("""
                SideEffectType.scheduleEvent for target '\(effect.targetID)' is not yet implemented.
                Parameters: \(effect.parameters)
                """)
        }
    }

    // MARK: - Combat Helpers

    /// Checks if an item can be used as an effective weapon against a target.
    /// Returns true if the item has the weapon flag or is a recognized combat tool.
    public func isEffectiveWeapon(_ itemID: ItemID) async -> Bool {
        guard let targetItem = try? await item(itemID) else { return false }
        return targetItem.hasFlag(.isWeapon) || targetItem.hasFlag(.isTool)
    }

    /// Determines if a character is currently in combat state.
    public func isInCombat(_ itemID: ItemID) async -> Bool {
        guard let targetItem = try? await item(itemID) else { return false }
        return targetItem.hasFlag(.isFighting) && targetItem.hasFlag(.isCharacter)
    }

    /// Generates a random combat outcome based on percentage chance.
    /// Common pattern in ZIL fighting systems.
    public func randomCombatOutcome() async -> Int {
        await randomPercentage()
    }
}
