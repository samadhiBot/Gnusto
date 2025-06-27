import Foundation

/// Handles the "ATTACK" command and its synonyms (e.g., "FIGHT", "HIT", "KILL").
/// Implements combat mechanics following ZIL patterns for violence against actors and objects.
public struct AttackActionHandler: ActionHandler {
    // MARK: - Verb Definition Properties

    public let syntax: [SyntaxRule] = [
        .match(.verb, .directObject),
        .match(.verb, .directObject, .with, .indirectObject),
    ]

    public let verbs: [Verb] = [.attack, .fight, .hit, .kill, .slay, .stab]

    public let requiresLight: Bool = true

    // MARK: - Action Processing Methods

    public init() {}

    /// Processes the "ATTACK" command.
    ///
    /// Handles different attack scenarios following ZIL V-ATTACK logic:
    /// 1. Non-characters: "I've known strange people, but fighting a [object]?"
    /// 2. Bare-handed attacks on characters: "Trying to attack a [character] with your bare hands is suicidal."
    /// 3. Non-weapon attacks on characters: "Trying to attack the [character] with a [item] is suicidal."
    /// 4. Weapon attacks: "You can't." (placeholder for combat system)
    public func process(command: Command, engine: GameEngine) async throws -> ActionResult {
        guard let targetItemID = command.directObjectItemID else {
            throw ActionResponse.prerequisiteNotMet(
                engine.messenger.doWhat(verb: command.verb)
            )
        }

        let targetItem = try await engine.item(targetItemID)

        guard await engine.playerCanReach(targetItemID) else {
            throw ActionResponse.itemNotAccessible(targetItemID)
        }

        // Follow ZIL V-ATTACK logic exactly
        let message: String

        // First check: Is target NOT a character? (ZIL: NOT FSET? PRSO ACTORBIT)
        if !targetItem.hasFlag(.isCharacter) {
            message = engine.messenger.attackNonCharacter(
                item: targetItem.withDefiniteArticle
            )
        }
        // Second check: No weapon specified (bare-handed attack)
        else if command.indirectObject == nil {
            message = engine.messenger.attackWithBareHands(
                character: targetItem.withDefiniteArticle
            )
        }
        // We have a weapon - validate and check if it's a real weapon
        else if let indirectObjectRef = command.indirectObject,
                case .item(let weaponID) = indirectObjectRef
        {
            let weapon = try await engine.item(weaponID)

            guard weapon.parent == .player else {
                throw ActionResponse.itemNotHeld(weaponID)
            }

            if !weapon.hasFlag(.isWeapon) {
                message = engine.messenger.attackWithNonWeapon(
                    character: targetItem.withDefiniteArticle,
                    item: weapon.withDefiniteArticle
                )
            } else {
                // Real weapon attack - placeholder for combat system
                message = engine.messenger.attackWithWeapon(
                    character: targetItem.withDefiniteArticle,
                    weapon: weapon.withDefiniteArticle
                )
            }
        } else {
            // Fallback case for non-item indirect objects
            message = engine.messenger.attackWithUnknown(
                enemy: targetItem.withDefiniteArticle
            )
        }

        return ActionResult(
            message,
            await engine.setFlag(.isTouched, on: targetItem),
            await engine.updatePronouns(to: targetItem)
        )
    }
}
