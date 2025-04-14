import Foundation

/// Handles the "attack <target> [with <weapon>]" command.
struct AttackHandler {

    /// Processes the attack command.
    ///
    /// - Parameters:
    ///   - context: The command context containing user input and world state.
    /// - Returns: An array of effects describing the outcome.
    static func handle(context: CommandContext) -> [Effect]? {
        let command = context.userInput
        let world = context.world

        guard let targetIDString = command.directObject, !targetIDString.isEmpty else {
            return [.showText("Who or what do you want to attack?")]
        }

        let targetID = Object.ID(targetIDString)

        // Basic validation: Is the target present?
        guard let targetObject = world.find(targetID) else {
            return [.showText("You don't see '\(targetIDString)' here.")]
        }

        // Prevent attacking oneself
        guard targetObject.id != world.player.id else {
            return [.showText("Attacking yourself seems unproductive.")]
        }

        world.mention(targetID)

        // TODO: Implement actual combat mechanics!
        // - Check if target is attackable (e.g., has HealthComponent, is NPC/monster).
        // - Check if player is holding the specified weapon (indirect object).
        // - Check if weapon is valid (.weapon flag?).
        // - Calculate damage, apply effects, check for death, etc.
        // - Handle NPCs fighting back.

        let weaponString = command.indirectObject ?? "your bare hands"
        let weaponText = (command.indirectObject != nil) ? " with the \(weaponString)" : ""

        // Placeholder response
        return [.showText("You attack \(targetObject.theName)\(weaponText).")]
        // A more realistic placeholder might be:
        // return [.showText("Violence isn't the answer here.")]
    }
}

// Requires: World, Effect, Object, Object.ID, UserInput
// Requires: Object extension for .theName
// Future: HealthComponent, WeaponComponent, CombatSystem, etc.
