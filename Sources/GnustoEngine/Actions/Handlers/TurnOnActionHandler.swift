import Foundation

/// Handles the "TURN ON" command, allowing the player to activate items that are
/// considered devices (e.g., light sources).
public struct TurnOnActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.light, .directObject),
        .match(.switch, .on, .directObject),
        .match(.turn, .on, .directObject),
    ]

    public let actions: [Intent] = [.lightSource, .burn]

    public let requiresLight: Bool = true

    // MARK: - Action Processing Methods

    public init() {}

    /// Processes the "TURN ON" command.
    ///
    /// This action validates prerequisites and activates the specified item if possible.
    /// Handles both devices (can be turned on/off) and flammable objects (can be burned).
    /// Devices take precedence over flammable behavior.
    public func process(command: Command, engine: GameEngine) async throws -> ActionResult {
        // Get direct object and ensure it's an item
        guard let directObjectRef = command.directObject else {
            throw ActionResponse.prerequisiteNotMet(
                engine.messenger.doWhat(verb: command.verb)
            )
        }
        guard case .item(let targetItemID) = directObjectRef else {
            throw ActionResponse.prerequisiteNotMet(
                engine.messenger.thatsNotSomethingYouCan(.light)
            )
        }

        // Fetch the item
        let targetItem = try await engine.item(targetItemID)

        // Verify the item is reachable (with light source exception in dark)
        let currentLocationID = await engine.playerLocationID
        let isHeld = targetItem.parent == .player
        let isInLocation = targetItem.parent == .location(currentLocationID)
        let isLightSource = targetItem.hasFlag(.isLightSource)
        let roomIsDark = await engine.playerLocationIsLit() == false

        var isReachable = false
        if isHeld {
            isReachable = true
        } else if isInLocation {
            // If it's a light source in a dark room, consider it reachable to turn on
            if roomIsDark && isLightSource {
                isReachable = true
            } else {
                // Otherwise, standard reachability check
                isReachable = await engine.playerCanReach(targetItemID)
            }
        }
        guard isReachable else {
            throw ActionResponse.itemNotAccessible(targetItemID)
        }

        // Check if the item is either a device or flammable
        let isDevice = targetItem.hasFlag(.isDevice)
        let isFlammable = targetItem.hasFlag(.isFlammable)

        guard isDevice || isFlammable else {
            throw ActionResponse.prerequisiteNotMet(
                engine.messenger.cannotTurnOn()
            )
        }

        // If it's flammable but not a device, delegate to burn logic
        if isFlammable && !isDevice {
            return try await processBurn(targetItem: targetItem, engine: engine)
        }

        // For devices, check if it's already on
        if isDevice && targetItem.hasFlag(.isOn) {
            throw ActionResponse.custom(
                engine.messenger.alreadyOn()
            )
        }

        // Check if room was dark before turning on the light
        let wasRoomDark = await engine.playerLocationIsLit() == false

        var messageParts: [String] = []
        messageParts.append("The \(targetItem.name) is now on.")

        // Check if turning on this light source illuminated a dark room
        if wasRoomDark && isLightSource {
            let currentLocation = try await engine.playerLocation()
            let locationIsInherentlyLit = currentLocation.hasFlag(.inherentlyLit)

            if !locationIsInherentlyLit {
                // This light source will provide light once turned on
                messageParts.append("You can see your surroundings now.")
            }
        }

        return ActionResult(
            messageParts.joined(separator: "\n"),
            await engine.setFlag(.isTouched, on: targetItem),
            await engine.setFlag(.isOn, on: targetItem)
        )
    }

    // MARK: - Helper Methods

    /// Processes the burn logic when a flammable (but non-device) item is "turned on".
    ///
    /// This method implements the same logic as `BurnActionHandler` for flammable items.
    /// It's called when the player uses "light" or "turn on" on a flammable object.
    ///
    /// - Parameters:
    ///   - targetItem: The flammable item to burn.
    ///   - engine: The game engine instance.
    /// - Returns: An `ActionResult` with burn-specific messaging and state changes.
    private func processBurn(
        targetItem: Item,
        engine: GameEngine
    ) async throws -> ActionResult {
        // Check if the item is flammable (should always be true in this context)
        if targetItem.hasFlag(.isFlammable) {
            return ActionResult(
                engine.messenger.itemBurnsToAshes(item: targetItem.withDefiniteArticle),
                await engine.setFlag(.isTouched, on: targetItem),
                await engine.updatePronouns(to: targetItem),
                await engine.move(targetItem, to: .nowhere)
            )
        } else {
            // Fallback message for non-flammable items (shouldn't reach here due to validation)
            return ActionResult(
                engine.messenger.cannotDoThat(
                    verb: .burn,
                    item: targetItem.withDefiniteArticle
                ),
                await engine.setFlag(.isTouched, on: targetItem),
                await engine.updatePronouns(to: targetItem)
            )
        }
    }
}
