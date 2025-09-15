import Foundation

/// A protocol defining turn-based combat behavior for enemies in the game.
///
/// Combat systems provide a sophisticated framework for implementing turn-based combat
/// encounters in interactive fiction games. Each enemy can have its own specialized
/// combat system, allowing for unique behaviors, special abilities, and varied difficulty.
///
/// The combat system follows the Gnusto state change pipeline - all state modifications
/// must flow through `ActionResult` objects to ensure proper game state management.
///
/// ## Turn-Based Flow
///
/// Each combat turn consists of:
/// 1. Player action (attack, defend, talk, use item, etc.)
/// 2. Enemy reaction (counter-attack, taunt, flee, special ability, etc.)
/// 3. Resolution of both actions with appropriate state changes
///
/// ## Enhanced Combat Events
///
/// The system supports a full range of combat outcomes beyond simple hit/miss:
/// - **Weapon Disarming**: Combatants can lose their weapons during combat
/// - **Staggering**: Attacks that cause temporary loss of balance and combat effectiveness
/// - **Hesitation**: Combat events that create openings for follow-up attacks
/// - **Vulnerability**: Temporary states that make subsequent attacks more effective
/// - **Unconsciousness**: Non-lethal incapacitation of combatants
/// - **Fleeing & Surrender**: Intelligent enemies can retreat or give up when outmatched
/// - **Pacification**: Diplomatic resolution of combat through conversation
///
/// ## Usage
///
/// Implement this protocol to create custom combat behavior:
///
/// ```swift
/// struct DragonCombatSystem: CombatSystem {
///     let enemyID: ItemID
///
///     func processCombatTurn(
///         playerAction: PlayerAction,
///         in context: ActionContext
///     ) async throws -> ActionResult {
///         // Custom dragon combat logic
///     }
/// }
/// ```
///
/// Register combat systems with the game engine to override default behavior for specific enemies.
public protocol CombatSystem: Sendable {
    /// The identifier of the enemy this combat system applies to.
    ///
    /// This links the combat system to a specific enemy item in the game world. The enemy should
    /// have the `.isCharacter` or `.isPerson` flag set to participate in combat.
    var enemyID: ItemID { get }

    /// Provides descriptive text for combat events.
    ///
    /// This closure generates narrative descriptions for combat events, allowing for rich
    /// storytelling during combat encounters. The descriptions should be contextually
    /// appropriate and enhance the player's understanding of what occurred.
    ///
    /// - Parameter event: The combat event to describe
    /// - Returns: A descriptive string for the event, or nil to use default descriptions
    /// - Throws: If description generation fails
    var description: @Sendable (
        CombatEvent,
        CombatMessenger
    ) async throws -> String? { get }

    /// Processes a complete turn of combat including player action and enemy reaction.
    ///
    /// This method orchestrates the entire combat turn:
    /// - Evaluates the player's action (attack, defend, talk, etc.)
    /// - Determines the enemy's reaction based on AI and combat state
    /// - Calculates outcomes using enemy attributes and combat mechanics
    /// - Returns appropriate messages and state changes
    ///
    /// The implementation should consider:
    /// - Character attributes (strength, dexterity, etc.)
    /// - Weapon effectiveness and special properties
    /// - Combat state (health levels, status effects)
    /// - Character-specific behaviors and special abilities
    ///
    /// - Parameters:
    ///   - playerAction: The action the player is attempting this turn
    ///   - context: The action context containing command and game state
    /// - Returns: An ActionResult containing messages and state changes for the entire turn
    /// - Throws: If required game state cannot be accessed or modified
    func processCombatTurn(
        playerAction: PlayerAction,
        in context: ActionContext
    ) async throws -> ActionResult

    /// Calculates the outcome of a combat attack.
    ///
    /// This method performs the core combat mathematics, considering:
    /// - Attacker and defender attributes
    /// - Weapon properties and effectiveness
    /// - Armor and defensive bonuses
    /// - Special combat events (disarming, staggering, hesitation, vulnerability)
    /// - Combat intensity escalation over time
    /// - Random factors within reasonable bounds
    ///
    /// The enhanced implementation uses action-packed mechanics that reduce total misses
    /// and incorporate tactical combat events for more engaging encounters.
    ///
    /// - Parameters:
    ///   - attacker: The enemy making the attack
    ///   - defender: The enemy being attacked
    ///   - weapon: The weapon being used (if any)
    ///   - context: The action context for accessing game state
    /// - Returns: A combat event describing the attack outcome
    /// - Throws: If combat calculation fails
    func calculateAttackOutcome(
        attacker: Combatant,
        defender: Combatant,
        weapon: ItemProxy?,
        in context: ActionContext
    ) async throws -> CombatEvent

    /// Determines the enemy's action for this turn.
    ///
    /// This method implements the enemy's AI, choosing appropriate actions based on:
    /// - Current combat state (health, position, status effects)
    /// - Character personality and combat style
    /// - Recent player actions and their tactical implications
    /// - Available special abilities and combat maneuvers
    /// - Opportunity for enhanced attacks when opponent is distracted
    /// - Retreat conditions and surrender thresholds
    ///
    /// - Parameters:
    ///   - playerAction: What the player did this turn
    ///   - enemyState: Current state of the enemy enemy
    ///   - context: The action context for accessing game state
    /// - Returns: The enemy's chosen action for this turn, or nil if no action
    /// - Throws: If enemy AI decision fails
    func determineEnemyAction(
        against playerAction: PlayerAction,
        enemy: ItemProxy,
        in context: ActionContext
    ) async throws -> CombatEvent?
}
