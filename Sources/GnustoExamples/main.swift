import Foundation
import GnustoEngine

/// This is the entry point for the GnustoExamples executable.
/// It demonstrates how to set up and run a game using the Gnusto engine.
struct GnustoExamplesApp {
    static func main() async throws {
        print("=== Welcome to the Gnusto Example Game ===")
        print("A demonstration of the Gnusto Interactive Fiction Engine")
        print("----------------------------------------")

        // Create and run the example game
        let game = await ExampleGame()
        await game.run()
    }
}

// Manually handle async main since Swift doesn't support it directly yet
extension GnustoExamplesApp {
    static func main() {
        Task {
            try await main()
        }

        // Keep the process alive until all tasks complete
        RunLoop.main.run()
    }
}

// Call the main function
GnustoExamplesApp.main()
