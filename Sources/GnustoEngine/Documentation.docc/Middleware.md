# Middleware Architecture

Gnusto's middleware architecture provides a composable way to extend game mechanics such combat, dialogue, and crafting.

## Overview

Middleware in Gnusto operates on a pipeline pattern. Each middleware component can intercept the game loop at specific points to observe, modify, or short-circuit the logic flow. This allows complex feature composition using independent, testable components.

## Architecture

### Middleware Lifecycle

Middleware hooks execute at specific points in the game loop:

| Game Loop Progression             | Notes                                           |
| --------------------------------- | ----------------------------------------------- |
| `beforeTurn()`                    | Can short-circuit entire turn                   |
| Read player input                 |                                                 |
| Parse input to Command            |                                                 |
| `beforeCommandExecution(command)` | Can modify or skip command (only if parse succeeds) |
| `onParseError(error, rawInput)`   | Called only when parsing fails                  |
| Execute command                   | Only if parse succeeded and not skipped         |
| `afterCommandExecution(result)`   | Called only when command was executed           |
| Check for player death            |                                                 |
| `beforeTimeAdvancement()`         | Can prevent time from advancing                 |
| Advance time (fuses/daemons)      |                                                 |
| `afterTurn()`                     | Cleanup, logging, etc.                          |

### Priority System

Middleware executes in priority order, with higher priority components running first.

| Middleware Types                      | Suggested Range |
| ------------------------------------- | --------------- |
| Critical systems (combat, death)      | 100-199         |
| Gameplay systems (dialogue, crafting) | 50-99           |
| Passive systems (achievements, hints) | 1-49            |
| Default priority                      | 0               |

## Creating Middleware

### Basic Middleware

```swift
struct WeatherMiddleware: GnustoMiddleware {
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

Middleware can persist state across player save/restore:

```swift
struct QuestMiddleware: GnustoMiddleware {
    let stateKey = "quests"
    let priority = 20
    
    struct State: Codable, Sendable {
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
    
    func saveState(context: MiddlewareContext) async throws -> (any Codable & Sendable)? {
        state
    }
    
    func restoreState(_ state: any Codable & Sendable, context: MiddlewareContext) async throws {
        if let questState = state as? State {
            self.state = questState
        }
    }
}
```

### Intercepting Middleware

Middleware can take over turn processing:

```swift
struct CutsceneMiddleware: GnustoMiddleware {
    let stateKey = "cutscene"
    let priority = 150  // Higher than combat
    
    func beforeTurn(context: MiddlewareContext) async throws -> MiddlewareResult {
        if await context.engine.hasFlag(.isInCutscene) {
            // Play cutscene, prevent normal turn processing
            await playCutscene(context.engine)
            return .handled(ActionResult("The cutscene plays..."))
        }
        return .continue
    }
}
```

## Parse Error Handling

Middleware can observe and respond to parse errors using the `onParseError` hook:

```swift
struct HelpfulMiddleware: GnustoMiddleware {
    let stateKey = "helpful"
    let priority = 10
    
    func onParseError(
        error: ParseError,
        rawInput: String,
        context: MiddlewareContext
    ) async throws {
        // Track parse errors for analytics
        await logParseError(error, rawInput)
        
        // Provide "did you mean?" suggestions
        if case .verbUnknown(let verb) = error {
            if let suggestion = findSimilarVerb(verb) {
                await context.engine.ioHandler.print(
                    "Did you mean '\(suggestion)'?"
                )
            }
        }
    }
}
```

**Note**: Parse errors are handled separately from command execution because there is no valid Command object when parsing fails. The `onParseError` hook receives the raw input string and the specific parse error instead.

## Combat Middleware

Combat was the first major system extracted to middleware. Here's how it works:

### Configuration

```swift
struct MyGame: GameBlueprint {
    var middleware: [any GnustoMiddleware] {
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
    var middleware: [any GnustoMiddleware] {
        [
            // High priority - combat must intercept early
            CombatMiddleware(...),                // priority: 100
            
            // Medium priority - gameplay systems
            DialogueMiddleware(...),              // priority: 50
            CraftingMiddleware(...),              // priority: 40
            
            // Low priority - passive observation
            AchievementMiddleware(),              // priority: 10
            HelpfulMiddleware(),                  // priority: 10 (parse error help)
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

## Best Practices

### Do

- Use middleware for optional, composable features
- Give middleware descriptive, unique state keys
- Set appropriate priorities based on execution order needs
- Return `.continue` from hooks you don't use (default implementation does this)
- Test middleware both in isolation and integrated
- Document what your middleware does and when it runs
- Use `onParseError` for parse error handling, not `afterCommandExecution`

### Do Not

- Put core IF mechanics in middleware (those belong in engine)
- Create middleware that depends on other middleware execution
- Mutate game state directly (use StateChange objects)
- Block or wait indefinitely in middleware hooks
- Assume middleware execution order beyond priority
- Try to handle parse errors in `afterCommandExecution` (use `onParseError` instead)

## Future Middleware Ideas

- RangedCombatMiddleware: Bows, guns, throwing weapons
- MagicCombatMiddleware: Spells, mana, spell effects
- DialogueMiddleware: Conversation trees with NPCs
- CraftingMiddleware: Combine items to create new ones
- WeatherMiddleware: Dynamic weather affecting gameplay
- TimeOfDayMiddleware: Day/night cycles
- HungerMiddleware: Food and survival mechanics
- EncumbranceMiddleware: Weight limits and carrying capacity
- StealthMiddleware: Sneaking past enemies
- TradeMiddleware: Economics and bartering
