import Foundation

/// Handles the "CLIMB" command, allowing the player to climb objects.
///
/// This handler implements ZIL-inspired behavior for climbing. When the player
/// climbs an object, the handler:
/// 1. Checks if the object enables traversal of any exit in the current location
/// 2. If so, uses that exit (e.g., "climb stairs" -> "go up")
/// 3. Otherwise, provides default climbing behavior for climbable objects
///
/// This works with the Exit system's `via:` parameter to create flexible
/// climbing-based movement (stairs, ladders, ropes, etc.).
public struct ClimbActionHandler: ActionHandler {
    /// Validates the "CLIMB" command.
    ///
    /// This method ensures that:
    /// 1. If a direct object is specified, it exists and is reachable.
    /// 2. The object is present in the current location (for global objects like stairs)
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Throws: Various `ActionResponse` errors if validation fails.
    public func validate(context: ActionContext) async throws {
        // CLIMB with no object is always valid (will be handled in process)
        guard let directObjectRef = context.command.directObject else {
            return
        }

        guard case .item(let targetItemID) = directObjectRef else {
            let message = context.message(.cannotActOnThat(verb: "climb"))
            throw ActionResponse.prerequisiteNotMet(message)
        }

        // Check if the target exists
        guard (try? await context.engine.item(targetItemID)) != nil else {
            throw ActionResponse.itemNotAccessible(targetItemID)
        }

        // Check if the target is reachable
        guard await context.engine.playerCanReach(targetItemID) else {
            throw ActionResponse.itemNotAccessible(targetItemID)
        }
    }

    /// Processes the "CLIMB" command.
    ///
    /// This method handles various climbing scenarios:
    /// 1. "climb" with no object - asks what to climb
    /// 2. "climb <object>" that enables an exit - traverses that exit
    /// 3. "climb <climbable object>" - default climbing behavior
    /// 4. "climb <non-climbable object>" - error message
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Returns: An `ActionResult` containing the message and any relevant state changes.
    public func process(context: ActionContext) async throws -> ActionResult {
        // Handle CLIMB with no object
        guard let directObjectRef = context.command.directObject else {
            let message = context.message(.climbWhat)
            return ActionResult(message)
        }

        guard case .item(let targetItemID) = directObjectRef else {
            let message = context.message(
                .actionHandlerInternalError(
                    handler: "ClimbActionHandler",
                    details: "directObject was not an item in process"))
            throw ActionResponse.internalEngineError(message)
        }

        let targetItem = try await context.engine.item(targetItemID)
        let currentLocation = try await context.engine.playerLocation()

        // Check if this object enables traversal of any exit in the current location
        // Sort directions to ensure consistent behavior when multiple exits use the same object
        // Priority: north, northeast, east, southeast, south, southwest, west, northwest, up, down, inside, outside
        let sortedExits = currentLocation.exits.sorted { first, second in
            first.key < second.key
        }

        for (direction, exit) in sortedExits {
            if exit.doorID == targetItemID {
                // This object enables traversal in this direction

                // For global objects like stairs, verify they're actually present
                if targetItem.parent == .nowhere,
                   currentLocation.localGlobals.contains(targetItemID) == false {
                    return ActionResult(
                        message: """
                                There \(targetItem.hasFlag(.isPlural) ? "are" : "is")
                                no \(targetItem.name) here.
                                """
                    )
                }
            }

            // Execute movement in the appropriate direction
            let goCommand = Command(
                verb: .go,
                direction: direction,
                rawInput: "go \(direction.rawValue)"
            )

            let goHandler = GoActionHandler()
            let goContext = ActionContext(
                command: goCommand,
                engine: context.engine
            )

            do {
                try await goHandler.validate(context: goContext)
                let goResult = try await goHandler.process(context: goContext)

                // Combine state changes from climb (touch/pronouns) with go result
                return ActionResult(
                    message: goResult.message,
                    changes: [
                        await context.engine.setFlag(.isTouched, on: targetItem),
                        await context.engine.updatePronouns(to: targetItem),
                    ] + goResult.changes
                )
            } catch {
                // If movement fails, let the engine handle the error
                throw error
            }
        }

        // No exit uses this object, so handle as regular climbing

        // Check if the item is climbable
        let message = if targetItem.hasFlag(.isClimbable) {
                // Default climbable behavior - can be overridden by specific item handlers
                context.message(.climbSuccess(item: targetItem.withDefiniteArticle))
            } else {
                // Not climbable
                context.message(.climbFailure(item: targetItem.withDefiniteArticle))
            }

        return ActionResult(
            message: message,
            changes: [
                await context.engine.setFlag(.isTouched, on: targetItem),
                await context.engine.updatePronouns(to: targetItem),
            ]
        )
    }
}
