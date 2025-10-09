import Foundation
import GnustoEngine

/// Middleware that adds melee combat capabilities to the game.
///
/// This middleware encapsulates all combat-related functionality, including:
/// - Detecting hostile enemies after player actions
/// - Managing combat state and turn flow
/// - Processing player and enemy combat actions
/// - Handling combat resolution (death, fleeing, victory)
///
/// Combat can be completely removed from a game by simply not including this
/// middleware in the game blueprint. Multiple combat middleware can be composed
/// for different combat types (melee, ranged, magic).
///
/// ## Example Usage
///
/// ```swift
/// var middleware: [any GnustoMiddleware] {
///     [
///         CombatMiddleware(
///             combatSystems: combatSystems,
///             combatMessengers: combatMessengers,
///             defaultCombatMessenger: defaultCombatMessenger
///         )
///     ]
/// }
/// ```
///
/// ## Public API
///
/// Combat middleware provides action handlers that game blueprints should register:
///
/// ```swift
/// var customActionHandlers: [ActionHandler] {
///     combatMiddleware.actionHandlers
/// }
/// ```
///
/// Game-specific code (event handlers, daemons) can initiate combat through instance methods.
/// The middleware instance can be stored in the game blueprint and passed to event handlers.
public struct CombatMiddleware: GnustoMiddleware {
    // MARK: - GnustoMiddleware Protocol

    public let stateKey = "combat"
    public let priority = 100  // High priority to intercept turns early

    // MARK: - Configuration

    private let combatSystems: [ItemID: any CombatSystem]
    private let combatMessengers: [ItemID: CombatMessenger]
    private let defaultCombatMessenger: CombatMessenger

    // MARK: - Public Properties

    /// Action handlers that provide combat functionality.
    ///
    /// Game blueprints should include these in their `customActionHandlers`:
    /// ```swift
    /// var customActionHandlers: [ActionHandler] {
    ///     combatMiddleware.actionHandlers
    /// }
    /// ```
    public var actionHandlers: [ActionHandler] {
        [
            CombatAttackActionHandler(middleware: self)
        ]
    }

    // MARK: - Initialization

    /// Creates a new combat middleware with the specified configuration.
    ///
    /// - Parameters:
    ///   - combatSystems: Custom combat systems for specific enemies
    ///   - combatMessengers: Custom combat messengers for specific enemies
    ///   - defaultCombatMessenger: Default messenger used when no custom messenger exists
    public init(
        combatSystems: [ItemID: any CombatSystem] = [:],
        combatMessengers: [ItemID: CombatMessenger] = [:],
        defaultCombatMessenger: CombatMessenger = CombatMessenger()
    ) {
        self.combatSystems = combatSystems
        self.combatMessengers = combatMessengers
        self.defaultCombatMessenger = defaultCombatMessenger
    }

    // MARK: - Public Static API

    /// Creates a StateChange to end combat by clearing the combat state.
    ///
    /// This is a public helper for use by combat systems and game code that
    /// needs to end combat without going through the full middleware flow.
    ///
    /// - Returns: A StateChange that clears combat state
    public static func endCombat() throws -> StateChange {
        try setCombatState(to: nil)
    }

    // MARK: - Public Instance Methods

    /// Initiates combat when an enemy attacks the player.
    ///
    /// This method is used by game-specific daemons and event handlers to start combat
    /// when an enemy initiates an attack. It uses the middleware's configured messengers
    /// and combat systems.
    ///
    /// - Parameters:
    ///   - enemy: The enemy that is attacking
    ///   - playerWeapon: Optional specific weapon for the player to use
    ///   - engine: The game engine
    /// - Returns: An `ActionResult` that initiates combat
    public func enemyAttacks(
        enemy: ItemProxy,
        playerWeapon: ItemProxy? = nil,
        engine: GameEngine
    ) async throws -> ActionResult {
        let finalPlayerWeapon =
            if let playerWeapon {
                playerWeapon
            } else {
                await engine.player.preferredWeapon
            }
        let finalEnemyWeapon = await enemy.preferredWeapon

        // Get the combat messenger from instance configuration
        let combatMsg = await combatMessenger(for: enemy.id, engine: engine)

        return try await ActionResult(
            combatMsg.enemyAttacks(
                enemy: enemy,
                playerWeapon: finalPlayerWeapon,
                enemyWeapon: finalEnemyWeapon
            ),
            Self.setCombatState(
                to: CombatState(
                    enemyID: enemy.id,
                    playerWeaponID: finalPlayerWeapon?.id,
                    enemyWeaponID: finalEnemyWeapon?.id
                )
            ),
            enemy.setCharacterAttributes(isFighting: true),
            enemy.setFlag(.isTouched)
        )
    }

