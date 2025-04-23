import CloakOfDarknessGame
import GnustoEngine

/// Main entry point for the Cloak of Darkness replica.
struct CloakOfDarkness {
    @MainActor
    static func main() async {
        print("Initializing Cloak of Darkness...\n")

        let game = CloakOfDarknessGame()
        let ioHandler = await ConsoleIOHandler()
        let parser = StandardParser()

        let engine = GameEngine(
            initialState: game.state,
            parser: parser,
            ioHandler: ioHandler,
            registry: game.registry,
            onEnterRoom: game.onEnterRoom,
            beforeTurn: game.beforeTurn
        )

        // --- Run Game ---
        await engine.run()

        print("\nThank you for playing Cloak of Darkness!")
    }
}
