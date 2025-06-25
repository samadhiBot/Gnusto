import Foundation

/// Handles the "BURN" command.
///
/// The BURN verb allows players to attempt to set fire to objects.
/// This handler checks if the target object is flammable and provides
/// appropriate responses. Most objects cannot be burned, but some specific
/// items (like paper, wood, etc.) may have special burn behavior.
public struct BurnActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb, .directObject),
        .match(.verb, .directObject, .with, .indirectObject),
    ]

    public let verbs: [VerbID] = [.burn, .ignite, .light]

    public let requiresLight: Bool = true

    // MARK: - Action Processing Methods

    public init() {}

    /// Validates the burn command.
    ///
    /// Ensures that:
    /// - A direct object is specified
    /// - The target object exists and is accessible
    /// - There is sufficient light to see the object
    ///
    /// - Parameter context: The action context containing the command and engine.
    /// - Throws: `ActionError` if validation fails.
    public func process(command: Command, engine: GameEngine) async throws -> ActionResult {

        guard let targetObjectID = command.directObject else {
            throw ActionResponse.prerequisiteNotMet(
                engine.messenger.doWhat(verb: command.verb)
            )
        }

        guard case .item(let itemID) = targetObjectID else {
            throw ActionResponse.prerequisiteNotMet(
                engine.messenger.thatsNotSomethingYouCan(.burn)
            )
        }

        // Check if the item exists and is accessible
        guard (try? await engine.item(itemID)) != nil else {
            throw ActionResponse.unknownEntity(targetObjectID)
        }

        guard await engine.playerCanReach(itemID) else {
            throw ActionResponse.itemNotAccessible(itemID)
        }
    /// Processes the "BURN" command.
    ///
    /// This action performs the following:
    /// 1. Retrieves the target item
    /// 2. Checks if the item has the `.isFlammable` property
    /// 3. If flammable, removes the item and provides a burn message
    /// 4. If not flammable, provides an appropriate refusal message
    /// 5. Sets the `.isTouched` flag on the item
    /// 6. Updates pronouns to refer to the item
    ///
    /// - Parameter context: The action context for the current action.
    /// - Returns: An `ActionResult` containing the burn result and any state changes.
        guard let targetObjectID = command.directObject,
            case .item(let itemID) = targetObjectID
        else {
            return ActionResult(
                engine.messenger.cannotDoThat(verb: "burn")
            )
        }

        let targetItem = try await engine.item(itemID)

        // Check if the item is flammable
        if targetItem.hasFlag(.isFlammable) {
            let message = engine.messenger.itemBurnsToAshes(
                item: targetItem.withDefiniteArticle.capitalizedFirst
            )
            return ActionResult(
                message,
                await engine.setFlag(.isTouched, on: targetItem),
                await engine.updatePronouns(to: targetItem),
                await engine.move(targetItem, to: .nowhere)
            )
        } else {
            // Most items cannot be burned
            return ActionResult(
                engine.messenger.burnCannotBurn(item: targetItem.withDefiniteArticle),
                await engine.setFlag(.isTouched, on: targetItem),
                await engine.updatePronouns(to: targetItem)
            )
        }
    }
}
