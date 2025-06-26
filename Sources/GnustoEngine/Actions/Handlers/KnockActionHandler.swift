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

    public let verbs: [Verb] = [.knock, .rap, .tap]

    public let requiresLight: Bool = true

    // MARK: - Action Processing Methods

    public init() {}

    /// Processes the "KNOCK" command.
    ///
    /// Handles knocking attempts on different types of objects.
    /// Generally provides appropriate responses following ZIL traditions.
    ///
    /// - Parameter command: The command being processed.
    /// - Parameter engine: The game engine.
    /// - Returns: An `ActionResult` with appropriate knocking message and state changes.
    public func process(command: Command, engine: GameEngine) async throws -> ActionResult {
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
        let targetItem = try await engine.item(targetItemID)

        guard await engine.playerCanReach(targetItemID) else {
            throw ActionResponse.itemNotAccessible(targetItemID)
        }

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
}
