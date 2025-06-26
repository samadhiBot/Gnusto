import Foundation

/// Handles the "SQUEEZE" command for squeezing objects.
/// Implements squeezing mechanics following ZIL patterns for physical interactions.
public struct SqueezeActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb, .directObject)
    ]

    public let verbs: [VerbID] = [.squeeze, .compress]

    public let requiresLight: Bool = true

    // MARK: - Action Processing Methods

    public init() {}

    /// Processes the "SQUEEZE" command.
    ///
    /// This action validates prerequisites and handles squeezing attempts on different types
    /// of objects. Generally provides descriptive responses following ZIL traditions.
    public func process(command: Command, engine: GameEngine) async throws -> ActionResult {
        // Squeeze requires a direct object (what to squeeze)
        guard let directObjectRef = command.directObject else {
            throw ActionResponse.prerequisiteNotMet(
                engine.messenger.doWhat(verb: command.verb)
            )
        }

        guard case .item(let targetItemID) = directObjectRef else {
            throw ActionResponse.prerequisiteNotMet(
                engine.messenger.cannotDoThat(verb: "squeeze")
            )
        }

        // Check if target exists and is accessible
        let targetItem = try await engine.item(targetItemID)
        guard await engine.playerCanReach(targetItemID) else {
            throw ActionResponse.itemNotAccessible(targetItemID)
        }

        // Determine appropriate response based on object type and properties
        let message =
            if targetItem.hasFlag(.isCharacter) {
                // Squeezing characters - not advisable
                engine.messenger.squeezeCharacter(character: targetItem.withDefiniteArticle)
            } else if targetItem.hasFlag(.isSoft) || targetItem.hasFlag(.isFlexible) {
                // Items that can be meaningfully squeezed
                engine.messenger.squeezeSuccess(item: targetItem.withDefiniteArticle)
            } else {
                // Generic squeezing response for objects
                engine.messenger.squeezeItem(item: targetItem.withDefiniteArticle)
            }

        return ActionResult(
            message,
            await engine.setFlag(.isTouched, on: targetItem),
            await engine.updatePronouns(to: targetItem)
        )
    }
}
