import CloakOfDarknessGame
import GnustoEngine

/// Main entry point for the Cloak of Darkness replica.
struct CloakOfDarkness {
    @MainActor
    static func main() async {
        print("Initializing Cloak of Darkness...\n")

        let engine = GameEngine(
            game: CloakOfDarknessGame(),
            parser: StandardParser(),
            ioHandler: await ConsoleIOHandler()
        )

        await engine.run()

        print("\nThank you for playing Cloak of Darkness!")
    }
}
