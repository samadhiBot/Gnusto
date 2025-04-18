import GnustoEngine

@MainActor
extension Components {
    /// Functionality related to weather simulation.
    enum Weather {
        // MARK: - Constants

        /// Constants for weather simulation
        enum Constants {
            /// ID for the weather daemon
            static let weatherDaemonID: DaemonID = "weatherDaemon"

            /// Key for weather state in gameSpecificState
            static let weatherStateKey = "weatherState"
        }

        // MARK: - Daemon Definition

        /// Creates a weather daemon that changes conditions outside.
        static func createWeatherDaemon() -> DaemonDefinition {
            return DaemonDefinition(
                id: Constants.weatherDaemonID,
                frequency: 10 // Change every 10 turns
            ) { engine in
                // Only affects outdoor locations
                let gameState = engine.getCurrentGameState()
                let locationID = gameState.player.currentLocationID
                let location = gameState.locations[locationID]

                // Randomly change the weather
                let weatherStates = ["sunny", "cloudy", "rainy"]
                let currentWeather = gameState.gameSpecificState?[Constants.weatherStateKey]?.value as? String ?? "sunny"

                // Choose a different weather state
                var newWeather = currentWeather
                while newWeather == currentWeather {
                    newWeather = weatherStates.randomElement() ?? "sunny"
                }

                // Update the weather state
                engine.updateGameState { state in
                    if state.gameSpecificState == nil {
                        state.gameSpecificState = [:]
                    }
                    state.gameSpecificState?[Constants.weatherStateKey] = AnyCodable(newWeather)
                }

                // Show weather change message if player is outside
                if location?.hasProperty(.outside) == true {
                    var message = ""
                    switch newWeather {
                    case "sunny":
                        message = "The clouds part, allowing sunlight to stream down through the trees."
                    case "cloudy":
                        message = "Clouds roll in, casting the forest in shadow."
                    case "rainy":
                        message = "Rain begins to fall gently through the forest canopy."
                    default:
                        break
                    }

                    if !message.isEmpty {
                        // Use the shared pending message key (defined in Lantern for now)
                        // TODO: Define pendingMessageKey in a shared location
                        engine.updateGameState { state in
                            state.gameSpecificState?[Components.Lantern.Constants.pendingMessageKey] = AnyCodable(message)
                        }
                    }
                }
            }
        }

        // MARK: - Setup

        /// Initializes the weather system: sets initial state and registers the daemon.
        /// - Parameter engine: The game engine instance.
        static func setupWeather(engine: GameEngine) async {
            // Set initial weather state
            await engine.updateGameState { state in
                // Initialize gameSpecificState if it doesn't exist
                if state.gameSpecificState == nil {
                    state.gameSpecificState = [:]
                }
                // Set initial weather only if not already set
                if state.gameSpecificState?[Constants.weatherStateKey] == nil {
                    state.gameSpecificState?[Constants.weatherStateKey] = AnyCodable("sunny")
                }
            }

            // Register the weather daemon
            let _ = await engine.registerDaemon(id: Constants.weatherDaemonID)
        }
    }
}
