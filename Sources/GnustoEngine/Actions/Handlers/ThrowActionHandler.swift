import Foundation

/// Handles the "THROW" command for throwing objects with optional targets.
/// Implements object throwing mechanics following ZIL patterns.
public struct ThrowActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb, .directObject),
        .match(.verb, .directObject, .at, .indirectObject),
        .match(.verb, .directObject, .to, .indirectObject),
    ]

    public let synonyms: [Verb] = [.throw, .hurl, .toss, .chuck]

    public let requiresLight: Bool = true

    // MARK: - Action Processing Methods

    public init() {}

    /// Processes the "THROW" command.
    ///
    /// Handles different throwing scenarios:
    /// - Throwing at specific targets
    /// - General throwing (drops item in current location)
    ///
    /// - Parameter context: The action context containing the command and game state.
    /// - Returns: An `ActionResult` with appropriate throwing message and state changes.
    public func process(context: ActionContext) async throws -> ActionResult {
        // Throw requires a direct object (what to throw)
        guard let projectile = try await context.itemDirectObject() else {
            throw ActionResponse.doWhat(context)
        }

        // Check if item is held
        guard await projectile.playerIsHolding else {
            throw ActionResponse.itemNotHeld(projectile)
        }

        let theProjectile = await projectile.withDefiniteArticle

        guard let target = try await context.itemIndirectObject() else {
            // General throwing - no specific target
            let location = await context.player.location

            return await ActionResult(
                context.msg.throwItem(context.command, item: theProjectile),
                projectile.setFlag(.isTouched),
                projectile.move(to: .location(location.id))
            )
        }

        // If a target is specified, validate it
        switch context.command.preposition {
        case .at:
            return await ActionResult(
                target.response(
                    object: {
                        context.msg.throwAtObject(context.command, item: theProjectile, target: $0)
                    },
                    character: {
                        context.msg.throwAtCharacter(
                            context.command, item: theProjectile, character: $0)
                    },
                    enemy: {
                        context.msg.throwAtEnemy(context.command, item: theProjectile, enemy: $0)
                    },
                ),
                projectile.setFlag(.isTouched),
                projectile.move(to: .location(context.player.location.id)),
                target.setFlag(.isTouched)
            )

        default:  // case .to:
            let roughValue = await projectile.roughValue
            let newParent: ParentEntity =
                if await target.isCharacter {
                    .item(target.id)
                } else {
                    await .location(context.player.location.id)
                }
            return await ActionResult(
                target.response(
                    object: {
                        context.msg.throwToObject(context.command, item: theProjectile, target: $0)
                    },
                    character: {
                        context.msg.throwToCharacter(
                            context.command,
                            item: theProjectile,
                            character: $0,
                            value: roughValue
                        )
                    },
                    enemy: {
                        context.msg.throwToEnemy(
                            context.command,
                            item: theProjectile,
                            enemy: $0,
                            value: roughValue
                        )
                    },
                ),
                projectile.setFlag(.isTouched),
                projectile.move(to: newParent),
                target.setFlag(.isTouched)
            )
        }
    }
}
