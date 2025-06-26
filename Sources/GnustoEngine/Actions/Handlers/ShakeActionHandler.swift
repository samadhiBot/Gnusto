import Foundation

/// Handles the "SHAKE" command for shaking objects.
/// Implements shaking mechanics following ZIL patterns for physical interactions.
public struct ShakeActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb, .directObject)
    ]

    public let verbs: [Verb] = [.shake, .rattle]

    public let requiresLight: Bool = true

    // MARK: - Action Processing Methods

    public init() {}

    /// Processes the "SHAKE" command.
    ///
    /// This action validates prerequisites and handles shaking attempts on different types
    /// of objects. Generally provides descriptive responses following ZIL traditions.
    public func process(command: Command, engine: GameEngine) async throws -> ActionResult {
        // Shake requires a direct object (what to shake)
        guard let directObjectRef = command.directObject else {
            throw ActionResponse.prerequisiteNotMet(
                engine.messenger.doWhat(verb: command.verb)
            )
        }
        guard case .item(let targetItemID) = directObjectRef else {
            throw ActionResponse.prerequisiteNotMet(
                engine.messenger.cannotDoThat(verb: "shake")
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
                // Shaking characters might not be appropriate
                engine.messenger.shakeCharacter(character: targetItem.withDefiniteArticle)
            } else if targetItem.hasFlag(.isLiquidContainer) {
                // Special message for liquid containers
                engine.messenger.shakeLiquidContainer(item: targetItem.withDefiniteArticle)
            } else if targetItem.hasFlag(.isContainer) {
                // Shaking containers might reveal contents
                if targetItem.hasFlag(.isOpen) {
                    engine.messenger.shakeOpenContainer(
                        container: targetItem.withDefiniteArticle
                    )
                } else {
                    engine.messenger.shakeClosedContainer(
                        container: targetItem.withDefiniteArticle
                    )
                }
            } else if targetItem.hasFlag(.isTakable) {
                // Message for a generic takable object
                engine.messenger.shakeTakableObject(item: targetItem.withDefiniteArticle)
            } else {
                // Generic shaking response for objects
                engine.messenger.shakeFixedObject(item: targetItem.withDefiniteArticle)
            }

        return ActionResult(
            message,
            await engine.setFlag(.isTouched, on: targetItem),
            await engine.updatePronouns(to: targetItem)
        )
    }
}
