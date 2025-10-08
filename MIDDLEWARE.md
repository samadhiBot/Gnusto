# Middleware Architecture in Gnusto

This document describes the middleware system implemented in Gnusto, which provides a clean, extensible way to add optional game features like combat, dialogue, crafting, and other mechanics without cluttering the core engine.

## Overview

Middleware in Gnusto operates on a **pipeline pattern**, where each middleware component can intercept the game loop at strategic points to observe, modify, or short-circuit execution. This allows game developers to compose complex features from independent, testable components.

### Key Benefits

- **Composable**: Mix and match features (combat + dialogue + weather)
- **Optional**: Games only include middleware they need
- **Testable**: Each middleware can be tested in isolation
- **Extensible**: Easy to create custom middleware
- **Clean Core**: Engine stays focused on core IF mechanics

## Architecture

### Middleware Lifecycle

Middleware hooks execute at specific points in the game loop:

```
┌─────────────────────────────────────────┐
│         Start Turn                      │
├─────────────────────────────────────────┤
│ 1. beforeTurn()                         │ ← Can short-circuit entire turn
├─────────────────────────────────────────┤
│ 2. Read player input                    │
├─────────────────────────────────────────┤
│ 3. Parse input to Command               │
├─────────────────────────────────────────┤
│ 4. beforeCommandExecution(command)      │ ← Can modify or skip command
├─────────────────────────────────────────┤
│ 5. Execute command                      │
├─────────────────────────────────────────┤
│ 6. afterCommandExecution(result)        │ ← Can add side effects
├─────────────────────────────────────────┤
│ 7. Check for player death               │
├─────────────────────────────────────────┤
│ 8. beforeTimeAdvancement()              │ ← Can prevent time from advancing
├─────────────────────────────────────────┤
│ 9. Advance time (fuses/daemons)         │
├─────────────────────────────────────────┤
│ 10. afterTurn()                         │ ← Cleanup, logging, etc.
└─────────────────────────────────────────┘
```

### Priority System

Middleware executes in **priority order** (highest first):
- **100-199**: Critical systems (combat, death)
- **50-99**: Gameplay systems (dialogue, crafting)
- **1-49**: Passive systems (achievements, hints)
- **0**: Default priority

## Creating Middleware

### Basic Middleware

```swift
struct WeatherMiddleware: GameMiddleware {
    let stateKey = "weather"
    let priority = 10
    
    func afterTurn(context: MiddlewareContext) async throws {
        // Update weather every turn
        let weather = await generateWeather(engine: context.engine)
        await context.engine.ioHandler.print("The weather is \(weather).")
    }
}
```

### Stateful Middleware

Middleware can persist state across save/restore:

```swift
struct QuestMiddleware: GameMiddleware {
    let stateKey = "quests"
    let priority = 20
    
    struct State: Codable {
        var activeQuests: [String]
        var completedQuests: [String]
    }
    
    private var state = State(activeQuests: [], completedQuests: [])
    
    func afterCommandExecution(
        command: Command,
        result: ActionResult,
        context: MiddlewareContext
    ) async throws -> ActionResult {
        // Check if command completed a quest
        if await checkQuestCompletion(command, context.engine) {
            return result.appending(
                ActionResult("Quest completed!")
            )
        }
        return result
    }
    
    func saveState(context: MiddlewareContext) async throws -> (any Codable)? {
        state
    }
    
    func restoreState(_ state: any Codable, context: MiddlewareContext) async throws {
        if let questState = state as? State {
            self.state = questState
        }
    }
}
```

### Intercepting Middleware

Middleware can take over turn processing:

```swift
struct CutsceneMiddleware: GameMiddleware {
    let stateKey = "cutscene"
    let priority = 150  // Higher than combat
    
    func beforeTurn(context: MiddlewareContext) async throws -> MiddlewareResult {
        if await context.engine.hasFlag(.isInCutscene) {
            // Play cutscene, prevent normal turn processing
            await playCutscene(context.engine)
            return .handled()
        }
        return .continue
    }
}
```

## Combat Middleware

Combat was the first major system extracted to middleware. Here's how it works:

### Configuration

```swift
struct MyGame: GameBlueprint {
    var middleware: [any GameMiddleware] {
        [
            CombatMiddleware(
                combatSystems: combatSystems,
                combatMessengers: combatMessengers,
                defaultCombatMessenger: defaultCombatMessenger
            )
        ]
    }
}
```

### How Combat Middleware Works

1. **After Command Execution**: Checks for hostile enemies
   - If hostile enemy found → initiates combat
   
2. **Before Command Execution**: Intercepts when in combat
   - Converts command to combat action
   - Processes through CombatSystem
   - Handles both player and enemy actions
   
3. **Combat State**: Persisted automatically via `saveState()`

### Example: Custom Combat for Boss

