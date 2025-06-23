import Foundation

/// Handles the CURSE verb for swearing, cursing, or expressing frustration.
///
/// This is a humorous atmospheric command that provides entertaining responses
/// to player attempts to curse or swear. Based on ZIL tradition.
public struct CurseActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let verbID: VerbID = .curse

    public let syntax: [SyntaxRule] = [
        SyntaxRule(.verb),
        SyntaxRule(.verb, .directObject)
    ]

    public let synonyms: [String] = ["swear", "damn"]

    public let requiresLight: Bool = false

    // MARK: - Action Processing Methods

    public init() {}

    public func validate(
        context: ActionContext
    ) async throws {
        // If there's a direct object, validate it exists and is reachable
        guard let directObjectRef = context.command.directObject else {
            return  // General cursing is always valid
        }

        guard case .item(let targetItemID) = directObjectRef else {
            throw ActionResponse.prerequisiteNotMet(
                context.message.thatsNotSomethingYouCan(.curse)
            )
        }

        // Check if item exists
        let _ = try await context.engine.item(targetItemID)

        // Check reachability (you can curse at things you can see)
        guard await context.engine.playerCanReach(targetItemID) else {
            throw ActionResponse.itemNotAccessible(targetItemID)
        }
    }

    public func process(
        context: ActionContext
    ) async throws -> ActionResult {
        // Handle cursing at a specific object
        if let directObjectRef = context.command.directObject,
            case .item(let targetItemID) = directObjectRef
        {
            let targetItem = try await context.engine.item(targetItemID)

            let message = context.message.curseTargetResponse(
                item: targetItem.withDefiniteArticle
            )
            return ActionResult(message)
        } else {
            // General cursing (no object)
            return ActionResult(
                context.message.curseResponse()
            )
        }
    }
}
