import Foundation

/// Represents the current state of an active combat encounter in the interactive fiction engine.
///
/// `CombatState` is the central data structure that tracks information needed to manage
/// turn-based combat encounters. It maintains the participants, progression, equipment, and
/// any special conditions or modifiers that affect the combat.
///
/// ## Combat Flow Integration
///
/// The combat state is stored in the game's global state under `GlobalID.combatState` and is
/// managed by the `GameEngine`. When combat begins (either through player-initiated attacks
/// or enemy encounters), a new `CombatState` is created and stored. The state persists across
/// combat rounds until the encounter ends through victory, defeat, or escape.
///
/// ## Usage in Combat Systems
///
/// Combat systems conforming to the `CombatSystem` protocol receive the current `CombatState`
/// through `ActionContext` and use it to make combat decisions. The state can be modified
/// between rounds to track progression, change weapons, or apply temporary effects.
///
/// ## State Persistence
///
/// As a `Codable` type, `CombatState` can be serialized for save games, ensuring that
/// ongoing combat encounters persist across game sessions.
///
/// ## Example Usage
///
/// ```swift
/// // Starting combat with a troll using a sword
/// let combatState = CombatState(
///     enemyID: .troll,
///     roundCount: 0,
///     playerWeaponID: .sword
/// )
/// ```
public struct CombatState: Codable, Equatable, Sendable, Hashable {

    // MARK: - Combat Participants

    /// The unique identifier of the enemy item involved in this combat encounter.
    ///
    /// This references an `Item` in the game world that represents the combat opponent.
    /// The enemy item should have appropriate combat-related properties such as
    /// `CharacterAttributes` for health, damage, and combat behavior.
    ///
    /// - Important: The enemy must exist in the game world and be accessible through
    ///   the `GameEngine`'s item lookup methods.
    public let enemyID: ItemID

    /// The weapon currently being used by the player, if any.
    ///
    /// This tracks the player's active weapon choice for the combat encounter. If `nil`,
    /// the player is fighting unarmed. The weapon affects damage calculations and may
    /// influence which combat actions are available.
    ///
    /// The weapon must be an item that the player possesses (typically in their inventory)
    /// and should have appropriate weapon properties such as damage values and weapon type.
    ///
    /// - Note: Some combat systems may require weapons for certain enemies, while others
    ///   allow unarmed combat. Check the enemy's `CombatAttributes.requiresWeapon` property.
    public let playerWeaponID: ItemID?

    // MARK: - Combat Progression

    /// The number of combat rounds that have elapsed in this encounter.
    ///
    /// This counter tracks the progression of the combat encounter, starting from 0 when
    /// combat begins. It increments after each complete round (player action + enemy response).
    ///
    /// Combat systems can use this for:
    /// - Applying time-based effects or escalating difficulty
    /// - Determining when certain special attacks or abilities become available
    /// - Implementing fatigue or endurance mechanics
    /// - Creating narrative descriptions that reflect the length of the battle
    ///
    /// - Note: A round represents one complete exchange between player and enemy, not
    ///   individual actions.
    public let roundCount: Int

    /// The current intensity level of the combat encounter (0.0 to 1.0).
    ///
    /// Combat intensity represents how brutal and escalated the fight has become. It starts
    /// low and can increase based on:
    /// - Number of rounds elapsed
    /// - Damage dealt and received
    /// - Critical hits and special combat events
    /// - Environmental factors and desperation
    ///
    /// Higher intensity affects:
    /// - **Damage multipliers**: More brutal strikes as fighters become desperate
    /// - **Critical hit chances**: Increased likelihood of devastating attacks
    /// - **Special event frequency**: More disarms, staggers, and tactical maneuvers
    /// - **Narrative tone**: Descriptions become more intense and visceral
    ///
    /// - Note: Intensity typically increases over time but can spike dramatically
    ///   from critical events like near-death experiences or weapon disarming.
    public let combatIntensity: Double

