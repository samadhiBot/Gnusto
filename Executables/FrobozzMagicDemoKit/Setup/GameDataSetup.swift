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
        let player = Player(in: "startRoom") // Start room ID

        // Build vocabulary
        let vocabulary = Vocabulary.build(items: items, verbs: verbs)

        // Create state
        let initialState = GameState(
            locations: locations,
            items: items,
            player: player,
            vocabulary: vocabulary
        )

        // --- Define Object Action Handlers ---
        let objectActionHandlers: [ItemID: ObjectActionHandler] = [
            // Handle OPEN/CLOSE/EXAMINE for Iron Door
            "ironDoor": { engine, command in
                switch command.verbID {
                case "open":
                    // Use updateLocationExits to modify the state
                    engine.updateLocationExits(
                        id: "ironDoorRoom",
                        adding: [.east: Exit(destination: "hiddenVault")]
                    )
                    return false // Allow default message
                case "close":
                    // Use updateLocationExits to modify the state
                    engine.updateLocationExits(
                        id: "ironDoorRoom",
                        removing: .east
                    )
                    return false // Allow default message
                case "examine":
                    let item = engine.item(with: "ironDoor") // We know the ID
                    let isLocked = item?.hasProperty(.locked) ?? true
                    let isOpen = item?.hasProperty(.open) ?? false

                    if !isLocked && isOpen {
                        await engine.output("A massive iron door that stands open now, revealing a passage to the east. The ancient runes around its frame glow faintly.")
                    } else if !isLocked {
                        await engine.output("A massive iron door, currently closed but unlocked. Ancient runes are inscribed around its frame, with a keyhole below the handle.")
                    } else {
                        await engine.output("A massive iron door, firmly shut and locked. Ancient runes are inscribed around its frame, with a keyhole below the handle.")
                    }
                    return true // Handled examine
                default:
                    return false // Did not handle other verbs
                }
            },

            // Handle EXAMINE for Lantern
            Components.Lantern.Constants.itemID: { engine, command in
                switch command.verbID {
                case "examine":
                    guard let itemID = command.directObject else { return false } // Should have DO for examine
                    // Access game specific state directly via engine helper
                    let item = engine.item(with: itemID)
                    // Use getStateValue to get the value safely
                    if let batteryLife = engine.getStateValue(key: Components.Lantern.Constants.batteryLifeKey)?.value as? Int {
                        let status = item?.hasProperty(.on) == true ? "lit" : "unlit"
                        await engine.output(
                            """
                            A sturdy brass lantern, currently \(status). It appears to have about \
                            \(batteryLife) turns of battery life remaining.
                            """
                        )
                        return true // Handled the examination
                    } else {
                        return false // Fallback to default examine handler
                    }
                default:
                    return false // Did not handle other verbs
                }
            },

            // Handle EXAMINE for Dark Pool
            "darkPool": { engine, command in
                switch command.verbID {
                case "examine":
                    await engine.output(
                        """
                        Looking into the clear, dark water, you can see what look like ancient \
                        artifacts resting on the bottom. They're just out of reach, but seem \
                        to be made of precious metals.
                        """
                    )
                    return true // Handled the examination
                default:
                    return false // Did not handle other verbs
                }
            },

            // Handle EXAMINE for Mysterious Altar
            "mysteriousAltar": { engine, command in
                switch command.verbID {
                case "examine":
                     await engine.output(
                        """
                        The altar is carved from a single piece of dark stone. The basin on top \
                        contains a swirling, iridescent liquid that seems to change colors as you watch. \
                        The liquid gives off a faint, pleasant aroma.
                        """
                    )
                    return true // Handled examine
                 default:
                    return false
                }
            }
        ]

        // Create registry with fuses, daemons, and object handlers
        let registry = GameDefinitionRegistry(
            fuseDefinitions: [
                Components.Lantern.createLanternWarningFuse()
            ],
            daemonDefinitions: [
                Components.Lantern.createLanternTimerDaemon(),
                Components.Weather.createWeatherDaemon()
            ],
            objectActionHandlers: objectActionHandlers // Pass handlers
        )

        return (initialState, registry)
    }
}

// Placeholders removed, assuming actual files exist now.
