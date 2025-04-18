import GnustoEngine

/// Handles the creation of initial game state and registry.
@MainActor
enum GameDataSetup {
    /// Creates the initial game state and registry with all necessary game data.
    /// - Returns: A tuple containing the initial `GameState` and `GameDefinitionRegistry`.
    static func createGameData() async -> (GameState, GameDefinitionRegistry) {
        // Create locations (defined in Game/*)
        let locations = CaveRegion.locations + ForestRegion.locations

        // Create items (defined in Game/*)
        let items = CaveRegion.items + ForestRegion.items

        // Define verbs (defined in Vocabulary/Vocabulary.swift)
        let verbs = VocabularySetup.verbs // Assuming verbs are defined here

        // Create player
        let player = Player(currentLocationID: "startRoom") // Start room ID

        // Build vocabulary
        let vocabulary = Vocabulary.build(items: items, verbs: verbs)

        // Create state
        let initialState = GameState.initial(
            initialLocations: locations,
            initialItems: items,
            initialPlayer: player,
            vocabulary: vocabulary
        )

        // Create registry with fuses and daemons (defined in Timers/* and Components/*)
        let registry = GameDefinitionRegistry(
            fuseDefinitions: [
                Components.Lantern.createLanternWarningFuse()
                // Add other fuses here if any
            ],
            daemonDefinitions: [
                Components.Lantern.createLanternTimerDaemon(),
                Components.Weather.createWeatherDaemon()
                // Add other daemons here if any
            ]
        )

        return (initialState, registry)
    }
}

// Placeholders removed, assuming actual files exist now.
