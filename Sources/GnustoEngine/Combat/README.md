# Combat System Architecture

## Overview

The Gnusto combat system provides a flexible, extensible framework for implementing turn-based combat in interactive fiction games. It supports both default combat behavior and full customization through combat systems and messengers.

## Architecture Components

### Core Protocols

#### `CombatSystem`
Defines combat behavior for enemies:
- **`enemyID`**: Links the system to a specific enemy
- **`description`**: Custom combat event descriptions
- **`processCombatTurn()`**: Main combat turn processing
- **`calculateAttackOutcome()`**: Attack resolution logic
- **`determineEnemyAction()`**: Enemy AI decisions

#### `CombatMessenger`
Provides narrative descriptions for combat events:
- Extends `StandardMessenger` for consistency
- Supports per-enemy customization
- Rich, context-aware combat descriptions
- Handles all combat event types (attacks, misses, wounds, etc.)

### Default Implementation

#### `StandardCombatSystem`
- D&D-style d20 combat mechanics
- Attribute-based attack and damage calculations
- Intelligent enemy AI (fleeing, surrender, pacification)
- Dynamic combat intensity and fatigue systems
- Special combat events (disarming, staggering, vulnerability)

#### `CombatMessenger`
- Rich narrative descriptions for all combat events
- Context-aware messaging based on weapons and combatants
- Multiple variations for each event type
- Supports gender-appropriate pronouns

## Configuration

### GameBlueprint Integration

```swift
struct MyGame: GameBlueprint {
    // Custom combat systems for specific enemies
    var combatSystems: [ItemID: any CombatSystem] {
        [
            "dragon": DragonCombatSystem(),
            "troll": TrollCombatSystem()
        ]
    }
    
    // Custom combat messengers for specific enemies
    var combatMessengers: [ItemID: CombatMessenger] {
        [
            "dragon": DragonCombatMessenger(),
            "ghost": HorrorCombatMessenger()
        ]
    }
    
    // Default messenger for unconfigured enemies
    var defaultCombatMessenger: CombatMessenger {
        CustomCombatMessenger(randomNumberGenerator: randomNumberGenerator)
    }
}
```

### ActionContext Integration

The `ActionContext` now provides access to combat messaging:

```swift
// In action handlers or combat systems
let combatMsg = await context.combatMsg  // Returns appropriate CombatMessenger
```

### GameEngine Integration

The `GameEngine` manages combat systems and messengers:

```swift
// Gets the appropriate combat system for an enemy
func combatSystem(versus enemyID: ItemID) -> CombatSystem

// Gets the appropriate combat messenger for an enemy  
func combatMessenger(for enemyID: ItemID) -> CombatMessenger
```

## Usage Patterns

### 1. Default Behavior
Most enemies can use the default system with no configuration:

```swift
// Just define the enemy item - combat works automatically
let troll = Item(
    id: "troll",
    .name("troll"),
    .isCharacter,
    .in("bridge")
)
```

### 2. Custom Combat Logic
For enemies needing special combat behavior:

```swift
struct DragonCombatSystem: CombatSystem {
    let enemyID: ItemID = "dragon"
    
    func processCombatTurn(
        playerAction: PlayerAction,
        in context: ActionContext
    ) async throws -> ActionResult {
        // Custom dragon combat with breath weapons, etc.
    }
    
    // Implement other required methods...
}
```

### 3. Custom Combat Messaging
For themed or atmospheric combat descriptions:

```swift
class HorrorCombatMessenger: CombatMessenger {
    override func enemyAttacks(
        enemy: ItemProxy,
        playerWeapon: ItemProxy?,
        enemyWeapon: ItemProxy?
    ) async throws -> String {
        return "From the shadows, \(await enemy.withDefiniteArticle) lunges!"
    }
}
```

### 4. Mixed Customization
Combine custom systems and messengers as needed:

```swift
var combatSystems: [ItemID: any CombatSystem] {
    ["dragon": DragonCombatSystem()]  // Custom combat logic
}

var combatMessengers: [ItemID: CombatMessenger] {
    [
        "dragon": DragonMessenger(),    // Custom messages for dragon
        "ghost": HorrorMessenger()      // Different theme for ghost
    ]
}
```

## Key Features

### Flexible Configuration
- Per-enemy combat systems and messengers
- Global defaults with specific overrides
- Mix and match systems and messengers independently

### Rich Combat Events
- Multiple damage categories (scratch, light, moderate, grave, critical, fatal)
- Special events (disarming, staggering, hesitation, vulnerability)
- Context-aware descriptions based on weapons and combatants

### Intelligent AI
- Health-based fleeing and surrender decisions
- Attribute-based pacification attempts
- Opportunity attacks on distracted players
- Fatigue and intensity systems affecting behavior

### Easy Integration
- Seamless integration with existing action handler system
- Clean separation of combat logic and presentation
- Extensible through standard Swift protocols

## Migration Notes

### From Previous System
- All combat messaging now goes through `CombatMessenger` instead of `StandardMessenger`
- Combat systems are now configured in `GameBlueprint` instead of ad-hoc registration
- `ActionContext.combatMsg` provides access to appropriate combat messenger

### Backwards Compatibility
- Existing games continue to work with default combat system and messenger
- No breaking changes to public APIs
- Gradual migration path for custom combat implementations