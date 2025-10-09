import Foundation

/// Handles the "ATTACK" command and its synonyms (e.g., "FIGHT", "HIT", "KILL").
///
/// By default, this handler provides non-violent responses. Combat functionality
/// is added by `CombatMiddleware` which intercepts this handler when combat is appropriate.
public struct AttackActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb, .directObject),
        .match(.verb, .directObject, .with, .indirectObject),
    ]

    public let synonyms: [Verb] = [
        .attack,
        .break,
        .destroy,
        .fight,
        .hit,
        .kill,
        .rip,
        .ruin,
        .shatter,
        .slay,
        .smash,
        .stab,
        .tear,
    ]

    public let requiresLight: Bool = true

    // MARK: - Action Processing Methods

    public init() {}

    /// Processes the "ATTACK" command.
    ///
    /// Default behavior provides non-violent responses. If `CombatMiddleware` is
    /// included in the game, it will intercept this handler to provide actual combat.
    public func process(context: ActionContext) async throws -> ActionResult {
        // Get the target item to attack
        guard
            let target = try await context.itemDirectObject(
                playerMessage: context.msg.attackSelf()
            )
        else {
            throw ActionResponse.doWhat(context)
        }

        // Check if target is a character
        if await target.isCharacter {
            // Default non-violent response for characters
            // CombatMiddleware will intercept and override this if present
            return await ActionResult(
                context.msg.attackCharacter(target.withDefiniteArticle),
                target.setFlag(.isTouched)
            )
        }

        // Non-character target
        return await ActionResult(
            context.msg.attackNonCharacter(target.withDefiniteArticle),
            target.setFlag(.isTouched)
        )
    }
}
