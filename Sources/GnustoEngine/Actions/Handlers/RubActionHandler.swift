import Foundation

/// Handles the "RUB" command for rubbing objects.
/// Implements rubbing mechanics following ZIL patterns for physical interactions.
public struct RubActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb, .directObject),
        .match(.verb, .directObject, .with, .indirectObject),
    ]

    public let verbs: [VerbID] = [.rub, .polish, .clean]

    public let requiresLight: Bool = true

    // MARK: - Action Processing Methods

    public init() {}

    /// Processes the "RUB" command.
    ///
    /// This action validates prerequisites and handles rubbing attempts on different types
    /// of objects. Generally provides descriptive responses following ZIL traditions.
    /// Can optionally use a tool specified in the indirect object.
    public func process(command: Command, engine: GameEngine) async throws -> ActionResult {
        // Rub requires a direct object (what to rub)
        guard let directObjectRef = command.directObject else {
            throw ActionResponse.prerequisiteNotMet(
                engine.messenger.doWhat(verb: command.verb)
            )
        }

        guard case .item(let targetItemID) = directObjectRef else {
            throw ActionResponse.prerequisiteNotMet(
                engine.messenger.cannotDoThat(verb: "rub")
            )
        }

        // Check if target exists and is accessible
        let targetItem = try await engine.item(targetItemID)
        guard await engine.playerCanReach(targetItemID) else {
            throw ActionResponse.itemNotAccessible(targetItemID)
        }

        // Handle optional rubbing tool (indirect object)
        var additionalStateChanges: [StateChange] = []
        if let indirectObjectRef = command.indirectObject {
            guard case .item(let toolItemID) = indirectObjectRef else {
                throw ActionResponse.prerequisiteNotMet(
                    engine.messenger.cannotActWithThat(verb: "rub")
                )
            }

            let toolItem = try await engine.item(toolItemID)
            guard toolItem.parent == .player else {
                throw ActionResponse.itemNotHeld(toolItemID)
            }

            // Mark tool as touched too
            if let toolTouchedChange = await engine.setFlag(.isTouched, on: toolItem) {
                additionalStateChanges.append(toolTouchedChange)
            }
        }

        // Determine appropriate response based on object type
        let message =
            if targetItem.hasFlag(.isCharacter) {
                // Rubbing characters might not be appropriate
                engine.messenger.rubCharacter(
                    character: targetItem.withDefiniteArticle
                )
            } else {
                // Generic rubbing response for objects
                engine.messenger.rubGenericObject(item: targetItem.withDefiniteArticle)
            }

        return ActionResult(
            message,
            await engine.setFlag(.isTouched, on: targetItem),
            await engine.updatePronouns(to: targetItem)
        )
    }
}
