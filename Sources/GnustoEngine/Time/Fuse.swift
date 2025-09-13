import Foundation

/// Defines the behavior of a timed event, known as a "fuse", scheduled to occur after a
/// specific number of game turns.
///
/// Fuses are classic ZIL features used to implement delayed actions or events. They can be
/// simple timers (like a bomb fuse) or complex context-aware events (like enemy recovery
/// with specific location and enemy data). When activated, fuses can optionally store custom
/// state data that persists until the event triggers.
///
/// You create `Fuse` instances and register them with the `GameBlueprint` when setting up your
/// game. To start a timed event, you would then use a game command or side effect to activate
/// the fuse by its ID, at which point the `GameEngine` begins tracking its countdown and any
/// associated state data. When the turn counter reaches zero, its `action` is executed.
public struct Fuse: Sendable {
    /// The initial number of game turns from when the fuse is activated until it triggers.
    /// This must be a positive integer.
    public let initialTurns: Int

    /// Indicates whether this fuse should automatically restart with its `initialTurns`
    /// after its action has been executed. If `false` (the default), the fuse triggers once
    /// and is then removed. If `true`, it will reactivate itself.
    public let repeats: Bool

    /// The action to execute when the fuse's timer reaches zero.
    ///
    /// This closure is executed on the `GameEngine`'s actor context, allowing you to
    /// safely query and modify the `GameState` through the provided `GameEngine` instance.
    /// The closure can return an `ActionResult` with a message to display to the player
    /// and any side effects to process, or `nil` if no player-visible output is needed.
    ///
    /// - Parameters:
    ///   - engine: The `GameEngine` instance, providing access to game state and mutation methods.
    ///   - state: The runtime state of the fuse, containing turn count and any custom
    ///                state data that was provided when the fuse was started.
    /// - Returns: An optional `ActionResult` containing a message and/or side effects,
    ///            or `nil` for silent execution.
    public let action: @Sendable (GameEngine, FuseState) async throws -> ActionResult?

    /// Initializes a new fuse definition.
    ///
    /// - Parameters:
    ///   - initialTurns: The number of turns from activation until the fuse triggers (must be > 0).
    ///   - repeats: Whether the fuse reactivates itself after triggering. Defaults to `false`.
    ///   - action: The closure to execute when the fuse triggers. It receives the `GameEngine`
    ///             instance and the fuse's runtime state (including custom data and turn count).
    public init(
        initialTurns: Int,
        repeats: Bool = false,
        action: @escaping @Sendable (GameEngine, FuseState) async throws -> ActionResult?
    ) {
        precondition(initialTurns > 0, "Fuse must have a positive initial turn count.")
        self.initialTurns = initialTurns
        self.repeats = repeats
        self.action = action
    }
}

extension Fuse {
    /// A predefined fuse that wakes up an unconscious enemy after 3 turns.
    ///
    /// This fuse requires specific state data to be provided when activated:
    /// - `"enemyID"`: The ID of the enemy item to wake up
    /// - `"locationID"`: The location ID where the wake-up occurs (for context)
    /// - `"message"`: The message to display when the enemy wakes up
    ///
    /// The fuse will only trigger if the enemy is still unconscious when the timer expires.
    /// If the enemy is already conscious or the required state data is missing, the fuse
    /// will complete silently without any effect.
    static let enemyWakeUp = Fuse(
        initialTurns: 3,
        action: { engine, state in
            // Specific enemy and location must be provided in the state
            guard
                let enemyID = state.getItemID("enemyID"),
                let wakeUpLocationID = state.getLocationID("locationID"),
                let message = state.getString("message"),
                let enemy = try? await engine.item(enemyID)
            else {
                engine.logger.warning(".enemyWakeUp fuse called without required state")
                return nil
            }

            guard try await enemy.isUnconscious else { return nil }

            // Only include a message if the player present when the enemy wakes up
            let wakeUpMessage: String? =
                if try await engine.player.location == enemy.location {
                    message
                } else {
                    nil
                }

            return try await ActionResult(
                message: wakeUpMessage,
                changes: [
                    enemy.setCharacterAttributes(consciousness: .alert)
                ]
            )
        }
    )

