import Foundation

/// Handles the "TURN ON" command, allowing the player to activate items that are
/// considered devices (e.g., light sources).
public struct TurnOnActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties


    public let syntax: [SyntaxRule] = [
        .match(.verb, .directObject, .on),
        .match(.verb, .on, .directObject),
    ]

    public let synonyms: [Verb] = [.switch, .turn]

    public let actions: [Intent] = [.lightSource]

    public let requiresLight: Bool = false

    // MARK: - Action Processing Methods

    public init() {}

    /// Processes the "TURN ON" command.
    ///
    /// This action validates prerequisites and activates the specified device if possible.
    /// Only handles devices that can be turned on/off (items with the .isDevice flag).
    public func process(context: ActionContext) async throws -> ActionResult {
        // Get direct object and ensure it's an item
        guard let targetItem = try await context.itemDirectObject() else {
            throw ActionResponse.doWhat(context)
        }

        // Check if the item is a device
        guard await targetItem.hasFlag(.isDevice) else {
            throw ActionResponse.feedback(
                context.msg.cannotTurnOn()
            )
        }

        // Check if it's already on
        if await targetItem.hasFlag(.isOn) {
            throw ActionResponse.feedback(
                context.msg.alreadyOn()
            )
        }

        return await ActionResult(
            context.msg.youDo(
                context.command,
                item: targetItem.withDefiniteArticle
            ),
            targetItem.setFlag(.isTouched),
            targetItem.setFlag(.isOn)
        )
    }

}
