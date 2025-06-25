import Foundation

/// Handles the "DEFLATE" command for deflating previously inflated objects like balloons, rafts, etc.
/// Implements deflation mechanics following ZIL patterns.
public struct DeflateActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb, .directObject)
    ]

    public let verbs: [VerbID] = [.deflate]

    public let requiresLight: Bool = true

    // MARK: - Action Processing Methods

    public init() {}

    /// Validates the "DEFLATE" command.
    ///
    /// This method ensures that:
    /// 1. A direct object is specified (what to deflate).
    /// 2. The target item exists and is reachable.
    /// 3. The item has the `.isInflatable` flag (can be deflated).
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Throws: Various `ActionResponse` errors if validation fails.
        public func process(
        command: Command,
        engine: GameEngine
    ) async throws -> ActionResult {

        // Deflate requires a direct object (what to deflate)
        guard let directObjectRef = command.directObject else {
            throw ActionResponse.prerequisiteNotMet(
                engine.messenger.doWhat(verb: command.verb)
            )
        }
        guard case .item(let targetItemID) = directObjectRef else {
            throw ActionResponse.prerequisiteNotMet(
                engine.messenger.thatsNotSomethingYouCan(.deflate)
            )
        }

        // Check if target exists and is reachable
        let targetItem = try await engine.item(targetItemID)
        guard await engine.playerCanReach(targetItemID) else {
            throw ActionResponse.itemNotAccessible(targetItemID)
        }

        // Check if item is inflatable (which means it can also be deflated)
        guard targetItem.hasFlag(.isInflatable) else {
            throw ActionResponse.prerequisiteNotMet(
                engine.messenger.cannotDoThat(
                    verb: .deflate,
                    item: targetItem.withDefiniteArticle
                )
            )
        }
    /// Processes the "DEFLATE" command.
    ///
    /// Handles deflating objects. If the object is not currently inflated, provides
    /// an appropriate message. If it is inflated, clears the `.isInflated` flag
    /// and provides confirmation.
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Returns: An `ActionResult` with appropriate deflate message and state changes.
        guard let directObjectRef = command.directObject,
            case .item(let targetItemID) = directObjectRef
        else {
            let message = engine.messenger.actionHandlerInternalError(
                handler: "DeflateActionHandler",
                details: "directObject was not an item in process"
            )
            throw ActionResponse.internalEngineError(message)
        }

        let targetItem = try await engine.item(targetItemID)

        // Check if currently inflated
        let isCurrentlyInflated = try await engine.hasFlag(.isInflated, on: targetItemID)

        let message =
            if !isCurrentlyInflated {
                engine.messenger.itemNotInflated(item: targetItem.withDefiniteArticle)
            } else {
                engine.messenger.deflateSuccess(item: targetItem.withDefiniteArticle)
            }

        return ActionResult(
            message,
            await engine.setFlag(.isTouched, on: targetItem),
            await engine.updatePronouns(to: targetItem),
            await engine.clearFlag(.isInflated, on: targetItem)
        )
    }

    /// Performs any post-processing after the deflate action completes.
    ///
    /// Currently no post-processing is needed for basic deflation.
    ///
    /// - Parameter context: The action context for the current action.
    public func postProcess(context: ActionContext, result: ActionResult) async throws {
        // No post-processing needed for deflate
    }
}
