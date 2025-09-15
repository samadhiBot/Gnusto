# Dynamic Properties and Proxy System

Learn how to use the proxy system for safe state access and dynamic properties to create sophisticated game mechanics while respecting the action pipeline.

## Overview

The Gnusto Engine's proxy system provides safe, concurrent access to game state while enabling both static and dynamic properties. Instead of accessing game objects directly, you work with proxy objects (`ItemProxy`, `LocationProxy`, `PlayerProxy`) that automatically handle state computation, validation, and safe concurrent access.

The proxy system enables complex game mechanics similar to those found in classic ZIL-based interactive fiction games like Zork, while maintaining Swift 6 concurrency safety and modern architectural patterns.

Compute handlers can be defined in your `GameBlueprint` using the `itemComputeHandlers` and `locationComputeHandlers` properties, or registered at runtime for more dynamic scenarios.

> **Note**: If you're using the GnustoAutoWiringPlugin, it will generate helpful scaffolding for the GameBlueprint approach, including commented examples for your items and locations.

**Important**: All property changes must flow through the action pipeline using `StateChange` builders accessed through proxy objects. This ensures proper validation, event handling, and consistency while maintaining concurrency safety.

## Proxy System Fundamentals

### Understanding Proxies

Instead of working with `Item`, `Location`, or `Player` objects directly, you access them through proxy objects that provide safe, concurrent access to both static and computed properties:

```swift
// Access through the engine returns proxy objects
let sword = try await engine.item(.magicSword)
let room = try await engine.location(.magicRoom)
let playerProxy = try await engine.player

// Proxies provide access to both static and computed properties
let damage = await sword.damage  // Could be static or computed
let description = await sword.description  // Dynamic based on current state
let isLit = await room.isLit     // Automatically computed
```

## Basic Usage with Proxies

### Reading Properties Through Proxies

Access properties through proxy objects, which automatically handle both static and computed values:

```swift
// Get proxy objects from the engine
let sword = try await engine.item(.sword)
let door = try await engine.item(.door)
let cave = try await engine.location(.cave)

// Access properties through proxies
let description = await sword.description
let isOpen = await door.hasFlag(.isOpen)
```

### Setting Properties (Respecting the Pipeline)

**Always use `StateChange` builders through proxy objects** to modify properties:

```swift
// Create StateChange using proxy builders
let sword = try await engine.item(.sword)

// Use proxy methods to create state changes
return ActionResult(
    context.msg.swordSharpened(),
    sword.setProperty("sharpness", to: 8),
    sword.setDescription("A gleaming blade")
)

// Flag operations through proxies
let door = try await engine.item(.door)
return ActionResult(
    context.msg.doorOpens(),
    door.setFlag(.isOpen)
)
```

## Validation Through Proxy System

The proxy system includes built-in validation that's called automatically when `StateChange`s are applied through the action pipeline.

### Proxy-Based Validation

Validation works seamlessly with the proxy system:

```swift
// Validation happens automatically when state changes are applied
let door = try await engine.item(.door)

// This will automatically validate through registered handlers
return ActionResult(
    context.msg.doorOpens(),
    door.setFlag(.isOpen)  // Validation applied here
)
```

### Registering Validation Handlers

You can register validation handlers that work with the proxy system:

```swift
// Register through the engine's validation system
await engine.registerItemValidator(itemID: .door, propertyID: .isOpen) { staticItem, newValue, gameState in
    guard case .bool(let isOpening) = newValue else { return false }

    // Can only open if not locked
    if isOpening {
        let isLocked = staticItem.properties[.isLocked]?.toBool ?? false
        return !isLocked
    }
    return true
}
```

### Complex State Management with Proxies

Inspired by Zork's troll combat system, using the proxy architecture:

```swift
// Ensure troll state consistency when fighting status changes
await engine.registerItemValidator(itemID: .troll, propertyID: "fighting") { staticItem, newValue, gameState in
    guard case .bool(let isFighting) = newValue else { return false }

    // If troll stops fighting, it must be unconscious or disarmed
    if !isFighting {
        let hasWeapon = staticItem.properties["hasWeapon"]?.toBool ?? false
        let isUnconscious = staticItem.properties["unconscious"]?.toBool ?? false
        return !hasWeapon || isUnconscious
    }
    return true
}
```

### Validation with Custom Error Messages

Validation handlers can throw specific errors through the messenger system:

```swift
await engine.registerItemValidator(itemID: .magicSword, propertyID: "enchantmentLevel") { staticItem, newValue, gameState in
    guard case .int(let level) = newValue else {
        throw ActionResponse.feedback("Enchantment level must be a number")
    }

    if level < 0 || level > 10 {
        throw ActionResponse.feedback("Enchantment level must be between 0 and 10")
    }

    return true
}
```

## StateChange Builders with Proxies

The proxy system provides convenient builders for creating `StateChange` objects that respect the action pipeline:

### Proxy-Based Property Builders

