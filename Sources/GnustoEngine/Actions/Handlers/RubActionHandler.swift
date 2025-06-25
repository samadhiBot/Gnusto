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

    /// Validates the "RUB" command.
    ///
    /// This method ensures that:
    /// 1. A direct object is specified (what to rub).
    /// 2. The target item exists and is reachable.
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Throws: Various `ActionResponse` errors if validation fails.
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

        // Check if target exists and is reachable
        _ = try await engine.item(targetItemID)
        guard await engine.playerCanReach(targetItemID) else {
            throw ActionResponse.itemNotAccessible(targetItemID)
        }
    /// Processes the "RUB" command.
    ///
    /// Handles rubbing attempts on different types of objects.
    /// Generally provides descriptive responses following ZIL traditions.
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Returns: An `ActionResult` with appropriate rubbing message and state changes.
        guard let directObjectRef = command.directObject,
            case .item(let targetItemID) = directObjectRef
        else {
            throw ActionResponse.internalEngineError(
                "RubActionHandler: directObject was not an item in process.")
        }

        let targetItem = try await engine.item(targetItemID)

        // Determine appropriate response based on object type
        let message =
            if targetItem.hasFlag(.isCharacter) {
                // Rubbing characters might not be appropriate
                engine.messenger.rubCharacter(character: targetItem.withDefiniteArticle)
            } else if targetItem.hasFlag(.isLightSource) {
                // Special message for light sources (lamps, lanterns)
                engine.messenger.rubLamp(item: targetItem.withDefiniteArticle)
            } else if targetItem.hasFlag(.isTakable) {
                // Message for a generic takable object
                engine.messenger.rubTakableObject(item: targetItem.withDefiniteArticle)
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

    /// Performs any post-processing after the rub action completes.
    ///
    /// Currently no post-processing is needed for basic rubbing.
    ///
    /// - Parameter context: The action context for the current action.
    public func postProcess(context: ActionContext) async throws {
        // No post-processing needed for rub
    }
}
