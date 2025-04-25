import GnustoEngine
import Foundation // For print

/// Container for game-specific engine hook implementations.
@MainActor
enum Hooks {

    // MARK: - Engine Hooks

    /// Custom logic that runs when the player enters a room.
    /// - Parameters:
    ///   - engine: The game engine.
    ///   - locationID: The ID of the location being entered.
    static func onEnterRoom(engine: GameEngine, locationID: LocationID) async -> Bool {
        // Use safe accessors
        let flagKey = "visited_treasure_room"
        let hasVisitedTreasure = engine.getFlagValue(key: flagKey) ?? false

        // Check for special room behaviors
        switch locationID {
        case "treasureRoom":
            if !hasVisitedTreasure {
                await engine.output("You've discovered the legendary treasure room!", style: .strong)
                // Use safe mutators
                engine.setFlagValue(key: flagKey, value: true)
                engine.updatePlayerScore(delta: 10) // Award points for discovery
            }

        case "undergroundPool":
            // Special atmosphere for the underground pool
            await engine.output(
                """
                The water in the pool ripples slightly as you enter, \
                disrupting the perfect mirror-like surface.
                """,
                style: .emphasis
            )

        case "hiddenVault":
            // Use safe accessors
            let vaultFlag = "visited_vault"
            let hasVisitedVault = engine.getFlagValue(key: vaultFlag) ?? false

            if !hasVisitedVault {
                await engine.output(
                    """
                    As you enter, the runes on the walls pulse with energy. \
                    You feel you've discovered something truly ancient and powerful.
                    """,
                    style: .strong
                )
                // Use safe mutators
                engine.setFlagValue(key: vaultFlag, value: true)
                engine.updatePlayerScore(delta: 15) // Award points for discovery
            }

        default:
            break
        }

        return false
    }

    /// Custom logic that runs at the start of each turn.
    /// - Parameter engine: The game engine.
    /// - Parameter command: The command about to be executed.
    static func beforeEachTurn(engine: GameEngine, command: Command) async -> Bool {
        // Use safe accessors
        let messageValue = engine.getGameSpecificStateValue(key: Components.Lantern.Constants.pendingMessageKey)

        // Check for pending messages from daemons or fuses
        if let pendingMessage = messageValue?.value as? String {
            await engine.output(pendingMessage)

            // Clear the pending message by removing the key
            engine.removeGameSpecificStateValue(key: Components.Lantern.Constants.pendingMessageKey)
        }

        // Add atmospheric messages based on location
        let locationID = engine.playerLocationID() // Safe accessor
        let turnCount = engine.playerMoves()      // Safe accessor

        // Only show atmospheric messages occasionally (every 5 turns)
        guard turnCount % 5 == 0 else { return false }

        switch locationID {
        case "darkChamber":
            await engine.output("A faint dripping sound echoes in the darkness.", style: .emphasis)
        case "treasureRoom":
            await engine.output("The gems in the walls glitter mysteriously.", style: .emphasis)
        case "outside", "streamBank":
            // Weather effects for outside areas
            if let weatherState = engine.getGameSpecificStateString(key: Components.Weather.Constants.weatherStateKey) {
                switch weatherState {
                case "sunny":
                    await engine.output("Sunlight filters through the trees above you.", style: .emphasis)
                case "cloudy":
                    await engine.output("Gray clouds drift overhead, dimming the light.", style: .emphasis)
                case "rainy":
                    await engine.output("Raindrops patter on the leaves around you.", style: .emphasis)
                default:
                    break
                }
            }
        case "crystalGrotto":
            await engine.output("The crystals around you shimmer with refracted light.", style: .emphasis)
        case "undergroundPool":
            await engine.output("The water in the pool is eerily still, like black glass.", style: .emphasis)
        default:
            break
        }

        return false
    }

    // MARK: - Helper Functions

    /// Check if the player has an active light source in their inventory.
    /// Includes the lantern (if lit) and the glowing gem.
    /// - Parameter engine: The game engine.
    /// - Returns: `true` if the player has an active light source.
    private static func hasActiveLight(engine: GameEngine) async -> Bool {
        // Get player's directly held items
        let playerItemIDs = engine.itemSnapshots(withParent: .player).map { $0.id }

        // Check for the lantern specifically
        if playerItemIDs.contains(Components.Lantern.Constants.itemID) {
            let lantern = engine.itemSnapshot(with: Components.Lantern.Constants.itemID)
            if lantern?.hasProperty(.on) == true {
                return true // Lit lantern found
            }
        }

        // Check for other light sources (like the glowing gem)
        for itemID in playerItemIDs {
            let item = engine.itemSnapshot(with: itemID)
            // Check if it's a light source BUT NOT the lantern (already checked)
            if itemID != Components.Lantern.Constants.itemID,
               item?.hasProperty(.lightSource) == true
            {
                // Assume non-lantern light sources are always 'on' if they have the property
                // (like the largeGem)
                return true
            }
        }

        return false // No active light source found
    }
}
