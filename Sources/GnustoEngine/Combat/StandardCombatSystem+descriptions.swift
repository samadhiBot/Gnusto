import Foundation

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
        return switch event {
        case let .enemyAttacks(enemy, playerWeapon, enemyWeapon):
            await messenger.enemyAttacks(
                enemy: enemy,
                playerWeapon: playerWeapon,
                enemyWeapon: enemyWeapon
            )

        case let .playerAttacks(enemy, playerWeapon, enemyWeapon):
            await messenger.playerAttacks(
                enemy: enemy,
                playerWeapon: playerWeapon,
                enemyWeapon: enemyWeapon
            )

        case let .enemySlain(enemy, playerWeapon, enemyWeapon, damage):
            await messenger.enemySlain(
                enemy: enemy,
                playerWeapon: playerWeapon,
                enemyWeapon: enemyWeapon,
                damage: damage
            )

        case let .enemyUnconscious(enemy, playerWeapon, enemyWeapon):
            await messenger.enemyUnconscious(
                enemy: enemy,
                playerWeapon: playerWeapon,
                enemyWeapon: enemyWeapon
            )

        case let .enemyDisarmed(enemy, playerWeapon, enemyWeapon, wasFumble):
            await messenger.enemyDisarmed(
                enemy: enemy,
                playerWeapon: playerWeapon,
                enemyWeapon: enemyWeapon,
                wasFumble: wasFumble
            )

        case let .enemyStaggers(enemy, playerWeapon, enemyWeapon):
            await messenger.enemyStaggers(
                enemy: enemy,
                playerWeapon: playerWeapon,
                enemyWeapon: enemyWeapon
            )

        case let .enemyHesitates(enemy, playerWeapon, enemyWeapon):
            await messenger.enemyHesitates(
                enemy: enemy,
                playerWeapon: playerWeapon,
                enemyWeapon: enemyWeapon,
            )

        case let .enemyVulnerable(enemy, playerWeapon, enemyWeapon):
            await messenger.enemyVulnerable(
                enemy: enemy,
                playerWeapon: playerWeapon,
                enemyWeapon: enemyWeapon,
            )

        case let .enemyCriticallyWounded(enemy, playerWeapon, enemyWeapon, damage):
            await messenger.enemyCriticallyWounded(
                enemy: enemy,
                playerWeapon: playerWeapon,
                enemyWeapon: enemyWeapon,
                damage: damage
            )

        case let .enemyGravelyInjured(enemy, playerWeapon, enemyWeapon, damage):
            await messenger.enemyGravelyInjured(
                enemy: enemy,
                playerWeapon: playerWeapon,
                enemyWeapon: enemyWeapon,
                damage: damage
            )

        case let .enemyInjured(enemy, playerWeapon, enemyWeapon, damage):
            await messenger.enemyInjured(
                enemy: enemy,
                playerWeapon: playerWeapon,
                enemyWeapon: enemyWeapon,
                damage: damage
            )

        case let .enemyLightlyInjured(enemy, playerWeapon, enemyWeapon, damage):
            await messenger.enemyLightlyInjured(
                enemy: enemy,
                playerWeapon: playerWeapon,
                enemyWeapon: enemyWeapon,
                damage: damage
            )

        case let .enemyGrazed(enemy, playerWeapon, enemyWeapon, damage):
            await messenger.enemyGrazed(
                enemy: enemy,
                playerWeapon: playerWeapon,
                enemyWeapon: enemyWeapon,
                damage: damage
            )

        case let .enemyMissed(enemy, playerWeapon, enemyWeapon):
            await messenger.enemyMissed(
                enemy: enemy,
                playerWeapon: playerWeapon,
                enemyWeapon: enemyWeapon
            )

        case let .enemyBlocked(enemy, playerWeapon, enemyWeapon):
            await messenger.enemyBlocked(
                enemy: enemy,
                playerWeapon: playerWeapon,
                enemyWeapon: enemyWeapon
            )

        case let .playerSlain(enemy, enemyWeapon, damage):
            await messenger.playerSlain(
                enemy: enemy,
                enemyWeapon: enemyWeapon,
                damage: damage
            )

        case let .playerUnconscious(enemy, enemyWeapon, damage):
            await messenger.playerUnconscious(
                enemy: enemy,
                enemyWeapon: enemyWeapon,
                damage: damage
            )

        case let .playerDisarmed(enemy, playerWeapon, enemyWeapon, wasFumble):
            await messenger.playerDisarmed(
                enemy: enemy,
                playerWeapon: playerWeapon,
                enemyWeapon: enemyWeapon,
                wasFumble: wasFumble
            )

        case let .playerStaggers(enemy, enemyWeapon):
            await messenger.playerStaggers(
                enemy: enemy,
                enemyWeapon: enemyWeapon
            )

        case let .playerHesitates(enemy, enemyWeapon):
            await messenger.playerHesitates(
                enemy: enemy,
                enemyWeapon: enemyWeapon
            )

        case let .playerVulnerable(enemy, enemyWeapon):
            await messenger.playerVulnerable(
                enemy: enemy,
                enemyWeapon: enemyWeapon
            )

        case let .playerCriticallyWounded(enemy, enemyWeapon, damage):
            await messenger.playerCriticallyWounded(
                enemy: enemy,
                enemyWeapon: enemyWeapon,
                damage: damage
            )

        case let .playerGravelyInjured(enemy, enemyWeapon, damage):
            await messenger.playerGravelyInjured(
                enemy: enemy,
                enemyWeapon: enemyWeapon,
                damage: damage
            )

        case let .playerInjured(enemy, enemyWeapon, damage):
            await messenger.playerInjured(
                enemy: enemy,
                enemyWeapon: enemyWeapon,
                damage: damage
            )

        case let .playerLightlyInjured(enemy, enemyWeapon, damage):
            await messenger.playerLightlyInjured(
                enemy: enemy,
                enemyWeapon: enemyWeapon,
                damage: damage
            )

        case let .playerGrazed(enemy, enemyWeapon, damage):
            await messenger.playerGrazed(
                enemy: enemy,
                enemyWeapon: enemyWeapon,
                damage: damage
            )

        case let .playerMissed(enemy, enemyWeapon):
            await messenger.playerMissed(
                enemy: enemy,
                enemyWeapon: enemyWeapon
            )

        case let .playerDodged(enemy, enemyWeapon):
            await messenger.playerDodged(
                enemy: enemy,
                enemyWeapon: enemyWeapon
            )

        case let .enemyFlees(enemy, enemyWeapon, direction, destination):
            await messenger.enemyFlees(
                enemy: enemy,
                enemyWeapon: enemyWeapon,
                direction: direction,
                destination: destination
            )

        case let .enemyPacified(enemy, enemyWeapon):
            await messenger.enemyPacified(
                enemy: enemy,
                enemyWeapon: enemyWeapon
            )

        case let .enemySurrenders(enemy, enemyWeapon):
            await messenger.enemySurrenders(
                enemy: enemy,
                enemyWeapon: enemyWeapon
            )

        case let .enemyTaunts(enemy, message):
            await messenger.enemyTaunts(
                enemy: enemy,
                message: message
            )

        case let .enemySpecialAction(enemy, enemyWeapon, message):
            await messenger.enemySpecialAction(
                enemy: enemy,
                enemyWeapon: enemyWeapon,
                message: message
            )

        case let .unarmedAttackDenied(enemy, enemyWeapon):
            await messenger.unarmedAttackDenied(
                enemy: enemy,
                enemyWeapon: enemyWeapon
            )

        case let .nonWeaponAttack(enemy, enemyWeapon, item):
            await messenger.nonWeaponAttack(
                enemy: enemy,
                enemyWeapon: enemyWeapon,
                item: item
            )

        case let .playerDistracted(enemy, enemyWeapon, command):
            await messenger.playerDistracted(
                enemy: enemy,
                enemyWeapon: enemyWeapon,
                command: command
            )

        case let .combatInterrupted(reason):
            await messenger.combatInterrupted(reason: reason)

        case let .stalemate(enemy, enemyWeapon):
            await messenger.stalemate(
                enemy: enemy,
                enemyWeapon: enemyWeapon
            )

        case let .error(errorMessage):
            errorMessage
        }
    }
}
