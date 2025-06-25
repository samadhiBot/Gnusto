import Foundation

/// Handles the CHOMP verb for biting, gnawing, or chewing actions.
///
/// This is a humorous command that provides entertaining responses to player attempts
/// to bite or chew on things. Based on ZIL tradition of atmospheric commands.
public struct ChompActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb, .directObject),
        .match(.chew),
    ]

    public let verbs: [VerbID] = [.chomp, .bite, .chew]

    public let requiresLight: Bool = true

    // MARK: - Action Processing Methods

    public init() {}

    public func validate(
        context: ActionContext
    ) async throws {
        // CHOMP without object is always valid (general chomping)
        guard let directObjectRef = command.directObject else {
            return
        }

        guard case .item(let targetItemID) = directObjectRef else {
            throw ActionResponse.prerequisiteNotMet(
                engine.messenger.thatsNotSomethingYouCan(.chomp)
            )
        }

        // Check if item exists (engine.item() will throw if not found)
        let _ = try await engine.item(targetItemID)

        // Check reachability
        guard await engine.playerCanReach(targetItemID) else {
            throw ActionResponse.itemNotAccessible(targetItemID)
        }
    }

    public func process(
        context: ActionContext
    ) async throws -> ActionResult {
        // Handle general chomping (no object)
        guard let directObjectRef = command.directObject,
            case .item(let targetItemID) = directObjectRef
        else {
            // Get random response from message provider
            return ActionResult(
                engine.messenger.chompResponse()
            )
        }

        let targetItem = try await engine.item(targetItemID)

        // Special responses for different types of items
        let message =
            if targetItem.hasFlag(.isEdible) {
                engine.messenger.chompEdible(
                    item: targetItem.withIndefiniteArticle
                )
            } else if targetItem.hasFlag(.isPerson) || targetItem.hasFlag(.isCharacter) {
                engine.messenger.chompCharacter(
                    targetItem.withDefiniteArticle
                )
            } else {
                engine.messenger.chompTargetResponse(
                    item: targetItem.withDefiniteArticle
                )
            }

        // Mark item as touched and update pronouns
        return ActionResult(
            message,
            await engine.setFlag(.isTouched, on: targetItem),
            await engine.updatePronouns(to: targetItem)
        )
    }
}
