import GnustoEngine

enum Handlers {
    static func cloakHandler(_ engine: GameEngine, _ command: Command) async throws -> Bool {
        switch command.verbID {
        case "examine":
            throw ActionError.customResponse("The cloak is unnaturally dark.")

        case "drop":
            if await engine.gameState.player.currentLocationID != "cloakroom" {
                throw ActionError.prerequisiteNotMet(
                    "This isn't the best place to leave a smart cloak lying around."
                )
            } else {
                // Allow the default drop action if in the cloakroom
                return false // Not handled (let default drop proceed)
            }

        default:
            // Any other verb targeting the cloak is not handled by this custom handler.
            return false
        }
    }

    static func messageHandler(_ engine: GameEngine, _ command: Command) async throws -> Bool {
        guard
            command.verbID == "examine",
            await engine.gameState.player.currentLocationID == "bar"
        else {
            return false
        }
        // Fix: Check location exists before accessing properties
        guard let bar = await engine.location(with: "bar") else {
            // Should not happen if game setup is correct
            throw ActionError.internalEngineError("Location 'bar' not found.")
        }
        guard bar.hasFlag(.isLit) else {
            throw ActionError.prerequisiteNotMet("It's too dark to do that.")
        }

        let disturbedCount = await engine.getStateValue(key: "disturbedCounter")?.toInt ?? 0
        let finalMessage: String
        if disturbedCount > 1 {
            finalMessage = "The message simply reads: \"You lose.\""
            await engine.requestQuit()
        } else {
            finalMessage = "The message simply reads: \"You win.\""
            await engine.requestQuit()
        }
        // Throw error to display the message via engine reporting
        throw ActionError.customResponse(finalMessage)
    }
}
