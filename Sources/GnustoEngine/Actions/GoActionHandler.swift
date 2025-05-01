import Foundation

/// Handles movement commands (e.g., "GO NORTH", "NORTH", "N").
public struct GoActionHandler: EnhancedActionHandler {

    public init() {}

    // MARK: - EnhancedActionHandler Methods

    public func validate(command: Command, engine: GameEngine) async throws {
        // 1. Identify Direction
        guard let direction = command.direction else {
            throw ActionError.internalEngineError("Go command processed without a direction.")
        }

        // 2. Get Current Location data
        let currentLocationID = await engine.gameState.player.currentLocationID
        guard let currentLoc = await engine.location(with: currentLocationID) else {
            throw ActionError.internalEngineError("Player's current location ID '\(currentLocationID)' is invalid.")
        }

        // 3. Find Exit
        guard let exit = currentLoc.exits[direction] else {
            throw ActionError.invalidDirection // Standard message: "You can't go that way."
        }

        // 4. Check Exit Conditions

        // Check for static blocked message first
        if let staticBlockedMessage = exit.blockedMessage {
            throw ActionError.directionIsBlocked(staticBlockedMessage)
        }

        // Check required key
        if let keyID = exit.requiredKey {
            let inventory = await engine.items(withParent: .player)
            let playerHasKey = inventory.contains { $0.id == keyID }
            if !playerHasKey {
                // TODO: Check Zork message for lacking a key for a passage
                throw ActionError.directionIsBlocked("You lack the key required to pass.")
            }
        }

        // Check door status if applicable
        if exit.isDoor {
            if !exit.isOpen {
                throw ActionError.directionIsBlocked("The \(direction.rawValue) door is closed.")
            }
            // Note: Lock check removed - UnlockAction should handle setting isLocked = false when isOpen is set true.
            // If a door can be open *and* locked, this needs reconsideration. Zork doors usually auto-unlock when opened.
        }
    }

    public func process(command: Command, engine: GameEngine) async throws -> ActionResult {
        // Validation passed, find exit again (state might have changed, though unlikely for exits)
        guard let direction = command.direction,
              let currentLoc = await engine.location(with: await engine.gameState.player.currentLocationID),
              let exit = currentLoc.exits[direction]
        else {
            // Should not happen if validate passed, but defensive check
            throw ActionError.internalEngineError("Exit disappeared between validate and process for GO command.")
        }

        // --- Create State Change ---
        let oldLocationID = await engine.gameState.player.currentLocationID
        let newLocationID = exit.destination

        let change = StateChange(
            entityId: .player,
            propertyKey: .playerLocation,
            oldValue: .locationID(oldLocationID),
            newValue: .locationID(newLocationID)
        )

        // --- Create Result ---
        // Movement itself doesn't usually print a message; the new location description suffices.
        // The engine's run loop will trigger describeCurrentLocation after state changes.
        return ActionResult(
            success: true,
            message: "", // No specific message for GO action itself
            stateChanges: [change]
        )
    }
}
