import Foundation

/// Handles the "SHAKE" command for shaking objects.
/// Implements shaking mechanics following ZIL patterns for physical interactions.
public struct ShakeActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb, .directObject)
    ]

    public let verbs: [VerbID] = [.shake, .rattle]

    public let requiresLight: Bool = true

    // MARK: - Action Processing Methods
    public init() {}

    /// Validates the "SHAKE" command.
    ///
    /// This method ensures that:
    /// 1. A direct object is specified (what to shake).
    /// 2. The target item exists and is reachable.
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Throws: Various `ActionResponse` errors if validation fails.
        public func process(
        command: Command,
        engine: GameEngine
    ) async throws -> ActionResult {

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

        // Check if target exists and is reachable
        _ = try await engine.item(targetItemID)
        guard await engine.playerCanReach(targetItemID) else {
            throw ActionResponse.itemNotAccessible(targetItemID)
        }
    /// Processes the "SHAKE" command.
    ///
    /// Handles shaking attempts on different types of objects.
    /// Generally provides descriptive responses following ZIL traditions.
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Returns: An `ActionResult` with appropriate shaking message and state changes.
        guard let directObjectRef = command.directObject,
            case .item(let targetItemID) = directObjectRef
        else {
            throw ActionResponse.internalEngineError(
                "ShakeActionHandler: directObject was not an item in process.")
        }

        let targetItem = try await engine.item(targetItemID)

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

    /// Performs any post-processing after the shake action completes.
    ///
    /// Currently no post-processing is needed for basic shaking.
    ///
    /// - Parameter context: The action context for the current action.
    public func postProcess(context: ActionContext) async throws {
        // No post-processing needed for shake
    }
}
