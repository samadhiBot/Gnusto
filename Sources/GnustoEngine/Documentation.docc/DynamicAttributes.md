# Dynamic Attributes

Learn how to use dynamic attributes and validation handlers to create sophisticated game mechanics while respecting the action pipeline.

## Overview

The Gnusto Engine's dynamic attribute system allows you to create attributes that are computed at runtime or validated when changed. This enables complex game mechanics similar to those found in classic ZIL-based interactive fiction games like Zork.

> **Note**: If you're using the GnustoAutoWiringPlugin, dynamic attribute registrations in your code (like `registerItemCompute(itemID: .sword, attribute: .sharpness)`) are automatically discovered and set up for you. You can focus on writing the logic while the plugin handles the wiring.

**Important**: All attribute changes must flow through the action pipeline using `StateChange` builders. This ensures proper validation, event handling, and consistency.

## Basic Usage

### Reading Attributes

Use the fetch methods to read dynamic or static attributes:

```swift
// Fetch typed values
let sharpness: Int = try await engine.attribute("sharpness", of .sword)
let description: String = try await engine.attribute(.description, of .sword)
let isOpen: Bool = try await engine.attribute(.isOpen, of .door)

// Fetch location attributes
let temperature: String = try await engine.attribute("temperature", of .cave)
```

### Setting Attributes (Respecting the Pipeline)

**Always use `StateChange` builders** to modify attributes. Never bypass the action pipeline:

```swift
// Create StateChange using builders
let item = try engine.item("sword")
if let change = await engine.setAttribute("sharpness", on: item, to: .int(8)) {
    // Apply through the pipeline (usually in an ActionHandler)
    return ActionResult(stateChanges: [change], message: "The sword gleams with sharpness.")
}

// Use convenience builders for common patterns
if let change = await engine.setDescription(on: item, to: "A gleaming blade") {
    return ActionResult(stateChanges: [change])
}

if let change = await engine.setAttribute("isOpen", on: door, to: true) {
    return ActionResult(stateChanges: [change], message: "The door swings open.")
}
```

## Validation Handlers

Validation handlers allow you to enforce rules when attributes are changed, similar to ZIL's property validation. They are called automatically when `StateChange`s are applied.

### Basic Validation

```swift
// Register a validation handler for a specific item and attribute
engine.registerItemValidate(itemID: "door", attributeID: "isOpen") { item, newValue in
    guard case .bool(let isOpening) = newValue else { return false }

    // Can only open if not locked
    if isOpening {
        let isLocked = item.attributes["isLocked"]?.toBool ?? false
        return !isLocked
    }
    return true
}
```

### Complex State Management

Inspired by Zork's troll combat system:

```swift
// Ensure troll state consistency when fighting status changes
engine.registerItemValidate(itemID: "troll", attributeID: "fighting") { item, newValue in
    guard case .bool(let isFighting) = newValue else { return false }

    // If troll stops fighting, it must be unconscious or disarmed
    if !isFighting {
        let hasWeapon = item.attributes["hasWeapon"]?.toBool ?? false
        let isUnconscious = item.attributes["unconscious"]?.toBool ?? false
        return !hasWeapon || isUnconscious
    }
    return true
}
```

### Throwing Specific Errors

Validation handlers can throw specific errors for better user feedback:

```swift
engine.registerItemValidate(itemID: "magicSword", attributeID: "enchantmentLevel") { item, newValue in
    guard case .int(let level) = newValue else {
        throw ActionResponse.prerequisiteNotMet("Enchantment level must be a number")
    }

    if level < 0 || level > 10 {
        throw ActionResponse.prerequisiteNotMet("Enchantment level must be between 0 and 10")
    }

    return true
}
```

## StateChange Builders

The engine provides convenient builders for creating `StateChange` objects that respect the action pipeline:

### Generic Attribute Builders

```swift
// Set any StateValue on items or locations
let change = await engine.setAttribute("customProp", on: item, to: .string("value"))
let change = await engine.setAttribute("temperature", on: location, to: .int(72))
```

### Convenience Builders

```swift
// Common patterns have dedicated builders
let change = await engine.setDescription(on: item, to: "A new description")
let change = await engine.setAttribute("isOpen", on: door, to: true)
let change = await engine.setAttribute("isLit", on: room, to: false)
let change = await engine.setAttribute("damage", on: weapon, to: 15)
let change = await engine.setAttribute("material", on: armor, to: "steel")
```

### Using StateChanges in Action Handlers

```swift
struct OpenActionHandler: ActionHandler {
    func process(context: ActionContext) async throws -> ActionResult {
        let item = try context.engine.item(context.command.directObjectID)

        // Validate the item can be opened
        guard item.hasProperty(.isOpenable) else {
            throw ActionResponse.itemNotOpenable(item)
        }

        // Create state change using builder
        guard let change = await context.engine.setAttribute("isOpen", on: item, to: true) else {
            throw ActionResponse.itemAlreadyOpen(item)
        }

        // Return result with state change - the engine will apply it through the pipeline
        return ActionResult(
            stateChanges: [change],
            message: "You open \(context.engine.theThat(item))."
        )
    }
}
```

## ZIL-Inspired Patterns

The dynamic attribute system enables classic interactive fiction patterns:

### Opening and Closing Objects

```swift
// Similar to ZIL's FSET/FCLEAR for OPENBIT
if let change = await engine.setAttribute("isOpen", on: chest, to: true) {
    return ActionResult(stateChanges: [change], message: "The chest creaks open.")
}
```

### Dynamic Descriptions

```swift
// Similar to ZIL's PUTP for changing descriptions
let trollState = await engine.gameState.items["troll"]?.attributes["fighting"]?.toBool ?? false
let newDescription = if trollState {
    "A nasty-looking troll, brandishing a bloody axe, blocks all passages."
} else {
    "An unconscious troll is sprawled on the floor."
}

if let change = await engine.setDescription(on: troll, to: newDescription) {
    return ActionResult(stateChanges: [change])
}
```

### State Transitions

```swift
// Complex state changes with validation
let changes = [
    await engine.setAttribute("unconscious", on: troll, to: true),
    await engine.setAttribute("fighting", on: troll, to: false),
    await engine.setAttribute("isVisible", on: axe, to: true)
].compactMap { $0 }

return ActionResult(
    stateChanges: changes,
    message: "The troll collapses, dropping his axe!"
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

The dynamic attribute system is fully integrated with the action pipeline:

1. **Validation**: When `StateChange`s are applied, dynamic validation handlers are called automatically
2. **Event Handlers**: Item and location event handlers can create `StateChange`s that trigger validation
3. **Consistency**: All state mutations flow through the same validation and application process
4. **Debugging**: All changes are tracked in `gameState.changeHistory` for debugging

This ensures that your game's state remains consistent and that all business rules are enforced, regardless of how state changes are initiated.
