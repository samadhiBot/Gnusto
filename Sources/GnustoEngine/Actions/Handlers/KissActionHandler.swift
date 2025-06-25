import Foundation

/// Handles the "KISS" command for kissing objects or characters.
/// Implements kissing mechanics following ZIL patterns for social interactions.
public struct KissActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb, .directObject)
    ]

    public let verbs: [VerbID] = [.kiss]

    public let requiresLight: Bool = true

    // MARK: - Action Processing Methods

    public init() {}

    /// Validates the "KISS" command.
    ///
    /// This method ensures that:
    /// 1. A direct object is specified (what to kiss).
    /// 2. The target item exists and is reachable.
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Throws: Various `ActionResponse` errors if validation fails.
        public func process(
        command: Command,
        engine: GameEngine
    ) async throws -> ActionResult {

        // Kiss requires a direct object (what to kiss)
        guard let directObjectRef = command.directObject else {
            throw ActionResponse.prerequisiteNotMet(
                engine.messenger.doWhat(verb: command.verb)
            )
        }

        if case .player = directObjectRef { return }

        guard case .item(let targetItemID) = directObjectRef else {
            throw ActionResponse.prerequisiteNotMet(
                engine.messenger.cannotDoThat(verb: "kiss")
            )
        }

        // Check if target exists and is reachable
        _ = try await engine.item(targetItemID)
        guard await engine.playerCanReach(targetItemID) else {
            throw ActionResponse.itemNotAccessible(targetItemID)
        }
    /// Processes the "KISS" command.
    ///
    /// Handles kissing attempts on different types of objects and characters.
    /// Generally provides humorous or appropriate responses following ZIL traditions.
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Returns: An `ActionResult` with appropriate kissing message and state changes.
        guard let directObjectRef = command.directObject else {
            throw ActionResponse.internalEngineError(
                "KissActionHandler: directObject was not an item in process."
            )
        }

        if case .player = directObjectRef {
            return ActionResult(
                engine.messenger.kissSelf()
            )
        }

        guard case .item(let targetItemID) = directObjectRef else {
            return ActionResult(
                engine.messenger.doWhat(verb: command.verb)
            )
        }

        let targetItem = try await engine.item(targetItemID)

        // Determine appropriate response based on object type
        let message =
            // Kissing characters
            if targetItem.hasFlag(.isCharacter) {
                if targetItem.hasFlag(.isFighting) {
                    engine.messenger.kissEnemy(enemy: targetItem.withDefiniteArticle)
                } else {
                    engine.messenger.kissCharacter(character: targetItem.withDefiniteArticle)
                }
            } else {
                // Kissing objects - generic response
                engine.messenger.kissObject(item: targetItem.withDefiniteArticle)
            }

        return ActionResult(
            message,
            await engine.setFlag(.isTouched, on: targetItem),
            await engine.updatePronouns(to: targetItem)
        )
    }
}
