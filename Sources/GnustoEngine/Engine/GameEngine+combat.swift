import Foundation

// MARK: - Combat State Management

extension GameEngine {
    /// Indicates whether the game is currently in a combat state.
    ///
    /// - Returns: `true` if there is an active combat state, `false` otherwise.
    public var isInCombat: Bool {
        combatState != nil
    }

    /// The current combat state, if any.
    ///
    /// - Returns: The active `CombatState` if combat is in progress, or `nil` if not in combat.
    public var combatState: CombatState? {
        if case .combatState(let combatState) = gameState.globalState[.combatState] {
            combatState
        } else {
            nil
        }
    }

    /// Initiates combat when an enemy attacks the player.
    ///
    /// This method sets up a new combat state with the attacking enemy and any weapon
    /// the player might be holding. It marks the enemy as touched and returns an
    /// appropriate message describing the attack.
    ///
    /// - Parameters:
    ///   - enemy: The enemy item that is attacking the player
    ///   - playerWeapon: The weapon the player is currently wielding, if any
    /// - Returns: An `ActionResult` containing the attack message and state changes
    /// - Throws: `ActionResponse` if there are issues with state changes
    public func enemyAttacks(
        enemy: ItemProxy,
        playerWeapon: ItemProxy? = nil
    ) async -> ActionResult {
        let playerWeapon =
            if let playerWeapon {
                playerWeapon
            } else {
                await player.preferredWeapon
            }
        return await ActionResult(
            combatMessenger(for: enemy.id).enemyAttacks(
                enemy: enemy,
                playerWeapon: playerWeapon,
                enemyWeapon: enemy.preferredWeapon
            ),
            setCombatState(
                to: CombatState(
                    enemyID: enemy.id,
                    playerWeaponID: playerWeapon?.id
                )
            ),
            enemy.setCharacterAttributes(isFighting: true),
            enemy.setFlag(.isTouched)
        )
    }

    /// Initiates combat when the player attacks an enemy.
    ///
    /// This method sets up a new combat state with the target enemy and any weapon
    /// the player is using. It marks the enemy as touched and returns an appropriate
    /// message describing the player's attack.
    ///
    /// - Parameters:
    ///   - enemy: The enemy item that the player is attacking
    ///   - playerWeapon: The weapon the player is using for the attack, if any
    ///   - enemyWeapon: The weapon the enemy is using for defense, if any
    /// - Returns: An `ActionResult` containing the attack message and state changes
    /// - Throws: `ActionResponse` if there are issues with state changes
    public func playerAttacks(
        enemy: ItemProxy,
        playerWeapon: ItemProxy?,
        enemyWeapon: ItemProxy?,
    ) async -> ActionResult {
        let playerWeapon =
            if let playerWeapon {
                playerWeapon
            } else {
                await player.preferredWeapon
            }
        let enemyWeapon =
            if let enemyWeapon {
                enemyWeapon
            } else {
                await enemy.preferredWeapon
            }
        return await ActionResult(
            combatMessenger(for: enemy.id).playerAttacks(
                enemy: enemy,
                playerWeapon: playerWeapon,
                enemyWeapon: enemyWeapon
            ),
            setCombatState(
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

    /// Processes a complete combat turn using the CombatSystem protocol.
    ///
    /// This method bridges the game loop's Command-based interface to the
    /// CombatSystem's PlayerAction-based interface, then delegates to the
    /// appropriate combat system for processing. It converts the player's command
    /// into a combat action and processes it through the combat system.
    ///
    /// - Parameter command: The player's command for this combat turn
    /// - Returns: The result of the combat turn processing, including any messages,
    ///           state changes, and side effects
    /// - Throws: `ActionResponse.internalEngineError` if not currently in combat,
    ///           or other `ActionResponse` errors from combat processing
    func getCombatResult(for command: Command) async throws -> ActionResult {
        guard let combatState else {
            assertionFailure("GameEngine.processCombatTurn invalid state")
            return .yield
        }

        // Get the combat system for this enemy
        let combatSystem = combatSystem(versus: combatState.enemyID)

        // Process the combat turn through the system
        return try await combatSystem.processCombatTurn(
            playerAction: getPlayerAction(for: command, in: combatState),
            in: ActionContext(command, self)
        )
    }

    func combatSystem(versus enemyID: ItemID) -> CombatSystem {
        gameBlueprint.combatSystems[enemyID] ?? StandardCombatSystem(versus: enemyID)
    }

    /// Returns the appropriate combat messenger for the given enemy.
    ///
    /// This method checks if there's a character-specific combat messenger configured
    /// for the given enemy ID. If not, it returns the default combat messenger.
    ///
    /// - Parameter enemyID: The ID of the enemy to get a combat messenger for
    /// - Returns: A `CombatMessenger` instance for the enemy
    func combatMessenger(for enemyID: ItemID) -> CombatMessenger {
        combatMessengers[enemyID] ?? defaultCombatMessenger
    }

    // MARK: - Command to PlayerAction Conversion

    /// Converts a Command to a PlayerAction for combat processing.
    ///
    /// This method analyzes the player's command and determines the most appropriate
    /// combat action to take. It maps various verb intents to standardized combat
    /// actions that the combat system can process.
    ///
    /// - Parameters:
    ///   - command: The player's parsed command
    ///   - combatState: The current combat state for context
    /// - Returns: A `PlayerAction` representing the intended combat action
    /// - Throws: May throw if there are issues accessing command objects
    func getPlayerAction(
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

    // MARK: - Combat State Queries

    /// Checks if combat should end based on current conditions.
    ///
    /// This method evaluates various conditions that would cause combat to end,
    /// such as the death or unconsciousness of either the player or the enemy,
    /// or when health points reach zero or below.
    ///
    /// - Parameter enemy: The enemy currently engaged in combat
    /// - Returns: `true` if combat should end, `false` if it should continue
    func shouldEndCombat(enemy: ItemProxy) async -> Bool {
        // Check if enemy is dead or unconscious
        if await !enemy.isAwake { return true }

        // Check if player is dead
        if await isPlayerDead { return true }

        // Check health conditions
        let playerHealth = await player.health
        let enemyHealth = await enemy.health
        return playerHealth <= 0 || enemyHealth <= 0
    }
}
