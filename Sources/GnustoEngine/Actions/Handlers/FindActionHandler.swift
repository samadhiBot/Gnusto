import Foundation

/// Handles the "FIND" command.
///
/// The FIND verb allows players to ask about the location of objects.
/// This handler provides different responses based on whether the target
/// object is visible, held by the player, or not present in the current scope.
public struct FindActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb, .directObject),
        .match(.search, .for, .directObject),
    ]

    public let synonyms: [Verb] = [.find, .locate]

    public let requiresLight: Bool = true

    // MARK: - Action Processing Methods

    public init() {}

    /// Processes the "FIND" command.
    ///
    /// This action provides different responses based on the target object's state:
    /// - If the object is held by the player: "You have it."
    /// - If the object is visible in the current location: "It's right here!"
    /// - If the object exists but isn't visible: "Any such thing lurks beyond your reach here."
    /// - If the object doesn't exist: "Any such thing lurks beyond your reach here."
    public func process(context: ActionContext) async throws -> ActionResult {
        guard let targetItem = try await context.itemDirectObject() else {
            throw ActionResponse.doWhat(context)
        }

        // Check if the player is holding it
        let message = if try await targetItem.playerIsHolding {
            context.msg.youHaveIt()
        } else if await targetItem.playerCanReach {
            context.msg.itsRightHere()
        } else {
            context.msg.unknownItem(targetItem.id)
        }

        return ActionResult(message)
    }
}
