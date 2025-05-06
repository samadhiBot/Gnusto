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
                let locationID = engine.gameState.player.currentLocationID
                let location = engine.location(with: locationID)

                // Randomly change the weather
                let weatherStates = ["sunny", "cloudy", "rainy"]
                let currentWeather = engine.getStateValue(key: Constants.weatherStateKey)?.value as? String ?? "sunny"

                // Choose a different weather state
                var newWeather = currentWeather
                while newWeather == currentWeather {
                    newWeather = weatherStates.randomElement() ?? "sunny"
                }

                // Update the weather state
                engine.updateGameSpecificState(key: Constants.weatherStateKey, value: AnyCodable(newWeather))

                // Show weather change message if player is outside
                if location?.attributes.contains(.outside) == true {
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
                        // Use updateGameSpecificState to set the pending message
                        engine.updateGameSpecificState(
                            key: Components.Lantern.Constants.pendingMessageKey,
                            value: AnyCodable(message)
                        )
                    }
                }
            }
        }

        // MARK: - Setup

        /// Initializes the weather system: sets initial state and registers the daemon.
        /// - Parameter engine: The game engine instance.
        @MainActor
        static func setupWeather(engine: GameEngine) async {
            // Set initial weather state using updateGameSpecificState
            // It safely handles nil dictionary and existing keys
            // Needs await for MainActor isolated call
            if engine.getStateValue(key: Constants.weatherStateKey) == nil {
                engine.updateGameSpecificState(key: Constants.weatherStateKey, value: AnyCodable("sunny"))
            }

            // Register the weather daemon
            // Needs await for MainActor isolated call
            let _ = engine.registerDaemon(id: Constants.weatherDaemonID)
        }
    }
}
