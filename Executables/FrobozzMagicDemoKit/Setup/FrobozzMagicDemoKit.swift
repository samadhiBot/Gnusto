import GnustoEngine
import Foundation // For print in init

/// A simple example game that demonstrates various Gnusto engine features.
/// This serves as both documentation and a reference implementation.
final class FrobozzMagicDemoKit {
    // MARK: - Properties

    /// The game engine instance that manages the game state.
    let engine: GameEngine

    /// The IO handler for printing messages
    let ioHandler: IOHandler

    // MARK: - Initialization

    /// Creates a new example game with all the necessary components set up.
    /// - Parameter customIOHandler: An optional custom IO handler. If nil, a ConsoleIOHandler is used.
    init(customIOHandler: IOHandler? = nil) async {
        // Set up the game data
        // We assume GameDataSetup is available and provides the necessary static method
        let (initialState, registry) = await GameDataSetup.createGameData()

        // Create the parser
        let parser = StandardParser()

        // Create or use the provided IO handler
        let resolvedIOHandler: IOHandler
        if let customIOHandler = customIOHandler {
            resolvedIOHandler = customIOHandler
        } else {
            resolvedIOHandler = await ConsoleIOHandler()
        }
        self.ioHandler = resolvedIOHandler

        // Create the engine with the initial components
        engine = await GameEngine(
            initialState: initialState,
            parser: parser,
            ioHandler: resolvedIOHandler,
            registry: registry,
            onEnterRoom: Hooks.onEnterRoom,       // Reference actual Hooks
            beforeTurn: Hooks.beforeEachTurn    // Reference actual Hooks
            // Removed onExamineItem registration
            // Removed onOpenItem registration
            // Removed onCloseItem registration
            // Note: Other hooks might be added here later if needed
        )

        // Set up feature components
        await Components.Lantern.setupLanternTimer(engine: engine)
        await Components.Weather.setupWeather(engine: engine)

        // Display an introduction message
        await ioHandler.print("Welcome to the Gnusto Example Adventure!", style: .strong)
        await ioHandler.print(
            """
            This small adventure demonstrates various features of the Gnusto Engine.
            Type 'help' for hints on what to try.
            """,
            style: .emphasis
        )
        await ioHandler.print("", style: .normal)

        await engine.run()
    }

    // Game data setup is handled in GameDataSetup.swift
    // Feature components (Lantern, Weather, etc.) are in Components/
    // Game world definitions (Locations, Items) are in Game/
    // Engine hooks are in Hooks/
    // Timers (Daemons, Fuses) are in Timers/
    // Vocabulary is in Vocabulary/
}
