import Foundation

/// Handles the "CLIMB" command, allowing the player to climb objects.
///
/// This handler implements ZIL-inspired behavior for climbing. When the player
/// climbs an object, the handler:
/// 1. Checks if the object enables traversal of any exit in the current location
/// 2. If so, uses that exit (e.g., "climb stairs" -> "go up")
/// 3. Otherwise, provides default climbing behavior for climbable objects
///
/// This works with the Exit system's `via:` parameter to create flexible
/// climbing-based movement (stairs, ladders, ropes, etc.).
public struct ClimbActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb),
        .match(.verb, .directObject),
    ]

    public let synonyms: [Verb] = [.climb, .ascend]

    public let requiresLight: Bool = true

    // MARK: - Action Processing Methods

    public init() {}

    /// Processes the "CLIMB" command.
    ///
    /// This action validates prerequisites and handles various climbing scenarios:
    /// 1. "climb" with no object - asks what to climb
    /// 2. "climb <object>" that enables an exit - traverses that exit
    /// 3. "climb <climbable object>" - default climbing behavior
    /// 4. "climb <non-climbable object>" - error message
    public func process(context: ActionContext) async throws -> ActionResult {
        guard let targetItem = try await context.itemDirectObject() else {
            // General climbing (no object)
            throw ActionResponse.doWhat(context)
        }

        let currentLocation = try await context.player.location

        // Check if this object enables traversal of any exit in the current location
        let sortedExits = try await currentLocation.exits.sorted { $0.direction < $1.direction }

        for exit in sortedExits {
            // Check if object enables traversal in this direction
            if exit.doorID == targetItem.id {
                // For global objects like stairs, verify they're actually present
                if try await targetItem.parent == .nowhere,
                   try await currentLocation.localGlobals.contains(targetItem.id) == false
                {
                    throw ActionResponse.itemNotAccessible(targetItem)
                }

                // Execute movement in the appropriate direction
                let goResult = try await GoActionHandler().process(
                    context: ActionContext(
                        Command(verb: .go, direction: exit.direction),
                        context.engine
                    )
                )

                // Combine state changes from climb (touch/pronouns) with go result
                return try await ActionResult(
                    message: goResult.message,
                    changes: [
                        targetItem.setFlag(.isTouched)
                    ] + goResult.changes
                )
            }
        }

        // No exit uses this object, so handle as regular climbing

        // Check if the item is climbable
        let message =
            if await targetItem.hasFlag(.isClimbable) {
                // Default climbable behavior - can be overridden by specific item handlers
                await context.msg.climbSuccess(targetItem.withDefiniteArticle)
            } else {
                // Not climbable
                await context.msg.cannotDo(
                    context.command,
                    item: targetItem.withDefiniteArticle
                )
            }

        return try await ActionResult(
            message,
            targetItem.setFlag(.isTouched)
        )
    }
}
