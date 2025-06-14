import Foundation

/// Handles the "LOOK INSIDE" command and its variants (e.g., "LOOK IN", "LOOK WITH").
/// This command allows players to look inside containers or examine the contents of objects.
/// By default, it delegates to examine behavior, but specific items can override this via ItemEventHandlers.
public struct LookInsideActionHandler: ActionHandler {

    /// Validates the "LOOK INSIDE" command.
    /// Requires a direct object that must be an item the player can reach.
    public func validate(context: ActionContext) async throws {
        guard let directObjectRef = context.command.directObject else {
            let message = context.message(.lookInsideWhat)
            throw ActionResponse.prerequisiteNotMet(message)
        }

        guard case .item(let targetItemID) = directObjectRef else {
            let message = context.message(.canOnlyLookInsideItems)
            throw ActionResponse.prerequisiteNotMet(message)
        }

        // Ensure item exists and is reachable
        guard (try? await context.engine.item(targetItemID)) != nil else {
            throw ActionResponse.unknownEntity(directObjectRef)
        }

        guard await context.engine.playerCanReach(targetItemID) else {
            throw ActionResponse.itemNotAccessible(targetItemID)
        }
    }

    /// Processes the "LOOK INSIDE" command.
    /// By default, delegates to examine behavior with special focus on container contents.
    public func process(context: ActionContext) async throws -> ActionResult {
        guard let directObjectRef = context.command.directObject,
            case .item(let targetItemID) = directObjectRef
        else {
            throw ActionResponse.internalEngineError("Validation should have caught this")
        }

        let targetItem = try await context.engine.item(targetItemID)
        var allStateChanges: [StateChange] = []

        // Set touched flag if not already set
        if let touchChange = await context.engine.setFlag(.isTouched, on: targetItem) {
            allStateChanges.append(touchChange)
        }

        // Update pronouns
        if let pronounChange = await context.engine.updatePronouns(to: targetItem) {
            allStateChanges.append(pronounChange)
        }

        // Check if the item is a container
        if targetItem.hasFlag(.isContainer) {
            // For containers, provide container-specific messaging
            let isOpen = try await context.engine.hasFlag(.isOpen, on: targetItem.id)

            if !isOpen {
                return ActionResult(
                    message: "The \(targetItem.name) is closed.",
                    stateChanges: allStateChanges
                )
            }

            // Show container contents
            let items = await context.engine.items(in: .item(targetItem.id))
            if items.isEmpty {
                return ActionResult(
                    message: "The \(targetItem.name) is empty.",
                    stateChanges: allStateChanges
                )
            } else {
                let itemListing = items.listWithIndefiniteArticles
                return ActionResult(
                    message: "In the \(targetItem.name) you see \(itemListing).",
                    stateChanges: allStateChanges
                )
            }
        } else {
            // For non-containers, delegate to examine behavior
            let description = try await context.engine.generateDescription(
                for: targetItem.id,
                attributeID: .description
            )

            let message =
                if !description.isEmpty {
                    description
                } else {
                    "You see nothing special inside the \(targetItem.name)."
                }

            return ActionResult(message: message, stateChanges: allStateChanges)
        }
    }
}
