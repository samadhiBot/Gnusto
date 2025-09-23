import Foundation

// MARK: - State Change & Side Effect Application

extension GameEngine {
    /// Processes side effects from an ActionResult.
    ///
    /// This method is called by the main action processing pipeline to handle any side effects
    /// that were generated as part of an action's execution.
    ///
    /// - Parameter effects: An array of `SideEffect` objects to process.
    /// - Throws: An error if any side effect cannot be processed.
    func processSideEffects(_ effects: SideEffect...) async throws {
        try await processSideEffects(effects)
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

            // Check both blueprint fuses and standard engine fuses
            guard let definition = fuses[fuseID] else {
                throw ActionResponse.internalEngineError(
                    "No Fuse found for fuse ID '\(effect.targetID)' in startFuse side effect."
                )
            }

            var fuseState: FuseState

            // Extract FuseState from the strongly-typed payload
            if let fuseStateFromPayload = effect.getPayload(as: FuseState.self) {
                fuseState = fuseStateFromPayload
                // If the FuseState has nil turns, use the definition's initialTurns
                if fuseState.turns == nil {
                    fuseState.turns = definition.initialTurns
                }
            } else if let dictionaryPayload = effect.getPayload(as: [String: StateValue].self) {
                // Handle legacy dictionary-based payloads
                let actualTurns = definition.initialTurns
                fuseState = try FuseState(turns: actualTurns, payload: dictionaryPayload)
            } else {
                // Fallback to default state if no payload provided
                fuseState = FuseState(turns: definition.initialTurns)
            }

            let addChange = StateChange.addActiveFuse(
                fuseID: fuseID,
                state: fuseState
            )
            try gameState.apply(addChange)

        case .stopFuse:
            let fuseID = try effect.targetID.fuseID()
            let removeChange = StateChange.removeActiveFuse(fuseID: fuseID)
            try gameState.apply(removeChange)

        case .runDaemon:
            let daemonID = try effect.targetID.daemonID()
            guard daemons[daemonID] != nil else {
                throw ActionResponse.internalEngineError(
                    "No Daemon found for daemon ID '\(daemonID)' in runDaemon side effect."
                )
            }
            if gameState.activeDaemons[daemonID] == nil {
                let initialState = DaemonState()
                try gameState.apply(
                    StateChange.addActiveDaemon(daemonID: daemonID, daemonState: initialState)
                )
            }

        case .stopDaemon:
            let daemonID = try effect.targetID.daemonID()
            if gameState.activeDaemons[daemonID] != nil {
                try gameState.apply(
                    StateChange.removeActiveDaemon(daemonID: daemonID)
                )
            }
        }
    }
}
