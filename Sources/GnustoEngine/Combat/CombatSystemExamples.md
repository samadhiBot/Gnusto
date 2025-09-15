# Combat System Examples

This document provides examples of how to use the combat system in Gnusto games.

## Basic Combat System Setup

### 1. Using Default Combat System

The simplest approach is to let enemies use the default combat system:

```swift
// In your GameBlueprint implementation
struct MyGame: GameBlueprint {
    var items: [Item] {
        [
            Item(
                id: "troll",
                .name("troll"),
                .description("A fierce troll blocks your path."),
                .isCharacter,
                .isFighting,
                .in("bridge")
            )
        ]
    }
    
    // No need to specify combatSystems - troll will use StandardCombatSystem
}
```

### 2. Custom Combat System for Specific Enemy

```swift
struct DragonCombatSystem: CombatSystem {
    let enemyID: ItemID = "dragon"
    
    let description: @Sendable (CombatEvent, CombatMessenger) async throws -> String? = { event, messenger in
        // Custom descriptions for dramatic dragon combat
        switch event {
        case .enemyAttacks:
            return "The dragon roars and breathes fire!"
        case .playerAttacks:
            return "You strike at the mighty beast!"
        default:
            return nil // Use default description
        }
    }
    
    func processCombatTurn(
        playerAction: PlayerAction,
        in context: ActionContext
    ) async throws -> ActionResult {
        // Custom dragon combat logic with breath weapons, wing attacks, etc.
        // This is where you'd implement special dragon abilities
        
        // For now, delegate to standard combat
        let standardSystem = StandardCombatSystem(versus: enemyID)
        return try await standardSystem.processCombatTurn(
            playerAction: playerAction,
            in: context
        )
    }
    
    func calculateAttackOutcome(
        attacker: Combatant,
        defender: Combatant,
        weapon: ItemProxy?,
        in context: ActionContext
    ) async throws -> CombatEvent {
        // Custom attack calculation with dragon-specific modifiers
        let standardSystem = StandardCombatSystem(versus: enemyID)
        return try await standardSystem.calculateAttackOutcome(
            attacker: attacker,
            defender: defender,
            weapon: weapon,
            in: context
        )
    }
    
    func determineEnemyAction(
        against playerAction: PlayerAction,
        enemy: ItemProxy,
        in context: ActionContext
    ) async throws -> CombatEvent? {
        // Dragon AI - might breathe fire, use claws, or flee when wounded
        if await context.engine.randomPercentage(chance: 30) {
            // 30% chance of breath weapon attack
            return .enemySpecialAction(
                enemy: enemy,
                enemyWeapon: nil,
                message: "The dragon breathes a gout of flame!"
            )
        }
        
        // Otherwise use standard combat AI
        let standardSystem = StandardCombatSystem(versus: enemyID)
        return try await standardSystem.determineEnemyAction(
            against: playerAction,
            enemy: enemy,
            in: context
        )
    }
}

// In your GameBlueprint implementation
struct MyGame: GameBlueprint {
    var combatSystems: [ItemID: any CombatSystem] {
        [
            "dragon": DragonCombatSystem()
        ]
    }
}
```

### 3. Custom Combat Messenger

```swift
class HorrorCombatMessenger: CombatMessenger {
    override func enemyAttacks(
        enemy: ItemProxy,
        playerWeapon: ItemProxy?,
        enemyWeapon: ItemProxy?
    ) async throws -> String {
        let theEnemy = await enemy.withDefiniteArticle
        return oneOf(
            "From the shadows, \(theEnemy) lunges with inhuman speed!",
            "Terror grips you as \(theEnemy) strikes without warning!",
            "The air fills with dread as \(theEnemy) attacks!"
        )
    }
    
    override func playerAttacks(
        enemy: ItemProxy,
        playerWeapon: ItemProxy?,
        enemyWeapon: ItemProxy?
    ) async throws -> String {
        let theEnemy = await enemy.withDefiniteArticle
        return oneOf(
            "Steeling yourself, you strike at \(theEnemy)!",
            "With desperate courage, you attack the horror!",
            "Fighting back your fear, you assault \(theEnemy)!"
        )
    }
}

// In your GameBlueprint implementation
struct HorrorGame: GameBlueprint {
    var combatMessengers: [ItemID: CombatMessenger] {
        [
            "ghost": HorrorCombatMessenger(),
            "zombie": HorrorCombatMessenger()
        ]
    }
    
    var defaultCombatMessenger: CombatMessenger {
        HorrorCombatMessenger(randomNumberGenerator: randomNumberGenerator)
    }
}
```

### 4. Per-Enemy Combat Messengers

```swift
class TrollCombatMessenger: CombatMessenger {
    override func enemyMissed(
        enemy: ItemProxy,
        playerWeapon: ItemProxy?,
        enemyWeapon: ItemProxy?
    ) async throws -> String {
        return oneOf(
            "The troll swings its massive club, but you duck just in time!",
            "Grunting with effort, the troll's attack goes wide!",
            "The troll's crude weapon smashes harmlessly into the ground!"
        )
    }
}

class ElegantDuelistMessenger: CombatMessenger {
    override func enemyMissed(
        enemy: ItemProxy,
        playerWeapon: ItemProxy?,
        enemyWeapon: ItemProxy?
    ) async throws -> String {
        return oneOf(
            "The duelist's rapier whistles past your ear in a precise thrust!",
            "With elegant footwork, the duelist's attack is expertly controlled!",
            "The duelist's blade dances around your guard but finds no opening!"
        )
    }
}

// In your GameBlueprint implementation
struct AdventureGame: GameBlueprint {
    var combatMessengers: [ItemID: CombatMessenger] {
        [
            "troll": TrollCombatMessenger(),
            "duelist": ElegantDuelistMessenger()
        ]
    }
}
```

## Advanced Usage

### Mixed Custom Systems and Messengers

You can mix and match custom combat systems and messengers:

```swift
struct MyGame: GameBlueprint {
    var combatSystems: [ItemID: any CombatSystem] {
        [
            "dragon": DragonCombatSystem(),  // Custom combat logic
            "wizard": WizardCombatSystem()   // Another custom system
        ]
    }
    
    var combatMessengers: [ItemID: CombatMessenger] {
        [
            "dragon": DragonCombatMessenger(),     // Custom messages for dragon
            "troll": TrollCombatMessenger(),       // Custom messages for troll
            "wizard": WizardCombatMessenger()      // Custom messages for wizard
        ]
    }
    
    var defaultCombatMessenger: CombatMessenger {
        // Default messenger for any enemies not specifically configured
        StandardCombatMessenger(randomNumberGenerator: randomNumberGenerator)
    }
}
```

### Runtime Combat System Configuration

You can also configure combat systems and messengers at runtime:

```swift
// During game initialization or based on game state
await engine.registerCombatSystem(BossCombatSystem(), for: "finalBoss")
await engine.registerCombatMessenger(EpicBattleMessenger(), for: "finalBoss")
```

This system provides maximum flexibility while maintaining simplicity for basic use cases. Most enemies can use the default system and messenger, while special encounters can have completely custom behavior and narrative.