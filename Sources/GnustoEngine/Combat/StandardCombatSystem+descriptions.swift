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
    ) async throws -> String {
        return switch event {
        case let .enemyAttacks(enemy, playerWeapon, enemyWeapon):
            try await messenger.enemyAttacks(
                enemy: enemy,
                playerWeapon: playerWeapon,
                enemyWeapon: enemyWeapon
            )

        case let .playerAttacks(enemy, playerWeapon, enemyWeapon):
            try await messenger.playerAttacks(
                enemy: enemy,
                playerWeapon: playerWeapon,
                enemyWeapon: enemyWeapon
            )

        case let .enemySlain(enemy, playerWeapon, enemyWeapon, damage):
            try await messenger.enemySlain(
                enemy: enemy,
                playerWeapon: playerWeapon,
                enemyWeapon: enemyWeapon,
                damage: damage
            )

        case let .enemyUnconscious(enemy, playerWeapon, enemyWeapon):
            try await messenger.enemyUnconscious(
                enemy: enemy,
                playerWeapon: playerWeapon,
                enemyWeapon: enemyWeapon
            )

        case let .enemyDisarmed(enemy, playerWeapon, enemyWeapon, wasFumble):
            try await messenger.enemyDisarmed(
                enemy: enemy,
                playerWeapon: playerWeapon,
                enemyWeapon: enemyWeapon,
                wasFumble: wasFumble
            )

        case let .enemyStaggers(enemy, playerWeapon, enemyWeapon):
            try await messenger.enemyStaggers(
                enemy: enemy,
                playerWeapon: playerWeapon,
                enemyWeapon: enemyWeapon
            )

        case let .enemyHesitates(enemy, playerWeapon, enemyWeapon):
            try await messenger.enemyHesitates(
                enemy: enemy,
                playerWeapon: playerWeapon,
                enemyWeapon: enemyWeapon,
            )

        case let .enemyVulnerable(enemy, playerWeapon, enemyWeapon):
            try await messenger.enemyVulnerable(
                enemy: enemy,
                playerWeapon: playerWeapon,
                enemyWeapon: enemyWeapon,
            )

        case let .enemyCriticallyWounded(enemy, playerWeapon, enemyWeapon, damage):
            try await messenger.enemyCriticallyWounded(
                enemy: enemy,
                playerWeapon: playerWeapon,
                enemyWeapon: enemyWeapon,
                damage: damage
            )

        case let .enemyGravelyInjured(enemy, playerWeapon, enemyWeapon, damage):
            try await messenger.enemyGravelyInjured(
                enemy: enemy,
                playerWeapon: playerWeapon,
                enemyWeapon: enemyWeapon,
                damage: damage
            )

        case let .enemyInjured(enemy, playerWeapon, enemyWeapon, damage):
            try await messenger.enemyInjured(
                enemy: enemy,
                playerWeapon: playerWeapon,
                enemyWeapon: enemyWeapon,
                damage: damage
            )

        case let .enemyLightlyInjured(enemy, playerWeapon, enemyWeapon, damage):
            try await messenger.enemyLightlyInjured(
                enemy: enemy,
                playerWeapon: playerWeapon,
                enemyWeapon: enemyWeapon,
                damage: damage
            )

        case let .enemyGrazed(enemy, playerWeapon, enemyWeapon, damage):
            try await messenger.enemyGrazed(
                enemy: enemy,
                playerWeapon: playerWeapon,
                enemyWeapon: enemyWeapon,
                damage: damage
            )

        case let .enemyMissed(enemy, playerWeapon, enemyWeapon):
            try await messenger.enemyMissed(
                enemy: enemy,
                playerWeapon: playerWeapon,
                enemyWeapon: enemyWeapon
            )

        case let .enemyBlocked(enemy, playerWeapon, enemyWeapon):
            try await messenger.enemyBlocked(
                enemy: enemy,
                playerWeapon: playerWeapon,
                enemyWeapon: enemyWeapon
            )

        case let .playerSlain(enemy, enemyWeapon, damage):
            try await messenger.playerSlain(
                enemy: enemy,
                enemyWeapon: enemyWeapon,
                damage: damage
            )

        case let .playerUnconscious(enemy, enemyWeapon, damage):
            try await messenger.playerUnconscious(
                enemy: enemy,
                enemyWeapon: enemyWeapon,
                damage: damage
            )

        case let .playerDisarmed(enemy, playerWeapon, enemyWeapon, wasFumble):
            try await messenger.playerDisarmed(
                enemy: enemy,
                playerWeapon: playerWeapon,
                enemyWeapon: enemyWeapon,
                wasFumble: wasFumble
            )

        case let .playerStaggers(enemy, enemyWeapon):
            try await messenger.playerStaggers(
                enemy: enemy,
                enemyWeapon: enemyWeapon
            )

        case let .playerHesitates(enemy, enemyWeapon):
            try await messenger.playerHesitates(
                enemy: enemy,
                enemyWeapon: enemyWeapon
            )

        case let .playerVulnerable(enemy, enemyWeapon):
            try await messenger.playerVulnerable(
                enemy: enemy,
                enemyWeapon: enemyWeapon
            )

        case let .playerCriticallyWounded(enemy, enemyWeapon, damage):
            try await messenger.playerCriticallyWounded(
                enemy: enemy,
                enemyWeapon: enemyWeapon,
                damage: damage
            )

        case let .playerGravelyInjured(enemy, enemyWeapon, damage):
            try await messenger.playerGravelyInjured(
                enemy: enemy,
                enemyWeapon: enemyWeapon,
                damage: damage
            )

        case let .playerInjured(enemy, enemyWeapon, damage):
            try await messenger.playerInjured(
                enemy: enemy,
                enemyWeapon: enemyWeapon,
                damage: damage
            )

        case let .playerLightlyInjured(enemy, enemyWeapon, damage):
            try await messenger.playerLightlyInjured(
                enemy: enemy,
                enemyWeapon: enemyWeapon,
                damage: damage
            )

        case let .playerGrazed(enemy, enemyWeapon, damage):
            try await messenger.playerGrazed(
                enemy: enemy,
                enemyWeapon: enemyWeapon,
                damage: damage
            )

        case let .playerMissed(enemy, enemyWeapon):
            try await messenger.playerMissed(
                enemy: enemy,
                enemyWeapon: enemyWeapon
            )

        case let .playerDodged(enemy, enemyWeapon):
            try await messenger.playerDodged(
                enemy: enemy,
                enemyWeapon: enemyWeapon
            )

        case let .enemyFlees(enemy, enemyWeapon, direction, destination):
            try await messenger.enemyFlees(
                enemy: enemy,
                enemyWeapon: enemyWeapon,
                direction: direction,
                destination: destination
            )

        case let .enemyPacified(enemy, enemyWeapon):
            try await messenger.enemyPacified(
                enemy: enemy,
                enemyWeapon: enemyWeapon
            )

        case let .enemySurrenders(enemy, enemyWeapon):
            try await messenger.enemySurrenders(
                enemy: enemy,
                enemyWeapon: enemyWeapon
            )

        case let .enemyTaunts(enemy, message):
            try await messenger.enemyTaunts(
                enemy: enemy,
                message: message
            )

        case let .enemySpecialAction(enemy, enemyWeapon, message):
            try await messenger.enemySpecialAction(
                enemy: enemy,
                enemyWeapon: enemyWeapon,
                message: message
            )

        case let .unarmedAttackDenied(enemy, enemyWeapon):
            try await messenger.unarmedAttackDenied(
                enemy: enemy,
                enemyWeapon: enemyWeapon
            )

        case let .nonWeaponAttack(enemy, enemyWeapon, item):
            try await messenger.nonWeaponAttack(
                enemy: enemy,
                enemyWeapon: enemyWeapon,
                item: item
            )

        case let .playerDistracted(enemy, enemyWeapon, command):
            try await messenger.playerDistracted(
                enemy: enemy,
                enemyWeapon: enemyWeapon,
                command: command
            )

        case let .combatInterrupted(reason):
            try await messenger.combatInterrupted(reason: reason)

        case let .stalemate(enemy, enemyWeapon):
            try await messenger.stalemate(
                enemy: enemy,
                enemyWeapon: enemyWeapon
            )

        case let .error(errorMessage):
            errorMessage
        }
    }
}
