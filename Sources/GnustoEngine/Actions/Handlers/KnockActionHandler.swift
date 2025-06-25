import Foundation

/// Handles the "KNOCK" command for knocking on objects.
/// Implements knocking mechanics following ZIL patterns for interactions.
public struct KnockActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.knock),
        .match(.tap, .directObject),
        .match(.verb, .on, .directObject),
    ]

    public let verbs: [VerbID] = [.knock, .rap, .tap]

    public let requiresLight: Bool = true

    // MARK: - Action Processing Methods

    public init() {}

    /// Validates the "KNOCK" command.
    ///
    /// This method ensures that:
    /// 1. A direct object is specified (what to knock on).
    /// 2. The target item exists and is reachable.
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Throws: Various `ActionResponse` errors if validation fails.
        public func process(
        command: Command,
        engine: GameEngine
    ) async throws -> ActionResult {

        // Knock requires a direct object (what to knock on)
        guard let directObjectRef = command.directObject else {
            throw ActionResponse.prerequisiteNotMet(
                engine.messenger.knockOnWhat()
            )
        }
        guard case .item(let targetItemID) = directObjectRef else {
            throw ActionResponse.prerequisiteNotMet(
                engine.messenger.cannotDoThat(verb: "knock on")
            )
        }

        // Check if target exists and is reachable
        _ = try await engine.item(targetItemID)
        guard await engine.playerCanReach(targetItemID) else {
            throw ActionResponse.itemNotAccessible(targetItemID)
        }
    /// Processes the "KNOCK" command.
    ///
    /// Handles knocking attempts on different types of objects.
    /// Generally provides appropriate responses following ZIL traditions.
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Returns: An `ActionResult` with appropriate knocking message and state changes.
        guard let directObjectRef = command.directObject,
            case .item(let targetItemID) = directObjectRef
        else {
            throw ActionResponse.internalEngineError(
                "KnockActionHandler: directObject was not an item in process.")
        }

        let targetItem = try await engine.item(targetItemID)

        // Determine appropriate response based on object type
        let message =
            if targetItem.hasFlag(.isDoor) {
                // Knocking on doors
                if targetItem.hasFlag(.isOpen) {
                    engine.messenger.knockOnOpenDoor(door: targetItem.withDefiniteArticle)
                } else if targetItem.hasFlag(.isLocked) {
                    engine.messenger.knockOnLockedDoor(door: targetItem.withDefiniteArticle)
                } else {
                    engine.messenger.knockOnClosedDoor(door: targetItem.withDefiniteArticle)
                }
            } else if targetItem.hasFlag(.isContainer) {
                // Knocking on containers
                engine.messenger.knockOnContainer(container: targetItem.withDefiniteArticle)
            } else {
                // Generic knocking response for objects
                engine.messenger.knockOnGenericObject(item: targetItem.withDefiniteArticle)
            }

        return ActionResult(
            message,
            await engine.setFlag(.isTouched, on: targetItem),
            await engine.updatePronouns(to: targetItem)
        )
    }

    /// Performs any post-processing after the knock action completes.
    ///
    /// Currently no post-processing is needed for basic knocking.
    ///
    /// - Parameter context: The action context for the current action.
    public func postProcess(context: ActionContext) async throws {
        // No post-processing needed for knock
    }
}
