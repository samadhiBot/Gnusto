import GnustoEngine

extension CloakOfDarknessGame {
    @MainActor
    public func onEnterRoom(engine: GameEngine, location: LocationID) async -> Bool {
        guard location == "bar" else { return false }
        let cloakIsWorn = engine.itemSnapshot(with: "cloak")?.hasProperty(.worn) ?? false
        if cloakIsWorn {
            engine.updateLocationProperties(id: "bar", removing: .isLit)
        } else {
            engine.updateLocationProperties(id: "bar", adding: .isLit)
        }
        return false
    }

    @MainActor
    public func beforeTurn(engine: GameEngine, command: Command) async -> Bool {
        let locationID = engine.playerLocationID()
        guard locationID == "bar" else { return false } // Only care about the bar

        let cloakIsWorn = engine.itemSnapshot(with: "cloak")?.hasProperty(.worn) ?? false

        if cloakIsWorn {
            // Ensure bar is dark if cloak is worn
            engine.updateLocationProperties(id: "bar", removing: .isLit)

            // Now check for unsafe actions IN THE DARK
            // Re-check lit status *after* potentially removing it
            let isLitNow = engine.locationSnapshot(with: locationID)?.properties.contains(.isLit) ?? false

            // --- DEBUG ---
            await engine.output("[DEBUG] In Hook: verb=\(command.verbID), cloakIsWorn=\(cloakIsWorn), isLitNow=\(isLitNow)", style: .debug)
            // -----------

            if !isLitNow { // Should definitely be false here if update worked
                let verb = command.verbID

                // Original ZIL safe verbs in dark Bar: LOOK, GAME-VERB?, THINK-ABOUT, GO NORTH
                // GAME-VERB? includes meta verbs like QUIT, SCORE, VERBOSE, etc.
                // Let's assume INVENTORY is also implicitly safe as a game state query.
                // ZIL logic: Check if the action is one specifically allowed in the dark.
                let isLook = verb == "look" || verb == "examine"
                let isThinkAbout = verb == "think-about"
                let isMetaVerb = verb == "quit" || verb == "score" || verb == "save" || verb == "restore" || verb == "verbose" || verb == "brief" || verb == "help" || verb == "inventory"
                let isLeavingNorth = verb == "go" && command.direction == .north

                let isActionAllowedInDark = isLook || isThinkAbout || isMetaVerb || isLeavingNorth

                // If the action is NOT specifically allowed, THEN it's an unsafe disturbance.
                if !isActionAllowedInDark {
                    await engine.output("[DEBUG] In Hook: Unsafe action detected! verb=\(verb)", style: .debug)
                    await engine.output("You grope around clumsily in the dark. Better be careful.", style: .normal)
                    engine.incrementGameSpecificStateCounter(key: "disturbedCounter")
                    return true // Handled
                }
            }
            // If we get here, either the room was somehow still lit, or the verb was safe/leaving.
            return false
        } else {
            // Cloak is not worn, ensure bar is lit
            engine.updateLocationProperties(id: "bar", adding: .isLit)
            return false // Hook didn't handle the command itself
        }
    }
}
