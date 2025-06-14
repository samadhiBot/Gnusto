import Foundation

/// Handles the "TIE" command for tying objects together.
/// Implements tying mechanics following ZIL patterns for object binding and connection.
public struct TieActionHandler: ActionHandler {
    public init() {}

    /// Validates the "TIE" command.
    ///
    /// This method ensures that:
    /// 1. A direct object is specified (what to tie).
    /// 2. If an indirect object is specified, it exists and is reachable.
    /// 3. The target items exist and are reachable.
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Throws: Various `ActionResponse` errors if validation fails.
    public func validate(context: ActionContext) async throws {
        // Tie requires a direct object (what to tie)
        guard let directObjectRef = context.command.directObject else {
            throw ActionResponse.prerequisiteNotMet(
                context.message(.tieWhat)
            )
        }
        guard case .item(let targetItemID) = directObjectRef else {
            throw ActionResponse.prerequisiteNotMet(
                context.message(.tieCannotTieThat)
            )
        }

        // Check if target exists and is reachable
        _ = try await context.engine.item(targetItemID)
        guard await context.engine.playerCanReach(targetItemID) else {
            throw ActionResponse.itemNotAccessible(targetItemID)
        }

        // If there's an indirect object, validate it too
        if let indirectObjectRef = context.command.indirectObject {
            guard case .item(let indirectItemID) = indirectObjectRef else {
                throw ActionResponse.prerequisiteNotMet(
                    context.message(.tieCannotTieToThat)
                )
            }

            _ = try await context.engine.item(indirectItemID)
            guard await context.engine.playerCanReach(indirectItemID) else {
                throw ActionResponse.itemNotAccessible(indirectItemID)
            }
        }
    }

    /// Processes the "TIE" command.
    ///
    /// Handles tying attempts on different types of objects.
    /// Can tie objects together or just tie objects in general.
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Returns: An `ActionResult` with appropriate tying message and state changes.
    public func process(context: ActionContext) async throws -> ActionResult {
        guard let directObjectRef = context.command.directObject,
            case .item(let targetItemID) = directObjectRef
        else {
            throw ActionResponse.internalEngineError(
                "TieActionHandler: directObject was not an item in process.")
        }

        let targetItem = try await context.engine.item(targetItemID)

        if let indirectObjectRef = context.command.indirectObject,
            case .item(let indirectItemID) = indirectObjectRef
        {
            // Tie X to Y
            let indirectItem = try await context.engine.item(indirectItemID)

            let message = try await handleTyingTogether(
                targetItem: targetItem,
                indirectItem: indirectItem,
                context: context
            )

            return ActionResult(
                message: message,
                stateChanges: [
                    await context.engine.setFlag(.isTouched, on: targetItem),
                    await context.engine.updatePronouns(to: targetItem),
                    await context.engine.setFlag(.isTouched, on: indirectItem),
                ]
            )
        } else {
            // Just "TIE X" - tie the object by itself
            let message = handleTyingAlone(targetItem: targetItem, context: context)

            return ActionResult(
                message: message,
                stateChanges: [
                    await context.engine.setFlag(.isTouched, on: targetItem),
                    await context.engine.updatePronouns(to: targetItem),
                ]
            )
        }
    }

    /// Handles tying two objects together.
    private func handleTyingTogether(
        targetItem: Item,
        indirectItem: Item,
        context: ActionContext
    ) async throws -> String {
        // Check if we're trying to tie something to itself
        if targetItem.id == indirectItem.id {
            return context.message(.tieCannotTieToSelf(item: targetItem.name))
        }

        // General tying attempts
        if targetItem.hasFlag(.isCharacter) || indirectItem.hasFlag(.isCharacter) {
            return context.message(.tieCannotTieLivingBeings)
        }

        return context.message(.tieNeedsSomethingToTieWith(item: targetItem.name))
    }

    /// Handles tying a single object.
    private func handleTyingAlone(
        targetItem: Item,
        context: ActionContext
    ) -> String {
        if targetItem.hasFlag(.isCharacter) {
            return context.message(
                .tieNeedsSomethingToTieCharacterWith(character: targetItem.name)
            )
        } else {
            return context.message(
                .tieNeedsSomethingToTieWith(item: targetItem.name)
            )
        }
    }

    /// Performs any post-processing after the tie action completes.
    ///
    /// Currently no post-processing is needed for basic tying.
    ///
    /// - Parameter context: The action context for the current action.
    public func postProcess(context: ActionContext) async throws {
        // No post-processing needed for tie
    }
}
