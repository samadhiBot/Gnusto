import Foundation

/// Handles the "PULL" command for pulling objects.
/// Implements pulling mechanics following ZIL patterns, as a complement to PUSH.
public struct PullActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb, .directObjects)
    ]

    public let verbs: [VerbID] = [.pull]

    public let requiresLight: Bool = true

    // MARK: - Action Processing Methods
    public init() {}

    /// Validates the "PULL" command.
    ///
    /// This method ensures that:
    /// 1. A direct object is specified (what to pull).
    /// 2. The target item exists and is reachable.
    /// 3. The item can be pulled (has the `.isPullable` flag or similar logic).
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Throws: Various `ActionResponse` errors if validation fails.
        public func process(
        command: Command,
        engine: GameEngine
    ) async throws -> ActionResult {

        // Pull requires a direct object (what to pull)
        guard let directObjectRef = command.directObject else {
            throw ActionResponse.prerequisiteNotMet(
                engine.messenger.doWhat(verb: command.verb)
            )
        }
        guard case .item(let targetItemID) = directObjectRef else {
            throw ActionResponse.prerequisiteNotMet(
                engine.messenger.thatsNotSomethingYouCan(.pull)
            )
        }

        // Check if target exists and is reachable
        _ = try await engine.item(targetItemID)
        guard await engine.playerCanReach(targetItemID) else {
            throw ActionResponse.itemNotAccessible(targetItemID)
        }
    /// Processes the "PULL" command.
    ///
    /// Handles pulling objects. Most objects cannot be pulled, but some specific
    /// items (like ropes, levers, handles) may have special pull behavior that
    /// can be customized via ItemEventHandlers.
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Returns: An `ActionResult` with appropriate pull message and state changes.
        guard let directObjectRef = command.directObject,
            case .item(let targetItemID) = directObjectRef
        else {
            throw ActionResponse.internalEngineError(
                "PullActionHandler: directObject was not an item in process.")
        }

        let targetItem = try await engine.item(targetItemID)

        // Check if item is specifically pullable
        let message = if targetItem.hasFlag(.isPullable) {
            engine.messenger.pullSuccess(item: targetItem.withDefiniteArticle)
        } else {
            // Default behavior: most things can't be pulled effectively
            engine.messenger.cannotDoThat(
                verb: .pull,
                item: targetItem.withDefiniteArticle
            )
        }

        return ActionResult(
            message,
            await engine.setFlag(.isTouched, on: targetItem),
            await engine.updatePronouns(to: targetItem)
        )
    }

    /// Performs any post-processing after the pull action completes.
    ///
    /// Currently no post-processing is needed for basic pulling.
    ///
    /// - Parameter context: The action context for the current action.
    public func postProcess(context: ActionContext, result: ActionResult) async throws {
        // No post-processing needed for pull
    }
}