    /// A predefined fuse that returns an enemy to a specific location after 3 turns.
    ///
    /// This fuse requires specific state data to be provided when activated:
    /// - `"enemyID"`: The ID of the enemy item to move back to the location
    /// - `"locationID"`: The location ID where the enemy should return to
    /// - `"message"`: The message to display when the enemy returns (only shown if player is present)
    ///
    /// The message will only be displayed to the player if they are at the return location
    /// when the fuse triggers. If the required state data is missing, the fuse will complete
    /// silently without any effect.
    static let enemyReturn = Fuse(
        initialTurns: 3,
        action: { engine, state in
            // Specific enemy and location must be provided in the state
            guard
                let enemyID = state.getItemID("enemyID"),
                let returnLocationID = state.getLocationID("locationID"),
                let message = state.getString("message"),
                let enemy = try? await engine.item(enemyID)
            else {
                engine.logger.warning(".enemyReturn fuse called without required state")
                return nil
            }

            // Only include a message if the player is at the return location
            let enemyReturnMessage: String? =
                if try await engine.player.location.id == returnLocationID {
                    message
                } else {
                    nil
                }

            return ActionResult(
                message: enemyReturnMessage,
                changes: [
                    enemy.move(to: returnLocationID)
                ]
            )
        }
    )

    /// A predefined fuse that removes temporary status effects after a specified duration.
    ///
    /// This fuse requires specific state data to be provided when activated:
    /// - `"itemID"`: The ID of the character/item affected by the status effect
    /// - `"effectName"`: A string identifier for the specific effect to remove
    ///
    /// Supported effect names include general conditions (poisoned, cursed, blessed, etc.)
    /// and combat conditions (offBalance, uncertain, vulnerable, etc.). The fuse will only
    /// trigger if the character still has the specified effect when the timer expires.
    /// Messages are displayed to the player if they are present to witness the recovery.
    static let statusEffectExpiry = Fuse(
        initialTurns: 3,
        action: { engine, state in
            // Specific character and effect must be provided in the state
            guard
                let itemID = state.getItemID("itemID"),
                let effectName = state.getString("effectName"),
                let character = try? await engine.item(itemID)
            else {
                engine.logger.warning(".statusEffectExpiry fuse called without required state")
                return nil
            }

            // Determine what type of effect we're dealing with and clear it
            let message: String?
            let stateChange: StateChange?

            switch effectName.lowercased() {
            // General conditions
            case "poisoned":
                guard
                    try await character.characterSheet.generalCondition == GeneralCondition.poisoned
                else { return nil }
                message = await determineStatusExpiryMessage(
                    for: character,
                    engine: engine,
                    recoveryMessage:
                        "\(await character.withDefiniteArticle.capitalized) looks healthier as the poison wears off."
                )
                stateChange = try await character.setCharacterAttributes(
                    generalCondition: GeneralCondition.normal)

            case "cursed":
                guard try await character.characterSheet.generalCondition == GeneralCondition.cursed
                else { return nil }
                message = await determineStatusExpiryMessage(
                    for: character,
                    engine: engine,
                    recoveryMessage:
                        "\(await character.withDefiniteArticle.capitalized) seems relieved as the curse lifts."
                )
                stateChange = try await character.setCharacterAttributes(
                    generalCondition: GeneralCondition.normal)

            case "blessed":
                guard
                    try await character.characterSheet.generalCondition == GeneralCondition.blessed
                else { return nil }
                message = await determineStatusExpiryMessage(
                    for: character,
                    engine: engine,
                    recoveryMessage:
                        "The divine blessing around \(await character.withDefiniteArticle) fades away."
                )
                stateChange = try await character.setCharacterAttributes(
                    generalCondition: GeneralCondition.normal)

            case "charmed":
                guard
                    try await character.characterSheet.generalCondition == GeneralCondition.charmed
                else { return nil }
                message = await determineStatusExpiryMessage(
                    for: character,
                    engine: engine,
                    recoveryMessage:
                        "\(await character.withDefiniteArticle.capitalized) shakes off the magical compulsion."
                )
                stateChange = try await character.setCharacterAttributes(
                    generalCondition: GeneralCondition.normal)

            case "terrified":
                guard
                    try await character.characterSheet.generalCondition
                        == GeneralCondition.terrified
                else { return nil }
                message = await determineStatusExpiryMessage(
                    for: character,
                    engine: engine,
                    recoveryMessage:
                        "\(await character.withDefiniteArticle.capitalized) regains composure as the supernatural fear subsides."
                )
                stateChange = try await character.setCharacterAttributes(
                    generalCondition: GeneralCondition.normal)

            case "drunk":
                guard try await character.characterSheet.generalCondition == GeneralCondition.drunk
                else { return nil }
                message = await determineStatusExpiryMessage(
                    for: character,
                    engine: engine,
                    recoveryMessage:
                        "\(await character.withDefiniteArticle.capitalized) sobers up."
                )
                stateChange = try await character.setCharacterAttributes(
                    generalCondition: GeneralCondition.normal)

            case "diseased":
                guard
                    try await character.characterSheet.generalCondition == GeneralCondition.diseased
                else { return nil }
                message = await determineStatusExpiryMessage(
                    for: character,
                    engine: engine,
                    recoveryMessage:
                        "\(await character.withDefiniteArticle.capitalized) recovers from the illness."
                )
                stateChange = try await character.setCharacterAttributes(
                    generalCondition: GeneralCondition.normal)

            // Combat conditions
            case "offbalance", "off-balance":
                guard
                    try await character.characterSheet.combatCondition == CombatCondition.offBalance
                else { return nil }
                message = await determineStatusExpiryMessage(
                    for: character,
                    engine: engine,
                    recoveryMessage:
                        "\(await character.withDefiniteArticle.capitalized) regains balance."
                )
                stateChange = try await character.setCharacterAttributes(
                    combatCondition: CombatCondition.normal)

            case "uncertain":
                guard
                    try await character.characterSheet.combatCondition == CombatCondition.uncertain
                else { return nil }
                message = await determineStatusExpiryMessage(
                    for: character,
                    engine: engine,
                    recoveryMessage:
                        "\(await character.withDefiniteArticle.capitalized) appears more confident."
                )
                stateChange = try await character.setCharacterAttributes(
                    combatCondition: CombatCondition.normal)

            case "vulnerable":
                guard
                    try await character.characterSheet.combatCondition == CombatCondition.vulnerable
                else { return nil }
                message = await determineStatusExpiryMessage(
                    for: character,
                    engine: engine,
                    recoveryMessage:
                        "\(await character.withDefiniteArticle.capitalized) recovers a defensive posture."
                )
                stateChange = try await character.setCharacterAttributes(
                    combatCondition: CombatCondition.normal)

            case "disarmed":
                guard try await character.characterSheet.combatCondition == CombatCondition.disarmed
                else { return nil }
                message = await determineStatusExpiryMessage(
                    for: character,
                    engine: engine,
                    recoveryMessage:
                        "\(await character.withDefiniteArticle.capitalized) adapts to fighting without a weapon."
                )
                stateChange = try await character.setCharacterAttributes(
                    combatCondition: CombatCondition.normal)

            default:
                engine.logger.warning(
                    "Unknown effect name '\(effectName)' in statusEffectExpiry fuse")
                return nil
            }

            return ActionResult(
                message: message,
                changes: [stateChange].compactMap { $0 }
            )
        }
    )

