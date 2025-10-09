import Foundation
import GnustoEngine

/// Handles the "ATTACK" command with combat functionality.
///
/// This action handler is provided by `CombatMiddleware` and should be registered
/// in the game blueprint's `customActionHandlers` to enable combat. It replaces
/// the default engine's `AttackActionHandler` with combat-aware behavior.
///
/// When the player attacks a character, this handler initiates combat using the
/// middleware's configured combat systems and messengers. For non-character targets,
/// it falls back to the standard non-violent response.
public struct CombatAttackActionHandler: ActionHandler {
    // MARK: - Properties

    /// Reference to the combat middleware for accessing configuration
    private let middleware: CombatMiddleware

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

    // MARK: - Initialization

    /// Creates a new combat attack action handler.
    ///
    /// - Parameter middleware: The combat middleware instance for accessing configuration
    public init(middleware: CombatMiddleware) {
        self.middleware = middleware
    }

    // MARK: - Action Processing Methods

    /// Processes the "ATTACK" command with combat functionality.
    ///
    /// When the player attacks a character, this initiates combat using the middleware's
    /// configured combat systems and messengers. For non-character targets, it provides
    /// a standard non-violent response.
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
            // Get weapon if specified in command
            let weapon = try await context.itemIndirectObject()

            // Initiate combat through middleware
            return try await middleware.playerAttacks(
                enemy: target,
                playerWeapon: weapon,
                enemyWeapon: nil,
                engine: context.engine
            )
        }

        // Non-character target - standard non-violent response
        return await ActionResult(
            context.msg.attackNonCharacter(target.withDefiniteArticle),
            target.setFlag(.isTouched)
        )
    }
}
