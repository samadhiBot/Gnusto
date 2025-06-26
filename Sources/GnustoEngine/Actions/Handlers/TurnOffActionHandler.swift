import Foundation

/// Handles the "TURN OFF" command, allowing the player to deactivate items that are
/// considered devices (e.g., light sources).
public struct TurnOffActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.blow, .out, .directObject),
        .match(.switch, .off, .directObject),
        .match(.turn, .off, .directObject),
        .match(.verb, .directObject),
    ]

    public let verbs: [VerbID] = [.extinguish, .douse]

    public let requiresLight: Bool = true

    // MARK: - Action Processing Methods

    public init() {}

    /// Processes the "TURN OFF" command.
    ///
    /// This action validates prerequisites and deactivates the specified device.
    /// Checks that the item exists, is reachable, is a device, and is currently on.
    /// Handles darkness messages when light sources are turned off.
    public func process(command: Command, engine: GameEngine) async throws -> ActionResult {
        // Get direct object and ensure it's an item
        guard let directObjectRef = command.directObject else {
            throw ActionResponse.prerequisiteNotMet(
                engine.messenger.doWhat(verb: command.verb)
            )
        }
        guard case .item(let targetItemID) = directObjectRef else {
            throw ActionResponse.prerequisiteNotMet(
                engine.messenger.thatsNotSomethingYouCan(.extinguish)
            )
        }

        // Check if item exists and is accessible
        let targetItem = try await engine.item(targetItemID)
        guard await engine.playerCanReach(targetItemID) else {
            throw ActionResponse.itemNotAccessible(targetItemID)
        }

        // Check if the item is a device
        guard targetItem.hasFlag(.isDevice) else {
            throw ActionResponse.prerequisiteNotMet(
                engine.messenger.cannotTurnOff()
            )
        }

        // Check if the item is currently on
        guard targetItem.hasFlag(.isOn) else {
            throw ActionResponse.custom(
                engine.messenger.alreadyOff()
            )
        }

        // Check if location will become dark when this light source is turned off
        let isLightSourceBeingTurnedOff = targetItem.hasFlag(.isLightSource)
        var messageParts = [
            engine.messenger.lightIsNowOff(item: targetItem.withDefiniteArticle)
        ]

        if isLightSourceBeingTurnedOff {
            let currentLocation = try await engine.playerLocation()

            // Is the room inherently lit?
            let locationIsInherentlyLit = currentLocation.hasFlag(.inherentlyLit)

            if !locationIsInherentlyLit {
                // Check for other active light sources (inventory or location)
                let allItems = await engine.gameState.items.values
                let otherActiveLightSources = allItems.filter { item in
                    guard item.id != targetItem.id else { return false }
                    let isInPlayerInventory = item.parent == .player
                    let isInCurrentLocation = item.parent == .location(currentLocation.id)
                    let providesLight = item.hasFlag(.isLightSource)
                    let isOn = item.hasFlag(.isOn)
                    return (isInPlayerInventory || isInCurrentLocation) && providesLight && isOn
                }

                if otherActiveLightSources.isEmpty {
                    messageParts.append(engine.messenger.nowDark())
                }
            }
        }

        return ActionResult(
            messageParts.joined(separator: "\n"),
            await engine.setFlag(.isTouched, on: targetItem),
            await engine.clearFlag(.isOn, on: targetItem),
            await engine.updatePronouns(to: targetItem)
        )
    }
}
