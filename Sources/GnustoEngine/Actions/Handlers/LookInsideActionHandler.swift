import Foundation

/// Handles the "LOOK INSIDE" command and its variants (e.g., "LOOK IN", "LOOK WITH").
/// This command allows players to look inside containers or examine the contents of objects.
/// By default, it delegates to examine behavior, but specific items can override this via ItemEventHandlers.
public struct LookInsideActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb, .in, .directObject),
        .match(.verb, .inside, .directObject),
    ]

    public let verbs: [VerbID] = [.look, .peek]

    public let requiresLight: Bool = true

    // MARK: - Action Processing Methods

    /// Validates the "LOOK INSIDE" command.
    /// Requires a direct object that must be an item the player can reach.
    public func process(command: Command, engine: GameEngine) async throws -> ActionResult {

        guard let directObjectRef = command.directObject else {
            throw ActionResponse.prerequisiteNotMet(
                engine.messenger.doWhat(verb: command.verb)
            )
        }

        guard case .item(let targetItemID) = directObjectRef else {
            throw ActionResponse.prerequisiteNotMet(
                engine.messenger.canOnlyLookInsideItems()
            )
        }

        // Ensure item exists and is reachable
        guard (try? await engine.item(targetItemID)) != nil else {
            throw ActionResponse.unknownEntity(directObjectRef)
        }

        guard await engine.playerCanReach(targetItemID) else {
            throw ActionResponse.itemNotAccessible(targetItemID)
        }
    /// Processes the "LOOK INSIDE" command.
    /// By default, delegates to examine behavior with special focus on container contents.
        guard let directObjectRef = command.directObject,
            case .item(let targetItemID) = directObjectRef
        else {
            throw ActionResponse.internalEngineError("Validation should have caught this")
        }

        let targetItem = try await engine.item(targetItemID)

        // Determine the message based on whether item is a container
        let message: String
        if targetItem.hasFlag(.isContainer) {
            // For containers, provide container-specific messaging
            let isOpen = try await engine.hasFlag(.isOpen, on: targetItem.id)

            if !isOpen {
                message = "The \(targetItem.name) is closed."
            } else {
                // Show container contents
                let items = await engine.items(in: .item(targetItem.id))
                if items.isEmpty {
                    message = "The \(targetItem.name) is empty."
                } else {
                    let itemListing = items.listWithIndefiniteArticles
                    message = "In the \(targetItem.name) you see \(itemListing)."
                }
            }
        } else {
            // For non-containers, delegate to examine behavior
            let description = try await engine.generateDescription(
                for: targetItem.id,
                attributeID: .description
            )

            if !description.isEmpty {
                message = description
            } else {
                message = "You see nothing special inside the \(targetItem.name)."
            }
        }

        return ActionResult(
            message,
            await engine.setFlag(.isTouched, on: targetItem),
            await engine.updatePronouns(to: targetItem)
        )
    }
}
