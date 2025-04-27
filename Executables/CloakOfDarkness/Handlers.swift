import GnustoEngine

@MainActor
struct Handlers {
    func cloakHandler(_ engine: GameEngine, _ command: Command) async -> Bool {
        switch command.verbID {
        case "examine":
            await engine.output("The cloak is unnaturally dark.")
            return true // Handled

        case "drop":
            // Original Inform logic: Prevent dropping outside cloakroom.
            if engine.playerLocationID() != "cloakroom" {
                await engine.output("This isn't the best place to leave a smart cloak lying around.")
                return true // Handled (action prevented)
            } else {
                // Allow the default drop action if in the cloakroom
                return false // Not handled (let default drop proceed)
            }

        default:
            // Any other verb targeting the cloak is not handled by this custom handler.
            return false
        }
    }

    func messageHandler(_ engine: GameEngine, _ command: Command) async -> Bool {
        guard command.verbID == "examine", engine.playerLocationID() == "bar" else { return false }
        guard engine.locationSnapshot(with: "bar")?.properties.contains(.isLit) ?? false else {
            await engine.output("It's too dark to do that.")
            return true
        }
        let disturbedCount = engine.getGameSpecificStateValue(key: "disturbedCounter")?.value as? Int ?? 0
        await engine.output("The message simply reads: \"You ", newline: false)
        if disturbedCount > 1 {
            await engine.output("lose.\"", style: .normal, newline: false)
            engine.quitGame()
        } else {
            await engine.output("win.\"", style: .normal, newline: false)
            engine.quitGame()
        }
        return true
    }
}
