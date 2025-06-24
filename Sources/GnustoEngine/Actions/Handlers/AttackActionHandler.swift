import Foundation

/// Handles the "ATTACK" command and its synonyms (e.g., "FIGHT", "HIT", "KILL").
/// Implements combat mechanics following ZIL patterns for violence against actors and objects.
public struct AttackActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb, .directObject),
        .match(.verb, .directObject, .with, .indirectObject),
    ]

    public let verbs: [VerbID] = [.attack, .fight, .hit, .kill, .slay, .stab]

    public let requiresLight: Bool = true

    // MARK: - Action Processing Methods
    public init() {}

    /// Validates the "ATTACK" command.
    ///
    /// This method ensures that:
    /// 1. A direct object is specified (what to attack).
    /// 2. The target item exists and is reachable.
    /// 3. If an indirect object (weapon) is specified, it exists and is held.
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Throws: Various `ActionResponse` errors if validation fails.
    public func validate(context: ActionContext) async throws {
        // Attack requires a direct object (what to attack)
        guard let directObjectRef = context.command.directObject else {
            throw ActionResponse.prerequisiteNotMet(
                context.message.doWhat(verb: context.command.verb)
            )
        }
        guard case .item(let targetItemID) = directObjectRef else {
            throw ActionResponse.prerequisiteNotMet(
                context.message.cannotDoThat(verb: "attack")
            )
        }

        // Check if target exists and is reachable
        _ = try await context.engine.item(targetItemID)
        guard await context.engine.playerCanReach(targetItemID) else {
            throw ActionResponse.itemNotAccessible(targetItemID)
        }

        // If weapon is specified, validate it
        if let indirectObjectRef = context.command.indirectObject {
            guard case .item(let weaponItemID) = indirectObjectRef else {
                throw ActionResponse.prerequisiteNotMet(
                    context.message.cannotActWithThat(verb: "attack")
                )
            }

            let weaponItem = try await context.engine.item(weaponItemID)
            guard weaponItem.parent == .player else {
                throw ActionResponse.itemNotHeld(weaponItemID)
            }
        }
    }

    /// Processes the "ATTACK" command.
    ///
    /// Handles different attack scenarios following ZIL V-ATTACK logic:
    /// 1. Non-characters: "I’ve known strange people, but fighting a [object]?"
    /// 2. Bare-handed attacks on characters: "Trying to attack a [character] with your bare hands is suicidal."
    /// 3. Non-weapon attacks on characters: "Trying to attack the [character] with a [item] is suicidal."
    /// 4. Weapon attacks: "You can't." (placeholder for combat system)
    ///
    /// - Parameter context: The `ActionContext` for the current action.
    /// - Returns: An `ActionResult` with appropriate combat message and state changes.
    public func process(context: ActionContext) async throws -> ActionResult {
        guard
            let directObjectRef = context.command.directObject,
            case .item(let targetItemID) = directObjectRef
        else {
            throw ActionResponse.internalEngineError(
                "AttackActionHandler: directObject was not an item in process."
            )
        }

        let targetItem = try await context.engine.item(targetItemID)

        // Follow ZIL V-ATTACK logic exactly
        let message: String

        // First check: Is target NOT a character? (ZIL: NOT FSET? PRSO ACTORBIT)
        if !targetItem.hasFlag(.isCharacter) {
            message = context.message.attackNonCharacter(item: targetItem.withIndefiniteArticle)
        }
        // Second check: No weapon specified OR weapon is hands (bare-handed attack)
        else if context.command.indirectObject == nil {
            message = context.message.attackWithBareHands(
                character: targetItem.withIndefiniteArticle
            )
        }
        // We have a weapon - check if it's a real weapon
        else if let indirectObjectRef = context.command.indirectObject,
            case .item(let weaponItemID) = indirectObjectRef
        {
            let weaponItem = try await context.engine.item(weaponItemID)

            if !weaponItem.hasFlag(.isWeapon) {
                message = context.message.attackWithNonWeapon(
                    character: targetItem.withDefiniteArticle,
                    weapon: weaponItem.withIndefiniteArticle
                )
            } else {
                // Real weapon attack - placeholder for combat system
                message = context.message.attackWithWeapon()
            }
        } else {
            // Fallback case
            message = context.message.attackWithWeapon()
        }

        return ActionResult(
            message,
            await context.engine.setFlag(.isTouched, on: targetItem),
            await context.engine.updatePronouns(to: targetItem),
        )
    }
}