    /// A predefined fuse that handles delayed environmental changes.
    ///
    /// This fuse can be used for various environmental effects that occur after a delay,
    /// such as weather changes, lighting changes, or other atmospheric modifications.
    /// The specific environmental change and any associated data should be provided
    /// in the fuse state when activated.
    ///
    /// This is primarily a demonstration fuse that logs the environmental change.
    /// Game developers should override or extend this for specific environmental effects.
    static let environmentalChange = Fuse(
        initialTurns: 2,
        action: { engine, state in
            engine.logger.info("Environmental change triggered with state: \(state.dictionary)")
            return nil
        }
    )

    /// Helper function to determine if a status expiry message should be shown to the player.
    ///
    /// - Parameters:
    ///   - character: The character recovering from the effect
    ///   - engine: The game engine for accessing player location
    ///   - recoveryMessage: The message to show if the player can witness the recovery
    /// - Returns: The message to display, or nil if the player can't see the character
    private static func determineStatusExpiryMessage(
        for character: ItemProxy,
        engine: GameEngine,
        recoveryMessage: String
    ) async -> String? {
        // Only show message if player is present to witness the recovery
        do {
            return try await engine.player.location == character.location ? recoveryMessage : nil
        } catch {
            engine.logger.warning(
                "Failed to determine location for status expiry message: \(error)")
            return nil
        }
    }
}
