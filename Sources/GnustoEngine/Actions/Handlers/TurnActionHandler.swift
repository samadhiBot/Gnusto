import Foundation

/// Handles the "TURN" command for turning objects.
/// Implements turning mechanics following ZIL patterns for object manipulation.
public struct TurnActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb, .directObject),
        .match(.verb, .directObject, .to, .indirectObject),
    ]

    public let verbs: [VerbID] = [.turn, .rotate, .twist]

    public let requiresLight: Bool = true

    // MARK: - Action Processing Methods

    public init() {}

    /// Validates the "TURN" command.
    ///
    /// This method ensures that:
    /// 1. A direct object is specified (what to turn).
    /// 2. The target item exists and is reachable.
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Throws: Various `ActionResponse` errors if validation fails.
    public func process(command: Command, engine: GameEngine) async throws -> ActionResult {

        // Turn requires a direct object (what to turn)
        guard let directObjectRef = command.directObject else {
            throw ActionResponse.prerequisiteNotMet(
                engine.messenger.doWhat(verb: command.verb)
            )
        }
        guard case .item(let targetItemID) = directObjectRef else {
            throw ActionResponse.prerequisiteNotMet(
                engine.messenger.cannotDoThat(verb: "turn")
            )
        }

        // Check if target exists and is reachable
        _ = try await engine.item(targetItemID)
        guard await engine.playerCanReach(targetItemID) else {
            throw ActionResponse.itemNotAccessible(targetItemID)
        }
    /// Processes the "TURN" command.
    ///
    /// Handles turning attempts on different types of objects.
    /// Provides appropriate responses following ZIL traditions.
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Returns: An `ActionResult` with appropriate turning message and state changes.
        guard let directObjectRef = command.directObject,
            case .item(let targetItemID) = directObjectRef
        else {
            throw ActionResponse.internalEngineError(
                "TurnActionHandler: directObject was not an item in process.")
        }

        let targetItem = try await engine.item(targetItemID)

        // Determine appropriate response based on object type
        let message =
            if targetItem.hasFlag(.isCharacter) {
                // Can't turn characters
                engine.messenger.turnCharacter(character: targetItem.withDefiniteArticle)
            } else if targetItem.hasFlag(.isKey) {
                // Keys need to be used with something
                engine.messenger.turnKey(item: targetItem.withDefiniteArticle)
            } else if targetItem.hasFlag(.isDial) {
                // Dials click into position
                engine.messenger.turnDial(item: targetItem.withDefiniteArticle)
            } else if targetItem.hasFlag(.isKnob) {
                // Knobs click into position
                engine.messenger.turnKnob(item: targetItem.withDefiniteArticle)
            } else if targetItem.hasFlag(.isWheel) {
                // Wheels rotate with effort
                engine.messenger.turnWheel(item: targetItem.withDefiniteArticle)
            } else if targetItem.hasFlag(.isHandle) {
                // Handles move with grinding sound
                engine.messenger.turnHandle(item: targetItem.withDefiniteArticle)
            } else if targetItem.hasFlag(.isTakable) {
                // Regular takable objects can be turned in hands
                engine.messenger.turnRegularObject(item: targetItem.withDefiniteArticle)
            } else {
                // Fixed objects can't be turned
                engine.messenger.turnFixedObject(item: targetItem.withDefiniteArticle)
            }

        return ActionResult(
            message,
            await engine.setFlag(.isTouched, on: targetItem),
            await engine.updatePronouns(to: targetItem)
        )
    }

    /// Performs any post-processing after the turn action completes.
    ///
    /// Currently no post-processing is needed for basic turning.
    ///
    /// - Parameter context: The action context for the current action.
    public func postProcess(context: ActionContext) async throws {
        // No post-processing needed for turn
    }
}
