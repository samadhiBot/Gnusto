import Foundation
import GnustoEngine

/// Implements a lantern timer system similar to Zork's.
/// This demonstrates:
/// 1. Creating daemons that track resource consumption
/// 2. Using fuses for timed warnings
/// 3. Managing state through game flags and properties

// MARK: - Constants

/// The lantern-related constants
public enum LanternConstants {
    /// Default number of turns the lantern stays lit
    public static let defaultBatteryLife = 200

    /// Number of turns at which the "low battery" warning appears
    public static let lowBatteryThreshold = 30

    /// ID for the lantern item
    public static let lanternID: ItemID = "brassLantern"

    /// ID for the lantern timer daemon
    public static let timerDaemonID: DaemonID = "lanternTimerDaemon"

    /// ID for the low battery warning fuse
    public static let lowBatteryWarningFuseID: FuseID = "lanternLowBatteryWarning"

    /// Key for the battery life in gameSpecificState
    public static let batteryLifeKey = "lanternBatteryLife"
}

// MARK: - Daemon Definition

/// Creates a daemon definition for the lantern timer.
/// - Returns: A `DaemonDefinition` that tracks the lantern's battery consumption
@MainActor
public func createLanternTimerDaemon() -> DaemonDefinition {
    return DaemonDefinition(
        id: LanternConstants.timerDaemonID,
        frequency: 1 // Run every turn
    ) { engine in
        // Closure runs every turn to update lantern battery

        let gameState = engine.getCurrentGameState()

        // Precondition: Lantern exists in the game
        guard let lantern = gameState.items[LanternConstants.lanternID] else {
            print("Warning: Lantern item not found in game state")
            return
        }

        // Only proceed if lantern is lit
        guard lantern.hasProperty(.lightSource) && lantern.hasProperty(.on) else {
            return
        }

        // Get current battery life from game state
        // Default to defaultBatteryLife if not set
        let batteryLifeValue = gameState.gameSpecificState?[LanternConstants.batteryLifeKey]?.value as? Int
            ?? LanternConstants.defaultBatteryLife

        // Decrement battery life by 1
        let newBatteryLife = max(0, batteryLifeValue - 1)

        // Update game state with new battery life
        engine.updateGameState { state in
            state.gameSpecificState?[LanternConstants.batteryLifeKey] = AnyCodable(newBatteryLife)
        }

        // Handle different battery states
        switch newBatteryLife {
        case LanternConstants.lowBatteryThreshold:
            // When we hit the threshold, add a fuse for the final warning
            let _ = engine.addFuse(id: LanternConstants.lowBatteryWarningFuseID)
            await engine.output("Your lantern is getting dim.", style: .strong)

        case 0:
            // Battery is fully depleted
            await engine.output("Your lantern has run out of power and is now dark.", style: .strong)

            // Turn off the lantern
            engine.removeItemProperty(itemID: LanternConstants.lanternID, property: .on)

            // Optional: Add darkness-related consequences here
            // (e.g., being eaten by a grue if in a dungeon location)

        default:
            break  // No action needed for other battery levels
        }
    }
}

// MARK: - Fuse Definition

/// Creates a fuse definition for the lantern's low battery warning.
/// - Returns: A `FuseDefinition` that will trigger a final warning before the lantern dies
@MainActor
public func createLanternWarningFuse() -> FuseDefinition {
    return FuseDefinition(
        id: LanternConstants.lowBatteryWarningFuseID,
        initialTurns: LanternConstants.lowBatteryThreshold / 2
    ) { engine in
        // This runs when the fuse triggers (halfway through the remaining battery life)
        await engine.output("Your lantern is getting very dim and will soon run out of power!", style: .strong)
    }
}

// MARK: - Setup Helper

/// Initializes the lantern timer system by registering the daemon and setting initial battery state.
/// - Parameters:
///   - engine: The game engine instance
///   - initialBatteryLife: Optional custom initial battery life (defaults to LanternConstants.defaultBatteryLife)
/// - Returns: True if setup was successful
@MainActor
@discardableResult
public func setupLanternTimer(
    engine: GameEngine,
    initialBatteryLife: Int = LanternConstants.defaultBatteryLife
) -> Bool {
    // Make sure the lantern exists
    guard engine.getCurrentGameState().items[LanternConstants.lanternID] != nil else {
        print("Cannot setup lantern timer: lantern item not found")
        return false
    }

    // Set initial battery life in game state
    engine.updateGameState { state in
        // Initialize gameSpecificState if it doesn't exist
        if state.gameSpecificState == nil {
            state.gameSpecificState = [:]
        }
        state.gameSpecificState?[LanternConstants.batteryLifeKey] = AnyCodable(initialBatteryLife)
    }

    // Register the daemon to start tracking battery life
    return engine.registerDaemon(id: LanternConstants.timerDaemonID)
}

// MARK: - Additional Helper Methods

/// Gets the current battery life of the lantern.
/// - Parameter engine: The game engine instance
/// - Returns: The remaining battery life in turns, or nil if not set
@MainActor
public func getLanternBatteryLife(engine: GameEngine) -> Int? {
    return engine.getCurrentGameState().gameSpecificState?[LanternConstants.batteryLifeKey]?.value as? Int
}

/// Recharges the lantern to the specified battery life.
/// - Parameters:
///   - engine: The game engine instance
///   - amount: The amount to set the battery life to (defaults to full charge)
@MainActor
public func rechargeLantern(
    engine: GameEngine,
    amount: Int = LanternConstants.defaultBatteryLife
) {
    engine.updateGameState { state in
        // Ensure gameSpecificState exists
        if state.gameSpecificState == nil {
            state.gameSpecificState = [:]
        }
        state.gameSpecificState?[LanternConstants.batteryLifeKey] = AnyCodable(amount)
    }

    // Also ensure the lantern daemon is registered
    engine.registerDaemon(id: LanternConstants.timerDaemonID)
}
