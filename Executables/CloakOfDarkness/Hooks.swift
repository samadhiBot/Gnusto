//import GnustoEngine
//
//struct Hooks {
//        public func onEnterRoom(engine: GameEngine, location: LocationID) async -> Bool {
//        guard location == "bar" else { return false }
//        let cloakIsWorn = try await engine.item("cloak")?.hasFlag(.isWorn) ?? false
//        if cloakIsWorn {
//            try? await engine
//                .setDynamicLocationValue(locationID: "bar", key: .isLit, newValue: .bool(false))
//        } else {
//            try? await engine.setDynamicLocationValue(locationID: "bar", key: .isLit, newValue: true,)
//        }
//        return false
//    }
//
//        public func beforeTurn(engine: GameEngine, command: Command) async throws -> Bool {
//        let locationID = await engine.playerLocationID
//        guard locationID == "bar" else { return false } // Only care about the bar
//
//        let cloakIsWorn = try await engine.item("cloak")?.hasFlag(.isWorn) ?? false
//
//        if cloakIsWorn {
//            // Ensure bar is dark if cloak is worn
//            try? await engine.setDynamicLocationValue(locationID: "bar", key: .isLit, newValue: .bool(false))
//
//            // Now check for unsafe actions IN THE DARK
//            // Re-check lit status *after* potentially removing it
//            let isLitNow = await engine.location(locationID)?.hasFlag(.isLit) ?? false
//
//            if !isLitNow { // Should definitely be false here if update worked
//                let verb = command.verbID
//
//                // Original ZIL safe verbs in dark Bar: LOOK, GAME-VERB?, THINK-ABOUT, GO NORTH
//                // GAME-VERB? includes meta verbs like QUIT, SCORE, VERBOSE, etc.
//                // Let's assume INVENTORY is also implicitly safe as a game state query.
//                // ZIL logic: Check if the action is one specifically allowed in the dark.
//                let isLook = verb == "look" || verb == "examine"
//                let isThinkAbout = verb == "think-about"
//                let isMetaVerb = verb == "quit" || verb == "score" || verb == "save" || verb == "restore" || verb == "verbose" || verb == "brief" || verb == "help" || verb == "inventory"
//                let isLeavingNorth = verb == "go" && command.direction == .north
//
//                let isActionAllowedInDark = isLook || isThinkAbout || isMetaVerb || isLeavingNorth
//
//                // If the action is NOT specifically allowed, THEN it's an unsafe disturbance.
//                if !isActionAllowedInDark {
//                    // Increment counter
//                    let currentCount = await engine.getStateValue(key: "disturbedCounter")?.toInt ?? 0
//                    await engine.applyGameSpecificStateChange(
//                        key: "disturbedCounter",
//                        value: .int(currentCount + 1)
//                    )
//
//                    // Throw error to display message and halt default action
//                    throw ActionResponse.prerequisiteNotMet("You grope around clumsily in the dark. Better be careful.")
//                    // return true // Implicitly handled by throwing
//                }
//            }
//            // If we get here, either the room was somehow still lit, or the verb was safe/leaving.
//            return false
//        } else {
//            // Cloak is not worn, ensure bar is lit
//            try? await engine.setDynamicLocationValue(locationID: "bar", key: .isLit, newValue: true,)
//            return false // Hook didn't handle the command itself
//        }
//    }
//}
