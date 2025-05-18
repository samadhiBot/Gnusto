import Foundation

/// Handles the "TURN ON" action for items, primarily light sources.
struct TurnOnActionHandler: ActionHandler {

    // MARK: - ActionHandler Methods

    func validate(context: ActionContext) async throws {
        // 1. Get direct object and ensure it's an item
        guard let directObjectRef = context.command.directObject else {
            throw ActionResponse.custom("Turn on what?")
        }
        guard case .item(let targetItemID) = directObjectRef else {
            throw ActionResponse.prerequisiteNotMet("You can only turn on items.")
        }

        // 2. Fetch the item snapshot.
        let targetItem = try await context.engine.item(targetItemID)

        // 3. Verify the item is reachable (with light source exception in dark).
        let currentLocationID = await context.engine.playerLocationID
        let isHeld = targetItem.parent == .player
        let isInLocation = targetItem.parent == .location(currentLocationID)
        let isLight = targetItem.hasFlag(.isLightSource)
        let roomIsDark = await context.engine.playerLocationIsLit() == false

        var isNormallyReachable = false
        if isHeld {
            isNormallyReachable = true
        } else if isInLocation {
            if !roomIsDark || !isLight {
                isNormallyReachable = await context.engine.playerCanReach(targetItemID)
            } else {
                isNormallyReachable = true // Allow turning on light in dark room
            }
        }
        guard isNormallyReachable else {
            throw ActionResponse.itemNotAccessible(targetItemID)
        }

        // 4. Check if the item has the `.device` property.
        guard targetItem.hasFlag(.isDevice) else {
            throw ActionResponse.prerequisiteNotMet("You can't turn that on.")
        }

        // 5. Check if the item already has the `.on` property.
        if targetItem.hasFlag(.isOn) {
            throw ActionResponse.custom("It's already on.")
        }
    }

    func process(context: ActionContext) async throws -> ActionResult {
        guard let directObjectRef = context.command.directObject,
              case .item(let targetItemID) = directObjectRef else {
            throw ActionResponse.internalEngineError("TurnOn: directObject was not an item in process.")
        }
        let targetItem = try await context.engine.item(targetItemID)

        // --- State Changes ---
        var stateChanges: [StateChange] = []

        // Change 1: Add .touched property change if needed
        if targetItem.attributes[.isTouched] != true {
            stateChanges.append(StateChange(
                entityID: .item(targetItem.id),
                attributeKey: .itemAttribute(.isTouched),
                oldValue: targetItem.attributes[.isTouched] ?? false,
                newValue: true,
            ))
        }

        // Change 2: Add .on property change (only if currently off)
        if targetItem.attributes[.isOn] != true {
            stateChanges.append(StateChange(
                entityID: .item(targetItem.id),
                attributeKey: .itemAttribute(.isOn),
                oldValue: targetItem.attributes[.isOn] ?? false,
                newValue: true,
            ))
        }

        // --- Determine Message ---
        let message = "The \(targetItem.name) is now on."

        // --- Side Effects (Optional) ---
        // Check if the room became lit. If so, the context.engine loop will describe it.
        // No explicit side effect needed here to trigger re-description.

        // --- Create Result ---
        return ActionResult(
            message: message,
            stateChanges: stateChanges
        )
    }
}
