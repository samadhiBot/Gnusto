import Foundation // For print
import GnustoEngine

@MainActor
enum Components {
    /// Functionality related to the Brass Lantern item.
    enum Lantern {
        // MARK: - Constants

        /// Constants for the lantern functionality
        enum Constants {
            /// Default number of turns the lantern stays lit
            static let defaultBatteryLife = 200

            /// Number of turns at which the "low battery" warning appears
            static let lowBatteryThreshold = 30

            /// ID for the lantern item
            static let itemID: ItemID = "brassLantern"

            /// ID for the lantern timer daemon
            static let timerDaemonID: DaemonID = "lanternTimerDaemon"

            /// ID for the low battery warning fuse
            static let lowBatteryWarningFuseID: FuseID = "lanternLowBatteryWarning"

            /// Key for the battery life in gameSpecificState
            static let batteryLifeKey = "lanternBatteryLife"

            /// Flag for pending messages
            static let pendingMessageKey = "pendingMessage" // Shared? Maybe move to Common?
        }

        // MARK: - Setup

        /// Initializes the lantern timer system by registering the daemon and setting initial battery state.
        /// Also sets initial weather state (consider moving weather init).
        /// - Parameter engine: The game engine instance.
        /// - Parameter initialBatteryLife: Optional custom initial battery life
        static func setupLanternTimer(
            engine: GameEngine,
            initialBatteryLife: Int = Constants.defaultBatteryLife
        ) async {
            // Make sure the lantern exists using itemSnapshot for safety
            guard await engine.itemSnapshot(with: Constants.itemID) != nil else {
                // Use Swift.print for simple logging in demo/examples
                Swift.print("Cannot setup lantern timer: lantern item '\(Constants.itemID)' not found")
                return
            }

            // Set initial battery life in game state
            await engine.updateGameState { state in
                // Initialize gameSpecificState if it doesn't exist
                if state.gameSpecificState == nil {
                    state.gameSpecificState = [:]
                }
                state.gameSpecificState?[Constants.batteryLifeKey] = AnyCodable(initialBatteryLife)

                // Weather initialization is now handled in Weather.setupWeather()
                /*
                // TODO: Move Weather initialization to Weather component
                // Set initial weather
                if state.gameSpecificState?[Components.Weather.Constants.weatherStateKey] == nil {
                     state.gameSpecificState?[Components.Weather.Constants.weatherStateKey] = AnyCodable("sunny")
                }
                */
            }

            // Register the daemon to start tracking battery life
            let _ = await engine.registerDaemon(id: Constants.timerDaemonID)

            // Weather daemon registration is now handled in Weather.setupWeather()
            /*
            // TODO: Move Weather daemon registration to Weather component
            // Register the weather daemon (Remove isDaemonRegistered check)
            let _ = engine.registerDaemon(id: Components.Weather.Constants.weatherDaemonID)
            */
        }

        // MARK: - Daemon Definition

        /// Creates a daemon definition for the lantern timer.
        /// - Returns: A `DaemonDefinition` that tracks the lantern's battery consumption
        static func createLanternTimerDaemon() -> DaemonDefinition {
            return DaemonDefinition(
                id: Constants.timerDaemonID,
                frequency: 1 // Run every turn
            ) { engine in
                // Closure runs every turn to update lantern battery
                let gameState = engine.getCurrentGameState()

                // Precondition: Lantern exists in the game
                guard let lantern = gameState.items[Constants.itemID] else {
                    Swift.print("Warning: Lantern item '\(Constants.itemID)' not found in game state for daemon.")
                    return
                }

                // Only proceed if lantern is lit
                guard lantern.hasProperty(.lightSource) && lantern.hasProperty(.on) else {
                    return
                }

                // Get current battery life from game state
                // Default to defaultBatteryLife if not set
                let batteryLifeValue = gameState.gameSpecificState?[Constants.batteryLifeKey]?.value as? Int
                    ?? Constants.defaultBatteryLife

                // Decrement battery life by 1
                let newBatteryLife = max(0, batteryLifeValue - 1)

                // Update game state with new battery life
                engine.updateGameState { state in
                    // Ensure gameSpecificState exists
                    if state.gameSpecificState == nil {
                        state.gameSpecificState = [:]
                    }
                    state.gameSpecificState?[Constants.batteryLifeKey] = AnyCodable(newBatteryLife)
                }

                // Handle different battery states
                switch newBatteryLife {
                case Constants.lowBatteryThreshold:
                    // When we hit the threshold, add a fuse for the final warning
                    let _ = engine.addFuse(id: Constants.lowBatteryWarningFuseID)

                    // Store message to be displayed on next turn
                    engine.updateGameState { state in
                        if state.gameSpecificState == nil { state.gameSpecificState = [:] }
                        state.gameSpecificState?[Constants.pendingMessageKey] = AnyCodable("Your lantern is getting dim.")
                    }

                case 0:
                    // Battery is fully depleted
                    // Store message to be displayed on next turn
                    engine.updateGameState { state in
                        if state.gameSpecificState == nil { state.gameSpecificState = [:] }
                        state.gameSpecificState?[Constants.pendingMessageKey] = AnyCodable("Your lantern has run out of power and is now dark.")
                    }

                    // Turn off the lantern
                    engine.removeItemProperty(itemID: Constants.itemID, property: .on)

                default:
                    break // No action needed for other battery levels
                }
            }
        }

        // MARK: - Fuse Definition

        /// Creates a fuse definition for the lantern's low battery warning.
        /// - Returns: A `FuseDefinition` that will trigger a final warning before the lantern dies
        @MainActor static func createLanternWarningFuse() -> FuseDefinition {
            FuseDefinition(
                id: Constants.lowBatteryWarningFuseID,
                initialTurns: Constants.lowBatteryThreshold / 2
            ) { engine in
                // This runs when the fuse triggers (halfway through the remaining battery life)
                // Store message to be displayed on next turn
                engine.updateGameState { state in
                    if state.gameSpecificState == nil { state.gameSpecificState = [:] }
                    state.gameSpecificState?[Constants.pendingMessageKey] = AnyCodable("Your lantern is getting very dim and will soon run out of power!")
                }
            }
        }
    }
}
