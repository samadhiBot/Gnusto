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

    /// Processes the "TASTE" command.
    ///
    /// This action validates prerequisites and provides gustatory responses to tasting items.
    /// Checks that the item exists and is accessible, then provides appropriate taste feedback.
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

        // Check if item exists and is accessible
        let targetItem = try await engine.item(itemID)
        guard await engine.playerCanReach(itemID) else {
            throw ActionResponse.itemNotAccessible(itemID)
        }

        return ActionResult(
            engine.messenger.tastesAverage(item: targetItem.withDefiniteArticle),
            await engine.setFlag(.isTouched, on: targetItem),
            await engine.updatePronouns(to: targetItem)
        )
    }
}
