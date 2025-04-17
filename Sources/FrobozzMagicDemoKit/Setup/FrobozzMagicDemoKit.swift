import GnustoEngine

/// A simple example game that demonstrates various Gnusto engine features.
/// This serves as both documentation and a reference implementation.
@MainActor
final class FrobozzMagicDemoKit {
    // MARK: - Properties

    /// The game engine instance that manages the game state.
    let engine: GameEngine

    /// The IO handler for printing messages
    let ioHandler: IOHandler

    // Initialization is handled in FrobozzMagicDemoKit+Init.swift
    // Game data setup is handled in GameDataSetup.swift
    // Feature components (Lantern, Weather, etc.) are in Components/
    // Game world definitions (Locations, Items) are in Game/
    // Engine hooks are in Hooks/
    // Timers (Daemons, Fuses) are in Timers/
    // Vocabulary is in Vocabulary/
}
