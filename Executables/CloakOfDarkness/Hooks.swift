import GnustoEngine

struct Hooks {
    @MainActor
    public func onEnterRoom(engine: GameEngine, location: LocationID) async -> Bool {
        guard location == "bar" else { return false }
        let cloakIsWorn = engine.item(with: "cloak")?.hasProperty(.worn) ?? false
        if cloakIsWorn {
            await engine.applyLocationPropertyChange(locationID: "bar", removing: [LocationProperty.isLit])
        } else {
            await engine.applyLocationPropertyChange(locationID: "bar", adding: [LocationProperty.isLit])
        }
        return false
    }

    @MainActor
    public func beforeTurn(engine: GameEngine, command: Command) async throws -> Bool {
        let locationID = engine.gameState.player.currentLocationID
        guard locationID == "bar" else { return false } // Only care about the bar

        let cloakIsWorn = engine.item(with: "cloak")?.hasProperty(.worn) ?? false

        if cloakIsWorn {
            // Ensure bar is dark if cloak is worn
            await engine.applyLocationPropertyChange(locationID: "bar", removing: [LocationProperty.isLit])

            // Now check for unsafe actions IN THE DARK
            // Re-check lit status *after* potentially removing it
            let isLitNow = engine.location(with: locationID)?.properties.contains(LocationProperty.isLit) ?? false

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
                    // Increment counter
                    let currentCount = engine.getGameSpecificStateValue(forKey: "disturbedCounter")?.value as? Int ?? 0
                    await engine.applyGameSpecificStateChange(key: "disturbedCounter", value: .int(currentCount + 1))

                    // Throw error to display message and halt default action
                    throw ActionError.prerequisiteNotMet("You grope around clumsily in the dark. Better be careful.")
                    // return true // Implicitly handled by throwing
                }
            }
            // If we get here, either the room was somehow still lit, or the verb was safe/leaving.
            return false
        } else {
            // Cloak is not worn, ensure bar is lit
            await engine.applyLocationPropertyChange(locationID: "bar", adding: [LocationProperty.isLit])
            return false // Hook didn't handle the command itself
        }
    }
}
