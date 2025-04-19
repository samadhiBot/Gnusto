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
    static func onEnterRoom(engine: GameEngine, locationID: LocationID) async {
        let gameState = engine.getCurrentGameState()

        // Check for special room behaviors
        switch locationID {
        case "treasureRoom":
            // First-time treasure room discovery
            let flag = "visited_treasure_room"
            let hasVisited = gameState.flags[flag] ?? false

            if !hasVisited {
                await engine.output("You've discovered the legendary treasure room!", style: .strong)
                engine.updateGameState { state in
                    state.flags[flag] = true
                    state.player.score += 10 // Award points for discovery
                }
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
            // First-time vault discovery
            let flag = "visited_vault"
            let hasVisited = gameState.flags[flag] ?? false

            if !hasVisited {
                await engine.output(
                    """
                    As you enter, the runes on the walls pulse with energy. \
                    You feel you've discovered something truly ancient and powerful.
                    """,
                    style: .strong
                )
                engine.updateGameState { state in
                    state.flags[flag] = true
                    state.player.score += 15 // Award points for discovery
                }
            }

        default:
            break
        }
    }

    /// Custom logic that runs at the start of each turn.
    /// - Parameter engine: The game engine.
    static func beforeEachTurn(engine: GameEngine) async {
        let gameState = engine.getCurrentGameState()

        // Check for pending messages from daemons or fuses
        // TODO: Use a more robust pending message system if multiple sources exist
        if let pendingMessage = gameState.gameSpecificState?[Components.Lantern.Constants.pendingMessageKey]?.value as? String {
            await engine.output(pendingMessage)

            // Clear the pending message
            engine.updateGameState { state in
                state.gameSpecificState?[Components.Lantern.Constants.pendingMessageKey] = nil
            }
        }

        // Add atmospheric messages based on location
        let locationID = gameState.player.currentLocationID
        let turnCount = gameState.player.moves

        // Only show atmospheric messages occasionally (every 5 turns)
        guard turnCount % 5 == 0 else { return }

        switch locationID {
        case "darkChamber":
            await engine.output("A faint dripping sound echoes in the darkness.", style: .emphasis)
        case "treasureRoom":
            await engine.output("The gems in the walls glitter mysteriously.", style: .emphasis)
        case "outside", "streamBank":
            // Weather effects for outside areas
            if let weatherState = gameState.gameSpecificState?[Components.Weather.Constants.weatherStateKey]?.value as? String {
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
    }

    /// Custom logic that runs when examining specific items.
    /// - Parameters:
    ///   - engine: The game engine.
    ///   - itemID: The ID of the item being examined.
    /// - Returns: `true` if the examination was handled, `false` to use default behavior.
    static func onExamineItem(engine: GameEngine, itemID: ItemID) async -> Bool {
        let gameState = engine.getCurrentGameState()

        switch itemID {
        case CaveRegion.brassLantern.id:
            // Custom lantern examination
            let item = engine.itemSnapshot(with: itemID)

            // Get the battery life, if available
            if let batteryLife = gameState.gameSpecificState?[Components.Lantern.Constants.batteryLifeKey]?.value as? Int {
                let status = item?.hasProperty(.on) == true ? "lit" : "unlit"
                let description = """
                    A sturdy brass lantern, currently \(status). It appears to have about \
                    \(batteryLife) turns of battery life remaining.
                    """
                await engine.output(description)
                return true // Handled
            } else {
                // Fallback if battery life isn't tracked (shouldn't normally happen)
                return false // Use default description
            }

        case "darkPool":
            // Custom pool examination
            await engine.output(
                """
                Looking into the clear, dark water, you can see what look like ancient \
                artifacts resting on the bottom. They're just out of reach, but seem \
                to be made of precious metals.
                """
            )
            return true // Handled

        case CaveRegion.ironDoor.id:
            // Custom door examination
            let isUnlocked = gameState.flags[Components.IronDoorPuzzle.Constants.doorUnlockedFlag] == true
            let item = engine.itemSnapshot(with: itemID)
            let isOpen = item?.hasProperty(.open) == true

            if isUnlocked && isOpen {
                await engine.output(
                    """
                    A massive iron door that stands open now, revealing a passage to the east. \
                    The ancient runes around its frame glow with a faint blue light.
                    """
                )
            } else if isUnlocked {
                 await engine.output(
                    """
                    A massive iron door, currently closed but unlocked. Ancient runes are \
                    inscribed around its frame, and there's a keyhole below the heavy handle.
                    """
                )
            } else {
                await engine.output(
                    """
                    A massive iron door, firmly shut and locked. Ancient runes are inscribed \
                    around its frame, and there's a keyhole below the heavy handle.
                    """
                )
            }
            return true // Handled

        case "mysteriousAltar":
            // Custom altar examination
            await engine.output(
                """
                The altar is carved from a single piece of dark stone. The basin on top \
                contains a swirling, iridescent liquid that seems to change colors as you watch. \
                The liquid gives off a faint, pleasant aroma.
                """
            )
            return true // Handled

        default:
            return false // Not handled, use default engine behavior
        }
    }

    /// Custom logic called after an item is successfully opened.
    /// - Parameters:
    ///   - engine: The game engine.
    ///   - itemID: The ID of the item being opened.
    /// - Returns: `true` to suppress the default "You open..." message, `false` otherwise.
    static func onOpenItem(engine: GameEngine, itemID: ItemID) async -> Bool {
        switch itemID {
        case "ironDoor":
            await engine.updateGameState { state in
                let ironDoorRoomID: LocationID = "ironDoorRoom"
                let vaultID: LocationID = "hiddenVault"
                // Ensure the room exists before modifying
                if state.locations[ironDoorRoomID] != nil {
                    state.locations[ironDoorRoomID]?.exits[.east] = Exit(destination: vaultID)
                    // print("HOOK DEBUG: Added east exit to ironDoorRoom.") // Debug print
                }
            }
            return false // Still print default message "You open the door."
        default:
            return false // Use default behavior for other items
        }
    }

    /// Custom logic called after an item is successfully closed.
    /// - Parameters:
    ///   - engine: The game engine.
    ///   - itemID: The ID of the item being closed.
    /// - Returns: `true` to suppress the default "You close..." message, `false` otherwise.
    static func onCloseItem(engine: GameEngine, itemID: ItemID) async -> Bool {
        switch itemID {
        case "ironDoor":
            await engine.updateGameState { state in
                let ironDoorRoomID: LocationID = "ironDoorRoom"
                // Ensure the room exists before modifying
                if state.locations[ironDoorRoomID] != nil {
                    state.locations[ironDoorRoomID]?.exits.removeValue(forKey: .east)
                    // print("HOOK DEBUG: Removed east exit from ironDoorRoom.") // Debug print
                }
            }
            return false // Still print default message "You close the door."
        default:
            return false // Use default behavior for other items
        }
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
