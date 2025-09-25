import Foundation

/// Handles the "ATTACK" command and its synonyms (e.g., "FIGHT", "HIT", "KILL").
/// Implements turn-based combat mechanics with D&D-style character properties.
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

    /// Processes the "ATTACK" command using the turn-based combat system.
    ///
    /// Handles different attack scenarios:
    /// 1. Non-characters: Returns a message about attacking inappropriate targets
    /// 2. Characters: Initiates combat if not already fighting, or processes combat turn
    ///
    /// Combat flow:
    /// - If not in combat: Initiates combat and transitions to combat mode
    /// - If already in combat with this enemy: Processes the combat turn
    /// - If in combat with a different enemy: Returns error message
    public func process(context: ActionContext) async throws -> ActionResult {
        // Get the target item to attack
        guard
            let target = try await context.itemDirectObject(
                playerMessage: context.msg.attackSelf()
            )
        else {
            throw ActionResponse.doWhat(context)
        }

        // First check: Is target NOT a character?
        guard await target.isCharacter else {
            return await ActionResult(
                context.msg.attackNonCharacter(target.withDefiniteArticle),
                target.setFlag(.isTouched)
            )
        }

        // If a weapon was specified, check if player is holding it
        let playerWeapon = try await findPlayerWeapon(in: context)

        // Check if an opponent requires a weapon for fight it
        if playerWeapon == nil, await target.characterSheet.requiresWeapon == true {
            return await ActionResult(
                context.engine.combatMessenger(for: target.id).unarmedAttackDenied(
                    enemy: target,
                    enemyWeapon: target.preferredWeapon
                )
            )
        }

        // Check if already in combat
        if let combat = await context.engine.combatState {
            // TODO: allow combat with multiple foes?
            guard combat.enemyID == target.id else {
                let enemy = await combat.enemy(with: context.engine)
                return await ActionResult(
                    context.msg.alreadyInCombat(
                        with: enemy.withDefiniteArticle
                    ),
                    target.setFlag(.isTouched)
                )
            }

            // Already in combat with this enemy: do not reset the combat state.
            // Simply mark interaction and let the combat system advance state this turn.
            return await ActionResult(
                target.setFlag(.isTouched)
            )
        }

        // Check if player can act (not unconscious/dead)
        guard await context.player.canAct else {
            return ActionResult(
                context.msg.youCannotAct()
            )
        }

        // Begin combat and hand off to combat system
        return await context.engine.playerAttacks(
            enemy: target,
            playerWeapon: playerWeapon,
            enemyWeapon: target.preferredWeapon
        )
    }

    func findPlayerWeapon(in context: ActionContext) async throws -> ItemProxy? {
        let weapon =
            if let specified = try await context.itemIndirectObject() {
                // Weapon specified in command
                specified
            } else if let previousID = await context.engine.combatState?.playerWeaponID {
                // Weapon used in previous combat turn
                await context.item(previousID)
            } else {
                // Best weapon (by damage) in player inventory
                await context.player.preferredWeapon
            }
        guard let weapon else {
            return nil
        }
        guard await weapon.playerIsHolding else {
            throw ActionResponse.itemNotHeld(weapon)
        }
        return weapon
    }
}
