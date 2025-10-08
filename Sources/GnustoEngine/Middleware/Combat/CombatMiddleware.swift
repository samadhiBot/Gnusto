import Foundation

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
/// var middleware: [any GameMiddleware] {
///     [
///         CombatMiddleware(
///             combatSystems: combatSystems,
///             combatMessengers: combatMessengers,
///             defaultCombatMessenger: defaultCombatMessenger
///         )
///     ]
/// }
/// ```
public struct CombatMiddleware: GameMiddleware {
    // MARK: - GameMiddleware Protocol

    public let stateKey = "combat"
    public let priority = 100  // High priority to intercept turns early

    // MARK: - Configuration

    private let combatSystems: [ItemID: any CombatSystem]
    private let combatMessengers: [ItemID: CombatMessenger]
    private let defaultCombatMessenger: CombatMessenger

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

    // MARK: - Middleware Hooks

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

        guard let combatState = await engine.combatState else {
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
            await !engine.isInCombat,
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
            let combatInitiation = await initiateEnemyAttack(
                enemy: creature,
                engine: engine
            )

            // Combine the original result with combat initiation
            return result.appending(combatInitiation)
        }

        return result
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

        // Process the complete combat turn through the system
        let result = try await combatSystem.processCombatTurn(
            playerAction: playerAction,
            in: ActionContext(command, engine)
        )

        // Check if combat should end
        let enemy = await engine.item(combatState.enemyID)
        if await shouldEndCombat(enemy: enemy, engine: engine) {
            return await result.appending(
                endCombat(engine: engine)
            )
        }