    /// The current fatigue level of the player (0.0 to 1.0).
    ///
    /// Player fatigue accumulates during prolonged combat and affects:
    /// - **Attack accuracy**: Tired fighters are less precise
    /// - **Damage output**: Exhaustion reduces striking power
    /// - **Defense capability**: Slower reactions to enemy attacks
    /// - **Special abilities**: Some advanced maneuvers require stamina
    ///
    /// Fatigue increases with:
    /// - Combat round duration
    /// - Damage taken (pain and blood loss)
    /// - Heavy weapon usage
    /// - Failed critical attempts
    ///
    /// - Note: Very high fatigue (>0.8) may trigger automatic flee attempts
    ///   or surrender conditions for intelligent combatants.
    public let playerFatigue: Double

    /// The current fatigue level of the enemy (0.0 to 1.0).
    ///
    /// Enemy fatigue follows similar mechanics to player fatigue but may have
    /// different thresholds and effects based on the enemy's attributes:
    /// - **Constitution**: Determines base fatigue resistance
    /// - **Bravery**: Affects when fatigue triggers flee/surrender behavior
    /// - **Intelligence**: Smart enemies may retreat before reaching exhaustion
    ///
    /// Enemy AI uses fatigue levels to make tactical decisions about continuing
    /// combat versus attempting escape or surrender.
    public let enemyFatigue: Double

    /// The weapon currently being used by the enemy, if any.
    ///
    /// This tracks the enemy's active weapon for the combat encounter. Unlike player
    /// weapons which are explicitly equipped, enemy weapons are typically determined
    /// by their character definition and combat attributes.
    ///
    /// Enemy weapons affect:
    /// - **Damage calculations**: Different weapons have different base damage
    /// - **Combat reach**: Some weapons allow attacks from greater distance
    /// - **Special abilities**: Certain weapons enable unique combat maneuvers
    /// - **Disarmament**: Enemies can lose weapons during combat
    ///
    /// If `nil`, the enemy is fighting unarmed (claws, fists, natural weapons).
    ///
    /// - Note: Enemy weapons may change during combat due to disarmament,
    ///   weapon breaking, or tactical weapon switching.
    public let enemyWeaponID: ItemID?

    // MARK: - Combat Modifiers

    // MARK: - Initialization

    /// Creates a new combat state for an encounter with the specified enemy.
    ///
    /// This initializer sets up the initial state for a combat encounter. All parameters
    /// except `enemyID` have sensible defaults for starting a new combat.
    ///
    /// - Parameters:
    ///   - enemyID: The unique identifier of the enemy item. Must reference a valid
    ///     item in the game world with appropriate combat attributes.
    ///   - roundCount: The starting round number. Defaults to 0 for new encounters.
    ///     Use higher values when resuming combat from a saved state.
    ///   - playerWeaponID: The weapon the player is wielding, or `nil` for unarmed combat.
    ///     Defaults to `nil`.
    ///   - combatIntensity: The initial combat intensity level. Defaults to 0.1 (calm start).
    ///   - playerFatigue: The player's initial fatigue level. Defaults to 0.0 (fresh).
    ///   - enemyFatigue: The enemy's initial fatigue level. Defaults to 0.0 (fresh).
    ///   - enemyWeaponID: The enemy's starting weapon, or `nil` for unarmed. Defaults to `nil`.
    ///
    /// ## Usage Examples
    /// ```swift
    /// // Basic combat with unarmed combatants
    /// let basicCombat = CombatState(enemyID: .goblin)
    ///
    /// // Combat with weapons and moderate intensity
    /// let armedCombat = CombatState(
    ///     enemyID: .troll,
    ///     playerWeaponID: .magicSword,
    ///     combatIntensity: 0.3,
    ///     enemyWeaponID: .club
    /// )
    ///
    /// // Continuing exhausting combat
    /// let continuedCombat = CombatState(
    ///     enemyID: .dragon,
    ///     roundCount: 5,
    ///     playerWeaponID: .dragonslayerSword,
    ///     combatIntensity: 0.8,
    ///     playerFatigue: 0.4,
    ///     enemyFatigue: 0.6
    /// )
    /// ```
    public init(
        enemyID: ItemID,
        roundCount: Int = 0,
        playerWeaponID: ItemID? = nil,
        combatIntensity: Double = 0.1,
        playerFatigue: Double = 0.0,
        enemyFatigue: Double = 0.0,
        enemyWeaponID: ItemID? = nil
    ) {
        self.enemyID = enemyID
        self.roundCount = roundCount
        self.playerWeaponID = playerWeaponID
        self.combatIntensity = max(0.0, min(1.0, combatIntensity))
        self.playerFatigue = max(0.0, min(1.0, playerFatigue))
        self.enemyFatigue = max(0.0, min(1.0, enemyFatigue))
        self.enemyWeaponID = enemyWeaponID
    }

