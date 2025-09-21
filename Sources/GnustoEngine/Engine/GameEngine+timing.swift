import Foundation

// MARK: - Timing and Clock Management

extension GameEngine {
    /// Advances the game clock by one tick, processing all active fuses and daemons.
    ///
    /// This method can be called to advance game time by one turn. It performs the following actions:
    /// 1. **Turn Increment**: Increments the player's move counter to advance game time.
    /// 2. **Fuses**: Iterates through all `activeFuses` in `gameState`.
    ///    - Decrements the turn counter for each active fuse.
    ///    - If a fuse's counter reaches zero or less:
    ///        - Retrieves the corresponding `Fuse` from the `GameBlueprint`.
    ///        - Executes the fuse's `action` closure, passing the `GameEngine` instance.
    ///        - Removes the fuse from `activeFuses` in `gameState`.
    ///        - If the fuse's `repeats` flag is `true`, it reactivates the fuse by adding it
    ///          back to `activeFuses` with its `initialTurns` count.
    /// 3. **Daemons**: Iterates through all `activeDaemons` in `gameState`.
    ///    - Retrieves the corresponding `Daemon` from the `GameBlueprint`.
    ///    - Executes the daemon's `action` closure, passing the `GameEngine` instance.
    ///
    /// Fuse and daemon actions can modify game state, print messages (by returning an `ActionResult`
    /// that the engine then processes), or even set `shouldQuit` to end the game.
    /// Errors during fuse/daemon definition lookup or action execution are logged.
    func tickClock() async throws {
        // Increment turn counter FIRST so daemons can see the correct turn number
        try gameState.apply(.incrementPlayerMoves)
        let currentTurn = gameState.player.moves

        // --- Process Fuses ---
        // Explicitly define the action type to match Fuse.action
        typealias FuseActionType = @Sendable (GameEngine, FuseState) async throws -> ActionResult?
        var expiredFuseIDsToExecute:
            [(id: FuseID, action: FuseActionType, definition: Fuse, state: FuseState)] = []

        // Iterate over a copy of keys from gameState.activeFuses for safe modification
        let activeFuseIDsInState = Array(gameState.activeFuses.keys)

        for fuseID in activeFuseIDsInState {
            guard let currentFuseState = gameState.activeFuses[fuseID] else {
                continue
            }

            let newTurns = currentFuseState.turns - 1

            let updateChange = StateChange.updateFuseTurns(fuseID: fuseID, turns: newTurns)
            try gameState.apply(updateChange)

            if newTurns <= 0 {
                // Check both blueprint fuses and standard engine fuses
                guard let definition = fuses[fuseID] else {
                    logger.warning(
                        "TickClock Error: No Fuse found for expiring fuse ID '\(fuseID)'. Cannot execute."
                    )
                    let removeChangeOnError = StateChange.removeActiveFuse(fuseID: fuseID)
                    try gameState.apply(removeChangeOnError)
                    continue
                }
                expiredFuseIDsToExecute.append(
                    (
                        id: fuseID, action: definition.action, definition: definition,
                        state: currentFuseState
                    ))

                let removeChange = StateChange.removeActiveFuse(fuseID: fuseID)
                try gameState.apply(removeChange)
            }
        }

        // Execute actions of expired fuses AFTER all state changes for this tick's expirations are processed
        for fuseToExecute in expiredFuseIDsToExecute {
            if let actionResult = try await fuseToExecute.action(self, fuseToExecute.state) {
                try await processActionResult(actionResult)
            }

            // Handle fuse repetition
            if fuseToExecute.definition.repeats {
                let newFuseState = FuseState(
                    turns: fuseToExecute.definition.initialTurns,
                    payload: fuseToExecute.state.payload
                )
                let restartChange = StateChange.addActiveFuse(
                    fuseID: fuseToExecute.id,
                    state: newFuseState
                )
                try gameState.apply(restartChange)
            }

            if shouldQuit || shouldRestart { return }
        }

        // --- Process Daemons ---
        // Iterate through active daemons and their states
        for (daemonID, daemonState) in gameState.activeDaemons {
            // Get definition from registry
            guard let definition = daemons[daemonID] else {
                logger.warning(
                    "Warning: Active daemon '\(daemonID)' has no definition in registry. Skipping."
                )
                continue
            }

            // Check if it's time for this daemon to run based on frequency
            // Skip execution on turn 0 and run only on turns where currentTurn % frequency == 0
            if currentTurn > 0 && currentTurn % definition.frequency == 0 {
                // Update execution tracking before running the daemon
                let updatedStateForExecution = daemonState.incrementingExecution(
                    currentTurn: currentTurn)

                // Execute the daemon's action with current state
                let (actionResult, newDaemonState) = try await definition.action(
                    self, updatedStateForExecution)

                // Process any action result
                if let actionResult = actionResult {
                    try await processActionResult(actionResult)
                }

                // Update daemon state if the daemon returned a new one
                if let newState = newDaemonState {
                    let updateChange = StateChange.updateDaemonState(
                        daemonID: daemonID, daemonState: newState)
                    try gameState.apply(updateChange)
                } else {
                    // If daemon didn't return new state, still update execution tracking
                    let updateChange = StateChange.updateDaemonState(
                        daemonID: daemonID, daemonState: updatedStateForExecution)
                    try gameState.apply(updateChange)
                }

                if shouldQuit || shouldRestart { return }
            }
        }
    }
}