    /// Initiates combat when the player attacks an enemy.
    ///
    /// This method is used internally by the combat attack action handler to start combat
    /// when the player initiates an attack. It uses the middleware's configured messengers
    /// and combat systems.
    ///
    /// - Parameters:
    ///   - enemy: The enemy being attacked
    ///   - playerWeapon: Optional weapon the player is using
    ///   - enemyWeapon: Optional weapon the enemy is using
    ///   - engine: The game engine
    /// - Returns: An `ActionResult` that initiates combat
    public func playerAttacks(
        enemy: ItemProxy,
        playerWeapon: ItemProxy?,
        enemyWeapon: ItemProxy?,
        engine: GameEngine
    ) async throws -> ActionResult {
        let finalPlayerWeapon =
            if let playerWeapon {
                playerWeapon
            } else {
                await engine.player.preferredWeapon
            }
        let finalEnemyWeapon =
            if let enemyWeapon {
                enemyWeapon
            } else {
                await enemy.preferredWeapon
            }

        // Get the combat messenger from instance configuration
        let combatMsg = await combatMessenger(for: enemy.id, engine: engine)

        return try await ActionResult(
            combatMsg.playerAttacks(
                enemy: enemy,
                playerWeapon: finalPlayerWeapon,
                enemyWeapon: finalEnemyWeapon
            ),
            Self.setCombatState(
                to: CombatState(
                    enemyID: enemy.id,
                    playerWeaponID: finalPlayerWeapon?.id,
                    enemyWeaponID: finalEnemyWeapon?.id
                )
            ),
            enemy.setCharacterAttributes(isFighting: true),
            enemy.setFlag(.isTouched)
        )
    }

    /// Checks if combat should end based on current conditions.
    ///
    /// This method evaluates various conditions that would cause combat to end,
    /// such as the death or unconsciousness of either the player or the enemy,
    /// or when health points reach zero or below.
    ///
    /// - Parameters:
    ///   - enemy: The enemy currently engaged in combat
    ///   - engine: The game engine
    /// - Returns: `true` if combat should end, `false` if it should continue
    public static func shouldEndCombat(
        enemy: ItemProxy,
        engine: GameEngine
    ) async -> Bool {
        // Check if enemy is dead or unconscious
        if await !enemy.isAwake { return true }

        // Check if player is dead
        if await engine.isPlayerDead { return true }

        // Check health conditions
        let playerHealth = await engine.player.health
        let enemyHealth = await enemy.health
        return playerHealth <= 0 || enemyHealth <= 0
    }

    // MARK: - Middleware Hooks