        return result
    }

    /// Initiates combat when an enemy attacks the player.
    private func initiateEnemyAttack(
        enemy: ItemProxy,
        engine: GameEngine
    ) async -> ActionResult {
        let playerWeapon = await engine.player.preferredWeapon
        let enemyWeapon = await enemy.preferredWeapon

        return await ActionResult(
            combatMessenger(for: enemy.id).enemyAttacks(
                enemy: enemy,
                playerWeapon: playerWeapon,
                enemyWeapon: enemyWeapon
            ),
            engine.setCombatState(
                to: CombatState(
                    enemyID: enemy.id,
                    playerWeaponID: playerWeapon?.id,
                    enemyWeaponID: enemyWeapon?.id
                )
            ),
            enemy.setCharacterAttributes(isFighting: true),
            enemy.setFlag(.isTouched)
        )
    }

    /// Ends combat and clears combat state.
    private func endCombat(engine: GameEngine) async -> ActionResult {
        await ActionResult(
            engine.endCombat()
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

        // Use cached StandardCombatSystem or create a new one
        return await engine.getCachedStandardCombatSystem(for: enemyID)
    }

    /// Returns the combat messenger for the specified enemy.
    private func combatMessenger(for enemyID: ItemID) -> CombatMessenger {
        combatMessengers[enemyID] ?? defaultCombatMessenger
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

    /// Checks if combat should end based on current conditions.
    private func shouldEndCombat(
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
}

// MARK: - GameEngine Combat Support

extension GameEngine {
    /// Indicates whether the game is currently in a combat state.
    public var isInCombat: Bool {
        combatState != nil
    }

    /// The current combat state, if any.
    public var combatState: CombatState? {
        if case .combatState(let combatState) = gameState.globalState[.combatState] {
            combatState
        } else {
            nil
        }
    }

    /// Returns a cached StandardCombatSystem for the specified enemy.
    ///
    /// This ensures consistent RNG behavior across combat turns by reusing
    /// the same system instance throughout a combat encounter.
    func getCachedStandardCombatSystem(for enemyID: ItemID) -> StandardCombatSystem {
        if let cachedSystem = standardCombatSystemCache[enemyID] {
            return cachedSystem
        }

        let newSystem = StandardCombatSystem(versus: enemyID)
        standardCombatSystemCache[enemyID] = newSystem
        return newSystem
    }

    /// Initiates combat when an enemy attacks the player.
    ///
    /// This is a public helper method used by daemons, event handlers, and game-specific
    /// code to start combat when an enemy initiates an attack.
    public func enemyAttacks(
        enemy: ItemProxy,
        playerWeapon: ItemProxy? = nil
    ) async -> ActionResult {
        let finalPlayerWeapon =
            if let playerWeapon {
                playerWeapon
            } else {
                await player.preferredWeapon
            }
        let finalEnemyWeapon = await enemy.preferredWeapon

        // Get the combat messenger (checking blueprint first)
        let messenger =
            gameBlueprint.combatMessengers[enemy.id]
            ?? gameBlueprint.defaultCombatMessenger

        return await ActionResult(
            messenger.enemyAttacks(
                enemy: enemy,
                playerWeapon: finalPlayerWeapon,
                enemyWeapon: finalEnemyWeapon
            ),
            setCombatState(
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
    /// This is a public helper method used by action handlers (e.g., AttackActionHandler)
    /// to start combat when the player initiates an attack.
    public func playerAttacks(
        enemy: ItemProxy,
        playerWeapon: ItemProxy?,
        enemyWeapon: ItemProxy?
    ) async -> ActionResult {
        let finalPlayerWeapon =
            if let playerWeapon {
                playerWeapon
            } else {
                await player.preferredWeapon
            }
        let finalEnemyWeapon =
            if let enemyWeapon {
                enemyWeapon
            } else {
                await enemy.preferredWeapon
            }

        // Get the combat messenger (checking blueprint first)
        let messenger =
            gameBlueprint.combatMessengers[enemy.id]
            ?? gameBlueprint.defaultCombatMessenger

        return await ActionResult(
            messenger.playerAttacks(
                enemy: enemy,
                playerWeapon: finalPlayerWeapon,
                enemyWeapon: finalEnemyWeapon
            ),
            setCombatState(
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

    /// Returns the appropriate combat messenger for the given enemy.
    ///
    /// This is a helper method for action handlers that need to access combat messaging.
    /// It checks if there's a character-specific combat messenger configured
    /// for the given enemy ID. If not, it returns the default combat messenger.
    ///
    /// - Parameter enemyID: The ID of the enemy to get a combat messenger for
    /// - Returns: A `CombatMessenger` instance for the enemy
    public func combatMessenger(for enemyID: ItemID) -> CombatMessenger {
        gameBlueprint.combatMessengers[enemyID] ?? gameBlueprint.defaultCombatMessenger
    }

    /// Checks if combat should end based on current conditions.
    ///
    /// This method evaluates various conditions that would cause combat to end,
    /// such as the death or unconsciousness of either the player or the enemy,
    /// or when health points reach zero or below.
    ///
    /// This is a helper method for tests and combat systems.
    ///
    /// - Parameter enemy: The enemy currently engaged in combat
    /// - Returns: `true` if combat should end, `false` if it should continue
    public func shouldEndCombat(enemy: ItemProxy) async -> Bool {
        // Check if enemy is dead or unconscious
        if await !enemy.isAwake { return true }

        // Check if player is dead
        if await isPlayerDead { return true }

        // Check health conditions
        let playerHealth = await player.health
        let enemyHealth = await enemy.health
        return playerHealth <= 0 || enemyHealth <= 0
    }

    /// Processes a complete combat turn using the CombatSystem protocol.
    ///
    /// This method bridges the game loop's Command-based interface to the
    /// CombatSystem's PlayerAction-based interface, then delegates to the
    /// appropriate combat system for processing.
    ///
    /// This is a helper method for tests that need to simulate combat turns.
    ///
    /// - Parameter command: The player's command for this combat turn
    /// - Returns: The result of the combat turn processing
    /// - Throws: `ActionResponse` errors from combat processing
    public func getCombatResult(for command: Command) async throws -> ActionResult {
        guard let combatState else {
            assertionFailure("GameEngine.getCombatResult called when not in combat")
            return .yield
        }

        // Get the combat system for this enemy
        let combatSystem = getCachedStandardCombatSystem(for: combatState.enemyID)

        // Convert command to player action
        let playerAction = await getPlayerAction(for: command, in: combatState)

        // Process the combat turn through the system
        return try await combatSystem.processCombatTurn(
            playerAction: playerAction,
            in: ActionContext(command, self)
        )
    }

    /// Converts a Command to a PlayerAction for combat processing.
    ///
    /// This helper method is used by getCombatResult and is also available
    /// for test compatibility.
    public func getPlayerAction(
        for command: Command,
        in combatState: CombatState
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