```swift
var combatSystems: [ItemID: any CombatSystem] {
    [
        .dragonBoss: DragonBossCombatSystem()
    ]
}

var combatMessengers: [ItemID: CombatMessenger] {
    [
        .dragonBoss: DragonBossMessenger()
    ]
}
```

## Middleware Registration

Middleware is registered via `GameBlueprint`:

```swift
struct MyGame: GameBlueprint {
    var middleware: [any GameMiddleware] {
        [
            // High priority - combat must intercept early
            CombatMiddleware(...),                // priority: 100
            
            // Medium priority - gameplay systems
            DialogueMiddleware(...),              // priority: 50
            CraftingMiddleware(...),              // priority: 40
            
            // Low priority - passive observation
            AchievementMiddleware(),              // priority: 10
            HintMiddleware()                      // priority: 5
        ]
    }
}
```

## Testing Middleware

### Unit Testing

Test middleware in isolation:

```swift
@Test("Weather middleware updates each turn")
func testWeatherMiddleware() async throws {
    let middleware = WeatherMiddleware()
    let (engine, mockIO) = await GameEngine.test(blueprint: MinimalGame())
    
    let context = MiddlewareContext(engine: engine)
    try await middleware.afterTurn(context: context)
    
    // Verify weather message was printed
    await mockIO.expect("The weather is")
}
```

### Integration Testing

Test middleware in the full game loop:

```swift
@Test("Combat middleware detects hostile enemy")
func testCombatMiddleware() async throws {
    let troll = Item("troll")
        .name("nasty troll")
        .characterSheet(.init(isHostile: true))
        .in(.startRoom)
    
    let game = MinimalGame(items: troll)
    let (engine, mockIO) = await GameEngine.test(blueprint: game)
    
    // Take a turn - combat should initiate
    try await engine.execute("look")
    
    await mockIO.expect("The troll attacks!")
    #expect(await engine.isInCombat == true)
}
```

## Migration Guide

### Before Middleware (Old Combat)

```swift
// Combat logic hardcoded in game loop
func processTurn() async throws {
    // ... normal processing ...
    
    // Hardcoded combat check
    if isInCombat {
        let combatResult = try await getCombatResult(for: command)
        try await processActionResult(combatResult)
    }
    
    // Check for hostile characters
    for creature in locationItems where await creature.isHostileEnemy {
        try await processActionResult(
            enemyAttacks(enemy: creature)
        )
    }
}
```

### After Middleware (Current)

```swift
// Clean game loop with middleware hooks
func processTurn() async throws {
    // Before turn hook
    let beforeResult = try await executeBeforeTurnMiddleware()
    if case .handled = beforeResult { return }
    
    // ... normal processing ...
    
    // After command hook (combat checks here)
    let finalResult = try await executeAfterCommandMiddleware(
        command: command,
        result: result
    )
}
```

## Best Practices

### DO

✅ Use middleware for optional, composable features  
✅ Give middleware descriptive, unique state keys  
✅ Set appropriate priorities based on execution order needs  
✅ Return `.continue` from hooks you don't use (default implementation)  
✅ Test middleware both in isolation and integrated  
✅ Document what your middleware does and when it runs

### DON'T

❌ Put core IF mechanics in middleware (those belong in engine)  
❌ Create middleware that depends on other middleware  
❌ Mutate game state directly (use StateChange objects)  
❌ Block or wait indefinitely in middleware hooks  
❌ Assume middleware execution order beyond priority

## Future Middleware Ideas

Here are some middleware that could be implemented:

- **RangedCombatMiddleware**: Bows, guns, throwing weapons
- **MagicCombatMiddleware**: Spells, mana, spell effects
- **DialogueMiddleware**: Conversation trees with NPCs
- **CraftingMiddleware**: Combine items to create new ones
- **WeatherMiddleware**: Dynamic weather affecting gameplay
- **TimeOfDayMiddleware**: Day/night cycles
- **HungerMiddleware**: Food and survival mechanics
- **EncumbranceMiddleware**: Weight limits and carrying capacity
- **StealthMiddleware**: Sneaking past enemies
- **TradeMiddleware**: Economics and bartering

## Performance Considerations

Middleware adds minimal overhead:
- Empty hooks: ~nanoseconds (default implementation returns immediately)
- Simple hooks: ~microseconds
- Complex hooks: depends on implementation

For text adventure games, this is negligible. If you're concerned about performance:
1. Profile first (use Instruments)
2. Optimize the slow middleware, not the system
3. Consider caching in stateful middleware

## Conclusion

The middleware architecture provides a clean separation between core engine concerns and optional game features. It honors SOLID principles while maintaining the simplicity and elegance that Gnusto strives for.

Combat is now completely optional—a game without combat simply doesn't include `CombatMiddleware`. Future features like magic, crafting, and dialogue will follow the same pattern, keeping Gnusto's core lean while enabling rich, complex games.
