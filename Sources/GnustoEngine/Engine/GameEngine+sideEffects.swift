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

    /// Processes a single side effect, potentially triggering StateChanges.
    /// - Parameter effect: The `SideEffect` to process.
    /// - Throws: An error if processing the side effect fails (e.g., definition not found, apply fails).
    private func processSideEffect(_ effect: SideEffect, gameState: inout GameState) throws {
        switch effect.type {
        case .startFuse:
            let fuseID = try effect.targetID.fuseID()
            guard let definition = definitionRegistry.fuseDefinitions[fuseID] else {
                throw ActionResponse.internalEngineError("""
                    No FuseDefinition found for fuse ID '\(effect.targetID)' \
                    in startFuse side effect.
                    """)
            }
            let initialTurns = effect.parameters["turns"]?.toInt ?? definition.initialTurns
            let addChange = StateChange(
                entityID: .global,
                attributeKey:
                        .addActiveFuse(
                            fuseID: definition.id,
                            initialTurns: initialTurns
                        ),
                oldValue: gameState.activeFuses[definition.id].map { .int($0) },
                newValue: .int(initialTurns)
            )
            try gameState.apply(addChange)

        case .stopFuse:
            let fuseID = try effect.targetID.fuseID()
            let oldTurns = gameState.activeFuses[fuseID]
            let removeChange = StateChange(
                entityID: .global,
                attributeKey: .removeActiveFuse(fuseID: fuseID),
                oldValue: oldTurns.map { StateValue.int($0) },
                newValue: .int(0)
            )
            try gameState.apply(removeChange)

        case .runDaemon:
            let daemonID = try effect.targetID.daemonID()
            guard definitionRegistry.daemonDefinitions[daemonID] != nil else {
                throw ActionResponse.internalEngineError("""
                    No DaemonDefinition found for daemon ID '\(daemonID)' \
                    in runDaemon side effect.
                    """)
            }
            if !gameState.activeDaemons.contains(daemonID) {
                try gameState.apply(
                    StateChange(
                        entityID: .global,
                        attributeKey: .addActiveDaemon(daemonID: daemonID),
                        oldValue: false,
                        newValue: true
                    )
                )
            }

        case .stopDaemon:
            let daemonID = try effect.targetID.daemonID()
            if gameState.activeDaemons.contains(daemonID) {
                try gameState.apply(
                    StateChange(
                        entityID: .global,
                        attributeKey: .removeActiveDaemon(daemonID: daemonID),
                        oldValue: true,
                        newValue: false
                    )
                )
            }

        case .scheduleEvent:
            // For scheduleEvent, effect.targetID (EntityID) can be used directly
            // without needing to convert it to a definition key.
            // The actual scheduling logic would go here.
            print("Warning: SideEffectType.scheduleEvent for target '\(effect.targetID)' not yet fully implemented.")
        }
    }
}
