import Foundation

/// Handles the "EMPTY" command for emptying containers of their contents.
/// Implements emptying mechanics following ZIL patterns.
public struct EmptyActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let verbID: VerbID = .empty

    public let syntax: [SyntaxRule] = [
        .match(.verb, .directObject),
        .match(.verb, .directObject, .into, .indirectObject),
    ]

    public let synonyms: [VerbID] = [.dump, .pour out]

    public let requiresLight: Bool = true

    // MARK: - Action Processing Methods

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
            throw ActionResponse.prerequisiteNotMet(
                context.message.doWhat(verb: .empty)
            )
        }
        guard case .item(let targetItemID) = directObjectRef else {
            throw ActionResponse.prerequisiteNotMet(
                context.message.canOnlyEmptyContainers()
            )
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
            message = context.message.containerAlreadyEmpty(
                container: targetItem.withDefiniteArticle.capitalizedFirst
            )
        } else {
            // Get current location to move items to
            let currentLocationID = await context.engine.playerLocationID

            // Collect move changes for all contents
            for item in contents {
                contentMoveChanges.append(
                    await context.engine.move(item, to: .location(currentLocationID))
                )
            }

            message = context.message.emptySuccess(
                container: targetItem.withDefiniteArticle,
                items: contents.listWithIndefiniteArticles,
                count: contents.count
            )
        }

        return ActionResult(
            message: message,
            changes: [
                await context.engine.setFlag(.isTouched, on: targetItem),
                await context.engine.updatePronouns(to: targetItem),
            ] + contentMoveChanges
        )
    }
}
