# Dynamic Properties

Learn how to use dynamic properties and validation handlers to create sophisticated game mechanics while respecting the action pipeline.

## Overview

The Gnusto Engine's dynamic property system allows you to create properties that are computed at runtime or validated when changed. This enables complex game mechanics similar to those found in classic ZIL-based interactive fiction games like Zork.

Compute handlers are defined in your `GameBlueprint` using the `itemComputeHandlers` and `locationComputeHandlers` properties. This compile-time approach ensures better performance and predictability.

> **Note**: If you're using the GnustoAutoWiringPlugin, it will generate helpful scaffolding for the GameBlueprint approach, including commented examples for your items and locations.

**Important**: All property changes must flow through the action pipeline using `StateChange` builders. This ensures proper validation, event handling, and consistency.

## GameBlueprint Approach (Recommended)

### Defining Compute Handlers in GameBlueprint

The preferred way to define compute handlers is directly in your `GameBlueprint`:

```swift
struct MyGameBlueprint: GameBlueprint {
    // ... other blueprint properties

    var itemComputeHandlers: [ItemID: [PropertyID: DynamicPropertyRegistry.ItemComputeHandler]] {
        [
            .magicSword: [
                .description: { item, gameState in
                    let enchantment = item.properties["enchantmentLevel"]?.toInt ?? 0
                    let desc = enchantment > 5 ? "A brilliantly glowing sword" : "A faintly shimmering blade"
                    return .string(desc)
                }
            ],
            .weatherVane: [
                .direction: { item, gameState in
                    let windDirection = gameState.globalState["windDirection"]?.toString ?? "north"
                    return .string(windDirection)
                }
            ]
        ]
    }

    var locationComputeHandlers: [LocationID: [PropertyID: DynamicPropertyRegistry.LocationComputeHandler]] {
        [
            .magicRoom: [
                .description: { location, gameState in
                    let isEnchanted = gameState.globalState["roomEnchanted"] == true
                    let desc = isEnchanted ? "The room sparkles with magical energy." : "The room appears ordinary."
                    return .string(desc)
                }
            ]
        ]
    }
}
```

### Auto-Generated Scaffolding

When using the GnustoAutoWiringPlugin, it will generate helpful scaffolding in your GameBlueprint extension:

```swift
extension MyGameBlueprint {
    // TODO: Add compute handlers for dynamic item properties
    // Example:
    // var itemComputeHandlers: [ItemID: [PropertyID: DynamicPropertyRegistry.ItemComputeHandler]] {
    //     [
    //         .sword: [
    //             .description: { item, gameState in
    //                 return .string("Dynamic description for \(item.name)")
    //             }
    //         ],
    //     ]
    // }

    // TODO: Add compute handlers for dynamic location properties
    // Example:
    // var locationComputeHandlers: [LocationID: [PropertyID: DynamicPropertyRegistry.LocationComputeHandler]] {
    //     [
    //         .livingRoom: [
    //             .description: { location, gameState in
    //                 return .string("Dynamic description for \(location.name)")
    //             }
    //         ],
    //     ]
    // }
}
```

## Runtime Registration Approach

You can also register compute handlers at runtime, which is useful for conditional or complex setup scenarios:

```swift
// Register after creating the engine
await engine.registerItemCompute(itemID: .magicSword, propertyID: .description) { item, gameState in
    let enchantment = item.properties["enchantmentLevel"]?.toInt ?? 0
    let desc = enchantment > 5 ? "A brilliantly glowing sword" : "A faintly shimmering blade"
    return .string(desc)
}

await engine.registerLocationCompute(locationID: .magicRoom, propertyID: .description) { location, gameState in
    let isEnchanted = gameState.globalState["roomEnchanted"] == true
    let desc = isEnchanted ? "The room sparkles with magical energy." : "The room appears ordinary."
    return .string(desc)
}
```

## Basic Usage

### Reading Properties

Use the fetch methods to read dynamic or static properties:

```swift
// Fetch typed values
let sharpness: Int = try await engine.property("sharpness", of .sword)
let description: String = try await engine.property(.description, of .sword)
let isOpen: Bool = try await engine.property(.isOpen, of .door)

// Fetch location properties
let temperature: String = try await engine.property("temperature", of .cave)
```

### Setting Properties (Respecting the Pipeline)

**Always use `StateChange` builders** to modify properties. Never bypass the action pipeline:

```swift
// Create StateChange using builders
let item = try engine.item("sword")
if let change = await engine.setProperty("sharpness", on: item, to: .int(8)) {
    // Apply through the pipeline (usually in an ActionHandler)
    return ActionResult(changes: [change], message: "🤡 The sword gleams with sharpness.")
}

// Use convenience builders for common patterns
if let change = await engine.setDescription(on: item, to: "A gleaming blade") {
    return ActionResult(changes: [change])
}

if let change = await engine.setProperty("isOpen", on: door, to: true) {
    return ActionResult(changes: [change], message: "🤡 The door swings open.")
}
```

## Validation Handlers

Validation handlers allow you to enforce rules when properties are changed, similar to ZIL's property validation. They are called automatically when `StateChange`s are applied.

### Basic Validation

```swift
// Register a validation handler for a specific item and property
engine.registerItemValidate(itemID: "door", propertyID: "isOpen") { item, newValue in
    guard case .bool(let isOpening) = newValue else { return false }

    // Can only open if not locked
    if isOpening {
        let isLocked = item.properties["isLocked"]?.toBool ?? false
        return !isLocked
    }
    return true
}
```

