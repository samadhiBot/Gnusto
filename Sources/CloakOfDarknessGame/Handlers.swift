import GnustoEngine

@MainActor
struct Handlers {
    func cloakHandler(_ engine: GameEngine, _ command: Command) async -> Bool {
        guard command.verbID == "examine" else { return false }
        await engine.output("The cloak is unnaturally dark.")
        return true
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
