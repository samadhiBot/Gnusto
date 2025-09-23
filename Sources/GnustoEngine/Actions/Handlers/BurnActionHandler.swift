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

    public let synonyms: [Verb] = [.burn, .ignite, .light]

    public let requiresLight: Bool = false

    // MARK: - Action Processing Methods

    public init() {}

    /// Processes the "BURN" command.
    ///
    /// This action validates prerequisites and attempts to burn the specified item.
    /// Checks if the item is flammable and provides appropriate responses.
    public func process(context: ActionContext) async throws -> ActionResult {
        // Special handling for commands like `LIGHT TORCH`
        if let igniteLightSourceResult = try await igniteLightSource(context) {
            return igniteLightSourceResult
        }

        // Get the target item to burn
        guard let target = try await context.itemDirectObject() else {
            throw ActionResponse.doWhat(context)
        }

        // Already on fire?
        if await target.hasFlag(.isBurning) {
            return await ActionResult(
                context.msg.alreadyBurning(target.withDefiniteArticle)
            )
        }

        // Redirect if the intent is to attack an enemy with something burning
        if await target.isHostileEnemy == true {
            return try await AttackActionHandler().process(context: context)
        }

        // Check if the player has specified an igniter intended to burn the target
        if let igniter = try await context.itemIndirectObject(
            failureMessage: context.msg.cannotDoWithThat(
                context.command,
                item: target.withDefiniteArticle
            )
        ) {
            // Validate that the player is holding the igniter
            guard await igniter.playerIsHolding else {
                throw ActionResponse.itemNotHeld(igniter)
            }

            // Make sure it's a valid igniter
            guard await igniter.hasFlags(any: .isBurning, .isSelfIgnitable) else {
                throw ActionResponse.cannotDoWithThat(context, target, igniter)
            }

            // Check whether the target is flammable
            return if await target.hasFlag(.isFlammable) {
                await ActionResult(
                    context.msg.itemBeginsToBurn(target.withDefiniteArticle),
                    target.setFlag(.isBurning),
                    target.setFlag(.isTouched)
                )
            } else {
                await ActionResult(
                    context.msg.burnItemWithTool(
                        context.command,
                        item: target.withDefiniteArticle,
                        tool: igniter.withDefiniteArticle
                    ),
                    target.setFlag(.isTouched)
                )
            }
        }

        // Check if target can self-ignite, like a match, i.e. nothing else is needed to light it
        if await target.hasFlag(.isSelfIgnitable) {
            return await ActionResult(
                context.msg.itemBeginsToBurn(target.withDefiniteArticle),
                target.setFlag(.isBurning),
                target.setFlag(.isTouched)
            )
        }

        // Most items cannot be burned
        return await ActionResult(
            target.response(
                object: { context.msg.cannotDo(context.command, item: $0) },
                character: { context.msg.burnCharacter(context.command, character: $0) }
            )
        )
    }

    public func igniteLightSource(_ context: ActionContext) async throws -> ActionResult? {
        // Get direct object and ensure it's an item
        guard let lightSource = try await context.itemDirectObject() else {
            return nil
        }

        // Reroute if the intention is to `turn on`, e.g. LIGHT FLASHLIGHT
        if await lightSource.hasFlags(all: .isDevice, none: .isFlammable) {
            return try await TurnOnActionHandler().process(context: context)
        }

        // Short circuit if the item is not a flammable light source
        guard await lightSource.hasFlags(all: .isLightSource, .isFlammable) else {
            return nil
        }

        // Check if it's already lit: no need to re-light a burning torch
        if await lightSource.isProvidingLight {
            throw await ActionResponse.feedback(
                context.msg.alreadyBurning(lightSource.withDefiniteArticle)
            )
        }

        // Check if it can self-ignite, like a match, i.e. nothing else is needed to light it
        if await lightSource.hasFlag(.isSelfIgnitable) {
            return await ActionResult(
                context.msg.lightIsNowBurning(lightSource.withDefiniteArticle),
                lightSource.setFlag(.isBurning),
                lightSource.setFlag(.isTouched)
            )
        }

        // Check for something to ignite the light source
        guard let igniter = try await context.itemIndirectObject() else {
            throw await ActionResponse.feedback(
                context.msg.lightRequiresFlame(lightSource.withDefiniteArticle)
            )
        }

        // Check if it's a valid igniter
        guard await igniter.hasFlags(any: .isBurning, .isSelfIgnitable) else {
            throw await ActionResponse.feedback(
                context.msg.lightRequiresIgniter(
                    lightSource.withDefiniteArticle,
                    igniter: igniter.withDefiniteArticle
                )
            )
        }

        return await ActionResult(
            context.msg.lightIsNowBurning(lightSource.withDefiniteArticle),
            lightSource.setFlag(.isBurning),
            lightSource.setFlag(.isTouched),
            igniter.setFlag(.isTouched)
        )
    }
}
