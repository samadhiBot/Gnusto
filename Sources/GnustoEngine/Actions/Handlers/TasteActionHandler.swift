import Foundation

/// Handles the "TASTE" command, providing a generic response when the player attempts
/// to taste an item.
///
/// By default, tasting items results in a non-specific message. Game developers can provide
/// more detailed taste descriptions or effects for particular items (e.g., food, potions)
/// by implementing custom `ItemEventHandler` logic.
public struct TasteActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb, .directObject)
    ]

    public let verbs: [VerbID] = [.taste, .lick]

    public let requiresLight: Bool = false

    // MARK: - Action Processing Methods

    public init() {}

    /// Validates the "TASTE" command.
    ///
    /// This method ensures that:
    /// 1. A direct object is specified (the player must indicate *what* to taste).
    /// 2. The direct object refers to an item.
    /// Tasting non-item entities or tasting nothing is not permitted by this handler.
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Throws: `ActionResponse.custom` if no direct object is provided, or
    ///           `ActionResponse.prerequisiteNotMet` if the direct object is not an item.
    public func process(command: Command, engine: GameEngine) async throws -> ActionResult {

        guard let directObjectRef = command.directObject else {
            throw ActionResponse.custom(
                engine.messenger.doWhat(verb: command.verb)
            )
        }
        guard case .item(let itemID) = directObjectRef else {
            throw ActionResponse.prerequisiteNotMet(
                engine.messenger.thatsNotSomethingYouCan(.taste)
            )
        }
        guard await engine.playerCanReach(itemID) else {
            throw ActionResponse.itemNotAccessible(itemID)
        }
    /// Processes the "TASTE" command.
    ///
    /// Assuming validation has passed (meaning a direct object, which is an item, was specified),
    /// this action returns a generic message like "That tastes about average."
    /// Specific taste effects or descriptions for items should be implemented via custom handlers.
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Returns: An `ActionResult` with a default taste-related message.
        // Validate ensures directObject is an item if present.
        // Generic response. Tasting specific items (like food) would need custom logic.
        return ActionResult(
            engine.messenger.tastesAverage()
        )
    }
}