    // MARK: - Proxy Accessors

    /// Retrieves the enemy as an `ItemProxy` for safe access to its properties and state.
    ///
    /// This method provides type-safe access to the enemy item through the proxy system,
    /// which ensures that computed values and dynamic properties are properly resolved.
    ///
    /// - Parameter engine: The game engine instance to use for proxy creation
    /// - Returns: An `ItemProxy` representing the enemy combatant
    /// - Throws: `ActionResponse` errors if the enemy item cannot be found or accessed
    ///
    /// ## Usage
    /// ```swift
    /// let enemy = await combatState.enemy(with: engine)
    /// let enemyHealth = await enemy.health
    /// let enemyName = enemy.withDefiniteArticle
    /// ```
    ///
    /// - Important: Always use this method rather than directly accessing items by ID
    ///   to ensure proper proxy behavior and computed value resolution.
    func enemy(with engine: GameEngine) async -> ItemProxy {
        await Item(id: enemyID).proxy(engine)
    }

    /// Retrieves the player's weapon as an `ItemProxy`, if one is being used.
    ///
    /// This method provides safe access to the player's weapon through the proxy system,
    /// returning `nil` if the player is fighting unarmed.
    ///
    /// - Parameter engine: The game engine instance to use for proxy creation
    /// - Returns: An `ItemProxy` representing the player's weapon, or `nil` if unarmed
    /// - Throws: `ActionResponse` errors if the weapon item exists but cannot be accessed
    ///
    /// ## Usage
    /// ```swift
    /// let weapon = await combatState.playerWeapon(with: engine)
    /// if let weapon {
    ///     let damage = await weapon.weaponAttributes.damage
    ///     let weaponName = weapon.withIndefiniteArticle
    /// } else {
    ///     // Player is fighting unarmed
    /// }
    /// ```
    ///
    /// - Note: This method only returns `nil` if `playerWeaponID` is `nil`. If a weapon
    ///   ID is stored but the weapon cannot be found, this method will throw an error.
    func playerWeapon(with engine: GameEngine) async -> ItemProxy? {
        guard let playerWeaponID else { return nil }
        return await Item(id: playerWeaponID).proxy(engine)
    }

    /// Retrieves the enemy's weapon as an `ItemProxy`, if one is being used.
    ///
    /// This method provides safe access to the enemy's weapon through the proxy system,
    /// returning `nil` if the enemy is fighting unarmed or using natural weapons.
    ///
    /// - Parameter engine: The game engine instance to use for proxy creation
    /// - Returns: An `ItemProxy` representing the enemy's weapon, or `nil` if unarmed
    /// - Throws: `ActionResponse` errors if the weapon item exists but cannot be accessed
    ///
    /// ## Usage
    /// ```swift
    /// let enemyWeapon = await combatState.enemyWeapon(with: engine)
    /// if let enemyWeapon {
    ///     let damage = await enemyWeapon.weaponAttributes.damage
    ///     let weaponType = enemyWeapon.weaponType
    /// } else {
    ///     // Enemy uses natural weapons (claws, fists, etc.)
    /// }
    /// ```
    func enemyWeapon(with engine: GameEngine) async -> ItemProxy? {
        guard let enemyWeaponID else { return nil }
        return await Item(id: enemyWeaponID).proxy(engine)
    }

