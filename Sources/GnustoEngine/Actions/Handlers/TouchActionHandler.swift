import Foundation

/// Handles the "TOUCH" command and its synonyms (e.g., "FEEL", "RUB", "PAT"), allowing the
/// player to physically interact with an item by touching it.
public struct TouchActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb, .directObject)
    ]

    public let verbs: [VerbID] = [.touch, .feel]

    public let requiresLight: Bool = true

    // MARK: - Action Processing Methods
    /// Validates the "TOUCH" command.
    ///
    /// This method ensures that:
    /// 1. A direct object is specified (the player must indicate *what* to touch).
    /// 2. The direct object refers to an existing item.
    /// 3. The player can reach the specified item.
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Throws: `ActionResponse.custom` if no direct object is provided,
    ///           `ActionResponse.prerequisiteNotMet` if the direct object is not an item,
    ///           or `ActionResponse.itemNotAccessible` if the item cannot be reached.
    ///           Can also throw errors from `engine.item()` if the item doesn't exist.
        public func process(
        command: Command,
        engine: GameEngine
    ) async throws -> ActionResult {

        // 1. Ensure we have a direct object and it's an item
        guard let directObjectRef = command.directObject else {
            throw ActionResponse.custom(
                engine.messenger.doWhat(verb: command.verb)
            )
        }
        guard case .item(let targetItemID) = directObjectRef else {
            throw ActionResponse.prerequisiteNotMet(
                engine.messenger.thatsNotSomethingYouCan(.touch)
            )
        }

        // 2. Check if item exists (engine.item() will throw if not found)
        let _ = try await engine.item(targetItemID)

        // 3. Check reachability
        guard await engine.playerCanReach(targetItemID) else {
            throw ActionResponse.itemNotAccessible(targetItemID)
        }
    /// Processes the "TOUCH" command.
    ///
    /// Assuming validation has passed, this action:
    /// 1. Retrieves the target item.
    /// 2. Creates a `StateChange` to set the `.isTouched` flag on the target item, if not already set.
    /// 3. Returns a generic message like "You feel nothing special."
    ///
    /// Specific tactile feedback or consequences for touching particular items can be implemented
    /// via custom `ItemEventHandler` logic.
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Returns: An `ActionResult` containing a default message and potentially a `StateChange`
    ///   to mark the item as touched.
    /// - Throws: `ActionResponse.internalEngineError` if the direct object is unexpectedly not an item.
    ///           Can also throw errors from `engine.item()` if the item doesn't exist.
        guard let directObjectRef = command.directObject,
            case .item(let targetItemID) = directObjectRef
        else {
            throw ActionResponse.internalEngineError(
                "Touch: directObject was not an item in process.")
        }
        let targetItem = try await engine.item(targetItemID)

        return ActionResult(
            engine.messenger.nothingSpecial(verb: .feel),
            await engine.setFlag(.isTouched, on: targetItem)
        )
    }
}
