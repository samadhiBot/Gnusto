import Foundation

/// Handles the "THROW" command for throwing objects with optional targets.
/// Implements object throwing mechanics following ZIL patterns.
public struct ThrowActionHandler: ActionHandler {
    public init() {}

    /// Validates the "THROW" command.
    ///
    /// This method ensures that:
    /// 1. A direct object is specified (what to throw).
    /// 2. The player is holding the item to throw.
    /// 3. If a target is specified, it exists and is reachable.
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Throws: Various `ActionResponse` errors if validation fails.
    public func validate(context: ActionContext) async throws {
        // Throw requires a direct object (what to throw)
        guard let directObjectRef = context.command.directObject else {
            throw ActionResponse.prerequisiteNotMet("Throw what?")
        }
        guard case .item(let itemToThrowID) = directObjectRef else {
            throw ActionResponse.prerequisiteNotMet("You can't throw that.")
        }

        // Check if item exists and is held
        let itemToThrow = try await context.engine.item(itemToThrowID)
        guard itemToThrow.parent == .player else {
            throw ActionResponse.itemNotHeld(itemToThrowID)
        }

        // If a target is specified, validate it
        if let indirectObjectRef = context.command.indirectObject {
            guard case .item(let targetItemID) = indirectObjectRef else {
                throw ActionResponse.prerequisiteNotMet("You can't throw at that.")
            }

            _ = try await context.engine.item(targetItemID)
            guard await context.engine.playerCanReach(targetItemID) else {
                throw ActionResponse.itemNotAccessible(targetItemID)
            }
        }
    }

    /// Processes the "THROW" command.
    ///
    /// Handles different throwing scenarios:
    /// - Throwing at specific targets
    /// - General throwing (drops item in current location)
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Returns: An `ActionResult` with appropriate throwing message and state changes.
    public func process(context: ActionContext) async throws -> ActionResult {
        guard let directObjectRef = context.command.directObject else {
            throw ActionResponse.internalEngineError(
                "ThrowActionHandler: directObject was nil in process.")
        }

        // Handle self reference
        if case .player = directObjectRef {
            let message = context.message(.cannotThrowYourself)
            return ActionResult(message)
        }

        guard case .item(let itemToThrowID) = directObjectRef else {
            throw ActionResponse.internalEngineError(
                "ThrowActionHandler: directObject was not an item in process.")
        }

        let itemToThrow = try await context.engine.item(itemToThrowID)
        let currentLocationID = await context.engine.playerLocationID
        var stateChanges: [StateChange] = []

        // Mark item as touched
        if let touchedChange = await context.engine.setFlag(.isTouched, on: itemToThrow) {
            stateChanges.append(touchedChange)
        }

        // Update pronouns to refer to the thrown item
        if let pronounChange = await context.engine.updatePronouns(to: itemToThrow) {
            stateChanges.append(pronounChange)
        }

        // Move the thrown item to the current location
        let dropChange = await context.engine.move(itemToThrow, to: .location(currentLocationID))
        stateChanges.append(dropChange)

        let message: String

        // Handle specific target throwing
        if let indirectObjectRef = context.command.indirectObject,
            case .item(let targetItemID) = indirectObjectRef
        {

            let targetItem = try await context.engine.item(targetItemID)

            // Mark target as touched too
            if let targetTouchedChange = await context.engine.setFlag(.isTouched, on: targetItem) {
                stateChanges.append(targetTouchedChange)
            }

            if targetItem.hasFlag(.isCharacter) {
                message = "You throw the \(itemToThrow.name) at the \(targetItem.name)."
            } else {
                message =
                    "You throw the \(itemToThrow.name) at the \(targetItem.name). It bounces off harmlessly."
            }

        } else {
            // General throwing - no specific target
            message = "You throw the \(itemToThrow.name), and it falls to the ground."
        }

        return ActionResult(message: message, stateChanges: stateChanges)
    }

    /// Performs any post-processing after the throw action completes.
    ///
    /// Currently no post-processing is needed for throwing.
    ///
    /// - Parameter context: The action context for the current action.
    public func postProcess(context: ActionContext) async throws {
        // No post-processing needed for throw
    }
}
