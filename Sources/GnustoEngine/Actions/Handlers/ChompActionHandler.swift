import Foundation

/// Handles the CHOMP verb for biting, gnawing, or chewing actions.
///
/// This is a humorous command that provides entertaining responses to player attempts
/// to bite or chew on things. Based on ZIL tradition of atmospheric commands.
public struct ChompActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let verbID: VerbID = .chomp

    public let syntax: [SyntaxRule] = [
        SyntaxRule(.verb, .directObject)
    ]

    public let synonyms: [String] = ["bite", "chew"]

    public let requiresLight: Bool = true

    // MARK: - Action Processing Methods

    public init() {}

    public func validate(
        context: ActionContext
    ) async throws {
        // CHOMP without object is always valid (general chomping)
        guard let directObjectRef = context.command.directObject else {
            return
        }

        guard case .item(let targetItemID) = directObjectRef else {
            throw ActionResponse.prerequisiteNotMet(
                context.message.thatsNotSomethingYouCan(.chomp)
            )
        }

        // Check if item exists (engine.item() will throw if not found)
        let _ = try await context.engine.item(targetItemID)

        // Check reachability
        guard await context.engine.playerCanReach(targetItemID) else {
            throw ActionResponse.itemNotAccessible(targetItemID)
        }
    }

    public func process(
        context: ActionContext
    ) async throws -> ActionResult {
        // Handle general chomping (no object)
        guard let directObjectRef = context.command.directObject,
            case .item(let targetItemID) = directObjectRef
        else {
            // Get random response from message provider
            return ActionResult(
                context.message.chompResponse()
            )
        }

        let targetItem = try await context.engine.item(targetItemID)

        // Special responses for different types of items
        let message =
            if targetItem.hasFlag(.isEdible) {
                context.message.chompEdible(
                    item: targetItem.withIndefiniteArticle
                )
            } else if targetItem.hasFlag(.isPerson) || targetItem.hasFlag(.isCharacter) {
                context.message.chompCharacter(
                    targetItem.withDefiniteArticle
                )
            } else {
                context.message.chompTargetResponse(
                    item: targetItem.withDefiniteArticle
                )
            }

        // Mark item as touched and update pronouns
        return ActionResult(
            message: message,
            changes: [
                await context.engine.setFlag(.isTouched, on: targetItem),
                await context.engine.updatePronouns(to: targetItem),
            ]
        )
    }
}