    // MARK: - Combat Progression Methods

    /// Creates a new combat state with incremented round count and updated combat metrics.
    ///
    /// This method advances the combat to the next round while applying natural progression
    /// of intensity and fatigue based on combat duration and events.
    ///
    /// - Parameters:
    ///   - intensityDelta: Change in combat intensity (-1.0 to +1.0). Defaults to +0.05.
    ///   - playerFatigueDelta: Change in player fatigue (-1.0 to +1.0). Defaults to +0.03.
    ///   - enemyFatigueDelta: Change in enemy fatigue (-1.0 to +1.0). Defaults to +0.03.
    ///   - newPlayerWeapon: New player weapon if changed, otherwise keeps current.
    ///   - newEnemyWeapon: New enemy weapon if changed, otherwise keeps current.
    /// - Returns: A new `CombatState` representing the next round
    ///
    /// ## Usage
    /// ```swift
    /// // Standard round progression
    /// let nextRound = currentState.nextRound()
    ///
    /// // Intense round with high fatigue
    /// let brutalRound = currentState.nextRound(
    ///     intensityDelta: 0.15,
    ///     playerFatigueDelta: 0.08,
    ///     enemyFatigueDelta: 0.06
    /// )
    ///
    /// // Disarmament event
    /// let disarmedRound = currentState.nextRound(
    ///     newEnemyWeapon: nil
    /// )
    /// ```
    func nextRound(
        intensityDelta: Double = 0.05,
        playerFatigueDelta: Double = 0.03,
        enemyFatigueDelta: Double = 0.03,
        newPlayerWeapon: ItemID? = nil,
        newEnemyWeapon: ItemID? = nil
    ) -> CombatState {
        return CombatState(
            enemyID: enemyID,
            roundCount: roundCount + 1,
            playerWeaponID: newPlayerWeapon ?? playerWeaponID,
            combatIntensity: combatIntensity + intensityDelta,
            playerFatigue: playerFatigue + playerFatigueDelta,
            enemyFatigue: enemyFatigue + enemyFatigueDelta,
            enemyWeaponID: newEnemyWeapon ?? enemyWeaponID
        )
    }

    /// Determines if the combat has reached a high intensity level requiring special handling.
    ///
    /// High intensity combat (>0.7) typically features:
    /// - Increased damage multipliers
    /// - More frequent critical hits
    /// - Enhanced special combat events
    /// - More visceral combat descriptions
    ///
    /// - Returns: `true` if combat intensity is above the high-intensity threshold
    var isHighIntensity: Bool {
        combatIntensity > 0.7
    }

    /// Determines if either combatant is significantly fatigued and may seek to end combat.
    ///
    /// High fatigue levels (>0.6) may trigger:
    /// - Reduced combat effectiveness
    /// - Increased chance of mistakes
    /// - AI decisions to flee or surrender
    /// - Player prompts to retreat
    ///
    /// - Returns: `true` if either player or enemy fatigue exceeds the threshold
    var isHighFatigue: Bool {
        playerFatigue > 0.6 || enemyFatigue > 0.6
    }

    /// Calculates the overall combat escalation level combining intensity and fatigue.
    ///
    /// This composite metric helps combat systems make decisions about:
    /// - When to trigger special events
    /// - How to modify damage calculations
    /// - What narrative tone to use
    /// - Whether to suggest combat resolution
    ///
    /// - Returns: A value from 0.0 to 1.0 representing total combat escalation
    var escalationLevel: Double {
        let intensityWeight = 0.7
        let fatigueWeight = 0.3
        let maxFatigue = max(playerFatigue, enemyFatigue)

        return (combatIntensity * intensityWeight) + (maxFatigue * fatigueWeight)
    }
}
