import Foundation
import GnustoEngine

extension StandardCombatSystem {
    /// Generates a human-readable description of a combat event using the provided messenger.
    ///
    /// This method serves as the default implementation for converting combat events into
    /// descriptive text that can be displayed to the player. It delegates to the appropriate
    /// messenger method based on the event type.
    ///
    /// - Parameters:
    ///   - event: The combat event to generate a description for
    ///   - messenger: The combat messenger responsible for generating the actual text
    /// - Returns: A string description of the combat event
    /// - Throws: Any error that occurs during message generation
    public func defaultCombatDescription(
        of event: CombatEvent,
        via messenger: CombatMessenger
    ) async -> String {
        switch event {
        case .enemyAttacks(let payload):
            await messenger.enemyAttacks(
                enemy: payload.enemy,
                playerWeapon: payload.playerWeapon,
                enemyWeapon: payload.enemyWeapon
            )

        case .playerAttacks(let payload):
            await messenger.playerAttacks(
                enemy: payload.enemy,
                playerWeapon: payload.playerWeapon,
                enemyWeapon: payload.enemyWeapon
            )

        case .enemyInjured(let payload):
            switch payload.damageCategory {
            case .fatal:
                await messenger.enemySlain(
                    enemy: payload.enemy,
                    playerWeapon: payload.playerWeapon,
                    enemyWeapon: payload.enemyWeapon,
                    damage: payload.damage
                )
            case .critical:
                await messenger.enemyCriticallyWounded(
                    enemy: payload.enemy,
                    playerWeapon: payload.playerWeapon,
                    enemyWeapon: payload.enemyWeapon,
                    damage: payload.damage
                )
            case .grave:
                await messenger.enemyGravelyInjured(
                    enemy: payload.enemy,
                    playerWeapon: payload.playerWeapon,
                    enemyWeapon: payload.enemyWeapon,
                    damage: payload.damage
                )
            case .moderate:
                await messenger.enemyInjured(
                    enemy: payload.enemy,
                    playerWeapon: payload.playerWeapon,
                    enemyWeapon: payload.enemyWeapon,
                    damage: payload.damage
                )
            case .light:
                await messenger.enemyLightlyInjured(
                    enemy: payload.enemy,
                    playerWeapon: payload.playerWeapon,
                    enemyWeapon: payload.enemyWeapon,
                    damage: payload.damage
                )
            case .scratch:
                await messenger.enemyGrazed(
                    enemy: payload.enemy,
                    playerWeapon: payload.playerWeapon,
                    enemyWeapon: payload.enemyWeapon,
                    damage: payload.damage
                )
            case .none:
                // Handle special conditions or default message
                if let condition = payload.combatCondition {
                    switch condition {
                    case .offBalance:
                        await messenger.enemyStaggers(
                            enemy: payload.enemy,
                            playerWeapon: payload.playerWeapon,
                            enemyWeapon: payload.enemyWeapon
                        )
                    case .uncertain:
                        await messenger.enemyHesitates(
                            enemy: payload.enemy,
                            playerWeapon: payload.playerWeapon,
                            enemyWeapon: payload.enemyWeapon
                        )
                    case .vulnerable:
                        await messenger.enemyVulnerable(
                            enemy: payload.enemy,
                            playerWeapon: payload.playerWeapon,
                            enemyWeapon: payload.enemyWeapon
                        )
                    default:
                        ""
                    }
                } else {
                    ""
                }
            }

        case .enemyUnconscious(let payload):
            await messenger.enemyUnconscious(
                enemy: payload.enemy,
                playerWeapon: payload.playerWeapon,
                enemyWeapon: payload.enemyWeapon
            )

        case .enemyDisarmed(let payload, let wasFumble):
            await messenger.enemyDisarmed(
                enemy: payload.enemy,
                playerWeapon: payload.playerWeapon,
                enemyWeapon: payload.enemyWeapon!,  // Safe: disarming requires a weapon
                wasFumble: wasFumble
            )

        case .enemyMissed(let payload):
            await messenger.enemyMissed(
                enemy: payload.enemy,
                playerWeapon: payload.playerWeapon,
                enemyWeapon: payload.enemyWeapon
            )

        case .enemyBlocked(let payload):
            await messenger.enemyBlocked(
                enemy: payload.enemy,
                playerWeapon: payload.playerWeapon,
                enemyWeapon: payload.enemyWeapon
            )

        case .playerInjured(let payload):
            switch payload.damageCategory {
            case .fatal:
                await messenger.playerSlain(
                    enemy: payload.enemy,
                    enemyWeapon: payload.enemyWeapon,
                    damage: payload.damage
                )
            case .critical:
                await messenger.playerCriticallyWounded(
                    enemy: payload.enemy,
                    enemyWeapon: payload.enemyWeapon,
                    player: payload.player!,  // Safe: player injuries require a player
                    damage: payload.damage
                )
            case .grave:
                await messenger.playerGravelyInjured(
                    enemy: payload.enemy,
                    enemyWeapon: payload.enemyWeapon,
                    player: payload.player!,  // Safe: player injuries require a player
                    damage: payload.damage
                )
            case .moderate:
                await messenger.playerInjured(
                    enemy: payload.enemy,
                    enemyWeapon: payload.enemyWeapon,
                    player: payload.player!,  // Safe: player injuries require a player
                    damage: payload.damage
                )
            case .light:
                await messenger.playerLightlyInjured(
                    enemy: payload.enemy,
                    enemyWeapon: payload.enemyWeapon,
                    player: payload.player!,  // Safe: player injuries require a player
                    damage: payload.damage
                )
            case .scratch:
                await messenger.playerGrazed(
                    enemy: payload.enemy,
                    enemyWeapon: payload.enemyWeapon,
                    player: payload.player!,  // Safe: player injuries require a player
                    damage: payload.damage
                )
            case .none:
                // Handle special conditions or default message
                if let condition = payload.combatCondition {
                    switch condition {
                    case .offBalance:
                        await messenger.playerStaggers(
                            enemy: payload.enemy,
                            enemyWeapon: payload.enemyWeapon
                        )
                    case .uncertain:
                        await messenger.playerHesitates(
                            enemy: payload.enemy,
                            enemyWeapon: payload.enemyWeapon
                        )
                    case .vulnerable:
                        await messenger.playerVulnerable(
                            enemy: payload.enemy,
                            enemyWeapon: payload.enemyWeapon
                        )
                    case .taunting:
                        // Enemy taunts - use a default message or expand messenger API
                        ""
                    default:
                        ""
                    }
                } else {
                    ""
                }
            }

        case .playerUnconscious(let payload):
            await messenger.playerUnconscious(
                enemy: payload.enemy,
                enemyWeapon: payload.enemyWeapon,
                damage: payload.damage
            )

        case .playerDisarmed(let payload, let wasFumble):
            await messenger.playerDisarmed(
                enemy: payload.enemy,
                playerWeapon: payload.playerWeapon!,  // Safe: disarming requires a weapon
                enemyWeapon: payload.enemyWeapon,
                wasFumble: wasFumble
            )

        case .playerMissed(let payload):
            await messenger.playerMissed(
                enemy: payload.enemy,
                enemyWeapon: payload.enemyWeapon
            )

        case .playerDodged(let payload):
            await messenger.playerDodged(
                enemy: payload.enemy,
                enemyWeapon: payload.enemyWeapon
            )

        case .enemyFlees(let payload, let direction, let destination):
            await messenger.enemyFlees(
                enemy: payload.enemy,
                enemyWeapon: payload.enemyWeapon,
                direction: direction,
                destination: destination
            )

        case .enemyPacified(let payload):
            await messenger.enemyPacified(
                enemy: payload.enemy,
                enemyWeapon: payload.enemyWeapon
            )

        case .enemySurrenders(let payload):
            await messenger.enemySurrenders(
                enemy: payload.enemy,
                enemyWeapon: payload.enemyWeapon
            )

        case .unarmedAttackDenied(let payload):
            await messenger.unarmedAttackDenied(
                enemy: payload.enemy,
                enemyWeapon: payload.enemyWeapon
            )

        case .nonWeaponAttack(let payload):
            await messenger.nonWeaponAttack(
                enemy: payload.enemy,
                enemyWeapon: payload.enemyWeapon,
                item: payload.playerWeapon!  // Safe: non-weapon attack requires an item
            )

        case .stalemate(let payload):
            await messenger.stalemate(
                enemy: payload.enemy,
                enemyWeapon: payload.enemyWeapon
            )

        case .combatInterrupted(let reason):
            await messenger.combatInterrupted(reason: reason)

        case .error(let errorMessage):
            errorMessage
        }
    }
}