    /// Intercept attack actions to provide combat functionality.
    ///
    /// This middleware intercepts `AttackActionHandler` to add combat mechanics.
    /// Without this middleware, attack commands would just display a non-violent message.
    public func interceptAction(
        handler: any ActionHandler,
        context: ActionContext
    ) async throws -> ActionResult? {
        // Only intercept AttackActionHandler
        guard handler is AttackActionHandler else {
            return nil
        }

        // Get the target item to attack
        guard
            let target = try await context.itemDirectObject(
                playerMessage: context.msg.attackSelf()
            )
        else {
            throw ActionResponse.doWhat(context)
        }

        // Only handle character targets
        guard await target.isCharacter else {
            // Let default handler deal with non-characters
            return nil
        }

        // If a weapon was specified, check if player is holding it
        let playerWeapon = try await findPlayerWeapon(in: context)

        // Check if an opponent requires a weapon to fight it
        if playerWeapon == nil, await target.characterSheet.requiresWeapon == true {
            let messenger = await self.combatMessenger(for: target.id, engine: context.engine)
            return await ActionResult(
                messenger.unarmedAttackDenied(
                    enemy: target,
                    enemyWeapon: target.preferredWeapon
                )
            )
        }

        // Check if already in combat
        if let combat = await Self.combatState(in: context.engine) {
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

        // Determine final weapons for combat
        let finalPlayerWeapon =
            if let playerWeapon {
                playerWeapon
            } else {
                await context.player.preferredWeapon
            }
        let finalEnemyWeapon: ItemProxy? =
            if let enemyWeapon = await target.preferredWeapon {
                enemyWeapon
            } else {
                nil
            }

        // Get the combat messenger and show intro message
        let combatMsg = await combatMessenger(for: target.id, engine: context.engine)
        let introMessage = await combatMsg.playerAttacks(
            enemy: target,
            playerWeapon: finalPlayerWeapon,
            enemyWeapon: finalEnemyWeapon
        )

        // Create the initial combat state
        let initialCombatState = CombatState(
            enemyID: target.id,
            playerWeaponID: finalPlayerWeapon?.id,
            enemyWeaponID: finalEnemyWeapon?.id
        )

        // Process the first combat turn immediately with the initial state
        let firstTurn = try await processCombatTurn(
            command: context.command,
            combatState: initialCombatState,
            engine: context.engine
        )

        // Combine intro message with first combat turn, including enemy state changes
        return ActionResult(
            message: [introMessage, firstTurn.message].compactMap { $0 }.joined(
                separator: .paragraph),
            changes: firstTurn.changes + [
                await target.setCharacterAttributes(isFighting: true),
                await target.setFlag(.isTouched),
            ],
            effects: firstTurn.effects
        )
    }

    /// Before command execution, intercept if we're in combat.
    ///
    /// When in combat, player commands are processed through the combat system
    /// rather than the normal action handlers. This ensures combat has full
    /// control over the turn flow.
    public func beforeCommandExecution(
        command: Command,
        context: MiddlewareContext
    ) async throws -> CommandMiddlewareResult {
        let engine = context.engine

        guard let combatState = await Self.combatState(in: engine) else {
            return .continue(command)
        }

        // We're in combat - process this as a combat turn
        let combatResult = try await processCombatTurn(
            command: command,
            combatState: combatState,
            engine: engine
        )

        // Skip normal command execution
        return .skip(combatResult)
    }

    /// After command execution, check for hostile enemies and initiate combat.
    ///
    /// This hook runs after normal command processing. If the player is not
    /// already in combat and there are hostile enemies present, combat is
    /// initiated with the first hostile enemy found.
    public func afterCommandExecution(
        command: Command,
        result: ActionResult,
        context: MiddlewareContext
    ) async throws -> ActionResult {
        let engine = context.engine

        // Don't check for enemies if already in combat, player dead, or game ending
        guard
            await !Self.isInCombat(in: engine),
            await !engine.isPlayerDead,
            await !engine.shouldQuit,
            await !engine.shouldRestart
        else {
            return result
        }

        // Check current location for hostile enemies
        let currentLocation = await engine.player.location
        let locationItems = await currentLocation.items

        for creature in locationItems where await creature.isHostileEnemy {
            // Found hostile enemy - initiate combat
            let combatInitiation = try await initiateEnemyAttack(
                enemy: creature,
                engine: engine
            )

            // Combine the original result with combat initiation
            return result.appending(combatInitiation)
        }

        return result
    }

    // MARK: - Combat State Access

    /// Indicates whether the game is currently in a combat state.
    static func isInCombat(in engine: GameEngine) async -> Bool {
        await combatState(in: engine) != nil
    }

    /// The current combat state, if any.
    static func combatState(in engine: GameEngine) async -> CombatState? {
        await engine.gameState.globalState[.combatMiddlewareState]?.toCodable(as: CombatState.self)
    }

    /// Creates a StateChange to set the combat state (internal for use by combat systems).
    static func setCombatState(to combatState: CombatState?) throws -> StateChange {
        if let combatState {
            try .setGlobalCodable(
                id: .combatMiddlewareState,
                value: AnyCodableSendable(combatState)
            )
        } else {
            .clearGlobalState(id: .combatMiddlewareState)
        }
    }

    // MARK: - Combat Processing

    /// Processes a complete combat turn (player action + enemy response).
    private func processCombatTurn(
        command: Command,
        combatState: CombatState,
        engine: GameEngine
    ) async throws -> ActionResult {
        // Get the combat system for this enemy
        let combatSystem = await getCombatSystem(
            for: combatState.enemyID,
            engine: engine
        )

        // Convert command to player action
        let playerAction = await getPlayerAction(
            for: command,
            in: combatState,
            engine: engine
        )

        // Temporarily set the combat state so the combat system can access it
        let tempStateChange = try Self.setCombatState(to: combatState)
        try await engine.applyActionResultChanges([tempStateChange])

        // Process the complete combat turn through the system
        let result = try await combatSystem.processCombatTurn(
            playerAction: playerAction,
            in: ActionContext(command, engine)
        )

        // Check if combat should end
        let enemy = await engine.item(combatState.enemyID)
        if await Self.shouldEndCombat(enemy: enemy, engine: engine) {
            return try result.appending(
                endCombat(engine: engine)
            )
        }

        return result
    }

    /// Initiates combat when an enemy attacks the player.
    private func initiateEnemyAttack(
        enemy: ItemProxy,
        engine: GameEngine
    ) async throws -> ActionResult {
        try await self.enemyAttacks(
            enemy: enemy,
            playerWeapon: nil,
            engine: engine
        )
    }

    /// Ends combat and clears combat state.
    private func endCombat(engine: GameEngine) throws -> ActionResult {
        try ActionResult(
            Self.endCombat()
        )
    }

    // MARK: - Helper Methods

    /// Returns the combat system for the specified enemy.
    private func getCombatSystem(
        for enemyID: ItemID,
        engine: GameEngine
    ) async -> any CombatSystem {
        // Check if there's a custom combat system first
        if let customSystem = combatSystems[enemyID] {
            return customSystem
        }

        // Get the appropriate combat messenger for this enemy
        let messenger = await combatMessenger(for: enemyID, engine: engine)

        // Create a StandardCombatSystem for this enemy with its messenger
        return StandardCombatSystem(versus: enemyID, combatMessenger: messenger)
    }

    /// Returns the combat messenger for the specified enemy.
    private func combatMessenger(for enemyID: ItemID, engine: GameEngine) async -> CombatMessenger {
        if let messenger = combatMessengers[enemyID] {
            return messenger
        }

        return defaultCombatMessenger
    }

    /// Finds the player's weapon for combat.
    private func findPlayerWeapon(in context: ActionContext) async throws -> ItemProxy? {
        let weapon =
            if let specified = try await context.itemIndirectObject() {
                // Weapon specified in command
                specified
            } else if let previousID = await Self.combatState(in: context.engine)?.playerWeaponID {
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

    /// Converts a Command to a PlayerAction for combat processing.
    private func getPlayerAction(
        for command: Command,
        in combatState: CombatState,
        engine: GameEngine
    ) async -> PlayerAction {
        switch true {
        case command.hasIntent(.attack, .burn, .cut, .eat):
            .attack
        case command.hasIntent(.ask, .tell):
            .talk(topic: command.indirectObject)
        case command.hasIntent(.move):
            .flee(direction: command.direction)
        case command.hasIntent(.defend):
            .defend
        case command.hasIntent(.give):
            if let itemProxy = command.directObject?.itemProxy {
                .useItem(item: itemProxy)
            } else {
                .other
            }
        default:
            .other
        }
    }
}
