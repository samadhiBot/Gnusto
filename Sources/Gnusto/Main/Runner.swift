import Foundation

/// Main entry point for running Gnusto games
public class Runner {
    /// Run a game
    /// - Parameter game: The game to run
    public static func run(_ game: Game) {
        // Create a renderer
        let renderer = Console()

        do {
            // Create the engine
            let engine = try Engine(game: game, renderer: renderer)

            // Start the game
            try engine.start()
        } catch {
            print("Error running game: \(error)")
        }
    }
}