```swift
// Set properties through proxy objects
let sword = try await engine.item(.sword)
let cave = try await engine.location(.cave)

// Proxy methods return StateChange objects
let propertyChange = sword.setProperty("customProp", to: .string("value"))
let temperatureChange = cave.setProperty("temperature", to: .int(72))
```

### Convenience Builders Through Proxies

```swift
// Common patterns have dedicated builders on proxies
let sword = try await engine.item(.sword)
let door = try await engine.item(.door)
let room = try await engine.location(.room)

let changes = [
    sword.setDescription("A new description"),
    door.setFlag(.isOpen),
    room.clearFlag(.isLit),
    sword.setProperty("damage", to: .int(15)),
    sword.setProperty("material", to: .string("steel"))
]
```

### Using Proxy StateChanges in Action Handlers

```swift
struct OpenActionHandler: ActionHandler {
    func process(context: ActionContext) async throws -> ActionResult {
        guard let targetItemID = context.command.directObjectItemID else {
            throw ActionResponse.feedback(context.msg.doWhat(context.command.verb))
        }

        let itemProxy = try await context.engine.item(targetItemID)

        // Validate the item can be opened
        guard await itemProxy.hasFlag(.isOpenable) else {
            throw ActionResponse.itemNotOpenable(itemProxy)
        }

        // Check if already open
        guard !await itemProxy.hasFlag(.isOpen) else {
            throw ActionResponse.itemAlreadyOpen(itemProxy)
        }

        // Return result with state change through proxy
        return ActionResult(
            context.msg.openItem(itemProxy.withDefiniteArticle),
            itemProxy.setFlag(.isOpen)
        )
    }
}
```

## ZIL-Inspired Patterns with Proxies

The proxy system enables classic interactive fiction patterns while maintaining concurrency safety:

### Opening and Closing Objects

```swift
// Similar to ZIL's FSET/FCLEAR for OPENBIT, but through proxies
let chest = try await engine.item(.chest)
return ActionResult(
    context.msg.chestOpens(),
    chest.setFlag(.isOpen)
)
```

### Dynamic Descriptions

```swift
// Similar to ZIL's PUTP for changing descriptions, with safe proxy access
let troll = try await engine.item(.troll)

let newDescription = if await troll.isFighting {
    "A nasty-looking troll, brandishing a bloody axe, blocks all passages."
} else {
    "An unconscious troll is sprawled on the floor."
}

return ActionResult(
    context.msg.trollChangesState(),
    troll.setDescription(newDescription)
)
```

### State Transitions Through Proxies

```swift
// Complex state changes with validation through the proxy system
let troll = try await engine.item(.troll)
let axe = try await engine.item(.axe)

return ActionResult(
    context.msg.trollCollapses(),
    troll.setFlag(.unconscious),
    troll.clearFlag(.fighting),
    axe.setFlag(.isVisible),
    axe.setParent(.location(troll.parent))
)
```

## Best Practices with Proxies

1. **Always access game objects through proxies** instead of direct references
2. **Use proxy StateChange builders** instead of direct state mutation
3. **Return proxy StateChanges in ActionResult** to respect the action pipeline
4. **Use validation handlers** for complex state dependencies and concurrency safety
5. **Throw specific errors** to provide clear feedback to players
6. **Use proxy convenience methods** for common patterns like flags and descriptions
7. **Register validators early** in your game setup, typically in the `GameBlueprint`
8. **Test edge cases** thoroughly, especially concurrent access scenarios
9. **Leverage computed properties** through proxies for dynamic content
10. **Never bypass the proxy system** for state access or mutations

## Error Handling with Proxies

The proxy system throws `ActionResponse` errors for various failure conditions:

- `ActionResponse.internalEngineError`: Item or location doesn't exist
- `ActionResponse.invalidValue`: Validation failed (generic or from validation handlers)
- `ActionResponse.concurrencyError`: Concurrent access violation (rare but possible)
- Custom errors: Thrown by validation handlers for specific conditions

Always handle these appropriately in your action handlers:

```swift
do {
    let itemProxy = try await context.engine.item(.someItem)
    let result = ActionResult(
        context.msg.success(),
        itemProxy.setFlag(.processed)
    )
    return result
} catch let response as ActionResponse {
    throw response // Re-throw ActionResponse for proper error reporting
} catch {
    throw ActionResponse.internalEngineError("Unexpected error: \(error)")
}
```

## Integration with Action Pipeline and Proxies

The proxy system is fully integrated with the action pipeline:

1. **Safe Access**: Proxies provide thread-safe access to game state with Swift 6 concurrency compliance
2. **Validation**: When `StateChange`s created by proxies are applied, validation handlers are called automatically
3. **Event Handlers**: Item and location event handlers can create `StateChange`s through proxies that trigger validation
4. **Consistency**: All state mutations flow through the same proxy system validation and application process
5. **Computed Properties**: Proxies automatically handle both static and computed properties transparently
6. **Debugging**: All changes are tracked in `gameState.changeHistory` with proxy access patterns for debugging

This ensures that your game's state remains consistent, thread-safe, and that all business rules are enforced through the unified proxy system, regardless of how state changes are initiated.