### Complex State Management

Inspired by Zork's troll combat system:

```swift
// Ensure troll state consistency when fighting status changes
engine.registerItemValidate(itemID: "troll", propertyID: "fighting") { item, newValue in
    guard case .bool(let isFighting) = newValue else { return false }

    // If troll stops fighting, it must be unconscious or disarmed
    if !isFighting {
        let hasWeapon = item.properties["hasWeapon"]?.toBool ?? false
        let isUnconscious = item.properties["unconscious"]?.toBool ?? false
        return !hasWeapon || isUnconscious
    }
    return true
}
```

### Throwing Specific Errors

Validation handlers can throw specific errors for better user feedback:

```swift
engine.registerItemValidate(itemID: "magicSword", propertyID: "enchantmentLevel") { item, newValue in
    guard case .int(let level) = newValue else {
        throw await ActionResponse.feedback("Enchantment level must be a number")
    }

    if level < 0 || level > 10 {
        throw await ActionResponse.feedback("Enchantment level must be between 0 and 10")
    }

    return true
}
```

## StateChange Builders

The engine provides convenient builders for creating `StateChange` objects that respect the action pipeline:

### Generic Property Builders

```swift
// Set any StateValue on items or locations
let change = await engine.setProperty("customProp", on: item, to: .string("value"))
let change = await engine.setProperty("temperature", on: location, to: .int(72))
```

### Convenience Builders

```swift
// Common patterns have dedicated builders
let change = await engine.setDescription(on: item, to: "A new description")
let change = await engine.setProperty("isOpen", on: door, to: true)
let change = await engine.setProperty("isLit", on: room, to: false)
let change = await engine.setProperty("damage", on: weapon, to: 15)
let change = await engine.setProperty("material", on: armor, to: "steel")
```

### Using StateChanges in Action Handlers

```swift
struct OpenActionHandler: ActionHandler {
    func process(context: ActionContext) async throws -> ActionResult {
        let item = try engine.item(command.directObjectID)

        // Validate the item can be opened
        guard item.hasProperty(.isOpenable) else {
            throw ActionResponse.itemNotOpenable(item)
        }

        // Create state change using builder
        guard let change = await engine.setProperty("isOpen", on: item, to: true) else {
            throw ActionResponse.itemAlreadyOpen(item)
        }

        // Return result with state change - the engine will apply it through the pipeline
        return ActionResult(
            changes: [change],
            message: "🤡 You open \(engine.theThat(item))."
        )
    }
}
```

## ZIL-Inspired Patterns

The dynamic property system enables classic interactive fiction patterns:

### Opening and Closing Objects

```swift
// Similar to ZIL's FSET/FCLEAR for OPENBIT
if let change = await engine.setProperty("isOpen", on: chest, to: true) {
    return ActionResult(changes: [change], message: "🤡 The chest creaks open.")
}
```

### Dynamic Descriptions

```swift
// Similar to ZIL's PUTP for changing descriptions
let trollState = await engine.gameState.items["troll"]?.properties["fighting"]?.toBool ?? false
let newDescription = if trollState {
    "A nasty-looking troll, brandishing a bloody axe, blocks all passages."
} else {
    "An unconscious troll is sprawled on the floor."
}

if let change = await engine.setDescription(on: troll, to: newDescription) {
    return ActionResult(changes: [change])
}
```

### State Transitions

```swift
// Complex state changes with validation
let changes = [
    await engine.setProperty("unconscious", on: troll, to: true),
    await engine.setProperty("fighting", on: troll, to: false),
    await engine.setProperty("isVisible", on: axe, to: true)
].compactMap { $0 }

return ActionResult(
    changes: changes,
    message: "🤡 The troll collapses, dropping his axe!"
)
```

## Best Practices

1. **Always use StateChange builders** instead of direct state mutation
2. **Return StateChanges in ActionResult** to respect the action pipeline
3. **Use validation handlers** for complex state dependencies
4. **Throw specific errors** to provide clear feedback to players
5. **Use convenience methods** for common patterns like flags and descriptions
6. **Register validators early** in your game setup, typically in the `GameBlueprint`
7. **Test edge cases** thoroughly, especially state transitions

## Error Handling

The system throws `ActionResponse` errors for various failure conditions:

- `ActionResponse.internalEngineError`: Item or location doesn't exist
- `ActionResponse.invalidValue`: Validation failed (generic or from validation handlers)
- Custom errors: Thrown by validation handlers for specific conditions

Always handle these appropriately in your action handlers:

```swift
do {
    let result = try await someActionHandler.process(context: context)
    return result
} catch let response as ActionResponse {
    throw response // Re-throw ActionResponse for proper error reporting
} catch {
    throw ActionResponse.internalEngineError("Unexpected error: \(error)")
}
```

## Integration with Action Pipeline

The dynamic property system is fully integrated with the action pipeline:

1. **Validation**: When `StateChange`s are applied, dynamic validation handlers are called automatically
2. **Event Handlers**: Item and location event handlers can create `StateChange`s that trigger validation
3. **Consistency**: All state mutations flow through the same validation and application process
4. **Debugging**: All changes are tracked in `gameState.changeHistory` for debugging

This ensures that your game's state remains consistent and that all business rules are enforced, regardless of how state changes are initiated.
