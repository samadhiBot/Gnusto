import Foundation

/// Handles the "TURN ON" command, allowing the player to activate items that are
/// considered devices (e.g., light sources).
public struct TurnOnActionHandler: ActionHandler {

    // MARK: - ActionHandler Methods

    /// Validates the "TURN ON" command.
    ///
    /// This method ensures that:
    /// 1. A direct object is specified (the player must indicate *what* to turn on).
    /// 2. The direct object refers to an existing item.
    /// 3. The player can reach the specified item. A special case allows turning on a
    ///    light source that is in the current dark room, even if otherwise unreachable.
    /// 4. The item has the `.isDevice` flag set (indicating it can be turned on/off).
    /// 5. The item is not already on (i.e., it currently lacks the `.isOn` flag).
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Throws: Various `ActionResponse` errors if validation fails, such as:
    ///           `custom` (for "Turn on what?" or "It's already on."),
    ///           `prerequisiteNotMet` (if not an item or not a device),
    ///           `itemNotAccessible`.
    ///           Can also throw errors from `context.engine.item()`.
    public func validate(context: ActionContext) async throws {
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
        let isLightSource = targetItem.hasFlag(.isLightSource)
        let roomIsDark = await context.engine.playerLocationIsLit() == false

        var isReachable = false
        if isHeld {
            isReachable = true
        } else if isInLocation {
            // If it's a light source in a dark room, consider it reachable to turn on.
            if roomIsDark && isLightSource {
                isReachable = true
            } else {
                // Otherwise, standard reachability check.
                isReachable = await context.engine.playerCanReach(targetItemID)
            }
        }
        guard isReachable else {
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

    /// Processes the "TURN ON" command.
    ///
    /// Assuming basic validation has passed (the item is a reachable device and is currently off),
    /// this action performs the following:
    /// 1. Retrieves the target item.
    /// 2. Ensures the `.isTouched` flag is set on the item.
    /// 3. Sets the `.isOn` flag on the item.
    /// 4. Returns an `ActionResult` with a confirmation message (e.g., "The flashlight is now on.")
    ///    and the state changes.
    ///
    /// If turning on the item illuminates a dark room, the game engine will automatically handle
    /// printing the room's description after this action completes.
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Returns: An `ActionResult` containing the message and relevant state changes.
    /// - Throws: `ActionResponse.internalEngineError` if the direct object is not an item (this should
    ///           be caught by `validate`), or errors from `context.engine.item()`.
    public func process(context: ActionContext) async throws -> ActionResult {
        guard let directObjectRef = context.command.directObject,
              case .item(let targetItemID) = directObjectRef else {
            throw ActionResponse.internalEngineError("TurnOn: directObject was not an item in process.")
        }
        let targetItem = try await context.engine.item(targetItemID)

        // --- State Changes ---
        var stateChanges: [StateChange] = []

        // Change 1: Ensure `.isTouched` flag is set.
        if let update = await context.engine.setFlag(.isTouched, on: targetItem) {
            stateChanges.append(update)
        }

        // Change 2: Set `.isOn` flag.
        // Validation ensures the item was off, so an update should always occur here.
        if let update = await context.engine.setFlag(.isOn, on: targetItem) {
            stateChanges.append(update)
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
