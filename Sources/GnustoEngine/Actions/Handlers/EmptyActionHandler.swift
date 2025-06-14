import Foundation

/// Handles the "EMPTY" command for emptying containers of their contents.
/// Implements emptying mechanics following ZIL patterns.
public struct EmptyActionHandler: ActionHandler {
    public init() {}

    /// Validates the "EMPTY" command.
    ///
    /// This method ensures that:
    /// 1. A direct object is specified (what to empty).
    /// 2. The target item exists and is reachable.
    /// 3. The item is a container that can be emptied.
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Throws: Various `ActionResponse` errors if validation fails.
    public func validate(context: ActionContext) async throws {
        // Empty requires a direct object (what to empty)
        guard let directObjectRef = context.command.directObject else {
            let message = context.message(.emptyWhat)
            throw ActionResponse.prerequisiteNotMet(message)
        }
        guard case .item(let targetItemID) = directObjectRef else {
            let message = context.message(.canOnlyEmptyContainers)
            throw ActionResponse.prerequisiteNotMet(message)
        }

        // Check if target exists and is reachable
        let targetItem = try await context.engine.item(targetItemID)
        guard await context.engine.playerCanReach(targetItemID) else {
            throw ActionResponse.itemNotAccessible(targetItemID)
        }

        // Check if item is a container
        guard targetItem.hasFlag(.isContainer) else {
            throw ActionResponse.targetIsNotAContainer(targetItemID)
        }

        // Check if container is open (can't empty closed containers)
        guard try await context.engine.hasFlag(.isOpen, on: targetItemID) else {
            throw ActionResponse.containerIsClosed(targetItemID)
        }
    }

    /// Processes the "EMPTY" command.
    ///
    /// Empties the contents of a container by moving all contained items to the
    /// current location. If the container is already empty, provides an appropriate message.
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Returns: An `ActionResult` with appropriate empty message and state changes.
    public func process(context: ActionContext) async throws -> ActionResult {
        guard let directObjectRef = context.command.directObject,
            case .item(let targetItemID) = directObjectRef
        else {
            throw ActionResponse.internalEngineError(
                "EmptyActionHandler: directObject was not an item in process.")
        }

        let targetItem = try await context.engine.item(targetItemID)

        // Get current contents of the container
        let contents = await context.engine.items(in: .item(targetItemID))

        let message: String
        var contentMoveChanges: [StateChange?] = []

        if contents.isEmpty {
            message =
                context
                .message(
                    .containerAlreadyEmpty(
                        container: targetItem.withDefiniteArticle.capitalizedFirst
                    )
                )
        } else {
            // Get current location to move items to
            let currentLocationID = await context.engine.playerLocationID

            // Collect move changes for all contents
            for item in contents {
                contentMoveChanges.append(
                    await context.engine.move(item, to: .location(currentLocationID)))
            }

            let itemNames = contents.listWithDefiniteArticles
            message = context.message(
                .emptySuccess(container: targetItem.name, items: itemNames, count: contents.count))
        }

        return ActionResult(
            message: message,
            stateChanges: [
                await context.engine.setFlag(.isTouched, on: targetItem),
                await context.engine.updatePronouns(to: targetItem),
            ] + contentMoveChanges
        )
    }

    /// Performs any post-processing after the empty action completes.
    ///
    /// Currently no post-processing is needed for basic emptying.
    ///
    /// - Parameter context: The action context for the current action.
    public func postProcess(context: ActionContext, result: ActionResult) async throws {
        // No post-processing needed for empty
    }
}
