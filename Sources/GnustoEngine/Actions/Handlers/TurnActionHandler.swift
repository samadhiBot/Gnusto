import Foundation

/// Handles the "TURN" command for turning objects.
/// Implements turning mechanics following ZIL patterns for object manipulation.
public struct TurnActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb, .directObject),
        .match(.verb, .directObject, .to, .indirectObject),
    ]

    public let verbs: [Verb] = [.turn, .rotate, .twist]

    public let requiresLight: Bool = true

    // MARK: - Action Processing Methods

    public init() {}

    /// Processes the "TURN" command.
    ///
    /// This action validates prerequisites and handles turning attempts on different types
    /// of objects. Provides appropriate responses following ZIL traditions.
    /// Can optionally turn to a specific setting specified in the indirect object.
    public func process(command: Command, engine: GameEngine) async throws -> ActionResult {
        // Turn requires a direct object (what to turn)
        guard let directObjectRef = command.directObject else {
            throw ActionResponse.prerequisiteNotMet(
                engine.messenger.doWhat(verb: command.verb)
            )
        }

        let targetItemID: ItemID
        switch directObjectRef {
        case .item(let itemID):
            targetItemID = itemID
        case .location(let locationID):
            throw ActionResponse.prerequisiteNotMet(
                engine.messenger.cannotDoThat(verb: "turn")
            )
        case .player:
            throw ActionResponse.prerequisiteNotMet(
                engine.messenger.cannotVerbYourself(verb: "turn")
            )
        case .universal:
            throw ActionResponse.prerequisiteNotMet(
                engine.messenger.cannotDoThat(verb: "turn")
            )
        }

        // Check if target exists and is accessible
        let targetItem = try await engine.item(targetItemID)
        guard await engine.playerCanReach(targetItemID) else {
            throw ActionResponse.itemNotAccessible(targetItemID)
        }

        // Determine appropriate response based on object type
        let message =
            if targetItem.hasFlag(.isCharacter) {
                engine.messenger.turnCharacter(character: targetItem.withDefiniteArticle)
            } else if targetItem.hasFlag(.isTakable) {
                engine.messenger.turnItem(item: targetItem.withDefiniteArticle)
            } else {
                engine.messenger.turnFixedObject(item: targetItem.withDefiniteArticle)
            }

        return ActionResult(
            message,
            await engine.setFlag(.isTouched, on: targetItem),
            await engine.updatePronouns(to: targetItem)
        )
    }
}
