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
            throw ActionResponse.prerequisiteNotMet("Tie what?")
        }
        guard case .item(let targetItemID) = directObjectRef else {
            throw ActionResponse.prerequisiteNotMet("You can't tie that.")
        }

        // Check if target exists and is reachable
        _ = try await context.engine.item(targetItemID)
        guard await context.engine.playerCanReach(targetItemID) else {
            throw ActionResponse.itemNotAccessible(targetItemID)
        }

        // If there's an indirect object, validate it too
        if let indirectObjectRef = context.command.indirectObject {
            guard case .item(let indirectItemID) = indirectObjectRef else {
                throw ActionResponse.prerequisiteNotMet("You can't tie something to that.")
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
              case .item(let targetItemID) = directObjectRef else {
            throw ActionResponse.internalEngineError("TieActionHandler: directObject was not an item in process.")
        }

        let targetItem = try await context.engine.item(targetItemID)
        var stateChanges: [StateChange] = []

        // Mark target as touched
        if let touchedChange = await context.engine.setFlag(.isTouched, on: targetItem) {
            stateChanges.append(touchedChange)
        }

        // Update pronouns to refer to the target
        if let pronounChange = await context.engine.updatePronouns(to: targetItem) {
            stateChanges.append(pronounChange)
        }

        let message: String

        if let indirectObjectRef = context.command.indirectObject,
           case .item(let indirectItemID) = indirectObjectRef {
            // Tie X to Y
            let indirectItem = try await context.engine.item(indirectItemID)

            // Mark indirect object as touched too
            if let indirectTouchedChange = await context.engine.setFlag(.isTouched, on: indirectItem) {
                stateChanges.append(indirectTouchedChange)
            }

            message = try await handleTyingTogether(
                targetItem: targetItem,
                indirectItem: indirectItem,
                context: context
            )
        } else {
            // Just "TIE X" - tie the object by itself
            message = handleTyingAlone(targetItem: targetItem)
        }

        return ActionResult(message: message, stateChanges: stateChanges)
    }

    /// Handles tying two objects together.
    private func handleTyingTogether(
        targetItem: Item,
        indirectItem: Item,
        context: ActionContext
    ) async throws -> String {
        // Check if we're trying to tie something to itself
        if targetItem.id == indirectItem.id {
            return "You can't tie the \(targetItem.name) to itself."
        }

        // Special cases for rope-like objects
        if targetItem.name.lowercased().contains("rope") || targetItem.name.lowercased().contains("cord") {
            if indirectItem.name.lowercased().contains("hook") || indirectItem.name.lowercased().contains("post") {
                return "You tie the \(targetItem.name) securely to the \(indirectItem.name)."
            } else if indirectItem.hasFlag(.isCharacter) {
                return "The \(indirectItem.name) doesn't seem willing to be tied up."
            } else {
                return "You tie the \(targetItem.name) to the \(indirectItem.name), though it doesn't seem particularly useful."
            }
        }

        // General tying attempts
        if targetItem.hasFlag(.isCharacter) || indirectItem.hasFlag(.isCharacter) {
            return "You can't tie living beings together like that."
        }

        if !targetItem.hasFlag(.isTakable) && !indirectItem.hasFlag(.isTakable) {
            return "You can't tie those large objects together."
        }

        return "You don't have anything suitable to tie the \(targetItem.name) to the \(indirectItem.name) with."
    }

    /// Handles tying a single object.
    private func handleTyingAlone(targetItem: Item) -> String {
        if targetItem.name.lowercased().contains("rope") || targetItem.name.lowercased().contains("cord") {
            return "You tie a knot in the \(targetItem.name)."
        } else if targetItem.name.lowercased().contains("laces") || targetItem.name.lowercased().contains("shoes") {
            return "You tie the \(targetItem.name) properly."
        } else if targetItem.hasFlag(.isCharacter) {
            return "You can't tie up the \(targetItem.name) without something to tie them with."
        } else {
            return "You can't tie the \(targetItem.name) without something to tie it with."
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
